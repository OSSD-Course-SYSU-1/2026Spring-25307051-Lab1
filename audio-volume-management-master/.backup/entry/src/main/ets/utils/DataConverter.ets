import relationalStore from '@ohos.data.relationalStore';
import { TimerTask, TimerTaskModel } from '../model/TimerTask';
import { VolumeSetting, VolumeSettingModel } from '../model/VolumeSetting';
import { TaskExecution, TaskExecutionModel } from '../model/TaskExecution';
import { TimeMode, TaskStatus, VolumeType } from '../model/TaskEnums';

/**
 * 数据转换工具类
 */
export class DataConverter {
  /**
   * 将数据库行转换为TimerTask对象
   */
  static rowToTimerTask(row: relationalStore.ValuesBucket, volumeSettings: VolumeSetting[]): TimerTask {
    const task: TimerTask = {
      id: row.id as string,
      name: row.name as string,
      timeMode: row.time_mode as TimeMode,
      hour: row.hour as number,
      minute: row.minute as number,
      volumeSettings: volumeSettings,
      status: row.status as TaskStatus,
      createdTime: row.created_time as number,
      lastExecuteTime: row.last_execute_time as number
    };

    const timeMode = task.timeMode;
    if (timeMode === TimeMode.ONCE) {
      task.executeTime = row.execute_time as number;
    } else if (timeMode === TimeMode.WEEKLY) {
      task.dayOfWeek = row.day_of_week as number;
    } else if (timeMode === TimeMode.MONTHLY) {
      task.dayOfMonth = row.day_of_month as number;
    }

    return task;
  }

  /**
   * 将TimerTask对象转换为数据库行
   */
  static timerTaskToRow(task: TimerTask): relationalStore.ValuesBucket {
    const row: relationalStore.ValuesBucket = {
      id: task.id,
      name: task.name,
      time_mode: task.timeMode,
      hour: task.hour,
      minute: task.minute,
      status: task.status,
      created_time: task.createdTime,
      last_execute_time: task.lastExecuteTime
    };

    if (task.timeMode === TimeMode.ONCE) {
      row.execute_time = task.executeTime;
    } else if (task.timeMode === TimeMode.WEEKLY) {
      row.day_of_week = task.dayOfWeek;
    } else if (task.timeMode === TimeMode.MONTHLY) {
      row.day_of_month = task.dayOfMonth;
    }

    return row;
  }

  /**
   * 将数据库行转换为VolumeSetting对象
   */
  static rowToVolumeSetting(row: relationalStore.ValuesBucket): VolumeSetting {
    return {
      id: row.id as string,
      volumeType: row.volume_type as VolumeType,
      targetApp: row.target_app as string,
      volumeValue: row.volume_value as number
    };
  }

  /**
   * 将VolumeSetting对象转换为数据库行
   */
  static volumeSettingToRow(setting: VolumeSetting, taskId: string): relationalStore.ValuesBucket {
    return {
      id: setting.id,
      task_id: taskId,
      volume_type: setting.volumeType,
      target_app: setting.targetApp,
      volume_value: setting.volumeValue
    };
  }

  /**
   * 将数据库行转换为TaskExecution对象
   */
  static rowToTaskExecution(row: relationalStore.ValuesBucket): TaskExecution {
    return {
      id: row.id as string,
      taskId: row.task_id as string,
      executeTime: row.execute_time as number,
      result: row.result as 'SUCCESS' | 'FAILED',
      errorMessage: row.error_message as string
    };
  }

  /**
   * 将TaskExecution对象转换为数据库行
   */
  static taskExecutionToRow(execution: TaskExecution): relationalStore.ValuesBucket {
    return {
      id: execution.id,
      task_id: execution.taskId,
      execute_time: execution.executeTime,
      result: execution.result,
      error_message: execution.errorMessage
    };
  }
}
