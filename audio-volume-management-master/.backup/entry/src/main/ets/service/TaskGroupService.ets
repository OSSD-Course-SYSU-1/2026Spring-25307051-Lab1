import { TaskGroup, GroupStatus, GroupWithTasks, TaskGroupModel, ValidationResult } from '../model/TaskGroup';
import { TimerTask } from '../model/TimerTask';
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
          taskIds: g.taskIds,
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
          taskIds: group.taskIds,
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
   */
  async createGroup(name: string, taskIds: string[]): Promise<TaskGroup> {
    try {
      // 验证名称
      const nameValidation = this.validateGroupName(name);
      if (!nameValidation.valid) {
        throw new Error(nameValidation.message);
      }

      // 验证任务数量
      const taskValidation = TaskGroupModel.validateTaskCount(taskIds);
      if (!taskValidation.valid) {
        throw new Error(taskValidation.message);
      }

      // 验证组合体数量上限
      const capacityValidation = await this.validateGroupCapacity();
      if (!capacityValidation.valid) {
        throw new Error(capacityValidation.message);
      }

      // 检查任务是否已属于其他组合体
      for (const taskId of taskIds) {
        const task = await this.taskService.getTaskById(taskId);
        if (task && task.groupId) {
          throw new Error(`任务 ${taskId} 已属于其他组合体`);
        }
      }

      // 创建组合体对象
      const group = new TaskGroupModel(undefined, name, taskIds, GroupStatus.ENABLED, false);

      // 保存到数据库
      await this.database.insertGroup({
        id: group.id,
        name: group.name,
        taskIds: group.taskIds,
        status: group.status,
        isExpanded: group.isExpanded,
        createdTime: group.createdTime,
        lastModifiedTime: group.lastModifiedTime
      });

      // 更新任务的groupId
      for (const taskId of taskIds) {
        await this.database.updateTaskGroupId(taskId, group.id);
      }

      Logger.info(TAG, `Group created: ${group.id} with ${taskIds.length} tasks`);
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

      // 清除所有子任务的groupId和originalStatus
      for (const taskId of group.taskIds) {
        await this.database.updateTaskGroupId(taskId, null);
        await this.database.updateTaskOriginalStatus(taskId, null);

        // 如果组合体已禁用，恢复子任务状态
        if (group.status === GroupStatus.DISABLED) {
          const task = await this.taskService.getTaskById(taskId);
          if (task && task.originalStatus) {
            await this.taskService.updateTaskStatus(taskId, task.originalStatus);
          }
        }
      }

      // 删除组合体记录
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

      // 更新所有子任务状态
      for (const taskId of group.taskIds) {
        const task = await this.taskService.getTaskById(taskId);
        if (!task) continue;

        if (status === GroupStatus.DISABLED) {
          // 禁用：保存原始状态，然后禁用任务
          await this.database.updateTaskOriginalStatus(taskId, task.status);
          await this.taskService.updateTaskStatus(taskId, TaskStatus.DISABLED);
        } else {
          // 启用：恢复原始状态
          if (task.originalStatus) {
            await this.taskService.updateTaskStatus(taskId, task.originalStatus);
            await this.database.updateTaskOriginalStatus(taskId, null);
          }
        }
      }

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
   */
  async addTasksToGroup(groupId: string, taskIds: string[]): Promise<void> {
    try {
      const group = await this.getGroupById(groupId);
      if (!group) {
        throw new Error('Group not found');
      }

      // 验证任务数量
      const newTaskIds = [...group.taskIds, ...taskIds];
      const taskValidation = TaskGroupModel.validateTaskCount(newTaskIds);
      if (!taskValidation.valid) {
        throw new Error(taskValidation.message);
      }

      // 检查任务是否已属于其他组合体
      for (const taskId of taskIds) {
        const task = await this.taskService.getTaskById(taskId);
        if (task && task.groupId && task.groupId !== groupId) {
          throw new Error(`任务 ${taskId} 已属于其他组合体`);
        }
      }

      // 更新组合体的taskIds
      await this.database.updateGroupTaskIds(groupId, newTaskIds);

      // 更新任务的groupId
      for (const taskId of taskIds) {
        await this.database.updateTaskGroupId(taskId, groupId);

        // 如果组合体已禁用，禁用新添加的任务
        if (group.status === GroupStatus.DISABLED) {
          const task = await this.taskService.getTaskById(taskId);
          if (task) {
            await this.database.updateTaskOriginalStatus(taskId, task.status);
            await this.taskService.updateTaskStatus(taskId, TaskStatus.DISABLED);
          }
        }
      }

      Logger.info(TAG, `Tasks added to group: ${groupId} <- ${taskIds.length} tasks`);
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

      // 从taskIds中移除
      const newTaskIds = group.taskIds.filter(id => id !== taskId);

      // 如果taskIds为空，解散组合体
      if (newTaskIds.length === 0) {
        await this.deleteGroup(groupId);
        Logger.info(TAG, `Group auto-dissolved: ${groupId}`);
        return;
      }

      // 更新组合体的taskIds
      await this.database.updateGroupTaskIds(groupId, newTaskIds);

      // 清除任务的groupId
      await this.database.updateTaskGroupId(taskId, null);

      // 恢复任务状态（如果组合体已禁用）
      if (group.status === GroupStatus.DISABLED) {
        const task = await this.taskService.getTaskById(taskId);
        if (task && task.originalStatus) {
          await this.taskService.updateTaskStatus(taskId, task.originalStatus);
          await this.database.updateTaskOriginalStatus(taskId, null);
        }
      }

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

      const tasks: TimerTask[] = [];
      for (const taskId of group.taskIds) {
        const task = await this.taskService.getTaskById(taskId);
        if (task) {
          tasks.push(task);
        }
      }

      return { group, tasks };
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
      const result: GroupWithTasks[] = [];

      for (const group of groups) {
        const tasks: TimerTask[] = [];
        for (const taskId of group.taskIds) {
          const task = await this.taskService.getTaskById(taskId);
          if (task) {
            tasks.push(task);
          }
        }
        result.push({ group, tasks });
      }

      Logger.info(TAG, `Retrieved ${result.length} groups with tasks`);
      return result;
    } catch (error) {
      Logger.error(TAG, `Failed to get all groups with tasks: ${JSON.stringify(error)}`);
      throw new Error(`Failed to get all groups with tasks: ${JSON.stringify(error)}`);
    }
  }
}
