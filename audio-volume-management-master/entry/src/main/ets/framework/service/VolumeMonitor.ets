import audio from '@ohos.multimedia.audio';
import { Logger } from '../utils/Logger';
import { VolumeType } from '../model/TaskEnums';

const TAG = 'VolumeMonitor';

/**
 * 音量变化监听器接口
 */
export interface VolumeChangeListener {
  onVolumeChange(volumeType: VolumeType, volume: number): void;
}

/**
 * 音量监听器
 * 用于监听系统音量变化
 */
export class VolumeMonitor {
  private audioManager: audio.AudioManager;
  private listeners: Set<VolumeChangeListener> = new Set();
  private isMonitoring: boolean = false;

  constructor() {
    this.audioManager = audio.getAudioManager();
  }

  /**
   * 开始监听音量变化
   */
  async startMonitoring(): Promise<void> {
    if (this.isMonitoring) {
      Logger.warn(TAG, 'Volume monitoring is already started');
      return;
    }

    try {
      // 监听媒体音量变化
      await this.audioManager.getVolume(audio.AudioVolumeType.MEDIA);
      this.isMonitoring = true;
      Logger.info(TAG, 'Volume monitoring started');
    } catch (error) {
      Logger.error(TAG, `Failed to start monitoring: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 停止监听音量变化
   */
  stopMonitoring(): void {
    if (!this.isMonitoring) {
      return;
    }

    this.isMonitoring = false;
    Logger.info(TAG, 'Volume monitoring stopped');
  }

  /**
   * 添加音量变化监听器
   */
  addListener(listener: VolumeChangeListener): void {
    this.listeners.add(listener);
    Logger.info(TAG, `Listener added, total listeners: ${this.listeners.size}`);
  }

  /**
   * 移除音量变化监听器
   */
  removeListener(listener: VolumeChangeListener): void {
    this.listeners.delete(listener);
    Logger.info(TAG, `Listener removed, total listeners: ${this.listeners.size}`);
  }

  /**
   * 通知所有监听器音量变化
   */
  notifyVolumeChange(volumeType: VolumeType, volume: number): void {
    Logger.info(TAG, `Notifying volume change: ${volumeType} = ${volume}`);
    this.listeners.forEach(listener => {
      try {
        listener.onVolumeChange(volumeType, volume);
      } catch (error) {
        Logger.error(TAG, `Failed to notify listener: ${JSON.stringify(error)}`);
      }
    });
  }

  /**
   * 获取当前音量
   */
  async getCurrentVolume(volumeType: VolumeType): Promise<number> {
    try {
      const audioVolumeType = this.convertVolumeType(volumeType);
      const volume = await this.audioManager.getVolume(audioVolumeType);
      return volume;
    } catch (error) {
      Logger.error(TAG, `Failed to get current volume: ${JSON.stringify(error)}`);
      return 0;
    }
  }

  /**
   * 转换音量类型
   */
  private convertVolumeType(volumeType: VolumeType): audio.AudioVolumeType {
    switch (volumeType) {
      case VolumeType.MEDIA:
        return audio.AudioVolumeType.MEDIA;
      case VolumeType.RINGTONE:
        return audio.AudioVolumeType.RINGTONE;
      case VolumeType.NOTIFICATION:
        // NOTIFICATION类型映射到RINGTONE
        return audio.AudioVolumeType.RINGTONE;
      case VolumeType.ALARM:
        return audio.AudioVolumeType.ALARM;
      default:
        return audio.AudioVolumeType.MEDIA;
    }
  }

  /**
   * 检查是否正在监听
   */
  isMonitoringActive(): boolean {
    return this.isMonitoring;
  }
}
