import { VolumeType } from './TaskEnums';

/**
 * 音量设置接口
 */
export interface VolumeSetting {
  id: string;              // 唯一标识符
  volumeType: VolumeType;  // 音量类型
  targetApp?: string;      // 目标应用包名（仅当volumeType为APP时需要）
  volumeValue: number;     // 音量值（0-100）
  mute?: boolean;          // 是否静音（关闭振动）
}

/**
 * 音量设置模型类
 */
export class VolumeSettingModel implements VolumeSetting {
  id: string;
  volumeType: VolumeType;
  targetApp?: string;
  volumeValue: number;
  mute?: boolean;

  constructor(
    id?: string,
    volumeType?: VolumeType,
    targetApp?: string,
    volumeValue?: number,
    mute?: boolean
  ) {
    this.id = id ?? this.generateUUID();
    this.volumeType = volumeType ?? VolumeType.MEDIA;
    this.targetApp = targetApp;
    this.volumeValue = volumeValue ?? 50;
    this.mute = mute ?? false;
  }

  /**
   * 生成UUID
   */
  private generateUUID(): string {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
      const r = Math.random() * 16 | 0;
      const v = c === 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  }

  /**
   * 获取音量类型显示名称
   */
  getDisplayName(): string {
    switch (this.volumeType) {
      case VolumeType.MEDIA:
        return '媒体音量';
      case VolumeType.RINGTONE:
        return '铃声音量';
      case VolumeType.NOTIFICATION:
        return '通知音量';
      case VolumeType.ALARM:
        return '闹钟音量';
      case VolumeType.APP:
        return this.targetApp || '应用音量';
      default:
        return '未知音量';
    }
  }
}
