import { TimerTask, TimerTaskModel } from '../../framework/model/TimerTask';
import { TaskStatus } from '../../framework/model/TaskEnums';
import { TimerTaskService } from '../../framework/service/TimerTaskService';
import { TimerScheduler } from '../../framework/service/TimerScheduler';
import { TaskValidator, ValidationResult } from '../../framework/utils/TaskValidator';
import { Logger } from '../../framework/utils/Logger';

const TAG = 'TimerTaskViewModel';

/**
 * 任务列表ViewModel接口
 */
export interface ITimerTaskViewModel {
  loadTasks(): Promise<TimerTask[]>;
  toggleTaskStatus(taskId: string): Promise<void>;
  deleteTask(taskId: string): Promise<void>;
  createTask(task: TimerTask): Promise<void>;
  updateTask(task: TimerTask): Promise<void>;
  validateTaskTime(task: TimerTask): boolean;
}

/**
 * 任务列表ViewModel实现
 */
export class TimerTaskViewModel implements ITimerTaskViewModel {
  private taskService: TimerTaskService;
  private scheduler: TimerScheduler;

  constructor(taskService: TimerTaskService, scheduler: TimerScheduler) {
    this.taskService = taskService;
    this.scheduler = scheduler;
  }

  /**
   * 加载任务列表
   */
  async loadTasks(): Promise<TimerTask[]> {
    try {
      const tasks = await this.taskService.getAllTasks();
      
      // 按执行时间排序
      tasks.sort((a, b) => {
        const timeA = this.scheduler.calculateNextExecuteTime(a);
        const timeB = this.scheduler.calculateNextExecuteTime(b);
        
        // 启用的任务排在前面
        if (a.status === TaskStatus.ENABLED && b.status !== TaskStatus.ENABLED) {
          return -1;
        }
        if (a.status !== TaskStatus.ENABLED && b.status === TaskStatus.ENABLED) {
          return 1;
        }
        
        // 同状态按时间排序
        return timeA - timeB;
      });

      Logger.info(TAG, `Loaded ${tasks.length} tasks`);
      return tasks;
    } catch (error) {
      Logger.error(TAG, `Failed to load tasks: ${JSON.stringify(error)}`);
      throw new Error('Failed to load tasks');
    }
  }

  /**
   * 切换任务状态
   */
  async toggleTaskStatus(taskId: string): Promise<void> {
    try {
      const task = await this.taskService.getTaskById(taskId);
      if (!task) {
        Logger.error(TAG, `Task not found: ${taskId}`);
        return;
      }

      const newStatus = task.status === TaskStatus.ENABLED ? TaskStatus.DISABLED : TaskStatus.ENABLED;
      await this.taskService.updateTaskStatus(taskId, newStatus);

      // 如果启用，重新调度任务
      if (newStatus === TaskStatus.ENABLED) {
        this.scheduler.scheduleTask(task);
      } else {
        this.scheduler.cancelTask(taskId);
      }

      Logger.info(TAG, `Task status toggled: ${taskId} -> ${newStatus}`);
    } catch (error) {
      Logger.error(TAG, `Failed to toggle task status: ${JSON.stringify(error)}`);
      throw new Error('Failed to toggle task status');
    }
  }

  /**
   * 删除任务
   */
  async deleteTask(taskId: string): Promise<void> {
    try {
      // 取消调度
      this.scheduler.cancelTask(taskId);

      // 删除任务
      await this.taskService.deleteTask(taskId);

      Logger.info(TAG, `Task deleted: ${taskId}`);
    } catch (error) {
      Logger.error(TAG, `Failed to delete task: ${JSON.stringify(error)}`);
      throw new Error('Failed to delete task');
    }
  }

  /**
   * 创建任务
   */
  async createTask(task: TimerTask): Promise<void> {
    try {
      // 验证任务
      const validation: ValidationResult = TaskValidator.validateTask(task);
      if (!validation.valid) {
        throw new Error(validation.message);
      }

      // 保存任务
      await this.taskService.saveTask(task);

      // 调度任务
      this.scheduler.scheduleTask(task);

      Logger.info(TAG, `Task created: ${task.id}`);
    } catch (error) {
      Logger.error(TAG, `Failed to create task: ${JSON.stringify(error)}`);
      throw new Error('Failed to create task');
    }
  }

  /**
   * 更新任务
   */
  async updateTask(task: TimerTask): Promise<void> {
    try {
      // 验证任务
      const validation: ValidationResult = TaskValidator.validateTask(task);
      if (!validation.valid) {
        throw new Error(validation.message);
      }

      // 保存任务
      await this.taskService.saveTask(task);

      // 重新调度任务
      this.scheduler.cancelTask(task.id);
      if (task.status === TaskStatus.ENABLED) {
        this.scheduler.scheduleTask(task);
      }

      Logger.info(TAG, `Task updated: ${task.id}`);
    } catch (error) {
      Logger.error(TAG, `Failed to update task: ${JSON.stringify(error)}`);
      throw new Error('Failed to update task');
    }
  }

  /**
   * 验证任务时间有效性
   */
  validateTaskTime(task: TimerTask): boolean {
    return TaskValidator.validateTime(task);
  }
}
