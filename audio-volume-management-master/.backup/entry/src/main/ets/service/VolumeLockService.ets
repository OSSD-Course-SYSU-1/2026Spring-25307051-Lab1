import { VolumeSetting } from '../model/VolumeSetting';
import { VolumeType, LockStatus } from '../model/TaskEnums';
import { VolumeService } from './VolumeService';
import { VolumeMonitor, VolumeChangeListener } from './VolumeMonitor';
import { Logger } from '../utils/Logger';

const TAG = 'VolumeLockService';

/**
 * 音量锁定服务
 * 用于在时间段内锁定音量，防止用户或系统修改
 */
export class VolumeLockService implements VolumeChangeListener {
  private volumeService: VolumeService;
  private volumeMonitor: VolumeMonitor;
  private lockedVolumes: Map<VolumeType, number> = new Map();
  private lockStatus: LockStatus = LockStatus.INACTIVE;
  private checkInterval: number | null = null;

  constructor(volumeService: VolumeService, volumeMonitor: VolumeMonitor) {
    this.volumeService = volumeService;
    this.volumeMonitor = volumeMonitor;
    this.volumeMonitor.addListener(this);
  }

  /**
   * 开始锁定音量
   */
  async startLock(volumeSettings: VolumeSetting[]): Promise<void> {
    try {
      Logger.info(TAG, 'Starting volume lock');

      // 保存要锁定的音量值
      this.lockedVolumes.clear();
      for (const setting of volumeSettings) {
        this.lockedVolumes.set(setting.volumeType, setting.volumeValue);
      }

      // 立即设置音量
      await this.volumeService.setVolumes(volumeSettings);

      // 更新锁定状态
      this.lockStatus = LockStatus.ACTIVE;

      // 启动定期检查
      this.startPeriodicCheck();

      Logger.info(TAG, 'Volume lock started successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to start volume lock: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 停止锁定音量
   */
  stopLock(): void {
    try {
      Logger.info(TAG, 'Stopping volume lock');

      // 清除锁定音量
      this.lockedVolumes.clear();

      // 更新锁定状态
      this.lockStatus = LockStatus.INACTIVE;

      // 停止定期检查
      this.stopPeriodicCheck();

      Logger.info(TAG, 'Volume lock stopped successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to stop volume lock: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 音量变化回调（实现VolumeChangeListener接口）
   */
  async onVolumeChange(volumeType: VolumeType, volume: number): Promise<void> {
    // 如果锁定未激活，直接返回
    if (this.lockStatus !== LockStatus.ACTIVE) {
      return;
    }

    // 检查是否需要恢复锁定音量
    const lockedVolume = this.lockedVolumes.get(volumeType);
    if (lockedVolume !== undefined && volume !== lockedVolume) {
      Logger.info(TAG, `Volume changed detected: ${volumeType} = ${volume}, restoring to ${lockedVolume}`);

      // 恢复锁定音量
      await this.volumeService.setVolumes([{
        id: '',
        volumeType: volumeType,
        volumeValue: lockedVolume,
        mute: false
      }]);
    }
  }

  /**
   * 启动定期检查
   */
  private startPeriodicCheck(): void {
    // 每5秒检查一次音量
    this.checkInterval = setInterval(() => {
      this.checkVolumes();
    }, 5000);
  }

  /**
   * 停止定期检查
   */
  private stopPeriodicCheck(): void {
    if (this.checkInterval !== null) {
      clearInterval(this.checkInterval);
      this.checkInterval = null;
    }
  }

  /**
   * 检查并恢复音量
   */
  private async checkVolumes(): Promise<void> {
    if (this.lockStatus !== LockStatus.ACTIVE) {
      return;
    }

    try {
      // 检查所有锁定的音量类型
      this.lockedVolumes.forEach((lockedVolume: number, volumeType: VolumeType) => {
        this.volumeMonitor.getCurrentVolume(volumeType).then((currentVolume: number) => {
          if (currentVolume !== lockedVolume) {
            Logger.info(TAG, `Periodic check: restoring ${volumeType} from ${currentVolume} to ${lockedVolume}`);
            this.volumeService.setVolumes([{
              id: '',
              volumeType: volumeType,
              volumeValue: lockedVolume,
              mute: false
            }]);
          }
        });
      });
    } catch (error) {
      Logger.error(TAG, `Failed to check volumes: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 获取锁定状态
   */
  getLockStatus(): LockStatus {
    return this.lockStatus;
  }

  /**
   * 检查是否正在锁定
   */
  isLocking(): boolean {
    return this.lockStatus === LockStatus.ACTIVE;
  }

  /**
   * 获取锁定的音量值
   */
  getLockedVolume(volumeType: VolumeType): number | undefined {
    return this.lockedVolumes.get(volumeType);
  }

  /**
   * 更新锁定的音量值
   */
  async updateLockedVolume(volumeType: VolumeType, volume: number): Promise<void> {
    if (this.lockStatus !== LockStatus.ACTIVE) {
      return;
    }

    try {
      this.lockedVolumes.set(volumeType, volume);
      await this.volumeService.setVolumes([{
        id: '',
        volumeType: volumeType,
        volumeValue: volume,
        mute: false
      }]);
      Logger.info(TAG, `Updated locked volume: ${volumeType} = ${volume}`);
    } catch (error) {
      Logger.error(TAG, `Failed to update locked volume: ${JSON.stringify(error)}`);
    }
  }
}
