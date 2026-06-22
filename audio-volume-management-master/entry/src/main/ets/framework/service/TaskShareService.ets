import { TimerTask } from '../model/TimerTask';
import { Logger } from '../utils/Logger';

const TAG = 'TaskShareService';

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
interface SharedData {
  version: string;
  type: string;
  timestamp: number;
  tasks: SimplifiedTask[];
}

/**
 * 任务分享服务
 * 使用系统分享功能将任务分享到其他设备
 */
export class TaskShareService {
  
  /**
   * 分享任务到其他设备
   * 生成分享数据并返回，由调用方处理实际分享
   */
  async shareTasks(tasks: TimerTask[]): Promise<string> {
    try {
      if (tasks.length === 0) {
        Logger.warn(TAG, 'No tasks to share');
        return '';
      }
      
      // 将任务数据转换为JSON字符串
      const simplifiedTasks: SimplifiedTask[] = tasks.map(task => this.simplifyTask(task));
      
      const sharedData: SharedData = {
        version: '1.0',
        type: 'timer_tasks',
        timestamp: Date.now(),
        tasks: simplifiedTasks
      };
      
      const taskData = JSON.stringify(sharedData);
      
      Logger.info(TAG, `Prepared to share ${tasks.length} tasks`);
      Logger.info(TAG, `Task data length: ${taskData.length} characters`);
      
      return taskData;
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to share tasks: ${errorMessage}`);
      return '';
    }
  }
  
  /**
   * 简化任务数据，只保留必要字段
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
    
    // 添加可选字段
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
   * 从分享数据中解析任务
   */
  parseSharedTasks(sharedData: string): TimerTask[] {
    try {
      const data: SharedData = JSON.parse(sharedData) as SharedData;
      
      if (data.type !== 'timer_tasks') {
        Logger.error(TAG, 'Invalid shared data type');
        return [];
      }
      
      Logger.info(TAG, `Parsed ${data.tasks.length} tasks from shared data`);
      return data.tasks as TimerTask[];
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to parse shared data: ${errorMessage}`);
      return [];
    }
  }
}
