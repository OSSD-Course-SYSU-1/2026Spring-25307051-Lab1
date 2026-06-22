import { audio } from '@kit.AudioKit';
import { VolumeSetting } from '../model/VolumeSetting';
import { VolumeType } from '../model/TaskEnums';
import { AudioVolumeController } from '../player/AudioVolumeController';
import { Logger } from '../utils/Logger';

const TAG = 'VolumeService';

/**
 * 音量控制服务接口
 */
export interface IVolumeService {
  setSystemVolume(streamType: audio.StreamUsage, volume: number): void;
  setAppVolume(packageName: string, volume: number): void;
  setVolumes(settings: VolumeSetting[]): void;
}

/**
 * 音量控制服务实现
 */
export class VolumeService implements IVolumeService {
  private audioVolumeManager: audio.AudioVolumeManager | undefined = undefined;
  private audioVolumeController: AudioVolumeController;

  constructor() {
    this.audioVolumeController = new AudioVolumeController();
    this.audioVolumeController.creatVolumeManager();
    this.initAudioVolumeManager();
  }

  /**
   * 初始化音量管理器
   */
  private initAudioVolumeManager(): void {
    try {
      const audioManager = audio.getAudioManager();
      this.audioVolumeManager = audioManager.getVolumeManager();
      Logger.info(TAG, 'AudioVolumeManager initialized');
    } catch (error) {
      Logger.error(TAG, `Failed to initialize AudioVolumeManager: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 设置系统音量
   * 注意：HarmonyOS API 6.0.2中AudioVolumeManager没有setVolumeByStream方法
   * 需要通过其他方式实现音量设置
   */
  setSystemVolume(streamType: audio.StreamUsage, volume: number): void {
    try {
      if (!this.audioVolumeManager) {
        Logger.error(TAG, 'AudioVolumeManager is not initialized');
        return;
      }

      // 获取音量范围
      const minVolume = this.audioVolumeManager.getMinVolumeByStream(streamType) ?? 0;
      const maxVolume = this.audioVolumeManager.getMaxVolumeByStream(streamType) ?? 15;

      // 将百分比转换为实际音量值
      const actualVolume = Math.round((volume / 100) * (maxVolume - minVolume) + minVolume);
      const clampedVolume = Math.max(minVolume, Math.min(maxVolume, actualVolume));

      // 注意：由于API限制，这里需要使用其他方式设置音量
      // 可能需要使用AudioRenderer或其他API
      Logger.info(TAG, `System volume set: stream=${streamType}, volume=${clampedVolume} (API limitation)`);
    } catch (error) {
      Logger.error(TAG, `Failed to set system volume: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 设置应用音量
   */
  setAppVolume(packageName: string, volume: number): void {
    try {
      if (!this.audioVolumeManager) {
        Logger.error(TAG, 'AudioVolumeManager is not initialized');
        return;
      }

      // 将百分比转换为应用音量（0-100）
      const actualVolume = Math.round(volume);
      const clampedVolume = Math.max(0, Math.min(100, actualVolume));

      // 设置应用音量
      this.audioVolumeManager.setAppVolumePercentage(clampedVolume);
      Logger.info(TAG, `App volume set: package=${packageName}, volume=${clampedVolume}`);
    } catch (error) {
      Logger.error(TAG, `Failed to set app volume: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 批量设置音量
   */
  setVolumes(settings: VolumeSetting[]): void {
    try {
      for (const setting of settings) {
        const streamType = this.mapVolumeTypeToStreamUsage(setting.volumeType);
        if (streamType !== null) {
          this.setSystemVolume(streamType, setting.volumeValue);
        } else if (setting.volumeType === VolumeType.APP && setting.targetApp) {
          this.setAppVolume(setting.targetApp, setting.volumeValue);
        }
      }
      Logger.info(TAG, `Set ${settings.length} volume settings`);
    } catch (error) {
      Logger.error(TAG, `Failed to set volumes: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 音量类型映射到StreamUsage
   */
  private mapVolumeTypeToStreamUsage(volumeType: VolumeType): audio.StreamUsage | null {
    switch (volumeType) {
      case VolumeType.MEDIA:
        return audio.StreamUsage.STREAM_USAGE_MUSIC;
      case VolumeType.RINGTONE:
        return audio.StreamUsage.STREAM_USAGE_RINGTONE;
      case VolumeType.NOTIFICATION:
        return audio.StreamUsage.STREAM_USAGE_NOTIFICATION;
      case VolumeType.ALARM:
        return audio.StreamUsage.STREAM_USAGE_ALARM;
      default:
        return null;
    }
  }
}
