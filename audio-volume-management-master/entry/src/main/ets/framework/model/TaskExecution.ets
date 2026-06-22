/**
 * 任务执行记录接口
 */
export interface TaskExecution {
  id: string;                  // 唯一标识符
  taskId: string;              // 关联的任务ID
  executeTime: number;         // 执行时间戳
  result: 'SUCCESS' | 'FAILED'; // 执行结果
  errorMessage?: string;       // 错误信息（可选）
}

/**
 * 任务执行记录模型类
 */
export class TaskExecutionModel implements TaskExecution {
  id: string;
  taskId: string;
  executeTime: number;
  result: 'SUCCESS' | 'FAILED';
  errorMessage?: string;

  constructor(data: Partial<TaskExecution>) {
    this.id = data.id || this.generateUUID();
    this.taskId = data.taskId || '';
    this.executeTime = data.executeTime || Date.now();
    this.result = data.result || 'SUCCESS';
    this.errorMessage = data.errorMessage;
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
