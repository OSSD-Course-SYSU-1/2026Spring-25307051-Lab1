import { TaskGroup, GroupStatus, GroupWithTasks, TaskGroupModel, ValidationResult } from '../model/TaskGroup';
import { TimerTask, TimerTaskModel } from '../model/TimerTask';
import { TaskStatus } from '../model/TaskEnums';
import { TimerTaskDatabase } from '../data/TimerTaskDatabase';
import { TimerTaskService } from './TimerTaskService';
import { Logger } from '../utils/Logger';

const TAG = 'TaskGroupService';

/**
 * 任务组合体服务接口
 */
export interface ITaskGroupService {
  getAllGroups(): Promise<TaskGroup[]>;
  getGroupById(id: string): Promise<TaskGroup | null>;
  createGroup(name: string, taskIds: string[]): Promise<TaskGroup>;
  deleteGroup(id: string): Promise<void>;
  updateGroupStatus(id: string, status: GroupStatus): Promise<void>;
  updateGroupExpanded(id: string, isExpanded: boolean): Promise<void>;
  addTasksToGroup(groupId: string, taskIds: string[]): Promise<void>;
  removeTaskFromGroup(groupId: string, taskId: string): Promise<void>;
  dissolveGroup(id: string): Promise<void>;
  validateGroupName(name: string): ValidationResult;
  validateGroupCapacity(): Promise<ValidationResult>;
  getGroupWithTasks(groupId: string): Promise<GroupWithTasks | null>;
  getAllGroupsWithTasks(): Promise<GroupWithTasks[]>;
}

/**
 * 任务组合体服务实现
 * 注意：组合体中的任务是独立副本，与外部任务完全分离
 */
export class TaskGroupService implements ITaskGroupService {
  private database: TimerTaskDatabase;
  private taskService: TimerTaskService;

  constructor(database: TimerTaskDatabase, taskService: TimerTaskService) {
    this.database = database;
    this.taskService = taskService;
  }

  /**
   * 获取所有组合体
   */
  async getAllGroups(): Promise<TaskGroup[]> {
    try {
      const groups = await this.database.getAllGroups();
      Logger.info(TAG, `Retrieved ${groups.length} groups`);
      const result: TaskGroup[] = groups.map(g => {
        const taskGroup: TaskGroup = {
          id: g.id,
          name: g.name,
          tasks: g.tasks,
          status: g.status as GroupStatus,
          isExpanded: g.isExpanded,
          createdTime: g.createdTime,
          lastModifiedTime: g.lastModifiedTime
        };
        return taskGroup;
      });
      return result;
    } catch (error) {
      Logger.error(TAG, `Failed to get all groups: ${JSON.stringify(error)}`);
      throw new Error('Failed to get all groups');
    }
  }

  /**
   * 根据ID获取组合体
   */
  async getGroupById(id: string): Promise<TaskGroup | null> {
    try {
      const group = await this.database.getGroupById(id);
      if (group) {
        Logger.info(TAG, `Retrieved group: ${id}`);
        return {
          id: group.id,
          name: group.name,
          tasks: group.tasks,
          status: group.status as GroupStatus,
          isExpanded: group.isExpanded,
          createdTime: group.createdTime,
          lastModifiedTime: group.lastModifiedTime
        };
      } else {
        Logger.warn(TAG, `Group not found: ${id}`);
        return null;
      }
    } catch (error) {
      Logger.error(TAG, `Failed to get group by id: ${JSON.stringify(error)}`);
      throw new Error('Failed to get group by id');
    }
  }

  /**
   * 创建组合体
   * 注意：会复制任务数据，创建独立副本
   */
  async createGroup(name: string, taskIds: string[]): Promise<TaskGroup> {
    try {
      // 验证名称
      const nameValidation = this.validateGroupName(name);
      if (!nameValidation.valid) {
        throw new Error(nameValidation.message);
      }

      // 获取原始任务数据
      const originalTasks: TimerTask[] = [];
      for (const taskId of taskIds) {
        const task = await this.taskService.getTaskById(taskId);
        if (task) {
          originalTasks.push(task);
        }
      }

      // 验证任务数量
      const taskValidation = TaskGroupModel.validateTaskCount(originalTasks);
      if (!taskValidation.valid) {
        throw new Error(taskValidation.message);
      }

      // 验证组合体数量上限
      const capacityValidation = await this.validateGroupCapacity();
      if (!capacityValidation.valid) {
        throw new Error(capacityValidation.message);
      }

      // 复制任务数据，生成新的ID
      const taskCopies: TimerTask[] = originalTasks.map(task => {
        return new TimerTaskModel(
          this.generateUUID(),
          task.name,
          task.timeMode,
          task.taskType,
          task.hour,
          task.minute,
          task.volumeSettings,
          task.status,
          Date.now(),
          task.lastExecuteTime,
          task.endHour,
          task.endMinute,
          task.lockStatus
        );
      });

      // 创建组合体对象
      const group = new TaskGroupModel(undefined, name, taskCopies, GroupStatus.ENABLED, false);

      // 保存到数据库
      await this.database.insertGroup({
        id: group.id,
        name: group.name,
        tasks: group.tasks,
        status: group.status,
        isExpanded: group.isExpanded,
        createdTime: group.createdTime,
        lastModifiedTime: group.lastModifiedTime
      });

      Logger.info(TAG, `Group created: ${group.id} with ${taskCopies.length} task copies`);
      return group;
    } catch (error) {
      Logger.error(TAG, `Failed to create group: ${JSON.stringify(error)}`);
      throw new Error(`Failed to create group: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 删除组合体（解散）
   */
  async deleteGroup(id: string): Promise<void> {
    try {
      const group = await this.getGroupById(id);
      if (!group) {
        throw new Error('Group not found');
      }

      // 直接删除组合体记录（任务副本会随之删除）
      await this.database.deleteGroup(id);
      Logger.info(TAG, `Group deleted: ${id}`);
    } catch (error) {
      Logger.error(TAG, `Failed to delete group: ${JSON.stringify(error)}`);
      throw new Error(`Failed to delete group: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 更新组合体状态
   */
  async updateGroupStatus(id: string, status: GroupStatus): Promise<void> {
    try {
      const group = await this.getGroupById(id);
      if (!group) {
        throw new Error('Group not found');
      }

      // 更新组合体状态
      await this.database.updateGroupStatus(id, status);

      // 更新所有子任务副本的状态
      const updatedTasks = group.tasks.map(task => {
        return new TimerTaskModel(
          task.id,
          task.name,
          task.timeMode,
          task.taskType,
          task.hour,
          task.minute,
          task.volumeSettings,
          status === GroupStatus.ENABLED ? TaskStatus.ENABLED : TaskStatus.DISABLED,
          task.createdTime,
          task.lastExecuteTime,
          task.endHour,
          task.endMinute,
          task.lockStatus
        );
      });

      await this.database.updateGroupTasks(id, updatedTasks);

      Logger.info(TAG, `Group status updated: ${id} -> ${status}`);
    } catch (error) {
      Logger.error(TAG, `Failed to update group status: ${JSON.stringify(error)}`);
      throw new Error(`Failed to update group status: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 更新组合体展开状态
   */
  async updateGroupExpanded(id: string, isExpanded: boolean): Promise<void> {
    try {
      await this.database.updateGroupExpanded(id, isExpanded);
      Logger.info(TAG, `Group expanded updated: ${id} -> ${isExpanded}`);
    } catch (error) {
      Logger.error(TAG, `Failed to update group expanded: ${JSON.stringify(error)}`);
      throw new Error(`Failed to update group expanded: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 添加任务到组合体
   * 注意：会复制任务数据，创建独立副本
   */
  async addTasksToGroup(groupId: string, taskIds: string[]): Promise<void> {
    try {
      const group = await this.getGroupById(groupId);
      if (!group) {
        throw new Error('Group not found');
      }

      // 获取原始任务数据
      const originalTasks: TimerTask[] = [];
      for (const taskId of taskIds) {
        const task = await this.taskService.getTaskById(taskId);
        if (task) {
          originalTasks.push(task);
        }
      }

      // 验证任务数量
      const newTasks: TimerTask[] = [];
      for (const task of group.tasks) {
        newTasks.push(task);
      }
      for (const task of originalTasks) {
        newTasks.push(task);
      }
      const taskValidation = TaskGroupModel.validateTaskCount(newTasks);
      if (!taskValidation.valid) {
        throw new Error(taskValidation.message);
      }

      // 复制任务数据，生成新的ID
      const taskCopies: TimerTask[] = originalTasks.map(task => {
        return new TimerTaskModel(
          this.generateUUID(),
          task.name,
          task.timeMode,
          task.taskType,
          task.hour,
          task.minute,
          task.volumeSettings,
          group.status === GroupStatus.ENABLED ? TaskStatus.ENABLED : TaskStatus.DISABLED,
          Date.now(),
          task.lastExecuteTime,
          task.endHour,
          task.endMinute,
          task.lockStatus
        );
      });

      // 更新组合体的任务列表
      const updatedTasks: TimerTask[] = [];
      for (const task of group.tasks) {
        updatedTasks.push(task);
      }
      for (const taskCopy of taskCopies) {
        updatedTasks.push(taskCopy);
      }
      await this.database.updateGroupTasks(groupId, updatedTasks);

      Logger.info(TAG, `Tasks added to group: ${groupId} <- ${taskCopies.length} task copies`);
    } catch (error) {
      Logger.error(TAG, `Failed to add tasks to group: ${JSON.stringify(error)}`);
      throw new Error(`Failed to add tasks to group: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 从组合体移出任务
   */
  async removeTaskFromGroup(groupId: string, taskId: string): Promise<void> {
    try {
      const group = await this.getGroupById(groupId);
      if (!group) {
        throw new Error('Group not found');
      }

      // 从任务列表中移除
      const newTasks = group.tasks.filter(t => t.id !== taskId);

      // 如果任务列表为空，解散组合体
      if (newTasks.length === 0) {
        await this.deleteGroup(groupId);
        Logger.info(TAG, `Group auto-dissolved: ${groupId}`);
        return;
      }

      // 更新组合体的任务列表
      await this.database.updateGroupTasks(groupId, newTasks);

      Logger.info(TAG, `Task removed from group: ${groupId} <- ${taskId}`);
    } catch (error) {
      Logger.error(TAG, `Failed to remove task from group: ${JSON.stringify(error)}`);
      throw new Error(`Failed to remove task from group: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 解散组合体
   */
  async dissolveGroup(id: string): Promise<void> {
    await this.deleteGroup(id);
  }

  /**
   * 验证组合体名称
   */
  validateGroupName(name: string): ValidationResult {
    return TaskGroupModel.validateName(name);
  }

  /**
   * 验证组合体数量上限
   */
  async validateGroupCapacity(): Promise<ValidationResult> {
    try {
      const groups = await this.getAllGroups();
      if (groups.length >= 50) {
        return { valid: false, message: '组合体数量已达上限（50个）' };
      }
      return { valid: true };
    } catch (error) {
      Logger.error(TAG, `Failed to validate group capacity: ${JSON.stringify(error)}`);
      return { valid: false, message: '验证组合体数量失败' };
    }
  }

  /**
   * 获取组合体及其子任务
   */
  async getGroupWithTasks(groupId: string): Promise<GroupWithTasks | null> {
    try {
      const group = await this.getGroupById(groupId);
      if (!group) {
        return null;
      }

      return { group, tasks: group.tasks };
    } catch (error) {
      Logger.error(TAG, `Failed to get group with tasks: ${JSON.stringify(error)}`);
      throw new Error(`Failed to get group with tasks: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 获取所有组合体及其子任务
   */
  async getAllGroupsWithTasks(): Promise<GroupWithTasks[]> {
    try {
      const groups = await this.getAllGroups();
      const result: GroupWithTasks[] = groups.map(group => {
        const groupWithTasks: GroupWithTasks = {
          group: group,
          tasks: group.tasks
        };
        return groupWithTasks;
      });

      Logger.info(TAG, `Retrieved ${result.length} groups with tasks`);
      return result;
    } catch (error) {
      Logger.error(TAG, `Failed to get all groups with tasks: ${JSON.stringify(error)}`);
      throw new Error(`Failed to get all groups with tasks: ${JSON.stringify(error)}`);
    }
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
}
