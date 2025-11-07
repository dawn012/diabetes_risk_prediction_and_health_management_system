/**
 * 补签追踪服务 - 追踪用户的补签历史
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { DateUtils } from "../utils/date_utils";

const db = admin.firestore();

export interface MakeupRecord {
  dateKey: string;      // "2025-01-15"
  timestamp: number;    // 记录时间
  logId: string;        // 触发补签的 log ID
}

export class MakeupTracker {
  /**
   * 检查并记录补签
   * @returns 如果是补签返回 true，否则返回 false
   */
  static async checkAndRecordMakeup(
    userId: string,
    achievementId: string,
    logId: string,
    logDateTime: number,
    dataType: string
  ): Promise<boolean> {
    const dateKey = DateUtils.getDateKey(logDateTime);
    const now = Date.now();
    const daysDiff = DateUtils.getDaysDifference(logDateTime, now);

    // 1. 检查是否在7天内
    if (daysDiff < 0 || daysDiff > 7) {
      return false; // 不在补签范围内
    }

    // 2. 检查当天是否
    if (daysDiff === 0) {
      return false; // 当天记录不算补签
    }

    // 3. 查询该日期之前是否有相关记录
    const hasExistingRecord = await this.hasRecordOnDate(
      userId,
      logDateTime,
      dataType,
      logId // 排除当前 log
    );

    if (hasExistingRecord) {
      return false; // 该日期已有记录，不算补签
    }

    // 4. 这是一个新的补签，记录到 userAchievement
    await this.recordMakeup(userId, achievementId, dateKey, logId);

    functions.logger.log(
      `✅ Makeup recorded: ${userId} - ${achievementId} - ${dateKey}`
    );

    return true;
  }

  /**
   * 检查指定日期是否已有相关记录
   */
  static async hasRecordOnDate(
    userId: string,
    targetTimestamp: number,
    dataType: string,
    excludeLogId?: string
  ): Promise<boolean> {
    //     const dateKey = DateUtils.getDateKey(targetTimestamp);
    const dayStart = new Date(targetTimestamp);
    dayStart.setUTCHours(0, 0, 0, 0);

    const dayEnd = new Date(targetTimestamp);
    dayEnd.setUTCHours(23, 59, 59, 999);

    const logsSnapshot = await db
      .collection("healthLogs")
      .doc(userId)
      .collection("logs")
      .where("logDateTime", ">=", dayStart.getTime())
      .where("logDateTime", "<=", dayEnd.getTime())
      .get();

    if (logsSnapshot.empty) {
      return false;
    }

    // 检查是否有符合条件的记录
    for (const doc of logsSnapshot.docs) {
      // 排除当前正在处理的 log
      if (excludeLogId && doc.id === excludeLogId) {
        continue;
      }

      const data = doc.data();
      if (this.hasDataType(data, dataType)) {
        return true; // 找到已存在的记录
      }
    }

    return false; // 没有找到相关记录
  }

  /**
   * 记录补签到 userAchievement
   */
  private static async recordMakeup(
    userId: string,
    achievementId: string,
    dateKey: string,
    logId: string
  ): Promise<void> {
    const userAchievementQuery = await db
      .collection("userAchievements")
      .where("userId", "==", userId)
      .where("achievementId", "==", achievementId)
      .limit(1)
      .get();

    if (userAchievementQuery.empty) {
      // 如果 userAchievement 还不存在，创建时会包含补签记录
      return;
    }

    const doc = userAchievementQuery.docs[0];
    const data = doc.data();
    const makeupHistory: MakeupRecord[] = data.makeupHistory || [];

    // 检查是否已记录过这个日期
    const exists = makeupHistory.some(record => record.dateKey === dateKey);
    if (exists) {
      return; // 已记录过，不重复记录
    }

    // 添加新的补签记录
    makeupHistory.push({
      dateKey,
      timestamp: Date.now(),
      logId,
    });

    await doc.ref.update({
      makeupHistory,
      makeupUsed: makeupHistory.length,
    });
  }

  /**
   * 移除补签记录（当该日期的记录被删除时）
   */
  static async removeMakeup(
    userId: string,
    achievementId: string,
    dateKey: string
  ): Promise<void> {
    const userAchievementQuery = await db
      .collection("userAchievements")
      .where("userId", "==", userId)
      .where("achievementId", "==", achievementId)
      .limit(1)
      .get();

    if (userAchievementQuery.empty) {
      return;
    }

    const doc = userAchievementQuery.docs[0];
    const data = doc.data();
    let makeupHistory: MakeupRecord[] = data.makeupHistory || [];

    // 移除该日期的补签记录
    makeupHistory = makeupHistory.filter(record => record.dateKey !== dateKey);

    await doc.ref.update({
      makeupHistory,
      makeupUsed: makeupHistory.length,
    });

    functions.logger.log(
      `🗑️ Makeup removed: ${userId} - ${achievementId} - ${dateKey}`
    );
  }

  /**
   * 检查数据类型
   */
  private static hasDataType(data: any, dataType: string): boolean {
    switch (dataType) {
    case "bloodGlucose":
      return data.bloodGlucose && data.bloodGlucose.glucoseLevel > 0;

    case "bloodPressure":
      return (
        data.bloodPressure &&
          (data.bloodPressure.systolic > 0 || data.bloodPressure.diastolic > 0)
      );

    case "bodyWeight":
      return data.bodyComposition && data.bodyComposition.weight > 0;

    case "physicalActivity":
      return (
        data.physicalActivity &&
          data.physicalActivity.activityType &&
          data.physicalActivity.duration > 0
      );

    case "steps":
      return data.physicalActivity && data.physicalActivity.steps > 0;

    default:
      return false;
    }
  }
}