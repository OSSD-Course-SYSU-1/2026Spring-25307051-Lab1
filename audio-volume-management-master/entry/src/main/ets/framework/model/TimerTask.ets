import { TimeMode, TaskStatus, TaskType, LockStatus } from './TaskEnums';
import { VolumeSetting } from './VolumeSetting';

/**
 * 一次性任务模式
 */
export enum OnceMode {
  DISPOSABLE = 'DISPOSABLE',   // 一次性：执行后自动删除
  REUSABLE = 'REUSABLE'        // 重复利用：执行后禁用，可再次启用
}

/**
 * 定时任务接口
 */
export interface TimerTask {
  id: string;                      // 唯一标识符
  name?: string;                   // 任务名称（可选）
  timeMode: TimeMode;              // 时间模式
  taskType: TaskType;              // 任务类型（瞬时/时间段）

  // 单次任务专用
  executeTime?: number;            // 执行时间戳
  onceMode?: OnceMode;             // 一次性模式（一次性/重复利用）
  baseTime?: number;               // 重复利用的基准时间戳
  daysOffset?: number;             // 相对于基准时间的天数偏移（0-14）

  // 每周循环专用
  dayOfWeek?: number;              // 星期几（1-7，1=周一）

  // 每月循环专用
  dayOfMonth?: number;             // 日期（1-31）

  // 通用时间字段
  hour: number;                    // 小时（0-23）
  minute: number;                  // 分钟（0-59）

  // 时间段锁定专用字段
  endHour?: number;                // 结束小时（0-23）
  endMinute?: number;              // 结束分钟（0-59）
  lockStatus?: LockStatus;         // 锁定状态

  volumeSettings: VolumeSetting[]; // 音量设置列表
  status: TaskStatus;              // 任务状态
  createdTime: number;             // 创建时间戳
  lastExecuteTime?: number;        // 最后执行时间戳
}

/**
 * 定时任务模型类
 */
export class TimerTaskModel implements TimerTask {
  id: string;
  name?: string;
  timeMode: TimeMode;
  taskType: TaskType;
  executeTime?: number;
  onceMode?: OnceMode;
  baseTime?: number;
  daysOffset?: number;
  dayOfWeek?: number;
  dayOfMonth?: number;
  hour: number;
  minute: number;
  endHour?: number;
  endMinute?: number;
  lockStatus?: LockStatus;
  volumeSettings: VolumeSetting[];
  status: TaskStatus;
  createdTime: number;
  lastExecuteTime?: number;

  constructor(
    id?: string,
    name?: string,
    timeMode?: TimeMode,
    taskType?: TaskType,
    hour?: number,
    minute?: number,
    volumeSettings?: VolumeSetting[],
    status?: TaskStatus,
    createdTime?: number,
    lastExecuteTime?: number,
    endHour?: number,
    endMinute?: number,
    lockStatus?: LockStatus
  ) {
    this.id = id ?? this.generateUUID();
    this.name = name;
    this.timeMode = timeMode ?? TimeMode.ONCE;
    this.taskType = taskType ?? TaskType.INSTANT;
    this.hour = hour ?? 0;
    this.minute = minute ?? 0;
    this.endHour = endHour;
    this.endMinute = endMinute;
    this.lockStatus = lockStatus ?? LockStatus.INACTIVE;
    this.volumeSettings = volumeSettings ?? [];
    this.status = status ?? TaskStatus.ENABLED;
    this.createdTime = createdTime ?? Date.now();
    this.lastExecuteTime = lastExecuteTime;
  }

  /**
   * 设置单次任务执行时间
   */
  setExecuteTime(executeTime: number): void {
    this.timeMode = TimeMode.ONCE;
    this.executeTime = executeTime;
  }

  /**
   * 设置每周循环
   */
  setWeekly(dayOfWeek: number): void {
    this.timeMode = TimeMode.WEEKLY;
    this.dayOfWeek = dayOfWeek;
  }

  /**
   * 设置每月循环
   */
  setMonthly(dayOfMonth: number): void {
    this.timeMode = TimeMode.MONTHLY;
    this.dayOfMonth = dayOfMonth;
  }

  /**
   * 设置为时间段锁定任务
   */
  setPeriodLock(endHour: number, endMinute: number): void {
    this.taskType = TaskType.PERIOD;
    this.endHour = endHour;
    this.endMinute = endMinute;
    this.lockStatus = LockStatus.INACTIVE;
  }

  /**
   * 检查当前是否在锁定时间段内
   */
  isInLockPeriod(): boolean {
    if (this.taskType !== TaskType.PERIOD) {
      return false;
    }

    const now = new Date();
    const currentHour = now.getHours();
    const currentMinute = now.getMinutes();
    const currentTime = currentHour * 60 + currentMinute;

    const startTime = this.hour * 60 + this.minute;
    const endTime = this.endHour! * 60 + this.endMinute!;

    // 处理跨天情况（例如：22:00 - 06:00）
    if (startTime > endTime) {
      return currentTime >= startTime || currentTime <= endTime;
    } else {
      return currentTime >= startTime && currentTime <= endTime;
    }
  }

  /**
   * 计算锁定结束时间戳
   */
  getLockEndTime(): number {
    const now = new Date();
    const endDate = new Date(now);

    // 设置结束时间
    endDate.setHours(this.endHour!, this.endMinute!, 0, 0);

    // 如果结束时间小于开始时间，说明跨天了
    const startTime = this.hour * 60 + this.minute;
    const endTime = this.endHour! * 60 + this.endMinute!;

    if (startTime > endTime && !this.isInLockPeriod()) {
      // 不在锁定时间段内，且跨天，结束时间应该是明天
      endDate.setDate(endDate.getDate() + 1);
    }

    return endDate.getTime();
  }

  /**
   * 生成任务描述文本
   */
  getDescription(): string {
    const timeStr = `${this.hour.toString().padStart(2, '0')}:${this.minute.toString().padStart(2, '0')}`;
    
    // 生成音量设置描述（包含静音状态）
    const volumeDesc = this.volumeSettings.map(setting => {
      if (setting.mute) {
        return '静音';
      }
      return `${setting.volumeValue}%`;
    }).join('、');

    if (this.timeMode === TimeMode.ONCE) {
      const now = Date.now();
      const diff = this.executeTime! - now;
      const days = Math.floor(diff / (1000 * 60 * 60 * 24));
      const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
      
      if (days > 0) {
        return `${days}天后 ${timeStr} 设置音量为 ${volumeDesc}`;
      } else if (hours > 0) {
        return `${hours}小时后 ${timeStr} 设置音量为 ${volumeDesc}`;
      } else {
        return `今天 ${timeStr} 设置音量为 ${volumeDesc}`;
      }
    } else if (this.timeMode === TimeMode.WEEKLY) {
      const weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      return `每${weekDays[(this.dayOfWeek! - 1) % 7]} ${timeStr} 设置音量为 ${volumeDesc}`;
    } else {
      return `每月${this.dayOfMonth}日 ${timeStr} 设置音量为 ${volumeDesc}`;
    }
  }

  /**
   * 计算下一次执行时间
   */
  getNextExecuteTime(): number {
    const now = new Date();
    
    if (this.timeMode === TimeMode.ONCE) {
      return this.executeTime!;
    } else if (this.timeMode === TimeMode.WEEKLY) {
      // 计算下一个指定星期几的时间
      const targetDay = this.dayOfWeek!; // 1-7, 1=周一
      const currentDay = now.getDay(); // 0-6, 0=周日
      const currentDayNormalized = currentDay === 0 ? 7 : currentDay; // 转换为1-7
      
      let daysUntil = targetDay - currentDayNormalized;
      if (daysUntil < 0) {
        daysUntil += 7;
      } else if (daysUntil === 0) {
        // 今天，检查时间是否已过
        const targetTime = new Date(now);
        targetTime.setHours(this.hour, this.minute, 0, 0);
        if (targetTime.getTime() <= now.getTime()) {
          daysUntil = 7;
        }
      }
      
      const nextDate = new Date(now);
      nextDate.setDate(now.getDate() + daysUntil);
      nextDate.setHours(this.hour, this.minute, 0, 0);
      
      return nextDate.getTime();
    } else {
      // 每月循环
      const targetDate = this.dayOfMonth!;
      const nextDate = new Date(now);
      
      // 检查当月是否有该日期
      const daysInCurrentMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
      
      if (targetDate <= daysInCurrentMonth && now.getDate() < targetDate) {
        // 当月有该日期且未到
        nextDate.setDate(targetDate);
      } else if (targetDate <= daysInCurrentMonth && now.getDate() === targetDate) {
        // 今天是该日期，检查时间
        const targetTime = new Date(now);
        targetTime.setHours(this.hour, this.minute, 0, 0);
        if (targetTime.getTime() <= now.getTime()) {
          // 时间已过，下个月
          nextDate.setMonth(now.getMonth() + 1);
          const daysInNextMonth = new Date(nextDate.getFullYear(), nextDate.getMonth() + 1, 0).getDate();
          if (targetDate <= daysInNextMonth) {
            nextDate.setDate(targetDate);
          } else {
            // 下个月没有该日期，再下个月
            nextDate.setMonth(nextDate.getMonth() + 1);
            nextDate.setDate(targetDate);
          }
        }
      } else {
        // 当月已过或没有该日期，下个月
        nextDate.setMonth(now.getMonth() + 1);
        const daysInNextMonth = new Date(nextDate.getFullYear(), nextDate.getMonth() + 1, 0).getDate();
        if (targetDate <= daysInNextMonth) {
          nextDate.setDate(targetDate);
        } else {
          // 下个月没有该日期，再下个月
          nextDate.setMonth(nextDate.getMonth() + 1);
          nextDate.setDate(targetDate);
        }
      }
      
      nextDate.setHours(this.hour, this.minute, 0, 0);
      return nextDate.getTime();
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
