/**
 * 定时任务相关枚举定义
 */

/**
 * 时间模式枚举
 */
export enum TimeMode {
  ONCE = 'ONCE',           // 单次任务
  WEEKLY = 'WEEKLY',       // 每周循环
  MONTHLY = 'MONTHLY'      // 每月循环
}

/**
 * 任务状态枚举
 */
export enum TaskStatus {
  ENABLED = 'ENABLED',     // 启用
  DISABLED = 'DISABLED',   // 禁用
  COMPLETED = 'COMPLETED'  // 已完成
}

/**
 * 音量类型枚举
 */
export enum VolumeType {
  MEDIA = 'MEDIA',                 // 媒体音量
  RINGTONE = 'RINGTONE',           // 铃声音量
  NOTIFICATION = 'NOTIFICATION',   // 通知音量
  ALARM = 'ALARM',                 // 闹钟音量
  APP = 'APP'                      // 应用音量
}

/**
 * 任务类型枚举
 */
export enum TaskType {
  INSTANT = 'INSTANT',    // 瞬时任务：立即设置音量
  PERIOD = 'PERIOD'       // 时间段任务：在时间段内锁定音量
}

/**
 * 锁定状态枚举
 */
export enum LockStatus {
  ACTIVE = 'ACTIVE',      // 激活中：正在锁定音量
  INACTIVE = 'INACTIVE'   // 未激活：未在锁定状态
}
