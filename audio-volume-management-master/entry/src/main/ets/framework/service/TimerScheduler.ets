import { TimerTask } from '../model/TimerTask';
import { TaskExecution, TaskExecutionModel } from '../model/TaskExecution';
import { TaskStatus, TimeMode, TaskType } from '../model/TaskEnums';
import { TimerTaskService } from './TimerTaskService';
import { VolumeService } from './VolumeService';
import { VolumeMonitor } from './VolumeMonitor';
import { PeriodLockManager } from './PeriodLockManager';
import { Logger } from '../utils/Logger';

const TAG = 'TimerScheduler';

/**
 * 定时调度服务接口
 */
export interface ITimerScheduler {
  scheduleTask(task: TimerTask): void;
  cancelTask(taskId: string): void;
  executeTask(task: TimerTask): Promise<void>;
  rescheduleAllTasks(): Promise<void>;
  calculateNextExecuteTime(task: TimerTask): number;
}

/**
 * 定时调度服务实现
 * 
 * 注意：这是一个简化实现，使用setTimeout进行定时调度
 * 完整实现应使用HarmonyOS的backgroundTaskManager和reminderRequestManager
 */
export class TimerScheduler implements ITimerScheduler {
  private taskService: TimerTaskService;
  private volumeService: VolumeService;
  private volumeMonitor: VolumeMonitor;
  private periodLockManager: PeriodLockManager;
  private scheduledTasks: Map<string, number> = new Map(); // taskId -> timerId

  constructor(taskService: TimerTaskService, volumeService: VolumeService) {
    this.taskService = taskService;
    this.volumeService = volumeService;
    this.volumeMonitor = new VolumeMonitor();
    this.periodLockManager = new PeriodLockManager(volumeService, this.volumeMonitor);
  }

  /**
   * 调度任务
   */
  scheduleTask(task: TimerTask): void {
    try {
      // 取消已存在的调度
      this.cancelTask(task.id);

      // 计算下一次执行时间
      const nextExecuteTime = this.calculateNextExecuteTime(task);
      const delay = nextExecuteTime - Date.now();

      if (delay <= 0) {
        Logger.warn(TAG, `Task ${task.id} execution time has passed`);
        return;
      }

      // 使用setTimeout调度任务
      const timerId = setTimeout(() => {
        this.executeTask(task);
      }, delay);

      this.scheduledTasks.set(task.id, timerId);
      Logger.info(TAG, `Task scheduled: ${task.id}, delay=${delay}ms`);
    } catch (error) {
      Logger.error(TAG, `Failed to schedule task: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 取消任务调度
   */
  cancelTask(taskId: string): void {
    try {
      const timerId = this.scheduledTasks.get(taskId);
      if (timerId !== undefined) {
        clearTimeout(timerId);
        this.scheduledTasks.delete(taskId);
        Logger.info(TAG, `Task cancelled: ${taskId}`);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to cancel task: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 执行任务
   */
  async executeTask(task: TimerTask): Promise<void> {
    try {
      Logger.info(TAG, `Executing task: ${task.id}`);

      // 检查任务状态
      const currentTask = await this.taskService.getTaskById(task.id);
      if (!currentTask || currentTask.status !== TaskStatus.ENABLED) {
        Logger.warn(TAG, `Task ${task.id} is not enabled, skip execution`);
        return;
      }

      // 根据任务类型执行不同的操作
      if (task.taskType === TaskType.PERIOD) {
        // 时间段锁定任务
        await this.periodLockManager.startPeriodLock(task);
      } else {
        // 瞬时任务：立即设置音量
        this.volumeService.setVolumes(task.volumeSettings);
      }

      // 记录执行结果
      const execution = new TaskExecutionModel({
        taskId: task.id,
        executeTime: Date.now(),
        result: 'SUCCESS'
      });
      await this.taskService.recordExecution(execution);

      // 更新任务状态
      if (task.timeMode === TimeMode.ONCE) {
        // 单次任务标记为已完成
        await this.taskService.updateTaskStatus(task.id, TaskStatus.COMPLETED);
        Logger.info(TAG, `Task ${task.id} completed`);
      } else {
        // 循环任务重新调度
        await this.taskService.updateTaskStatus(task.id, TaskStatus.ENABLED);
        this.scheduleTask(task);
        Logger.info(TAG, `Task ${task.id} rescheduled`);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to execute task: ${JSON.stringify(error)}`);

      // 记录执行失败
      const execution = new TaskExecutionModel({
        taskId: task.id,
        executeTime: Date.now(),
        result: 'FAILED',
        errorMessage: JSON.stringify(error)
      });
      await this.taskService.recordExecution(execution);
    }
  }

  /**
   * 重新调度所有任务（系统重启后）
   */
  async rescheduleAllTasks(): Promise<void> {
    try {
      Logger.info(TAG, 'Rescheduling all tasks');

      // 获取所有启用的任务
      const allTasks = await this.taskService.getAllTasks();
      const enabledTasks = allTasks.filter(task => task.status === TaskStatus.ENABLED);

      // 重新调度每个任务
      for (const task of enabledTasks) {
        this.scheduleTask(task);

        // 对于时间段锁定任务，检查并恢复锁定
        if (task.taskType === TaskType.PERIOD) {
          await this.periodLockManager.checkAndRestoreLock(task);
        }
      }

      Logger.info(TAG, `Rescheduled ${enabledTasks.length} tasks`);
    } catch (error) {
      Logger.error(TAG, `Failed to reschedule all tasks: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 计算下一次执行时间
   */
  calculateNextExecuteTime(task: TimerTask): number {
    const now = new Date();

    if (task.timeMode === TimeMode.ONCE) {
      return task.executeTime!;
    } else if (task.timeMode === TimeMode.WEEKLY) {
      // 计算下一个指定星期几的时间
      const targetDay = task.dayOfWeek!; // 1-7, 1=周一
      const currentDay = now.getDay(); // 0-6, 0=周日
      const currentDayNormalized = currentDay === 0 ? 7 : currentDay; // 转换为1-7

      let daysUntil = targetDay - currentDayNormalized;
      if (daysUntil < 0) {
        daysUntil += 7;
      } else if (daysUntil === 0) {
        // 今天，检查时间是否已过
        const targetTime = new Date(now);
        targetTime.setHours(task.hour, task.minute, 0, 0);
        if (targetTime.getTime() <= now.getTime()) {
          daysUntil = 7;
        }
      }

      const nextDate = new Date(now);
      nextDate.setDate(now.getDate() + daysUntil);
      nextDate.setHours(task.hour, task.minute, 0, 0);

      return nextDate.getTime();
    } else {
      // 每月循环
      const targetDate = task.dayOfMonth!;
      const nextDate = new Date(now);

      // 检查当月是否有该日期
      const daysInCurrentMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();

      if (targetDate <= daysInCurrentMonth && now.getDate() < targetDate) {
        // 当月有该日期且未到
        nextDate.setDate(targetDate);
      } else if (targetDate <= daysInCurrentMonth && now.getDate() === targetDate) {
        // 今天是该日期，检查时间
        const targetTime = new Date(now);
        targetTime.setHours(task.hour, task.minute, 0, 0);
        if (targetTime.getTime() <= now.getTime()) {
          // 时间已过，下个月
          nextDate.setMonth(now.getMonth() + 1);
          const daysInNextMonth = new Date(nextDate.getFullYear(), nextDate.getMonth() + 1, 0).getDate();
          if (targetDate <= daysInNextMonth) {
            nextDate.setDate(targetDate);
          } else {
            // 下个月没有该日期，再下个月
            nextDate.setMonth(nextDate.getMonth() + 1);
            nextDate.setDate(targetDate);
          }
        }
      } else {
        // 当月已过或没有该日期，下个月
        nextDate.setMonth(now.getMonth() + 1);
        const daysInNextMonth = new Date(nextDate.getFullYear(), nextDate.getMonth() + 1, 0).getDate();
        if (targetDate <= daysInNextMonth) {
          nextDate.setDate(targetDate);
        } else {
          // 下个月没有该日期，再下个月
          nextDate.setMonth(nextDate.getMonth() + 1);
          nextDate.setDate(targetDate);
        }
      }

      nextDate.setHours(task.hour, task.minute, 0, 0);
      return nextDate.getTime();
    }
  }
}
