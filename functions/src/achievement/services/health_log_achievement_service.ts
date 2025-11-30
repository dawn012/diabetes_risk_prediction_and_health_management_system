/**
 * 成就服务
 * 只处理健康数据相关的成就
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { AchievementConfig } from "../config/achievement_config";
import { DateUtils } from "../utils/date_utils";

const db = admin.firestore();

export class HealthLogAchievementService {
  /**
   * 统计当月有效数据
   */
  static async countCurrentMonthData(
    userId: string,
    config: AchievementConfig
  ): Promise<number> {
    const monthStart = DateUtils.getCurrentMonthStart();
    const monthEnd = DateUtils.getCurrentMonthEnd();

    const logsSnapshot = await db
      .collection("healthLogs")
      .doc(userId)
      .collection("logs")
      .where("logDateTime", ">=", monthStart.getTime())
      .where("logDateTime", "<=", monthEnd.getTime())
      .get();

    if (logsSnapshot.empty) {
      return 0;
    }

    // 特别处理 steps（你现在 steps 在根层）
    if (config.dataType === "steps") {
      const docs = logsSnapshot.docs;

      // 你可以在 config.trackingStrategy 里为 steps 配
      // - "totalSteps"：算当月总步数
      // - "qualifiedDays"：算达标天数（>= dailyTarget）
      // - "uniqueDays"：只算有 steps 的天数
      switch (config.trackingStrategy) {
      case "totalSteps": {
        let totalSteps = 0;
        for (const doc of docs) {
          const data = doc.data();
          const id = data.logId || doc.id;

          // 可选：只认 steps_* 的 log
          if (!id.startsWith("steps_")) continue;

          const steps = data.steps || 0;
          if (steps > 0) {
            totalSteps += steps;
          }
        }
        return totalSteps;
      }

      case "qualifiedDays": {
        const dailyTarget = config.stepsConfig?.dailyTarget || 8000;
        const dailySteps = new Map<string, number>();

        for (const doc of docs) {
          const data = doc.data();
          const id = data.logId || doc.id;
          if (!id.startsWith("steps_")) continue;

          const steps = data.steps || 0;
          if (steps <= 0) continue;

          const dateKey = DateUtils.getDateKey(data.logDateTime);
          dailySteps.set(dateKey, (dailySteps.get(dateKey) || 0) + steps);
        }

        let qualifiedDays = 0;
        for (const steps of dailySteps.values()) {
          if (steps >= dailyTarget) qualifiedDays++;
        }
        return qualifiedDays;
      }

      case "uniqueDays": {
        const daySet = new Set<string>();
        for (const doc of docs) {
          const data = doc.data();
          const id = data.logId || doc.id;
          if (!id.startsWith("steps_")) continue;

          const steps = data.steps || 0;
          if (steps > 0) {
            const dateKey = DateUtils.getDateKey(data.logDateTime);
            daySet.add(dateKey);
          }
        }
        return daySet.size;
      }

      default:
        return 0;
      }
    }

    switch (config.trackingStrategy) {
    case "uniqueDays":
      return this.countUniqueDays(logsSnapshot.docs, config.dataType);

    case "sumDuration":
      return this.sumDuration(logsSnapshot.docs);

    case "totalSteps":
      // 这里是旧版 physicalActivity.steps，用于旧 schema，
      // 如果你以后完全不用 physicalActivity.steps，可以删掉这行
      return this.countTotalSteps(logsSnapshot.docs);

    case "qualifiedDays":
      return this.countQualifiedStepsDays(
        logsSnapshot.docs,
        config.stepsConfig?.dailyTarget || 8000
      );

    default:
      return 0;
    }
  }

  /**
   * 统计唯一天数
   */
  private static countUniqueDays(
    docs: admin.firestore.QueryDocumentSnapshot[],
    dataType: string
  ): number {
    const validDates = new Set<string>();

    const dateGroups = new Map<
      string,
      admin.firestore.QueryDocumentSnapshot[]
    >();

    for (const doc of docs) {
      const data = doc.data();
      const dateKey = DateUtils.getDateKey(data.logDateTime);

      if (!dateGroups.has(dateKey)) {
        dateGroups.set(dateKey, []);
      }
      dateGroups.get(dateKey)!.push(doc);
    }

    for (const [dateKey, dayDocs] of dateGroups.entries()) {
      const hasData = dayDocs.some((doc) =>
        this.hasDataType(doc.data(), dataType)
      );
      if (hasData) {
        validDates.add(dateKey);
      }
    }

    return validDates.size;
  }

  /**
   * 累计运动时长
   */
  private static sumDuration(
    docs: admin.firestore.QueryDocumentSnapshot[]
  ): number {
    let totalMinutes = 0;

    for (const doc of docs) {
      const data = doc.data();
      if (data.physicalActivity && data.physicalActivity.duration > 0) {
        totalMinutes += data.physicalActivity.duration;
      }
    }

    return totalMinutes;
  }

  /**
   * 统计累计步数
   */
  private static countTotalSteps(
    docs: admin.firestore.QueryDocumentSnapshot[]
  ): number {
    let totalSteps = 0;

    for (const doc of docs) {
      const data = doc.data();
      if (data.physicalActivity && data.physicalActivity.steps > 0) {
        totalSteps += data.physicalActivity.steps;
      }
    }

    return totalSteps;
  }

  /**
   * 统计达标步数天数
   */
  private static countQualifiedStepsDays(
    docs: admin.firestore.QueryDocumentSnapshot[],
    dailyTarget: number
  ): number {
    const dailySteps = new Map<string, number>();

    for (const doc of docs) {
      const data = doc.data();

      if (!data.physicalActivity || data.physicalActivity.steps <= 0) {
        continue;
      }

      const dateKey = DateUtils.getDateKey(data.logDateTime);
      dailySteps.set(
        dateKey,
        (dailySteps.get(dateKey) || 0) + data.physicalActivity.steps
      );
    }

    let qualifiedDays = 0;
    for (const steps of dailySteps.values()) {
      if (steps >= dailyTarget) {
        qualifiedDays++;
      }
    }

    return qualifiedDays;
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
      return typeof data.steps === "number" && data.steps > 0;

    default:
      return false;
    }
  }

  /**
   * 更新用户成就进度（支持删除空进度）
   */
  static async updateAchievementProgress(
    userId: string,
    achievementId: string,
    currentCount: number,
    config: AchievementConfig
  ): Promise<void> {
    try {
      const userAchievementQuery = await db
        .collection("userAchievements")
        .where("userId", "==", userId)
        .where("achievementId", "==", achievementId)
        .limit(1)
        .get();

      // 如果进度为 0，删除 userAchievement（如果存在）
      if (currentCount === 0) {
        if (!userAchievementQuery.empty) {
          const doc = userAchievementQuery.docs[0];
          await doc.ref.delete();

          functions.logger.log(
            `Deleted userAchievement (no progress): ${userId} - ${achievementId}`
          );

          // 如果之前有积分，需要扣除
          const existingPoints = doc.data().earnedPoints || 0;
          if (existingPoints > 0 && config.achievementType === "periodic") {
            await db
              .collection("users")
              .doc(userId)
              .update({
                totalScore:
                  admin.firestore.FieldValue.increment(-existingPoints),
              });

            functions.logger.log(
              `Deducted ${existingPoints} points from user ${userId}`
            );
          }
        }
        return;
      }

      let userAchievementRef: admin.firestore.DocumentReference;
      let existingData: any = null;

      if (userAchievementQuery.empty) {
        // 创建新的 userAchievement
        userAchievementRef = db.collection("userAchievements").doc();

        const makeupUsed = await this.getMakeupCount(userId, achievementId);

        await userAchievementRef.set({
          userAchievementId: userAchievementRef.id,
          userId,
          achievementId,
          currentCount,
          currentLevel: "none",
          earnedPoints: 0,
          status: "in progress",
          makeupHistory: [],
          makeupUsed,
          startedAt: Date.now(),
          completedAt: null,
        });

        functions.logger.log(
          `✅ Created userAchievement: ${userId} - ${achievementId}`
        );
      } else {
        // 更新现有的 userAchievement
        const doc = userAchievementQuery.docs[0];
        userAchievementRef = doc.ref;
        existingData = doc.data();

        const makeupUsed = existingData.makeupHistory?.length || 0;

        await userAchievementRef.update({
          currentCount,
          makeupUsed,
        });

        functions.logger.log(
          `📊 Updated progress: ${userId} - ${achievementId} - count: ${currentCount}, makeup: ${makeupUsed}`
        );
      }

      // 检查并升级等级
      await this.checkAndUpgradeLevel(
        userId,
        achievementId,
        currentCount,
        existingData?.currentLevel || "none",
        existingData?.earnedPoints || 0,
        userAchievementRef,
        config
      );
    } catch (error) {
      functions.logger.error("❌ Error updating achievement progress:", error);
      throw error;
    }
  }

  /**
   * 获取补签次数
   */
  private static async getMakeupCount(
    userId: string,
    achievementId: string
  ): Promise<number> {
    const userAchievementQuery = await db
      .collection("userAchievements")
      .where("userId", "==", userId)
      .where("achievementId", "==", achievementId)
      .limit(1)
      .get();

    if (userAchievementQuery.empty) {
      return 0;
    }

    const data = userAchievementQuery.docs[0].data();
    return data.makeupHistory?.length || 0;
  }

  /**
   * 检查并升级等级
   */
  private static async checkAndUpgradeLevel(
    userId: string,
    achievementId: string,
    currentCount: number,
    existingLevel: string,
    existingPoints: number,
    userAchievementRef: admin.firestore.DocumentReference,
    config: AchievementConfig
  ): Promise<void> {
    // 🔧 直接使用 config.levels（已经在 reset 时更新过了）
    const levels = config.levels;

    let newLevel = "none";
    let newPoints = 0;

    // 根据当前进度确定等级和积分（累加所有达成的等级积分）
    for (const level of levels) {
      if (currentCount >= level.criteria) {
        newLevel = level.level;
        newPoints += level.points;
      }
    }

    // 计算积分变化
    const pointsDiff = newPoints - existingPoints;

    // 如果等级或积分有变化
    if (newLevel !== existingLevel || pointsDiff !== 0) {
      const updateData: any = {
        currentLevel: newLevel,
        earnedPoints: newPoints,
      };

      // 如果达到最高等级
      const highestLevel = levels[levels.length - 1];
      if (
        newLevel === highestLevel.level &&
        currentCount >= highestLevel.criteria
      ) {
        updateData.status = "completed";
        if (!existingLevel || existingLevel === "none") {
          updateData.completedAt =
            Date.now();
        }
      } else {
        // 确保状态是 in progress
        updateData.status = "in progress";
        if (existingLevel === highestLevel.level) {
          updateData.completedAt = null;
        }
      }

      await userAchievementRef.update(updateData);

      functions.logger.log(
        `🎉 Level changed: ${existingLevel} → ${newLevel}, Points: ${existingPoints} → ${newPoints}`
      );

      // 更新用户总分
      if (pointsDiff !== 0 && config.achievementType === "periodic") {
        await db
          .collection("users")
          .doc(userId)
          .update({
            totalScore: admin.firestore.FieldValue.increment(pointsDiff),
          });

        functions.logger.log(
          pointsDiff > 0
            ? `💰 Awarded ${pointsDiff} points to user ${userId}`
            : `📉 Deducted ${Math.abs(pointsDiff)} points from user ${userId}`
        );
      }
    }
  }

  /**
   * 重置 periodic 成就（同时更新 Gold 动态天数）
   */
  static async resetPeriodicAchievements(userId: string): Promise<void> {
    try {
      const userAchievementsSnapshot = await db
        .collection("userAchievements")
        .where("userId", "==", userId)
        .get();

      if (userAchievementsSnapshot.empty) {
        return;
      }

      const batch = db.batch();
      let deletedCount = 0;

      for (const doc of userAchievementsSnapshot.docs) {
        const userAchievementData = doc.data();
        const achievementId = userAchievementData.achievementId;

        const achievementDoc = await db
          .collection("achievements")
          .doc(achievementId)
          .get();

        if (!achievementDoc.exists) continue;

        const achievement = achievementDoc.data();
        if (
          achievement &&
          achievement.achievementType === "periodic" &&
          // 只重置健康数据相关的成就
          (achievement.dataType === "bloodGlucose" ||
            achievement.dataType === "bloodPressure" ||
            achievement.dataType === "bodyWeight" ||
            achievement.dataType === "physicalActivity" ||
            achievement.dataType === "steps")
        ) {
          // 删除 userAchievement 记录
          batch.delete(doc.ref);
          deletedCount++;

          functions.logger.log(
            `Deleted: ${achievementId} for user ${userId}`
          );
        }
      }

      if (deletedCount > 0) {
        await batch.commit();
        functions.logger.log(
          `✅ Monthly reset completed: deleted ${deletedCount} health achievements for user ${userId}`
        );
      } else {
        functions.logger.log(
          `ℹ️ No health achievements found to delete for user ${userId}`
        );
      }
    } catch (error) {
      functions.logger.error("❌ Error resetting achievements:", error);
    }
  }

  /**
   * 更新所有 periodic 成就的 Gold 动态天数
   */
  static async updateGoldDynamicCriteria(): Promise<void> {
    try {
      const daysInMonth = new Date(
        new Date().getFullYear(),
        new Date().getMonth() + 1,
        0
      ).getDate();

      functions.logger.log(`📅 Updating Gold criteria to ${daysInMonth} days`);

      const achievementsSnapshot = await db
        .collection("achievements")
        .where("isActive", "==", true)
        .where("achievementType", "==", "periodic")
        .get();

      const batch = db.batch();
      let updateCount = 0;

      for (const doc of achievementsSnapshot.docs) {
        const data = doc.data();
        const levels = data.levels || [];

        // 检查是否有 Gold 动态等级
        let needsUpdate = false;
        const updatedLevels = levels.map((level: any) => {
          if (level.level === "gold" && level.isDynamic === true) {
            if (level.criteria !== daysInMonth) {
              needsUpdate = true;
              return {
                ...level,
                criteria: daysInMonth,
              };
            }
          }
          return level;
        });

        if (needsUpdate) {
          batch.update(doc.ref, { levels: updatedLevels });
          updateCount++;
          functions.logger.log(
            `📝 Updated ${doc.id}: Gold → ${daysInMonth} days`
          );
        }
      }

      if (updateCount > 0) {
        await batch.commit();
        functions.logger.log(
          `✅ Updated ${updateCount} achievements with new Gold criteria`
        );
      } else {
        functions.logger.log("✅ No achievements need Gold criteria update");
      }
    } catch (error) {
      functions.logger.error("❌ Error updating Gold criteria:", error);
      throw error;
    }
  }
}