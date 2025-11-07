/**
 * 日期工具 - 处理月度追踪和补签逻辑
 */

export class DateUtils {
  /**
   * 获取当前月份的第一天（UTC）
   */
  static getCurrentMonthStart(): Date {
    const now = new Date();
    return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1, 0, 0, 0, 0));
  }

  /**
   * 获取当前月份的最后一天（UTC）
   */
  static getCurrentMonthEnd(): Date {
    const now = new Date();
    return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 0, 23, 59, 59, 999));
  }

  /**
   * 获取日期的 YYYY-MM-DD 字符串（UTC）
   */
  static getDateKey(timestamp: number): string {
    const date = new Date(timestamp);
    return `${date.getUTCFullYear()}-${String(date.getUTCMonth() + 1).padStart(2, "0")}-${String(date.getUTCDate()).padStart(2, "0")}`;
  }

  /**
   * 检查是否是新月份的第一天
   */
  static isFirstDayOfMonth(): boolean {
    const now = new Date();
    return now.getUTCDate() === 1;
  }

  /**
   * 计算两个日期之间的天数差
   */
  static getDaysDifference(timestamp1: number, timestamp2: number): number {
    const date1 = new Date(timestamp1);
    const date2 = new Date(timestamp2);

    // 转换为 UTC 日期（忽略时间部分）
    const utc1 = Date.UTC(date1.getFullYear(), date1.getMonth(), date1.getDate());
    const utc2 = Date.UTC(date2.getFullYear(), date2.getMonth(), date2.getDate());

    return Math.floor((utc2 - utc1) / (1000 * 60 * 60 * 24));
  }

  /**
   * 检查日期是否在指定天数范围内
   */
  static isWithinDays(timestamp: number, maxDaysBack: number): boolean {
    const now = Date.now();
    const daysDiff = this.getDaysDifference(timestamp, now);
    return daysDiff >= 0 && daysDiff <= maxDaysBack;
  }

  /**
   * 检查日期是否在当前月份
   */
  static isInCurrentMonth(timestamp: number): boolean {
    const date = new Date(timestamp);
    const now = new Date();
    return (
      date.getUTCFullYear() === now.getUTCFullYear() &&
      date.getUTCMonth() === now.getUTCMonth()
    );
  }

  /**
   * 获取当月天数
   */
  static getDaysInCurrentMonth(): number {
    const now = new Date();
    return new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
  }
}