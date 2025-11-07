/**
 * 健康数据触发器
 */

import {
  onDocumentCreated,
  onDocumentUpdated,
  onDocumentDeleted,
} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { HealthLogAchievementService } from "../services/health_log_achievement_service";
import { MakeupTracker } from "../services/makeup_tracker";
import { getAchievementConfigs } from "../config/achievement_config";

/**
 * 健康数据创建
 */
export const onHealthLogCreated = onDocumentCreated(
  "healthLogs/{userId}/logs/{logId}",
  async (event) => {
    const { userId, logId } = event.params;
    const logData = event.data?.data();

    if (!logData) return;

    functions.logger.log(`🏥 Health log created: ${userId} - ${logId}`);

    // 处理补签和成就更新
    await processAchievementsWithMakeup(userId, logId, logData, null);
  }
);

/**
 * 健康数据更新
 */
export const onHealthLogUpdated = onDocumentUpdated(
  "healthLogs/{userId}/logs/{logId}",
  async (event) => {
    const { userId, logId } = event.params;
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!beforeData || !afterData) return;

    // 检查 logDateTime 是否变化
    const dateTimeChanged = beforeData.logDateTime !== afterData.logDateTime;

    // 检查数据值是否变化
    const glucoseChanged =
      beforeData.bloodGlucose?.glucoseLevel !== afterData.bloodGlucose?.glucoseLevel;
    const pressureChanged =
      beforeData.bloodPressure?.systolic !== afterData.bloodPressure?.systolic;
    const weightChanged =
      beforeData.bodyComposition?.weight !== afterData.bodyComposition?.weight;
    const activityChanged =
      beforeData.physicalActivity?.duration !== afterData.physicalActivity?.duration;
    const stepsChanged =
      beforeData.physicalActivity?.steps !== afterData.physicalActivity?.steps;

    if (
      dateTimeChanged ||
      glucoseChanged ||
      pressureChanged ||
      weightChanged ||
      activityChanged ||
      stepsChanged
    ) {
      functions.logger.log(`🔄 Health log updated: ${userId} - ${logId}`);

      // 处理补签和成就更新
      await processAchievementsWithMakeup(userId, logId, afterData, beforeData);
    }
  }
);

/**
 * 健康数据删除
 */
export const onHealthLogDeleted = onDocumentDeleted(
  "healthLogs/{userId}/logs/{logId}",
  async (event) => {
    const { userId, logId } = event.params;
    const deletedData = event.data?.data();

    if (!deletedData) return;

    functions.logger.log(`🗑️ Health log deleted: ${userId} - ${logId}`);

    // 检查并移除补签记录
    await handleLogDeletion(userId, logId, deletedData);

    // 重新计算成就
    await processAchievements(userId);
  }
);

/**
 * 处理成就（带补签追踪）
 */
async function processAchievementsWithMakeup(
  userId: string,
  logId: string,
  afterData: any,
  beforeData: any | null
): Promise<void> {
  try {
    const configs = await getAchievementConfigs();

    for (const config of configs) {
      // Steps 不支持补签，跳过补签检查
      if (config.dataType === "steps") {
        continue;
      }

      // 检查补签
      if (config.makeupConfig.enabled) {
        // 如果是 Update 且 logDateTime 变化了，需要处理旧日期的补签移除
        if (beforeData && beforeData.logDateTime !== afterData.logDateTime) {
          const oldDateKey = getDateKey(beforeData.logDateTime);
          await MakeupTracker.removeMakeup(userId, config.achievementId, oldDateKey);
        }

        // 检查新日期是否需要记录补签
        const isMakeup = await MakeupTracker.checkAndRecordMakeup(
          userId,
          config.achievementId,
          logId,
          afterData.logDateTime,
          config.dataType
        );

        // 检查补签次数限制
        if (isMakeup && config.makeupConfig.maxMakeupCount) {
          const makeupCount = await getMakeupCount(userId, config.achievementId);
          if (makeupCount > config.makeupConfig.maxMakeupCount) {
            functions.logger.warn(
              `⚠️ Makeup limit exceeded: ${userId} - ${config.achievementId}`
            );
            // 移除最新的补签
            await MakeupTracker.removeMakeup(
              userId,
              config.achievementId,
              getDateKey(afterData.logDateTime)
            );
          }
        }
      }
    }

    // 重新计算所有成就
    await processAchievements(userId);
  } catch (error) {
    functions.logger.error("❌ Error processing achievements with makeup:", error);
  }
}

/**
 * 处理日志删除（检查并移除补签）
 */
async function handleLogDeletion(
  userId: string,
  logId: string,
  deletedData: any
): Promise<void> {
  try {
    const configs = await getAchievementConfigs();
    const dateKey = getDateKey(deletedData.logDateTime);

    for (const config of configs) {
      if (config.dataType === "steps") continue;

      // 检查该日期是否还有其他相关记录
      const hasOtherRecords = await MakeupTracker.hasRecordOnDate(
        userId,
        deletedData.logDateTime,
        config.dataType,
        logId
      );

      // 如果没有其他记录了，移除补签
      if (!hasOtherRecords) {
        await MakeupTracker.removeMakeup(userId, config.achievementId, dateKey);
      }
    }
  } catch (error) {
    functions.logger.error("❌ Error handling log deletion:", error);
  }
}

/**
 * 重新计算所有成就
 */
async function processAchievements(userId: string): Promise<void> {
  try {
    const configs = await getAchievementConfigs();

    const updatePromises = configs.map(async (config) => {
      try {
        const currentCount = await HealthLogAchievementService.countCurrentMonthData(
          userId,
          config
        );

        await HealthLogAchievementService.updateAchievementProgress(
          userId,
          config.achievementId,
          currentCount,
          config
        );

        functions.logger.log(
          `✅ ${config.dataType}: count=${currentCount}`
        );
      } catch (error) {
        functions.logger.error(`❌ Error processing ${config.dataType}:`, error);
      }
    });

    await Promise.all(updatePromises);
  } catch (error) {
    functions.logger.error("❌ Error processing achievements:", error);
  }
}

/**
 * 辅助函数
 */
function getDateKey(timestamp: number): string {
  const date = new Date(timestamp);
  return `${date.getUTCFullYear()}-${String(date.getUTCMonth() + 1).padStart(2, "0")}-${String(date.getUTCDate()).padStart(2, "0")}`;
}

async function getMakeupCount(userId: string, achievementId: string): Promise<number> {
  const db = admin.firestore();
  const query = await db
    .collection("userAchievements")
    .where("userId", "==", userId)
    .where("achievementId", "==", achievementId)
    .limit(1)
    .get();

  if (query.empty) return 0;

  const data = query.docs[0].data();
  return data.makeupHistory?.length || 0;
}