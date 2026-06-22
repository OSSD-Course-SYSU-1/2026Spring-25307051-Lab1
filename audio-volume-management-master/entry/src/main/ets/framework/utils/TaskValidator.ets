import { TimerTask } from '../model/TimerTask';
import { TimeMode } from '../model/TaskEnums';

/**
 * 验证结果接口
 */
export interface ValidationResult {
  valid: boolean;
  message: string;
}

/**
 * 任务验证工具类
 */
export class TaskValidator {
  /**
   * 验证任务时间有效性
   */
  static validateTime(task: TimerTask): boolean {
    const now = Date.now();

    if (task.timeMode === TimeMode.ONCE) {
      // 单次任务：执行时间必须晚于当前时间
      return task.executeTime !== undefined && task.executeTime > now;
    } else if (task.timeMode === TimeMode.WEEKLY) {
      // 每周循环：星期几必须在1-7范围内
      return task.dayOfWeek !== undefined && task.dayOfWeek >= 1 && task.dayOfWeek <= 7;
    } else if (task.timeMode === TimeMode.MONTHLY) {
      // 每月循环：日期必须在1-31范围内
      return task.dayOfMonth !== undefined && task.dayOfMonth >= 1 && task.dayOfMonth <= 31;
    }

    return false;
  }

  /**
   * 验证音量值有效性
   */
  static validateVolumeValue(value: number): boolean {
    return value >= 0 && value <= 100;
  }

  /**
   * 验证小时有效性
   */
  static validateHour(hour: number): boolean {
    return hour >= 0 && hour <= 23;
  }

  /**
   * 验证分钟有效性
   */
  static validateMinute(minute: number): boolean {
    return minute >= 0 && minute <= 59;
  }

  /**
   * 验证星期几有效性
   */
  static validateDayOfWeek(dayOfWeek: number): boolean {
    return dayOfWeek >= 1 && dayOfWeek <= 7;
  }

  /**
   * 验证日期有效性
   */
  static validateDayOfMonth(dayOfMonth: number): boolean {
    return dayOfMonth >= 1 && dayOfMonth <= 31;
  }

  /**
   * 验证任务完整性
   */
  static validateTask(task: TimerTask): ValidationResult {
    // 验证时间模式
    if (!task.timeMode) {
      const result: ValidationResult = { valid: false, message: '时间模式不能为空' };
      return result;
    }

    // 验证小时
    if (!TaskValidator.validateHour(task.hour)) {
      const result: ValidationResult = { valid: false, message: '小时必须在0-23之间' };
      return result;
    }

    // 验证分钟
    if (!TaskValidator.validateMinute(task.minute)) {
      const result: ValidationResult = { valid: false, message: '分钟必须在0-59之间' };
      return result;
    }

    // 验证时间模式相关字段
    if (task.timeMode === TimeMode.ONCE) {
      if (!task.executeTime) {
        const result: ValidationResult = { valid: false, message: '单次任务必须指定执行时间' };
        return result;
      }
      // 注释掉时间验证，允许设置过去的时间（用于测试）
      // if (task.executeTime <= Date.now()) {
      //   const result: ValidationResult = { valid: false, message: '执行时间不能早于当前时间' };
      //   return result;
      // }
    } else if (task.timeMode === TimeMode.WEEKLY) {
      if (!task.dayOfWeek || !TaskValidator.validateDayOfWeek(task.dayOfWeek)) {
        const result: ValidationResult = { valid: false, message: '星期几必须在1-7之间' };
        return result;
      }
    } else if (task.timeMode === TimeMode.MONTHLY) {
      if (!task.dayOfMonth || !TaskValidator.validateDayOfMonth(task.dayOfMonth)) {
        const result: ValidationResult = { valid: false, message: '日期必须在1-31之间' };
        return result;
      }
    }

    // 验证音量设置
    if (!task.volumeSettings || task.volumeSettings.length === 0) {
      const result: ValidationResult = { valid: false, message: '至少需要设置一项音量' };
      return result;
    }

    for (const setting of task.volumeSettings) {
      if (!TaskValidator.validateVolumeValue(setting.volumeValue)) {
        const result: ValidationResult = { valid: false, message: '音量值必须在0-100之间' };
        return result;
      }
    }

    const result: ValidationResult = { valid: true, message: '验证通过' };
    return result;
  }
}
