import { audio } from '@kit.AudioKit';
import { VolumeSetting } from '../model/VolumeSetting';
import { VolumeType } from '../model/TaskEnums';
import { AudioVolumeController } from '../../communication/audio/AudioVolumeController';
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
  // 保存静音前的音量值，用于取消静音时恢复
  private volumeBeforeMute: Map<audio.StreamUsage, number> = new Map();

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
   * 注意：HarmonyOS不允许应用直接修改系统音量
   * 只能通过setAppVolumePercentage修改应用音量
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

      Logger.info(TAG, `Setting system volume: stream=${streamType}, percentage=${volume}%, actualVolume=${clampedVolume}, range=[${minVolume}-${maxVolume}]`);

      // HarmonyOS不允许应用直接修改系统音量
      // 使用应用音量作为替代方案
      this.audioVolumeController.setAppVolumePercentage(clampedVolume);
      
      Logger.info(TAG, `App volume set successfully: stream=${streamType}, volume=${clampedVolume}`);
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
   * 设置静音状态
   * 使用音量控制实现静音效果，并保存静音前的音量值以便恢复
   */
  setMute(streamType: audio.StreamUsage, mute: boolean): void {
    try {
      if (!this.audioVolumeManager) {
        Logger.error(TAG, 'AudioVolumeManager is not initialized');
        return;
      }

      if (mute) {
        // 静音前先保存当前音量值
        const currentVolume = this.audioVolumeManager.getVolumeByStream(streamType) ?? 50;
        this.volumeBeforeMute.set(streamType, currentVolume);
        
        // 设置音量为最小值实现静音
        const minVolume = this.audioVolumeManager.getMinVolumeByStream(streamType) ?? 0;
        this.setSystemVolume(streamType, minVolume);
        Logger.info(TAG, `Mute set: stream=${streamType}, mute=true, saved volume=${currentVolume}`);
      } else {
        // 取消静音，恢复之前的音量值
        const savedVolume = this.volumeBeforeMute.get(streamType);
        if (savedVolume !== undefined) {
          this.setSystemVolume(streamType, savedVolume);
          Logger.info(TAG, `Mute unset: stream=${streamType}, restored volume=${savedVolume}`);
        } else {
          // 如果没有保存的音量值，恢复到默认值50%
          this.setSystemVolume(streamType, 50);
          Logger.info(TAG, `Mute unset: stream=${streamType}, restored to default 50%`);
        }
      }
    } catch (error) {
      Logger.error(TAG, `Failed to set mute: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 批量设置音量
   */
  setVolumes(settings: VolumeSetting[]): void {
    try {
      Logger.info(TAG, `Setting ${settings.length} volume settings`);
      
      for (const setting of settings) {
        Logger.info(TAG, `Processing volume setting: type=${setting.volumeType}, volume=${setting.volumeValue}%, mute=${setting.mute}`);
        
        const streamType = this.mapVolumeTypeToStreamUsage(setting.volumeType);
        if (streamType !== null) {
          // 优先处理静音设置
          if (setting.mute) {
            Logger.info(TAG, `Setting mute for ${setting.volumeType}`);
            this.setMute(streamType, true);
          } else {
            Logger.info(TAG, `Setting volume for ${setting.volumeType}: ${setting.volumeValue}%`);
            this.setMute(streamType, false);
            this.setSystemVolume(streamType, setting.volumeValue);
          }
        } else if (setting.volumeType === VolumeType.APP && setting.targetApp) {
          this.setAppVolume(setting.targetApp, setting.volumeValue);
        }
      }
      Logger.info(TAG, `All ${settings.length} volume settings processed`);
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
