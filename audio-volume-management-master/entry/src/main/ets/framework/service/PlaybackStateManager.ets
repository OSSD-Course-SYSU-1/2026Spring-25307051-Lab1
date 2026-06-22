/**
 * 播放状态管理器
 * 实现多端播放状态同步
 */
import distributedDataObject from '@ohos.data.distributedDataObject';
import { Logger } from './Logger';

const TAG = 'PlaybackStateManager';

/**
 * 播放状态数据结构
 */
export interface PlaybackState {
  songId: string;        // 歌曲ID
  songName: string;      // 歌曲名称
  progress: number;      // 播放进度(毫秒)
  duration: number;      // 总时长(毫秒)
  isPlaying: boolean;    // 是否播放中
  volume: number;        // 音量
  timestamp: number;     // 时间戳
}

/**
 * 播放状态管理器
 * 实现多端播放状态同步
 */
export class PlaybackStateManager {
  private static instance: PlaybackStateManager;
  private d_object: distributedDataObject.DistributedObject | null = null;
  private context: Context;
  private listeners: Array<(state: PlaybackState) => void> = [];
  private sessionId: string = '';

  private constructor(context: Context) {
    this.context = context;
    this.initDistributedObject();
  }

  /**
   * 获取单例实例
   */
  static getInstance(context: Context): PlaybackStateManager {
    if (!PlaybackStateManager.instance) {
      PlaybackStateManager.instance = new PlaybackStateManager(context);
    }
    return PlaybackStateManager.instance;
  }

  /**
   * 初始化分布式数据对象
   */
  private initDistributedObject(): void {
    try {
      const initialState: PlaybackState = {
        songId: '',
        songName: '',
        progress: 0,
        duration: 0,
        isPlaying: false,
        volume: 50,
        timestamp: Date.now()
      };

      this.d_object = distributedDataObject.create(this.context, initialState);

      // 监听数据变化
      this.d_object.on('change', (sessionId: string, fields: Array<string>) => {
        Logger.info(TAG, `Data changed: ${fields.join(', ')}`);
        this.notifyListeners();
      });

      Logger.info(TAG, 'Distributed object initialized');
    } catch (error) {
      Logger.error(TAG, `Failed to init distributed object: ${error}`);
    }
  }

  /**
   * 设置会话ID(加入协同组)
   */
  setSessionId(sessionId: string): void {
    if (this.d_object) {
      this.sessionId = sessionId;
      this.d_object.setSessionId(sessionId);
      Logger.info(TAG, `Session ID set: ${sessionId}`);
    }
  }

  /**
   * 生成新的会话ID(创建协同组)
   */
  generateSessionId(): string {
    const sessionId = distributedDataObject.genSessionId();
    Logger.info(TAG, `Generated session ID: ${sessionId}`);
    return sessionId;
  }

  /**
   * 获取当前会话ID
   */
  getSessionId(): string {
    return this.sessionId;
  }

  /**
   * 更新播放状态
   */
  updatePlaybackState(state: Partial<PlaybackState>): void {
    if (!this.d_object) return;

    try {
      // 更新分布式数据对象
      Object.keys(state).forEach((key) => {
        (this.d_object as any)[key] = (state as any)[key];
      });

      // 更新时间戳
      this.d_object['timestamp'] = Date.now();

      Logger.info(TAG, `Playback state updated: ${JSON.stringify(state)}`);
    } catch (error) {
      Logger.error(TAG, `Failed to update playback state: ${error}`);
    }
  }

  /**
   * 获取当前播放状态
   */
  getPlaybackState(): PlaybackState {
    if (!this.d_object) {
      return {
        songId: '',
        songName: '',
        progress: 0,
        duration: 0,
        isPlaying: false,
        volume: 50,
        timestamp: Date.now()
      };
    }

    return {
      songId: this.d_object['songId'] as string,
      songName: this.d_object['songName'] as string,
      progress: this.d_object['progress'] as number,
      duration: this.d_object['duration'] as number,
      isPlaying: this.d_object['isPlaying'] as boolean,
      volume: this.d_object['volume'] as number,
      timestamp: this.d_object['timestamp'] as number
    };
  }

  /**
   * 监听播放状态变化
   */
  onStateChange(listener: (state: PlaybackState) => void): void {
    this.listeners.push(listener);
  }

  /**
   * 移除监听器
   */
  offStateChange(listener: (state: PlaybackState) => void): void {
    const index = this.listeners.indexOf(listener);
    if (index > -1) {
      this.listeners.splice(index, 1);
    }
  }

  /**
   * 通知所有监听器
   */
  private notifyListeners(): void {
    const state = this.getPlaybackState();
    this.listeners.forEach(listener => {
      try {
        listener(state);
      } catch (error) {
        Logger.error(TAG, `Listener error: ${error}`);
      }
    });
  }

  /**
   * 保存分布式数据对象(用于迁移)
   */
  async save(targetDevice: string): Promise<void> {
    if (!this.d_object) return;

    try {
      await this.d_object.save(targetDevice);
      Logger.info(TAG, `Data saved to device: ${targetDevice}`);
    } catch (error) {
      Logger.error(TAG, `Failed to save data: ${error}`);
    }
  }

  /**
   * 监听数据恢复状态
   */
  onRestore(callback: (sessionId: string, networkId: string, status: string) => void): void {
    if (!this.d_object) return;

    this.d_object.on('status', (sessionId: string, networkId: string, status: string) => {
      Logger.info(TAG, `Data status: ${status}, sessionId: ${sessionId}`);
      callback(sessionId, networkId, status);
    });
  }

  /**
   * 销毁实例
   */
  destroy(): void {
    if (this.d_object) {
      this.d_object.off('change');
      this.d_object.off('status');
      this.d_object = null;
    }
    this.listeners = [];
    PlaybackStateManager.instance = null as any;
    Logger.info(TAG, 'PlaybackStateManager destroyed');
  }
}
