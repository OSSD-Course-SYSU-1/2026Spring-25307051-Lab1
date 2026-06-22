import { TimerTask, TimerTaskModel } from '../model/TimerTask';
import { TaskType, LockStatus } from '../model/TaskEnums';
import { VolumeLockService } from './VolumeLockService';
import { VolumeMonitor } from './VolumeMonitor';
import { VolumeService } from './VolumeService';
import { Logger } from '../utils/Logger';

const TAG = 'PeriodLockManager';

/**
 * 时间段锁定管理器
 * 管理所有时间段锁定任务的激活和停用
 */
export class PeriodLockManager {
  private volumeLockService: VolumeLockService;
  private volumeMonitor: VolumeMonitor;
  private volumeService: VolumeService;
  private activeLocks: Map<string, number> = new Map(); // taskId -> timer

  constructor(volumeService: VolumeService, volumeMonitor: VolumeMonitor) {
    this.volumeService = volumeService;
    this.volumeMonitor = volumeMonitor;
    this.volumeLockService = new VolumeLockService(volumeService, volumeMonitor);
  }

  /**
   * 启动时间段锁定任务
   */
  async startPeriodLock(task: TimerTask): Promise<void> {
    try {
      if (task.taskType !== TaskType.PERIOD) {
        Logger.warn(TAG, `Task ${task.id} is not a period lock task`);
        return;
      }

      Logger.info(TAG, `Starting period lock for task ${task.id}`);

      // 检查是否已经在锁定时间段内
      if (this.isInLockPeriod(task)) {
        // 立即激活锁定
        await this.activateLock(task);
      }

      // 设置结束时间定时器
      this.scheduleLockEnd(task);

      Logger.info(TAG, `Period lock started for task ${task.id}`);
    } catch (error) {
      Logger.error(TAG, `Failed to start period lock: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 停止时间段锁定任务
   */
  stopPeriodLock(taskId: string): void {
    try {
      Logger.info(TAG, `Stopping period lock for task ${taskId}`);

      // 清除定时器
      const timer = this.activeLocks.get(taskId);
      if (timer) {
        clearTimeout(timer);
        this.activeLocks.delete(taskId);
      }

      // 如果是当前激活的锁定，停止它
      if (this.volumeLockService.isLocking()) {
        this.volumeLockService.stopLock();
      }

      Logger.info(TAG, `Period lock stopped for task ${taskId}`);
    } catch (error) {
      Logger.error(TAG, `Failed to stop period lock: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 激活锁定
   */
  private async activateLock(task: TimerTask): Promise<void> {
    try {
      Logger.info(TAG, `Activating lock for task ${task.id}`);

      // 启动音量锁定
      await this.volumeLockService.startLock(task.volumeSettings);

      // 更新任务锁定状态
      task.lockStatus = LockStatus.ACTIVE;

      Logger.info(TAG, `Lock activated for task ${task.id}`);
    } catch (error) {
      Logger.error(TAG, `Failed to activate lock: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 停用锁定
   */
  private deactivateLock(task: TimerTask): void {
    try {
      Logger.info(TAG, `Deactivating lock for task ${task.id}`);

      // 停止音量锁定
      this.volumeLockService.stopLock();

      // 更新任务锁定状态
      task.lockStatus = LockStatus.INACTIVE;

      Logger.info(TAG, `Lock deactivated for task ${task.id}`);
    } catch (error) {
      Logger.error(TAG, `Failed to deactivate lock: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 调度锁定结束
   */
  private scheduleLockEnd(task: TimerTask): void {
    try {
      const lockEndTime = this.getLockEndTime(task);
      const delay = lockEndTime - Date.now();

      if (delay <= 0) {
        Logger.warn(TAG, `Lock end time has passed for task ${task.id}`);
        return;
      }

      // 设置定时器，在结束时停用锁定
      const timer = setTimeout(() => {
        this.deactivateLock(task);
        this.activeLocks.delete(task.id);
      }, delay);

      this.activeLocks.set(task.id, timer);

      Logger.info(TAG, `Lock end scheduled for task ${task.id} in ${delay}ms`);
    } catch (error) {
      Logger.error(TAG, `Failed to schedule lock end: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 检查并恢复锁定（系统重启后）
   */
  async checkAndRestoreLock(task: TimerTask): Promise<void> {
    try {
      if (task.taskType !== TaskType.PERIOD) {
        return;
      }

      // 检查是否在锁定时间段内
      if (this.isInLockPeriod(task)) {
        Logger.info(TAG, `Restoring lock for task ${task.id} after system restart`);
        await this.activateLock(task);
        this.scheduleLockEnd(task);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to check and restore lock: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 获取锁定服务
   */
  getLockService(): VolumeLockService {
    return this.volumeLockService;
  }

  /**
   * 检查是否有激活的锁定
   */
  hasActiveLock(): boolean {
    return this.volumeLockService.isLocking();
  }

  /**
   * 清理所有锁定
   */
  cleanup(): void {
    Logger.info(TAG, 'Cleaning up all period locks');

    // 清除所有定时器
    this.activeLocks.forEach((timer: number) => {
      clearTimeout(timer);
    });
    this.activeLocks.clear();

    // 停止音量锁定
    this.volumeLockService.stopLock();
  }

  /**
   * 检查当前是否在锁定时间段内
   */
  private isInLockPeriod(task: TimerTask): boolean {
    if (task.taskType !== TaskType.PERIOD) {
      return false;
    }

    const now = new Date();
    const currentHour = now.getHours();
    const currentMinute = now.getMinutes();
    const currentTime = currentHour * 60 + currentMinute;

    const startTime = task.hour * 60 + task.minute;
    const endTime = task.endHour! * 60 + task.endMinute!;

    // 处理跨天情况（例如：22:00 - 06:00）
    if (startTime > endTime) {
      return currentTime >= startTime || currentTime <= endTime;
    } else {
      return currentTime >= startTime && currentTime <= endTime;
    }
  }

  /**
   * 计算锁定结束时间戳
   */
  private getLockEndTime(task: TimerTask): number {
    const now = new Date();
    const endDate = new Date(now);

    // 设置结束时间
    endDate.setHours(task.endHour!, task.endMinute!, 0, 0);

    // 如果结束时间小于开始时间，说明跨天了
    const startTime = task.hour * 60 + task.minute;
    const endTime = task.endHour! * 60 + task.endMinute!;

    if (startTime > endTime && !this.isInLockPeriod(task)) {
      // 不在锁定时间段内，且跨天，结束时间应该是明天
      endDate.setDate(endDate.getDate() + 1);
    }

    return endDate.getTime();
  }
}
