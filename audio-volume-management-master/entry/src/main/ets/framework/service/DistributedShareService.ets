import { TimerTask } from '../model/TimerTask';
import { Logger } from '../utils/Logger';
import { common, Want } from '@kit.AbilityKit';
import distributedDeviceManager from '@ohos.distributedDeviceManager';
import { TaskDistributedManager, TaskSyncCallback, DeviceInfo as DistributedDeviceInfo, DeviceListCallback } from './TaskDistributedManager';

const TAG = 'DistributedShareService';

/**
 * 设备信息接口
 */
export interface DeviceInfo {
  deviceId: string;
  deviceName: string;
  deviceType: string;
  networkId: string;
}

/**
 * 简化的任务数据接口
 */
interface SimplifiedTask {
  id: string;
  name?: string;
  timeMode: string;
  taskType: string;
  executeTime?: number;
  dayOfWeek?: number;
  dayOfMonth?: number;
  hour: number;
  minute: number;
  endHour?: number;
  endMinute?: number;
  volumeSettings: object[];
  status: string;
}

/**
 * 分享数据接口
 */
interface ShareDataPayload {
  version: string;
  type: string;
  timestamp: number;
  tasks: SimplifiedTask[];
}

/**
 * 分布式设备分享服务
 */
export class DistributedShareService {
  private context: common.UIAbilityContext | null = null;
  private deviceManager: distributedDeviceManager.DeviceManager | null = null;
  private taskDistributedManager: TaskDistributedManager | null = null;
  private tasksReceivedCallback?: (tasks: TimerTask[]) => void;

  /**
   * 初始化
   */
  async initialize(context: common.UIAbilityContext): Promise<void> {
    try {
      this.context = context;
      
      // 创建设备管理器
      const bundleName = context.applicationInfo.name;
      this.deviceManager = distributedDeviceManager.createDeviceManager(bundleName);
      
      // 初始化任务分布式管理器
      this.taskDistributedManager = TaskDistributedManager.getInstance(context);
      
      Logger.info(TAG, 'DistributedShareService initialized');
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to initialize: ${errorMessage}`);
    }
  }

  /**
   * 获取可用的分布式设备列表
   */
  async getAvailableDevices(): Promise<DeviceInfo[]> {
    try {
      Logger.info(TAG, 'Getting available devices');
      
      if (!this.deviceManager) {
        Logger.error(TAG, 'DeviceManager not initialized');
        return [];
      }
      
      // 获取所有在线设备
      const devices = this.deviceManager.getAvailableDeviceListSync();
      Logger.info(TAG, `Found ${devices.length} devices`);
      
      // 转换为DeviceInfo格式
      const deviceInfos: DeviceInfo[] = [];
      for (let i = 0; i < devices.length; i++) {
        const device = devices[i];
        const info: DeviceInfo = {
          deviceId: device.deviceId,
          deviceName: device.deviceName,
          deviceType: device.deviceType,
          networkId: device.networkId || ''
        };
        deviceInfos.push(info);
      }
      
      return deviceInfos;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to get available devices: ${errorMessage}`);
      return [];
    }
  }

  /**
   * 分享任务到指定设备
   */
  async shareTasksToDevice(tasks: TimerTask[], targetDeviceId: string): Promise<boolean> {
    try {
      if (!this.context) {
        Logger.error(TAG, 'Context not initialized');
        return false;
      }

      if (!this.taskDistributedManager) {
        Logger.error(TAG, 'TaskDistributedManager not initialized');
        return false;
      }

      // 使用分布式数据对象同步任务
      const success = this.taskDistributedManager.publishTasks(tasks);
      
      if (success) {
        Logger.info(TAG, `Successfully shared ${tasks.length} tasks via distributed object`);
      }
      
      return success;
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to share tasks: ${errorMessage}`);
      return false;
    }
  }

  /**
   * 准备分享数据
   */
  private prepareShareData(tasks: TimerTask[]): ShareDataPayload {
    const simplifiedTasks: SimplifiedTask[] = tasks.map(task => this.simplifyTask(task));
    
    return {
      version: '1.0',
      type: 'timer_tasks',
      timestamp: Date.now(),
      tasks: simplifiedTasks
    };
  }

  /**
   * 简化任务数据
   */
  private simplifyTask(task: TimerTask): SimplifiedTask {
    const simplified: SimplifiedTask = {
      id: task.id,
      timeMode: task.timeMode,
      taskType: task.taskType,
      hour: task.hour,
      minute: task.minute,
      volumeSettings: task.volumeSettings as object[],
      status: task.status
    };

    if (task.name !== undefined) {
      simplified.name = task.name;
    }
    if (task.executeTime !== undefined) {
      simplified.executeTime = task.executeTime;
    }
    if (task.dayOfWeek !== undefined) {
      simplified.dayOfWeek = task.dayOfWeek;
    }
    if (task.dayOfMonth !== undefined) {
      simplified.dayOfMonth = task.dayOfMonth;
    }
    if (task.endHour !== undefined) {
      simplified.endHour = task.endHour;
    }
    if (task.endMinute !== undefined) {
      simplified.endMinute = task.endMinute;
    }

    return simplified;
  }

  /**
   * 生成新的会话ID(创建协同组)
   */
  generateSessionId(): string {
    try {
      Logger.info(TAG, 'Generating session ID...');
      
      if (!this.taskDistributedManager) {
        Logger.error(TAG, 'TaskDistributedManager not initialized');
        return '';
      }
      
      const sessionId = this.taskDistributedManager.generateSessionId();
      Logger.info(TAG, `Generated session ID: ${sessionId}`);
      return sessionId;
    } catch (error) {
      Logger.error(TAG, `Failed to generate session ID: ${JSON.stringify(error)}`);
      return '';
    }
  }

  /**
   * 设置会话ID(加入协同组)
   */
  setSessionId(sessionId: string): boolean {
    try {
      Logger.info(TAG, `Setting session ID: ${sessionId}`);
      
      if (!this.taskDistributedManager) {
        Logger.error(TAG, 'TaskDistributedManager not initialized');
        return false;
      }
      
      const success = this.taskDistributedManager.setSessionId(sessionId);
      Logger.info(TAG, `Session ID set result: ${success}`);
      return success;
    } catch (error) {
      Logger.error(TAG, `Failed to set session ID: ${JSON.stringify(error)}`);
      return false;
    }
  }

  /**
   * 获取当前会话ID
   */
  getSessionId(): string {
    if (!this.taskDistributedManager) {
      return '';
    }
    return this.taskDistributedManager.getSessionId();
  }

  /**
   * 获取设备ID
   */
  getDeviceId(): string {
    if (!this.taskDistributedManager) {
      return '';
    }
    return this.taskDistributedManager.getDeviceId();
  }

  /**
   * 注册任务接收回调
   */
  setTasksReceivedCallback(callback: (tasks: TimerTask[]) => void): void {
    this.tasksReceivedCallback = callback;
    if (this.taskDistributedManager) {
      this.taskDistributedManager.onTaskSync(callback);
    }
  }

  /**
   * 注册设备列表更新回调
   */
  setDeviceListCallback(callback: DeviceListCallback): void {
    if (this.taskDistributedManager) {
      this.taskDistributedManager.onDeviceListUpdate(callback);
    }
  }
  
  /**
   * 离开协同组
   */
  leaveSession(): void {
    if (this.taskDistributedManager) {
      this.taskDistributedManager.leaveSession();
    }
  }
}
