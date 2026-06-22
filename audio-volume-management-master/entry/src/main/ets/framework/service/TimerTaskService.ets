import { TimerTask } from '../model/TimerTask';
import { TaskExecution } from '../model/TaskExecution';
import { TaskStatus } from '../model/TaskEnums';
import { TimerTaskDatabase } from '../data/TimerTaskDatabase';
import { Logger } from '../utils/Logger';

const TAG = 'TimerTaskService';

/**
 * 任务管理服务接口
 */
export interface ITimerTaskService {
  getAllTasks(): Promise<TimerTask[]>;
  getTaskById(id: string): Promise<TimerTask | null>;
  saveTask(task: TimerTask): Promise<void>;
  deleteTask(id: string): Promise<void>;
  updateTaskStatus(id: string, status: TaskStatus): Promise<void>;
  getExecutionHistory(taskId: string, limit?: number): Promise<TaskExecution[]>;
  recordExecution(execution: TaskExecution): Promise<void>;
}

/**
 * 任务管理服务实现
 */
export class TimerTaskService implements ITimerTaskService {
  private database: TimerTaskDatabase;

  constructor(database: TimerTaskDatabase) {
    this.database = database;
  }

  /**
   * 获取所有任务
   */
  async getAllTasks(): Promise<TimerTask[]> {
    try {
      const tasks = await this.database.getAllTasks();
      Logger.info(TAG, `Retrieved ${tasks.length} tasks`);
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
    try {
      const task = await this.database.getTaskById(id);
      if (task) {
        Logger.info(TAG, `Retrieved task: ${id}`);
      } else {
        Logger.warn(TAG, `Task not found: ${id}`);
      }
      return task;
    } catch (error) {
      Logger.error(TAG, `Failed to get task by id: ${JSON.stringify(error)}`);
      throw new Error('Failed to get task by id');
    }
  }

  /**
   * 保存任务（创建或更新）
   */
  async saveTask(task: TimerTask): Promise<void> {
    try {
      const existingTask = await this.database.getTaskById(task.id);
      
      if (existingTask) {
        await this.database.updateTask(task);
        Logger.info(TAG, `Task updated: ${task.id}`);
      } else {
        await this.database.insertTask(task);
        Logger.info(TAG, `Task created: ${task.id}`);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to save task: ${JSON.stringify(error)}`);
      throw new Error('Failed to save task');
    }
  }

  /**
   * 删除任务
   */
  async deleteTask(id: string): Promise<void> {
    try {
      await this.database.deleteTask(id);
      Logger.info(TAG, `Task deleted: ${id}`);
    } catch (error) {
      Logger.error(TAG, `Failed to delete task: ${JSON.stringify(error)}`);
      throw new Error('Failed to delete task');
    }
  }

  /**
   * 更新任务状态
   */
  async updateTaskStatus(id: string, status: TaskStatus): Promise<void> {
    try {
      await this.database.updateTaskStatus(id, status);
      Logger.info(TAG, `Task status updated: ${id} -> ${status}`);
    } catch (error) {
      Logger.error(TAG, `Failed to update task status: ${JSON.stringify(error)}`);
      throw new Error('Failed to update task status');
    }
  }

  /**
   * 获取任务执行历史
   */
  async getExecutionHistory(taskId: string, limit: number = 10): Promise<TaskExecution[]> {
    try {
      const executions = await this.database.getExecutionHistory(taskId, limit);
      Logger.info(TAG, `Retrieved ${executions.length} execution records for task: ${taskId}`);
      return executions;
    } catch (error) {
      Logger.error(TAG, `Failed to get execution history: ${JSON.stringify(error)}`);
      throw new Error('Failed to get execution history');
    }
  }

  /**
   * 记录任务执行
   */
  async recordExecution(execution: TaskExecution): Promise<void> {
    try {
      await this.database.recordExecution(execution);
      Logger.info(TAG, `Execution recorded: ${execution.taskId}`);
    } catch (error) {
      Logger.error(TAG, `Failed to record execution: ${JSON.stringify(error)}`);
      throw new Error('Failed to record execution');
    }
  }
}
