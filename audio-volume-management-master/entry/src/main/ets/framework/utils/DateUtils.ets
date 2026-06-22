/**
 * 日期格式化工具类
 * 用于处理定时任务的日期显示逻辑
 */

/**
 * 格式化一次性任务的执行时间
 * 将executeTime转换为用户友好的日期显示文本
 * 
 * @param executeTime 任务执行时间戳（毫秒）
 * @param hour 任务执行小时（0-23）
 * @param minute 任务执行分钟（0-59）
 * @returns 格式化后的日期时间字符串
 */
export function formatOnceTaskTime(executeTime: number | undefined, hour: number, minute: number): string {
  // 格式化时间部分为 HH:mm
  const timeStr = `${hour.toString().padStart(2, '0')}:${minute.toString().padStart(2, '0')}`;
  
  // 如果executeTime不存在，默认显示为今天
  if (executeTime === undefined || executeTime === null) {
    return `今天 ${timeStr}`;
  }
  
  // 获取当前时间和执行时间的日期部分（去除时分秒）
  const now = new Date();
  const currentDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const executeDate = new Date(executeTime);
  const targetDate = new Date(executeDate.getFullYear(), executeDate.getMonth(), executeDate.getDate());
  
  // 计算天数差
  const diffTime = targetDate.getTime() - currentDate.getTime();
  const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24));
  
  // 根据天数差选择显示格式
  if (diffDays === 0) {
    // 今天
    return `今天 ${timeStr}`;
  } else if (diffDays === 1) {
    // 明天
    return `明天 ${timeStr}`;
  } else if (diffDays > 1 && diffDays <= 15) {
    // 2-15天内，检查是否跨年
    if (targetDate.getFullYear() === currentDate.getFullYear()) {
      // 同一年，显示"MM月DD日"
      const month = (targetDate.getMonth() + 1).toString().padStart(2, '0');
      const day = targetDate.getDate().toString().padStart(2, '0');
      return `${month}月${day}日 ${timeStr}`;
    } else {
      // 跨年，显示"YYYY年MM月DD日"
      const year = targetDate.getFullYear();
      const month = (targetDate.getMonth() + 1).toString().padStart(2, '0');
      const day = targetDate.getDate().toString().padStart(2, '0');
      return `${year}年${month}月${day}日 ${timeStr}`;
    }
  } else if (diffDays < 0) {
    // 已过期的任务，显示完整日期
    if (targetDate.getFullYear() === currentDate.getFullYear()) {
      const month = (targetDate.getMonth() + 1).toString().padStart(2, '0');
      const day = targetDate.getDate().toString().padStart(2, '0');
      return `${month}月${day}日 ${timeStr}`;
    } else {
      const year = targetDate.getFullYear();
      const month = (targetDate.getMonth() + 1).toString().padStart(2, '0');
      const day = targetDate.getDate().toString().padStart(2, '0');
      return `${year}年${month}月${day}日 ${timeStr}`;
    }
  } else {
    // 超过15天，显示完整日期
    if (targetDate.getFullYear() === currentDate.getFullYear()) {
      const month = (targetDate.getMonth() + 1).toString().padStart(2, '0');
      const day = targetDate.getDate().toString().padStart(2, '0');
      return `${month}月${day}日 ${timeStr}`;
    } else {
      const year = targetDate.getFullYear();
      const month = (targetDate.getMonth() + 1).toString().padStart(2, '0');
      const day = targetDate.getDate().toString().padStart(2, '0');
      return `${year}年${month}月${day}日 ${timeStr}`;
    }
  }
}
