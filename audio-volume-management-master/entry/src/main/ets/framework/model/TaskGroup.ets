import { TimerTask, TimerTaskModel } from './TimerTask';

/**
 * 组合体状态枚举
 */
export enum GroupStatus {
  ENABLED = 'ENABLED',   // 启用
  DISABLED = 'DISABLED'  // 禁用
}

/**
 * 验证结果接口
 */
export interface ValidationResult {
  valid: boolean;
  message?: string;
}

/**
 * 任务组合体接口
 * 注意：组合体中的任务是独立副本，与外部任务完全分离
 */
export interface TaskGroup {
  id: string;                      // 唯一标识符（UUID）
  name: string;                    // 组合体名称（最大长度30字符）
  tasks: TimerTask[];              // 子任务列表（独立副本，非引用）
  status: GroupStatus;             // 组合体开关状态
  isExpanded: boolean;             // 展开状态
  createdTime: number;             // 创建时间戳
  lastModifiedTime?: number;       // 最后修改时间戳
}

/**
 * 组合体与子任务的聚合接口（保持兼容）
 */
export interface GroupWithTasks {
  group: TaskGroup;                // 组合体对象
  tasks: TimerTask[];              // 子任务列表
}

/**
 * 任务组合体模型类
 */
export class TaskGroupModel implements TaskGroup {
  id: string;
  name: string;
  tasks: TimerTask[];
  status: GroupStatus;
  isExpanded: boolean;
  createdTime: number;
  lastModifiedTime?: number;

  constructor(
    id?: string,
    name?: string,
    tasks?: TimerTask[],
    status?: GroupStatus,
    isExpanded?: boolean,
    createdTime?: number,
    lastModifiedTime?: number
  ) {
    this.id = id ?? this.generateUUID();
    this.name = name ?? '新组合体';
    this.tasks = tasks ?? [];
    this.status = status ?? GroupStatus.ENABLED;
    this.isExpanded = isExpanded ?? false;
    this.createdTime = createdTime ?? Date.now();
    this.lastModifiedTime = lastModifiedTime;
  }

  /**
   * 添加子任务（复制任务数据）
   */
  addTask(task: TimerTask): void {
    // 创建任务副本，生成新的ID
    const taskCopy = this.cloneTask(task);
    this.tasks.push(taskCopy);
    this.lastModifiedTime = Date.now();
  }

  /**
   * 移除子任务
   */
  removeTask(taskId: string): void {
    const index = this.tasks.findIndex(t => t.id === taskId);
    if (index > -1) {
      this.tasks.splice(index, 1);
      this.lastModifiedTime = Date.now();
    }
  }

  /**
   * 切换状态
   */
  toggleStatus(): void {
    this.status = this.status === GroupStatus.ENABLED ? GroupStatus.DISABLED : GroupStatus.ENABLED;
    this.lastModifiedTime = Date.now();
  }

  /**
   * 切换展开状态
   */
  toggleExpanded(): void {
    this.isExpanded = !this.isExpanded;
    this.lastModifiedTime = Date.now();
  }

  /**
   * 克隆任务（创建独立副本）
   */
  private cloneTask(task: TimerTask): TimerTask {
    // 创建任务副本，生成新的ID
    const clonedTask: TimerTask = new TimerTaskModel(
      this.generateUUID(),  // 生成新的ID
      task.name,
      task.timeMode,
      task.taskType,
      task.hour,
      task.minute,
      task.volumeSettings,
      task.status,
      Date.now(),  // 新的创建时间
      task.lastExecuteTime,
      task.endHour,
      task.endMinute,
      task.lockStatus
    );
    return clonedTask;
  }

  /**
   * 验证组合体名称
   */
  static validateName(name: string): ValidationResult {
    if (!name || name.trim().length === 0) {
      const result: ValidationResult = { valid: false, message: '组合体名称不能为空' };
      return result;
    }
    if (name.length > 30) {
      const result: ValidationResult = { valid: false, message: '组合体名称长度不能超过30字符' };
      return result;
    }
    const result: ValidationResult = { valid: true };
    return result;
  }

  /**
   * 验证子任务数量
   */
  static validateTaskCount(tasks: TimerTask[]): ValidationResult {
    if (tasks.length === 0) {
      const result: ValidationResult = { valid: false, message: '组合体至少需要1个子任务' };
      return result;
    }
    if (tasks.length > 20) {
      const result: ValidationResult = { valid: false, message: '组合体最多包含20个子任务' };
      return result;
    }
    const result: ValidationResult = { valid: true };
    return result;
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
