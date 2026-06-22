import relationalStore from '@ohos.data.relationalStore';
import { TimerTask, TimerTaskModel } from '../model/TimerTask';
import { VolumeSetting, VolumeSettingModel } from '../model/VolumeSetting';
import { TaskExecution, TaskExecutionModel } from '../model/TaskExecution';
import { TimeMode, TaskStatus, VolumeType, TaskType, LockStatus } from '../model/TaskEnums';
import { Logger } from '../utils/Logger';

const TAG = 'TimerTaskDatabase';

/**
 * 组合体数据接口
 */
interface GroupData {
  id: string;
  name: string;
  taskIds: string[];
  status: string;
  isExpanded: boolean;
  createdTime: number;
  lastModifiedTime?: number;
}

/**
 * 定时任务数据库管理类
 */
export class TimerTaskDatabase {
  private rdbStore: relationalStore.RdbStore | null = null;
  private context: Context;

  constructor(context: Context) {
    this.context = context;
  }

  /**
   * 初始化数据库
   */
  async initialize(): Promise<void> {
    try {
      const config: relationalStore.StoreConfig = {
        name: 'TimerVolumeManager.db',
        securityLevel: relationalStore.SecurityLevel.S1
      };

      this.rdbStore = await relationalStore.getRdbStore(this.context, config);
      Logger.info(TAG, 'Database created successfully');

      await this.createTables();
      Logger.info(TAG, 'Tables created successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to initialize database: ${JSON.stringify(error)}`);
      throw new Error('Failed to initialize database');
    }
  }

  /**
   * 创建数据库表
   */
  private async createTables(): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('RdbStore is not initialized');
    }

    // 创建timer_tasks表
    const createTaskTable = `
      CREATE TABLE IF NOT EXISTS timer_tasks (
        id TEXT PRIMARY KEY,
        name TEXT,
        time_mode TEXT NOT NULL,
        task_type TEXT NOT NULL,
        execute_time INTEGER,
        day_of_week INTEGER,
        day_of_month INTEGER,
        hour INTEGER NOT NULL,
        minute INTEGER NOT NULL,
        end_hour INTEGER,
        end_minute INTEGER,
        lock_status TEXT,
        status TEXT NOT NULL,
        created_time INTEGER NOT NULL,
        last_execute_time INTEGER
      )
    `;
    await this.rdbStore.executeSql(createTaskTable);

    // 创建volume_settings表（不包含mute字段，后面会添加）
    const createVolumeTable = `
      CREATE TABLE IF NOT EXISTS volume_settings (
        id TEXT PRIMARY KEY,
        task_id TEXT NOT NULL,
        volume_type TEXT NOT NULL,
        target_app TEXT,
        volume_value INTEGER NOT NULL
      )
    `;
    await this.rdbStore.executeSql(createVolumeTable);

    // 创建task_executions表
    const createExecutionTable = `
      CREATE TABLE IF NOT EXISTS task_executions (
        id TEXT PRIMARY KEY,
        task_id TEXT NOT NULL,
        execute_time INTEGER NOT NULL,
        result TEXT NOT NULL,
        error_message TEXT
      )
    `;
    await this.rdbStore.executeSql(createExecutionTable);

    // 添加mute字段（如果不存在）
    await this.addColumnIfNotExists('volume_settings', 'mute', 'INTEGER DEFAULT 0');

    // 添加时间段锁定相关字段（如果不存在）
    await this.addColumnIfNotExists('timer_tasks', 'task_type', 'TEXT DEFAULT "INSTANT"');
    await this.addColumnIfNotExists('timer_tasks', 'end_hour', 'INTEGER');
    await this.addColumnIfNotExists('timer_tasks', 'end_minute', 'INTEGER');
    await this.addColumnIfNotExists('timer_tasks', 'lock_status', 'TEXT DEFAULT "INACTIVE"');

    // 创建task_groups表（任务组合体）
    const createGroupTable = `
      CREATE TABLE IF NOT EXISTS task_groups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        task_ids TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'ENABLED',
        is_expanded INTEGER DEFAULT 0,
        created_time INTEGER NOT NULL,
        last_modified_time INTEGER
      )
    `;
    await this.rdbStore.executeSql(createGroupTable);
    Logger.info(TAG, 'task_groups table created');

    // 为timer_tasks表添加组合体相关字段
    await this.addColumnIfNotExists('timer_tasks', 'group_id', 'TEXT');
    await this.addColumnIfNotExists('timer_tasks', 'original_status', 'TEXT');
  }

  /**
   * 添加列（如果不存在）
   */
  private async addColumnIfNotExists(tableName: string, columnName: string, columnDef: string): Promise<void> {
    if (!this.rdbStore) {
      return;
    }

    try {
      // 查询表结构
      const sql = `PRAGMA table_info(${tableName})`;
      const resultSet = await this.rdbStore.querySql(sql);
      
      let columnExists = false;
      while (resultSet.goToNextRow()) {
        const name = resultSet.getString(resultSet.getColumnIndex('name'));
        if (name === columnName) {
          columnExists = true;
          break;
        }
      }
      resultSet.close();

      // 如果列不存在，则添加
      if (!columnExists) {
        const alterSql = `ALTER TABLE ${tableName} ADD COLUMN ${columnName} ${columnDef}`;
        await this.rdbStore.executeSql(alterSql);
        Logger.info(TAG, `Column ${columnName} added to ${tableName}`);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to add column ${columnName}: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 插入任务
   */
  async insertTask(task: TimerTask): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('RdbStore is not initialized');
    }

    try {
      // 插入任务主表
      const taskRow: relationalStore.ValuesBucket = {
        id: task.id,
        name: task.name ?? '',
        time_mode: task.timeMode,
        task_type: task.taskType,
        hour: task.hour,
        minute: task.minute,
        end_hour: task.endHour ?? 0,
        end_minute: task.endMinute ?? 0,
        lock_status: task.lockStatus ?? 'INACTIVE',
        status: task.status,
        created_time: task.createdTime,
        last_execute_time: task.lastExecuteTime ?? 0
      };

      if (task.timeMode === TimeMode.ONCE && task.executeTime !== undefined) {
        taskRow.execute_time = task.executeTime;
      } else if (task.timeMode === TimeMode.WEEKLY && task.dayOfWeek !== undefined) {
        taskRow.day_of_week = task.dayOfWeek;
      } else if (task.timeMode === TimeMode.MONTHLY && task.dayOfMonth !== undefined) {
        taskRow.day_of_month = task.dayOfMonth;
      }

      await this.rdbStore.insert('timer_tasks', taskRow);

      // 插入音量设置
      await this.saveVolumeSettings(task.id, task.volumeSettings);

      Logger.info(TAG, `Task inserted: ${task.id}`);
    } catch (error) {
      Logger.error(TAG, `Failed to insert task: ${JSON.stringify(error)}`);
      throw new Error('Failed to insert task');
    }
  }

  /**
   * 更新任务
   */
  async updateTask(task: TimerTask): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('RdbStore is not initialized');
    }

    try {
      const taskRow: relationalStore.ValuesBucket = {
        name: task.name ?? '',
        time_mode: task.timeMode,
        task_type: task.taskType,
        hour: task.hour,
        minute: task.minute,
        end_hour: task.endHour ?? 0,
        end_minute: task.endMinute ?? 0,
        lock_status: task.lockStatus ?? 'INACTIVE',
        status: task.status,
        last_execute_time: task.lastExecuteTime ?? 0
      };

      if (task.timeMode === TimeMode.ONCE && task.executeTime !== undefined) {
        taskRow.execute_time = task.executeTime;
      } else if (task.timeMode === TimeMode.WEEKLY && task.dayOfWeek !== undefined) {
        taskRow.day_of_week = task.dayOfWeek;
      } else if (task.timeMode === TimeMode.MONTHLY && task.dayOfMonth !== undefined) {
        taskRow.day_of_month = task.dayOfMonth;
      }

      const predicates = new relationalStore.RdbPredicates('timer_tasks');
      predicates.equalTo('id', task.id);

      await this.rdbStore.update(taskRow, predicates);

      // 更新音量设置（先删除旧的，再插入新的）
      await this.deleteVolumeSettings(task.id);
      await this.saveVolumeSettings(task.id, task.volumeSettings);

      Logger.info(TAG, `Task updated: ${task.id}`);
    } catch (error) {
      Logger.error(TAG, `Failed to update task: ${JSON.stringify(error)}`);
      throw new Error('Failed to update task');
    }
  }

  /**
   * 删除任务
   */
  async deleteTask(id: string): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('RdbStore is not initialized');
    }

    try {
      // 删除音量设置
      await this.deleteVolumeSettings(id);

      // 删除执行记录
      const executionPredicates = new relationalStore.RdbPredicates('task_executions');
      executionPredicates.equalTo('task_id', id);
      await this.rdbStore.delete(executionPredicates);

      // 删除任务
      const taskPredicates = new relationalStore.RdbPredicates('timer_tasks');
      taskPredicates.equalTo('id', id);
      await this.rdbStore.delete(taskPredicates);

      Logger.info(TAG, `Task deleted: ${id}`);
    } catch (error) {
      Logger.error(TAG, `Failed to delete task: ${JSON.stringify(error)}`);
      throw new Error('Failed to delete task');
    }
  }

  /**
   * 获取所有任务
   */
  async getAllTasks(): Promise<TimerTask[]> {
    if (!this.rdbStore) {
      throw new Error('RdbStore is not initialized');
    }

    try {
      const predicates = new relationalStore.RdbPredicates('timer_tasks');
      predicates.orderByAsc('created_time');

      const resultSet = await this.rdbStore.query(predicates);
      const tasks: TimerTask[] = [];

      while (resultSet.goToNextRow()) {
        const task = await this.rowToTimerTask(resultSet);
        tasks.push(task);
      }

      resultSet.close();
      Logger.info(TAG, `Loaded ${tasks.length} tasks`);
      return tasks;
    } catch (error) {
      Logger.error(TAG, `Failed to get all tasks: ${JSON.stringify(error)}`);
      throw new Error('Failed to get all tasks');
    }
  }

  /**
   * 根据ID获取任务
   */
  async getTaskById(id: string): Promise<TimerTask | null> {
    if (!this.rdbStore) {
      throw new Error('RdbStore is not initialized');
    }

    try {
      const predicates = new relationalStore.RdbPredicates('timer_tasks');
      predicates.equalTo('id', id);

      const resultSet = await this.rdbStore.query(predicates);
      let task: TimerTask | null = null;

      if (resultSet.goToNextRow()) {
        task = await this.rowToTimerTask(resultSet);
      }

      resultSet.close();
      return task;
    } catch (error) {
      Logger.error(TAG, `Failed to get task by id: ${JSON.stringify(error)}`);
      throw new Error('Failed to get task by id');
    }
  }

  /**
   * 更新任务状态
   */
  async updateTaskStatus(id: string, status: TaskStatus): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('RdbStore is not initialized');
    }

    try {
      const row: relationalStore.ValuesBucket = {
        status: status
      };

      const predicates = new relationalStore.RdbPredicates('timer_tasks');
      predicates.equalTo('id', id);

      await this.rdbStore.update(row, predicates);
      Logger.info(TAG, `Task status updated: ${id} -> ${status}`);
    } catch (error) {
      Logger.error(TAG, `Failed to update task status: ${JSON.stringify(error)}`);
      throw new Error('Failed to update task status');
    }
  }

  /**
   * 保存音量设置
   */
  private async saveVolumeSettings(taskId: string, settings: VolumeSetting[]): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('RdbStore is not initialized');
    }

    for (const setting of settings) {
      const row: relationalStore.ValuesBucket = {
        id: setting.id,
        task_id: taskId,
        volume_type: setting.volumeType,
        target_app: setting.targetApp ?? '',
        volume_value: setting.volumeValue,
        mute: setting.mute ? 1 : 0
      };

      await this.rdbStore.insert('volume_settings', row);
    }
  }

  /**
   * 删除音量设置
   */
  private async deleteVolumeSettings(taskId: string): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('RdbStore is not initialized');
    }

    const predicates = new relationalStore.RdbPredicates('volume_settings');
    predicates.equalTo('task_id', taskId);
    await this.rdbStore.delete(predicates);
  }

  /**
   * 获取音量设置
   */
  private async getVolumeSettings(taskId: string): Promise<VolumeSetting[]> {
    if (!this.rdbStore) {
      throw new Error('RdbStore is not initialized');
    }

    const predicates = new relationalStore.RdbPredicates('volume_settings');
    predicates.equalTo('task_id', taskId);

    const resultSet = await this.rdbStore.query(predicates);
    const settings: VolumeSetting[] = [];

    while (resultSet.goToNextRow()) {
      const setting: VolumeSetting = {
        id: resultSet.getString(resultSet.getColumnIndex('id')),
        volumeType: resultSet.getString(resultSet.getColumnIndex('volume_type')) as VolumeType,
        targetApp: resultSet.getString(resultSet.getColumnIndex('target_app')),
        volumeValue: resultSet.getLong(resultSet.getColumnIndex('volume_value')),
        mute: resultSet.getLong(resultSet.getColumnIndex('mute')) === 1
      };
      settings.push(setting);
    }

    resultSet.close();
    return settings;
  }

  /**
   * 将数据库行转换为TimerTask对象
   */
  private async rowToTimerTask(resultSet: relationalStore.ResultSet): Promise<TimerTask> {
    const id = resultSet.getString(resultSet.getColumnIndex('id'));
    const volumeSettings = await this.getVolumeSettings(id);

    const taskModel = new TimerTaskModel(
      id,
      resultSet.getString(resultSet.getColumnIndex('name')),
      resultSet.getString(resultSet.getColumnIndex('time_mode')) as TimeMode,
      resultSet.getString(resultSet.getColumnIndex('task_type')) as TaskType,
      resultSet.getLong(resultSet.getColumnIndex('hour')),
      resultSet.getLong(resultSet.getColumnIndex('minute')),
      volumeSettings,
      resultSet.getString(resultSet.getColumnIndex('status')) as TaskStatus,
      resultSet.getLong(resultSet.getColumnIndex('created_time')),
      resultSet.getLong(resultSet.getColumnIndex('last_execute_time')),
      resultSet.getLong(resultSet.getColumnIndex('end_hour')),
      resultSet.getLong(resultSet.getColumnIndex('end_minute')),
      resultSet.getString(resultSet.getColumnIndex('lock_status')) as LockStatus
    );

    const timeMode = taskModel.timeMode;
    if (timeMode === TimeMode.ONCE) {
      taskModel.executeTime = resultSet.getLong(resultSet.getColumnIndex('execute_time'));
    } else if (timeMode === TimeMode.WEEKLY) {
      taskModel.dayOfWeek = resultSet.getLong(resultSet.getColumnIndex('day_of_week'));
    } else if (timeMode === TimeMode.MONTHLY) {
      taskModel.dayOfMonth = resultSet.getLong(resultSet.getColumnIndex('day_of_month'));
    }

    return taskModel;
  }

  /**
   * 记录任务执行
   */
  async recordExecution(execution: TaskExecution): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('RdbStore is not initialized');
    }

    try {
      const row: relationalStore.ValuesBucket = {
        id: execution.id,
        task_id: execution.taskId,
        execute_time: execution.executeTime,
        result: execution.result,
        error_message: execution.errorMessage ?? ''
      };

      await this.rdbStore.insert('task_executions', row);
      Logger.info(TAG, `Execution recorded: ${execution.taskId}`);
    } catch (error) {
      Logger.error(TAG, `Failed to record execution: ${JSON.stringify(error)}`);
      throw new Error('Failed to record execution');
    }
  }

  /**
   * 获取执行历史
   */
  async getExecutionHistory(taskId: string, limit: number = 10): Promise<TaskExecution[]> {
    if (!this.rdbStore) {
      throw new Error('RdbStore is not initialized');
    }

    try {
      const predicates = new relationalStore.RdbPredicates('task_executions');
      predicates.equalTo('task_id', taskId);
      predicates.orderByDesc('execute_time');
      predicates.limitAs(limit);

      const resultSet = await this.rdbStore.query(predicates);
      const executions: TaskExecution[] = [];

      while (resultSet.goToNextRow()) {
        const execution: TaskExecution = {
          id: resultSet.getString(resultSet.getColumnIndex('id')),
          taskId: resultSet.getString(resultSet.getColumnIndex('task_id')),
          executeTime: resultSet.getLong(resultSet.getColumnIndex('execute_time')),
          result: resultSet.getString(resultSet.getColumnIndex('result')) as 'SUCCESS' | 'FAILED',
          errorMessage: resultSet.getString(resultSet.getColumnIndex('error_message'))
        };
        executions.push(execution);
      }

      resultSet.close();
      return executions;
    } catch (error) {
      Logger.error(TAG, `Failed to get execution history: ${JSON.stringify(error)}`);
      throw new Error('Failed to get execution history');
    }
  }

  /**
   * 插入组合体
   */
  async insertGroup(group: GroupData): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('RdbStore is not initialized');
    }

    try {
      const row: relationalStore.ValuesBucket = {
        id: group.id,
        name: group.name,
        task_ids: JSON.stringify(group.taskIds),
        status: group.status,
        is_expanded: group.isExpanded ? 1 : 0,
        created_time: group.createdTime,
        last_modified_time: group.lastModifiedTime ?? 0
      };

      await this.rdbStore.insert('task_groups', row);
      Logger.info(TAG, `Group inserted: ${group.id}`);
    } catch (error) {
      Logger.error(TAG, `Failed to insert group: ${JSON.stringify(error)}`);
      throw new Error('Failed to insert group');
    }
  }

  /**
   * 根据ID获取组合体
   */
  async getGroupById(id: string): Promise<GroupData | null> {
    if (!this.rdbStore) {
      throw new Error('RdbStore is not initialized');
    }

    try {
      const predicates = new relationalStore.RdbPredicates('task_groups');
      predicates.equalTo('id', id);

      const resultSet = await this.rdbStore.query(predicates);
      let group: GroupData | null = null;

      if (resultSet.goToNextRow()) {
        const groupData: GroupData = {
          id: resultSet.getString(resultSet.getColumnIndex('id')),
          name: resultSet.getString(resultSet.getColumnIndex('name')),
          taskIds: JSON.parse(resultSet.getString(resultSet.getColumnIndex('task_ids'))),
          status: resultSet.getString(resultSet.getColumnIndex('status')),
          isExpanded: resultSet.getLong(resultSet.getColumnIndex('is_expanded')) === 1,
          createdTime: resultSet.getLong(resultSet.getColumnIndex('created_time')),
          lastModifiedTime: resultSet.getLong(resultSet.getColumnIndex('last_modified_time'))
        };
        group = groupData;
      }

      resultSet.close();
      return group;
    } catch (error) {
      Logger.error(TAG, `Failed to get group by id: ${JSON.stringify(error)}`);
      throw new Error('Failed to get group by id');
    }
  }

  /**
   * 获取所有组合体
   */
  async getAllGroups(): Promise<GroupData[]> {
    if (!this.rdbStore) {
      throw new Error('RdbStore is not initialized');
    }

    try {
      const predicates = new relationalStore.RdbPredicates('task_groups');
      predicates.orderByDesc('created_time');

      const resultSet = await this.rdbStore.query(predicates);
      const groups: GroupData[] = [];

      while (resultSet.goToNextRow()) {
        const group: GroupData = {
          id: resultSet.getString(resultSet.getColumnIndex('id')),
          name: resultSet.getString(resultSet.getColumnIndex('name')),
          taskIds: JSON.parse(resultSet.getString(resultSet.getColumnIndex('task_ids'))),
          status: resultSet.getString(resultSet.getColumnIndex('status')),
          isExpanded: resultSet.getLong(resultSet.getColumnIndex('is_expanded')) === 1,
          createdTime: resultSet.getLong(resultSet.getColumnIndex('created_time')),
          lastModifiedTime: resultSet.getLong(resultSet.getColumnIndex('last_modified_time'))
        };
        groups.push(group);
      }

      resultSet.close();
      Logger.info(TAG, `Loaded ${groups.length} groups`);
      return groups;
    } catch (error) {
      Logger.error(TAG, `Failed to get all groups: ${JSON.stringify(error)}`);
      throw new Error('Failed to get all groups');
    }
  }

  /**
   * 更新组合体状态
   */
  async updateGroupStatus(id: string, status: string): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('RdbStore is not initialized');
    }

    try {
      const row: relationalStore.ValuesBucket = {
        status: status,
        last_modified_time: Date.now()
      };

      const predicates = new relationalStore.RdbPredicates('task_groups');
      predicates.equalTo('id', id);

      await this.rdbStore.update(row, predicates);
      Logger.info(TAG, `Group status updated: ${id} -> ${status}`);
    } catch (error) {
      Logger.error(TAG, `Failed to update group status: ${JSON.stringify(error)}`);
      throw new Error('Failed to update group status');
    }
  }

  /**
   * 更新组合体展开状态
   */
  async updateGroupExpanded(id: string, isExpanded: boolean): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('RdbStore is not initialized');
    }

    try {
      const row: relationalStore.ValuesBucket = {
        is_expanded: isExpanded ? 1 : 0,
        last_modified_time: Date.now()
      };

      const predicates = new relationalStore.RdbPredicates('task_groups');
      predicates.equalTo('id', id);

      await this.rdbStore.update(row, predicates);
      Logger.info(TAG, `Group expanded updated: ${id} -> ${isExpanded}`);
    } catch (error) {
      Logger.error(TAG, `Failed to update group expanded: ${JSON.stringify(error)}`);
      throw new Error('Failed to update group expanded');
    }
  }

  /**
   * 删除组合体
   */
  async deleteGroup(id: string): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('RdbStore is not initialized');
    }

    try {
      const predicates = new relationalStore.RdbPredicates('task_groups');
      predicates.equalTo('id', id);
      await this.rdbStore.delete(predicates);
      Logger.info(TAG, `Group deleted: ${id}`);
    } catch (error) {
      Logger.error(TAG, `Failed to delete group: ${JSON.stringify(error)}`);
      throw new Error('Failed to delete group');
    }
  }

  /**
   * 更新组合体的子任务列表
   */
  async updateGroupTaskIds(id: string, taskIds: string[]): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('RdbStore is not initialized');
    }

    try {
      const row: relationalStore.ValuesBucket = {
        task_ids: JSON.stringify(taskIds),
        last_modified_time: Date.now()
      };

      const predicates = new relationalStore.RdbPredicates('task_groups');
      predicates.equalTo('id', id);

      await this.rdbStore.update(row, predicates);
      Logger.info(TAG, `Group taskIds updated: ${id}`);
    } catch (error) {
      Logger.error(TAG, `Failed to update group taskIds: ${JSON.stringify(error)}`);
      throw new Error('Failed to update group taskIds');
    }
  }

  /**
   * 更新任务的groupId
   */
  async updateTaskGroupId(taskId: string, groupId: string | null): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('RdbStore is not initialized');
    }

    try {
      const row: relationalStore.ValuesBucket = {
        group_id: groupId ?? null
      };

      const predicates = new relationalStore.RdbPredicates('timer_tasks');
      predicates.equalTo('id', taskId);

      await this.rdbStore.update(row, predicates);
      Logger.info(TAG, `Task groupId updated: ${taskId} -> ${groupId}`);
    } catch (error) {
      Logger.error(TAG, `Failed to update task groupId: ${JSON.stringify(error)}`);
      throw new Error('Failed to update task groupId');
    }
  }

  /**
   * 更新任务的原始状态
   */
  async updateTaskOriginalStatus(taskId: string, originalStatus: string | null): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('RdbStore is not initialized');
    }

    try {
      const row: relationalStore.ValuesBucket = {
        original_status: originalStatus ?? null
      };

      const predicates = new relationalStore.RdbPredicates('timer_tasks');
      predicates.equalTo('id', taskId);

      await this.rdbStore.update(row, predicates);
      Logger.info(TAG, `Task originalStatus updated: ${taskId} -> ${originalStatus}`);
    } catch (error) {
      Logger.error(TAG, `Failed to update task originalStatus: ${JSON.stringify(error)}`);
      throw new Error('Failed to update task originalStatus');
    }
  }
}
