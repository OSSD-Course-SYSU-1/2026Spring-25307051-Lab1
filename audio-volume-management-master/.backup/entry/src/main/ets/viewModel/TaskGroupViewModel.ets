import { TaskGroup, GroupStatus, GroupWithTasks, ValidationResult } from '../model/TaskGroup';
import { TimerTask } from '../model/TimerTask';
import { TaskGroupService } from '../service/TaskGroupService';
import { TimerTaskService } from '../service/TimerTaskService';
import { Logger } from '../utils/Logger';

const TAG = 'TaskGroupViewModel';

/**
 * 任务组合体ViewModel接口
 */
export interface ITaskGroupViewModel {
  loadGroupsWithTasks(): Promise<GroupWithTasks[]>;
  createGroup(name: string, taskIds: string[]): Promise<TaskGroup>;
  dissolveGroup(groupId: string): Promise<void>;
  toggleGroupStatus(groupId: string): Promise<void>;
  toggleGroupExpanded(groupId: string): Promise<void>;
  addTasksToGroup(groupId: string, taskIds: string[]): Promise<void>;
  removeTaskFromGroup(groupId: string, taskId: string): Promise<void>;
  validateGroupName(name: string): ValidationResult;
  validateGroupCapacity(): Promise<ValidationResult>;
}

/**
 * 任务组合体ViewModel实现
 */
export class TaskGroupViewModel implements ITaskGroupViewModel {
  private groupService: TaskGroupService;
  private taskService: TimerTaskService;

  constructor(groupService: TaskGroupService, taskService: TimerTaskService) {
    this.groupService = groupService;
    this.taskService = taskService;
  }

  /**
   * 加载所有组合体及其子任务
   */
  async loadGroupsWithTasks(): Promise<GroupWithTasks[]> {
    try {
      const groupsWithTasks = await this.groupService.getAllGroupsWithTasks();

      // 按创建时间倒序排列
      groupsWithTasks.sort((a, b) => {
        return b.group.createdTime - a.group.createdTime;
      });

      Logger.info(TAG, `Loaded ${groupsWithTasks.length} groups with tasks`);
      return groupsWithTasks;
    } catch (error) {
      Logger.error(TAG, `Failed to load groups with tasks: ${JSON.stringify(error)}`);
      throw new Error('Failed to load groups with tasks');
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
      if (taskIds.length === 0) {
        throw new Error('请至少选择一个任务');
      }

      // 创建组合体
      const group = await this.groupService.createGroup(name, taskIds);
      Logger.info(TAG, `Group created: ${group.id}`);
      return group;
    } catch (error) {
      Logger.error(TAG, `Failed to create group: ${JSON.stringify(error)}`);
      throw new Error(`Failed to create group: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 解散组合体
   */
  async dissolveGroup(groupId: string): Promise<void> {
    try {
      await this.groupService.dissolveGroup(groupId);
      Logger.info(TAG, `Group dissolved: ${groupId}`);
    } catch (error) {
      Logger.error(TAG, `Failed to dissolve group: ${JSON.stringify(error)}`);
      throw new Error(`Failed to dissolve group: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 切换组合体状态
   */
  async toggleGroupStatus(groupId: string): Promise<void> {
    try {
      const group = await this.groupService.getGroupById(groupId);
      if (!group) {
        throw new Error('Group not found');
      }

      const newStatus = group.status === GroupStatus.ENABLED ? GroupStatus.DISABLED : GroupStatus.ENABLED;
      await this.groupService.updateGroupStatus(groupId, newStatus);
      Logger.info(TAG, `Group status toggled: ${groupId} -> ${newStatus}`);
    } catch (error) {
      Logger.error(TAG, `Failed to toggle group status: ${JSON.stringify(error)}`);
      throw new Error(`Failed to toggle group status: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 切换组合体展开状态
   */
  async toggleGroupExpanded(groupId: string): Promise<void> {
    try {
      const group = await this.groupService.getGroupById(groupId);
      if (!group) {
        throw new Error('Group not found');
      }

      const newExpanded = !group.isExpanded;
      await this.groupService.updateGroupExpanded(groupId, newExpanded);
      Logger.info(TAG, `Group expanded toggled: ${groupId} -> ${newExpanded}`);
    } catch (error) {
      Logger.error(TAG, `Failed to toggle group expanded: ${JSON.stringify(error)}`);
      throw new Error(`Failed to toggle group expanded: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 添加任务到组合体
   */
  async addTasksToGroup(groupId: string, taskIds: string[]): Promise<void> {
    try {
      await this.groupService.addTasksToGroup(groupId, taskIds);
      Logger.info(TAG, `Tasks added to group: ${groupId}`);
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
      await this.groupService.removeTaskFromGroup(groupId, taskId);
      Logger.info(TAG, `Task removed from group: ${groupId} <- ${taskId}`);
    } catch (error) {
      Logger.error(TAG, `Failed to remove task from group: ${JSON.stringify(error)}`);
      throw new Error(`Failed to remove task from group: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 验证组合体名称
   */
  validateGroupName(name: string): ValidationResult {
    return this.groupService.validateGroupName(name);
  }

  /**
   * 验证组合体数量上限
   */
  async validateGroupCapacity(): Promise<ValidationResult> {
    return await this.groupService.validateGroupCapacity();
  }
}
