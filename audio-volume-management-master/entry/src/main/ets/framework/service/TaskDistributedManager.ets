/**
 * 任务分布式管理器
 * 使用分布式数据对象实现跨设备任务同步
 */
import distributedDataObject from '@ohos.data.distributedDataObject';
import { TimerTask } from '../model/TimerTask';
import { Logger } from '../utils/Logger';
import common from '@ohos.app.ability.common';

const TAG = 'TaskDistributedManager';

/**
 * 分布式任务数据结构
 */
export interface DistributedTaskData {
  version: string;
  timestamp: number;
  tasks: string; // JSON字符串形式的任务数组
  sourceDevice: string;
  devices: string; // JSON字符串形式的设备ID数组
  sessionCreator: string; // 会话创建者的设备ID
}

/**
 * 设备信息
 */
export interface DeviceInfo {
  deviceId: string;
  joinTime: number;
}

/**
 * 任务同步回调
 */
export type TaskSyncCallback = (tasks: TimerTask[]) => void;

/**
 * 设备列表更新回调
 */
export type DeviceListCallback = (devices: DeviceInfo[]) => void;

/**
 * 任务分布式管理器
 * 实现多设备间任务数据的实时同步
 */
export class TaskDistributedManager {
  private static instance: TaskDistributedManager | undefined = undefined;
  private d_object: distributedDataObject.DataObject | null = null;
  private context: common.UIAbilityContext;
  private sessionId: string = '';
  private syncCallbacks: TaskSyncCallback[] = [];
  private deviceListCallbacks: DeviceListCallback[] = [];
  private deviceId: string = '';
  private isSessionCreator: boolean = false;

  private constructor(context: common.UIAbilityContext) {
    this.context = context;
    this.deviceId = `device_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    this.initDistributedObject();
  }

  /**
   * 获取单例实例
   */
  static getInstance(context: common.UIAbilityContext): TaskDistributedManager {
    if (!TaskDistributedManager.instance) {
      TaskDistributedManager.instance = new TaskDistributedManager(context);
    }
    return TaskDistributedManager.instance!;
  }

  /**
   * 初始化分布式数据对象
   */
  private initDistributedObject(): void {
    try {
      Logger.info(TAG, 'Initializing distributed object...');
      
      // 初始化设备列表（包含当前设备）
      const initialDevices: DeviceInfo[] = [
        { deviceId: this.deviceId, joinTime: Date.now() }
      ];
      
      const initialData: DistributedTaskData = {
        version: '1.0',
        timestamp: Date.now(),
        tasks: '[]',
        sourceDevice: this.deviceId,
        devices: JSON.stringify(initialDevices),
        sessionCreator: this.deviceId
      };

      Logger.info(TAG, `Creating distributed object with initial data`);
      Logger.info(TAG, `Initial devices: ${initialData.devices}`);
      
      this.d_object = distributedDataObject.create(this.context, initialData);

      if (!this.d_object) {
        Logger.error(TAG, 'Failed to create distributed object: result is null');
        return;
      }

      Logger.info(TAG, 'Distributed object created successfully');

      // 监听数据变化
      if (this.d_object) {
        this.d_object.on('change', (sessionId: string, fields: Array<string>) => {
          Logger.info(TAG, `=== DATA CHANGE EVENT ===`);
          Logger.info(TAG, `Session ID: ${sessionId}`);
          Logger.info(TAG, `Changed fields: ${fields.join(', ')}`);
          Logger.info(TAG, `Current device ID: ${this.deviceId}`);
          this.onDataChanged();
        });
        Logger.info(TAG, 'Change listener registered');
      } else {
        Logger.error(TAG, 'Distributed object is null after creation, cannot register listener');
      }

      Logger.info(TAG, `Task distributed object initialized, deviceId: ${this.deviceId}`);
    } catch (error) {
      Logger.error(TAG, `Failed to init distributed object: ${JSON.stringify(error)}`);
      this.d_object = null;
    }
  }

  /**
   * 数据变化处理
   */
  private onDataChanged(): void {
    if (!this.d_object) {
      Logger.error(TAG, 'Distributed object is null in onDataChanged');
      return;
    }

    try {
      Logger.info(TAG, 'Processing data change...');
      
      // 获取分布式对象的数据
      const obj = this.d_object;
      if (!obj) {
        Logger.error(TAG, 'Object is null after check');
        return;
      }
      
      // 安全地读取数据属性
      Logger.info(TAG, 'Reading data properties...');
      
      let version = '1.0';
      let timestamp = 0;
      let tasksJson = '[]';
      let sourceDevice = '';
      let devicesJson = '[]';
      
      try {
        version = (obj as ESObject)['version'] as string || '1.0';
      } catch (e) {
        Logger.warn(TAG, `Failed to read version: ${e}`);
      }
      
      try {
        timestamp = (obj as ESObject)['timestamp'] as number || 0;
      } catch (e) {
        Logger.warn(TAG, `Failed to read timestamp: ${e}`);
      }
      
      try {
        tasksJson = (obj as ESObject)['tasks'] as string || '[]';
      } catch (e) {
        Logger.warn(TAG, `Failed to read tasks: ${e}`);
      }
      
      try {
        sourceDevice = (obj as ESObject)['sourceDevice'] as string || '';
      } catch (e) {
        Logger.warn(TAG, `Failed to read sourceDevice: ${e}`);
      }
      
      try {
        devicesJson = (obj as ESObject)['devices'] as string || '[]';
      } catch (e) {
        Logger.warn(TAG, `Failed to read devices: ${e}`);
      }
      
      Logger.info(TAG, `Data read - version: ${version}, timestamp: ${timestamp}, sourceDevice: ${sourceDevice}`);
      Logger.info(TAG, `Tasks JSON length: ${tasksJson.length}`);
      Logger.info(TAG, `Devices JSON: ${devicesJson}`);
      
      // 处理设备列表更新
      if (devicesJson && devicesJson !== '[]' && devicesJson.length > 2) {
        try {
          const devices = JSON.parse(devicesJson) as DeviceInfo[];
          Logger.info(TAG, `Devices updated: ${devices.length} devices`);
          this.notifyDeviceListUpdate(devices);
        } catch (e) {
          Logger.error(TAG, `Failed to parse devices: ${e}`);
        }
      }
      
      // 过滤掉自己发送的数据
      if (sourceDevice === this.deviceId) {
        Logger.info(TAG, 'Data is from current device, skipping');
        return;
      }
      
      // 处理任务数据
      if (tasksJson && tasksJson !== '[]' && tasksJson.length > 2) {
        let tasks: TimerTask[] = [];
        try {
          tasks = JSON.parse(tasksJson) as TimerTask[];
        } catch (parseError) {
          Logger.error(TAG, `Failed to parse tasks JSON: ${parseError}`);
          return;
        }
        
        if (tasks.length > 0) {
          Logger.info(TAG, `=== RECEIVED ${tasks.length} TASKS FROM ${sourceDevice} ===`);
          
          // 通知所有回调
          this.syncCallbacks.forEach((callback, index) => {
            try {
              callback(tasks);
            } catch (error) {
              Logger.error(TAG, `Callback ${index} error: ${JSON.stringify(error)}`);
            }
          });
        }
      }
    } catch (error) {
      Logger.error(TAG, `Failed to process data change: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 通知设备列表更新
   */
  private notifyDeviceListUpdate(devices: DeviceInfo[]): void {
    Logger.info(TAG, `Notifying ${this.deviceListCallbacks.length} device list callbacks`);
    this.deviceListCallbacks.forEach((callback, index) => {
      try {
        callback(devices);
      } catch (error) {
        Logger.error(TAG, `Device list callback ${index} error: ${JSON.stringify(error)}`);
      }
    });
  }
  
  /**
   * 注册设备列表更新回调
   */
  onDeviceListUpdate(callback: DeviceListCallback): void {
    this.deviceListCallbacks.push(callback);
    Logger.info(TAG, 'Device list callback registered');
  }
  
  /**
   * 注销设备列表更新回调
   */
  offDeviceListUpdate(callback: DeviceListCallback): void {
    const index = this.deviceListCallbacks.indexOf(callback);
    if (index !== -1) {
      this.deviceListCallbacks.splice(index, 1);
      Logger.info(TAG, 'Device list callback unregistered');
    }
  }
  
  /**
   * 生成新的会话ID(创建协同组)
   */
  generateSessionId(): string {
    try {
      Logger.info(TAG, 'Generating session ID...');
      
      if (!this.d_object) {
        Logger.error(TAG, 'Distributed object not initialized, cannot generate session ID');
        return '';
      }
      
      const sessionId = distributedDataObject.genSessionId();
      
      if (!sessionId) {
        Logger.error(TAG, 'Failed to generate session ID: result is empty');
        return '';
      }
      
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
      Logger.info(TAG, `=== SETTING SESSION ID ===`);
      Logger.info(TAG, `Session ID: ${sessionId}`);
      Logger.info(TAG, `Distributed object exists: ${this.d_object !== null}`);
      Logger.info(TAG, `Current device ID: ${this.deviceId}`);
      
      if (!this.d_object) {
        Logger.error(TAG, 'Distributed object not initialized, cannot set session ID');
        return false;
      }
      
      if (!sessionId) {
        Logger.error(TAG, 'Session ID is empty');
        return false;
      }
      
      this.sessionId = sessionId;
      this.d_object.setSessionId(sessionId);
      this.isSessionCreator = false; // 加入会话的不是创建者
      
      Logger.info(TAG, `=== SESSION ID SET SUCCESSFULLY ===`);
      Logger.info(TAG, `Session ID: ${sessionId}`);
      Logger.info(TAG, `Object is now in session: ${sessionId}`);
      
      // 等待一小段时间让数据同步，然后加入设备列表
      setTimeout(() => {
        this.joinSessionAsDevice();
      }, 500);
      
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to set session ID: ${JSON.stringify(error)}`);
      return false;
    }
  }
  
  /**
   * 作为设备加入会话
   */
  private joinSessionAsDevice(): void {
    if (!this.d_object) {
      Logger.error(TAG, 'Distributed object is null');
      return;
    }
    
    try {
      const obj = this.d_object;
      
      // 读取当前设备列表
      let devicesJson = '[]';
      try {
        devicesJson = (obj as ESObject)['devices'] as string || '[]';
      } catch (e) {
        Logger.warn(TAG, `Failed to read devices: ${e}`);
      }
      
      let devices: DeviceInfo[] = [];
      try {
        devices = JSON.parse(devicesJson) as DeviceInfo[];
      } catch (e) {
        Logger.error(TAG, `Failed to parse devices JSON: ${e}`);
        devices = [];
      }
      
      // 检查当前设备是否已在列表中
      const existingDevice = devices.find(d => d.deviceId === this.deviceId);
      if (!existingDevice) {
        // 添加当前设备到列表
        devices.push({
          deviceId: this.deviceId,
          joinTime: Date.now()
        });
        
        // 更新设备列表
        (obj as ESObject)['devices'] = JSON.stringify(devices);
        (obj as ESObject)['timestamp'] = Date.now();
        (obj as ESObject)['sourceDevice'] = this.deviceId;
        
        Logger.info(TAG, `=== DEVICE JOINED SESSION ===`);
        Logger.info(TAG, `Total devices: ${devices.length}`);
        Logger.info(TAG, `Devices: ${JSON.stringify(devices)}`);
      } else {
        Logger.info(TAG, `Device already in session`);
      }
      
      // 通知设备列表更新
      this.notifyDeviceListUpdate(devices);
      
    } catch (error) {
      Logger.error(TAG, `Failed to join session as device: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 获取当前会话ID
   */
  getSessionId(): string {
    return this.sessionId;
  }

  /**
   * 获取设备ID
   */
  getDeviceId(): string {
    return this.deviceId;
  }

  /**
   * 发布任务数据到分布式对象
   */
  publishTasks(tasks: TimerTask[]): boolean {
    Logger.info(TAG, `=== PUBLISH TASKS ===`);
    Logger.info(TAG, `Tasks count: ${tasks ? tasks.length : 0}`);
    Logger.info(TAG, `Distributed object exists: ${this.d_object !== null}`);
    Logger.info(TAG, `Session ID: ${this.sessionId}`);
    Logger.info(TAG, `Device ID: ${this.deviceId}`);
    
    if (!this.d_object) {
      Logger.error(TAG, 'Distributed object not initialized');
      return false;
    }

    if (!tasks || tasks.length === 0) {
      Logger.error(TAG, 'Tasks array is empty or null');
      return false;
    }

    try {
      Logger.info(TAG, `Publishing ${tasks.length} tasks...`);
      
      // 验证任务数据
      for (let i = 0; i < tasks.length; i++) {
        const task = tasks[i];
        if (!task.id) {
          Logger.error(TAG, `Task ${i} has no id`);
          return false;
        }
        if (!task.timeMode) {
          Logger.error(TAG, `Task ${i} has no timeMode`);
          return false;
        }
      }
      
      // 序列化任务数据
      let tasksJson = '';
      try {
        tasksJson = JSON.stringify(tasks);
      } catch (stringifyError) {
        Logger.error(TAG, `Failed to stringify tasks: ${stringifyError}`);
        return false;
      }
      
      Logger.info(TAG, `Tasks JSON length: ${tasksJson.length}`);
      
      if (tasksJson.length === 0 || tasksJson === '[]') {
        Logger.error(TAG, 'Tasks JSON is empty after stringify');
        return false;
      }
      
      // 更新分布式对象的属性
      const obj = this.d_object;
      if (obj) {
        // 先更新时间戳和源设备
        (obj as ESObject)['timestamp'] = Date.now();
        (obj as ESObject)['sourceDevice'] = this.deviceId;
        
        // 最后更新任务数据，这会触发change事件
        (obj as ESObject)['tasks'] = tasksJson;
        
        Logger.info(TAG, `Distributed object properties updated`);
        Logger.info(TAG, `Timestamp: ${(obj as ESObject)['timestamp']}`);
        Logger.info(TAG, `SourceDevice: ${(obj as ESObject)['sourceDevice']}`);
        Logger.info(TAG, `Tasks JSON preview: ${tasksJson.substring(0, Math.min(100, tasksJson.length))}...`);
      }
      
      Logger.info(TAG, `Successfully published ${tasks.length} tasks to distributed object`);
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to publish tasks: ${JSON.stringify(error)}`);
      return false;
    }
  }

  /**
   * 注册任务同步回调
   */
  onTaskSync(callback: TaskSyncCallback): void {
    this.syncCallbacks.push(callback);
    Logger.info(TAG, 'Task sync callback registered');
  }

  /**
   * 取消注册任务同步回调
   */
  offTaskSync(callback: TaskSyncCallback): void {
    const index = this.syncCallbacks.indexOf(callback);
    if (index !== -1) {
      this.syncCallbacks.splice(index, 1);
      Logger.info(TAG, 'Task sync callback unregistered');
    }
  }

  /**
   * 离开协同组
   */
  leaveSession(): void {
    if (this.d_object && this.sessionId) {
      this.d_object.setSessionId('');
      this.sessionId = '';
      Logger.info(TAG, 'Left session');
    }
  }

  /**
   * 销毁实例
   */
  destroy(): void {
    if (this.d_object) {
      this.d_object.off('change');
      this.leaveSession();
    }
    this.d_object = null;
    this.syncCallbacks = [];
    TaskDistributedManager.instance = undefined;
    Logger.info(TAG, 'TaskDistributedManager destroyed');
  }
}
