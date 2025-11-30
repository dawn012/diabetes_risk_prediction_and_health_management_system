/**
 * Community Achievement Service (重构版)
 * 处理社区相关的成就追踪 - 统一使用增量更新机制
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { DateUtils } from "../utils/date_utils";

const db = admin.firestore();

export class CommunityAchievementService {
  /**
   * 统计获得某类 Gold 的次数（永久成就）
   */
  static async countGoldAchievements(
    userId: string,
    dataType: string
  ): Promise<number> {
    const achievementsSnapshot = await db
      .collection("achievements")
      .where("dataType", "==", dataType)
      .where("achievementType", "==", "periodic")
      .where("isActive", "==", true)
      .limit(1)
      .get();

    if (achievementsSnapshot.empty) {
      return 0;
    }

    const achievementId = achievementsSnapshot.docs[0].id;

    const historySnapshot = await db
      .collection("achievementHistory")
      .where("userId", "==", userId)
      .where("achievementId", "==", achievementId)
      .where("level", "==", "gold")
      .get();

    return historySnapshot.size;
  }

  /**
   * 统计获得某等级的总次数（所有类型，永久成就）
   */
  static async countTotalLevelAchievements(
    userId: string,
    level: "bronze" | "silver" | "gold"
  ): Promise<number> {
    const historySnapshot = await db
      .collection("achievementHistory")
      .where("userId", "==", userId)
      .where("level", "==", level)
      .get();

    return historySnapshot.size;
  }

  /**
   * 统计终身步数（永久成就）
   */
  static async countTotalSteps(userId: string): Promise<number> {
    const logsSnapshot = await db
      .collection("healthLogs")
      .doc(userId)
      .collection("logs")
      .get();

    let totalSteps = 0;

    logsSnapshot.docs.forEach((doc) => {
      const data = doc.data();
      const id = data.logId || doc.id;

      // 可选：只认 steps_* 的 log
      if (!id.startsWith("steps_")) return;

      const steps = data.steps || 0;
      if (steps > 0) {
        totalSteps += steps;
      }
    });

    return totalSteps;
  }

  /**
   * 帖子创建时的成就更新
   * 同时更新 periodic 和 permanent 成就
   */
  static async handlePostCreated(
    userId: string,
    postType?: string
  ): Promise<void> {
    try {
      // 1. 更新周期性成就：发帖数
      await this.incrementAchievementByDataType(userId, "communityPost");

      // 2. 更新永久成就：总发帖数
      await this.incrementAchievementByDataType(userId, "totalPosts");

      // 3. 根据帖子类型更新对应的永久成就
      if (postType) {
        const dataTypeMap: Record<string, string> = {
          general: "generalPosts",
          tips: "tipsPosts",
          recipe: "recipePosts",
          story: "storyPosts",
        };

        const dataType = dataTypeMap[postType];
        if (dataType) {
          await this.incrementAchievementByDataType(userId, dataType);
        }
      }

      // 4. 更新活跃天数
      await this.incrementActiveDaysIfNewDay(userId);

      functions.logger.log(
        `✅ Post achievements updated for user ${userId}, type: ${postType}`
      );
    } catch (error) {
      functions.logger.error("❌ Error handling post created:", error);
    }
  }

  /**
   * 评论创建时的成就更新
   * 同时更新 periodic 和 permanent 成就
   */
  static async handleCommentCreated(userId: string, postId: string): Promise<void> {
    try {
      // 1. 更新周期性成就：评论数
      await this.incrementAchievementByDataType(userId, "communityComment");

      // 2. 更新永久成就：支持性成员（不同帖子的评论数）
      await this.incrementSupportiveMemberIfNewPost(userId, postId);

      // 3. 更新活跃天数
      await this.incrementActiveDaysIfNewDay(userId);

      functions.logger.log(
        `✅ Comment achievements updated for user ${userId}`
      );
    } catch (error) {
      functions.logger.error("❌ Error handling comment created:", error);
    }
  }

  /**
   * 增量更新活跃天数（需要检查是否是新的一天）
   */
  static async incrementActiveDaysIfNewDay(userId: string): Promise<void> {
    try {
      const today = new Date();
      const todayKey = DateUtils.getDateKey(today.getTime());

      // 检查今天是否已经记录过活跃
      const todayActivityQuery = await db
        .collection("userActivities")
        .where("userId", "==", userId)
        .where("dateKey", "==", todayKey)
        .limit(1)
        .get();

      // 如果今天还没有记录过活跃，才增加计数
      if (todayActivityQuery.empty) {
        // 记录今天的活跃
        await db.collection("userActivities").add({
          userId,
          dateKey: todayKey,
          recordedAt: Date.now(),
        });

        // 增量更新活跃天数成就
        await this.incrementAchievementByDataType(
          userId,
          "communityActiveDay"
        );

        functions.logger.log(`New active day recorded for user ${userId}`);
      }
    } catch (error) {
      functions.logger.error("❌ Error incrementing active days:", error);
    }
  }

  /**
   * 支持性成员：只在“第一次评论某个 post”时 +1
   * 使用 supportiveMemberRecords 作为去重记录
   */
  private static async incrementSupportiveMemberIfNewPost(
    userId: string,
    postId: string
  ): Promise<void> {
    try {
      // 1. 先检查这个 user + post 是否已经被记录过
      const recordQuery = await db
        .collection("supportiveMemberRecords")
        .where("userId", "==", userId)
        .where("postId", "==", postId)
        .limit(1)
        .get();

      if (!recordQuery.empty) {
        // 已经算过这篇 post，不再 +1
        functions.logger.log(
          `SupportiveMember already counted for user ${userId} on post ${postId}`
        );
        return;
      }

      // 2. 写入一条去重记录（只增不减）
      const recordRef = db.collection("supportiveMemberRecords").doc();
      await recordRef.set({
        recordId: recordRef.id,
        userId,
        postId,
        firstCommentAt: Date.now(),
      });

      // 3. 真正去给 supportiveMember 成就 +1
      await this.incrementAchievementByDataType(userId, "supportiveMember");

      functions.logger.log(
        `✅ SupportiveMember incremented for user ${userId} on new post ${postId}`
      );
    } catch (error) {
      functions.logger.error(
        "❌ Error incrementing supportiveMember for new post:",
        error
      );
    }
  }

  /**
   * 核心方法：根据 dataType 增量更新成就
   */
  private static async incrementAchievementByDataType(
    userId: string,
    dataType: string
  ): Promise<void> {
    try {
      // 查找该 dataType 的所有激活成就
      const achievementsSnapshot = await db
        .collection("achievements")
        .where("isActive", "==", true)
        .where("dataType", "==", dataType)
        .get();

      if (achievementsSnapshot.empty) {
        return;
      }

      const updatePromises: Promise<void>[] = [];

      for (const achievementDoc of achievementsSnapshot.docs) {
        const achievement = achievementDoc.data();
        const achievementId = achievementDoc.id;

        // 增量更新成就进度
        updatePromises.push(
          this.incrementAchievementProgress(userId, achievementId, achievement)
        );
      }

      await Promise.all(updatePromises);
    } catch (error) {
      functions.logger.error(
        `❌ Error incrementing achievement for dataType ${dataType}:`,
        error
      );
    }
  }

  /**
   * 增量更新成就进度（统一方法，支持 periodic 和 permanent）
   */
  private static async incrementAchievementProgress(
    userId: string,
    achievementId: string,
    achievement: any
  ): Promise<void> {
    try {
      const userAchievementQuery = await db
        .collection("userAchievements")
        .where("userId", "==", userId)
        .where("achievementId", "==", achievementId)
        .limit(1)
        .get();

      let userAchievementRef: admin.firestore.DocumentReference;
      let currentCount = 1; // 默认增加1
      let existingLevel = "none";
      let existingPoints = 0;

      if (userAchievementQuery.empty) {
        // 创建新的 userAchievement（初始 count = 1）
        userAchievementRef = db.collection("userAchievements").doc();

        await userAchievementRef.set({
          userAchievementId: userAchievementRef.id,
          userId,
          achievementId,
          currentCount: 1,
          currentLevel: "none",
          earnedPoints: 0,
          status: "in progress",
          startedAt: Date.now(),
          completedAt: null,
        });

        functions.logger.log(
          `Created userAchievement: ${userId} - ${achievementId} (count: 1)`
        );
      } else {
        // 🔧 更新现有的 userAchievement，currentCount + 1
        const doc = userAchievementQuery.docs[0];
        userAchievementRef = doc.ref;
        const existingData = doc.data();

        currentCount = (existingData.currentCount || 0) + 1;
        existingLevel = existingData.currentLevel || "none";
        existingPoints = existingData.earnedPoints || 0;

        await userAchievementRef.update({
          currentCount,
        });

        functions.logger.log(
          `Incremented achievement: ${userId} - ${achievementId} (count: ${currentCount})`
        );
      }

      // 检查并升级等级
      await this.checkAndUpgradeLevel(
        userId,
        achievementId,
        currentCount,
        existingLevel,
        existingPoints,
        userAchievementRef,
        achievement
      );
    } catch (error) {
      functions.logger.error(
        "❌ Error incrementing achievement progress:",
        error
      );
      throw error;
    }
  }

  /**
   * 更新非社区类的永久成就（Gold 次数、总等级次数、终身步数）
   * 这些成就需要重新计算，保留原有逻辑
   */
  static async updateNonCommunityPermanentAchievements(
    userId: string
  ): Promise<void> {
    try {
      const achievementsSnapshot = await db
        .collection("achievements")
        .where("isActive", "==", true)
        .where("achievementType", "==", "permanent")
        .get();

      const updatePromises: Promise<void>[] = [];

      for (const achievementDoc of achievementsSnapshot.docs) {
        const achievement = achievementDoc.data();
        const achievementId = achievementDoc.id;
        const dataType = achievement.dataType;

        // 跳过社区相关的永久成就（这些已经通过增量更新处理）
        const communityDataTypes = [
          "totalPosts",
          "generalPosts",
          "tipsPosts",
          "recipePosts",
          "storyPosts",
          "supportiveMember",
        ];

        if (communityDataTypes.includes(dataType)) {
          continue;
        }

        // 处理需要重新计算的永久成就
        let currentCount = 0;

        switch (dataType) {
        // 不再每天重算 lifetimeSteps
        //         case "lifetimeSteps":
        //           currentCount = await this.countTotalSteps(userId);
        //           break;

        case "glucoseGoldCount":
          currentCount = await this.countGoldAchievements(
            userId,
            "bloodGlucose"
          );
          break;

        case "pressureGoldCount":
          currentCount = await this.countGoldAchievements(
            userId,
            "bloodPressure"
          );
          break;

        case "weightGoldCount":
          currentCount = await this.countGoldAchievements(
            userId,
            "bodyWeight"
          );
          break;

        case "activityGoldCount":
          currentCount = await this.countGoldAchievements(
            userId,
            "physicalActivity"
          );
          break;

        case "totalGold":
          currentCount = await this.countTotalLevelAchievements(
            userId,
            "gold"
          );
          break;

        case "totalSilver":
          currentCount = await this.countTotalLevelAchievements(
            userId,
            "silver"
          );
          break;

        case "totalBronze":
          currentCount = await this.countTotalLevelAchievements(
            userId,
            "bronze"
          );
          break;

        default:
          continue;
        }

        // 只有当 count > 0 时才更新成就
        if (currentCount > 0) {
          updatePromises.push(
            this.updateAchievementProgress(
              userId,
              achievementId,
              currentCount,
              achievement
            )
          );
        }
      }

      await Promise.all(updatePromises);
    } catch (error) {
      functions.logger.error(
        "❌ Error updating non-community permanent achievements:",
        error
      );
    }
  }

  /**
   * 更新成就进度（用于需要重新计算的成就）
   */
  private static async updateAchievementProgress(
    userId: string,
    achievementId: string,
    currentCount: number,
    achievement: any
  ): Promise<void> {
    try {
      const userAchievementQuery = await db
        .collection("userAchievements")
        .where("userId", "==", userId)
        .where("achievementId", "==", achievementId)
        .limit(1)
        .get();

      let userAchievementRef: admin.firestore.DocumentReference;
      let existingData: any = null;

      if (userAchievementQuery.empty) {
        // 创建新的 userAchievement
        userAchievementRef = db.collection("userAchievements").doc();

        await userAchievementRef.set({
          userAchievementId: userAchievementRef.id,
          userId,
          achievementId,
          currentCount,
          currentLevel: "none",
          earnedPoints: 0,
          status: "in progress",
          startedAt: Date.now(),
          completedAt: null,
        });

        functions.logger.log(
          `✅ Created userAchievement: ${userId} - ${achievementId} (count: ${currentCount})`
        );
      } else {
        // 更新现有的 userAchievement
        const doc = userAchievementQuery.docs[0];
        userAchievementRef = doc.ref;
        existingData = doc.data();

        await userAchievementRef.update({
          currentCount,
        });

        functions.logger.log(
          `Updated progress: ${userId} - ${achievementId} (count: ${currentCount})`
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
        achievement
      );
    } catch (error) {
      functions.logger.error("❌ Error updating achievement progress:", error);
      throw error;
    }
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
    achievement: any
  ): Promise<void> {
    const levels = achievement.levels;
    const achievementType = achievement.achievementType;

    let newLevel = "none";
    let newPoints = 0;

    // 根据当前进度确定等级和积分
    for (const level of levels) {
      if (currentCount >= level.criteria) {
        newLevel = level.level;
        newPoints += level.points;
      }
    }

    // 计算积分变化（仅周期性成就有积分）
    const pointsDiff =
      achievementType === "periodic" ? newPoints - existingPoints : 0;

    // 如果等级有变化
    if (newLevel !== existingLevel) {
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
          updateData.completedAt = Date.now();
        }
      } else {
        updateData.status = "in progress";
        if (existingLevel === highestLevel.level) {
          updateData.completedAt = null;
        }
      }

      await userAchievementRef.update(updateData);

      functions.logger.log(
        `Level changed: ${existingLevel} → ${newLevel}, Points: ${existingPoints} → ${newPoints}`
      );

      // 更新用户总分（仅周期性成就）
      if (pointsDiff !== 0 && achievementType === "periodic") {
        await db
          .collection("users")
          .doc(userId)
          .update({
            totalScore: admin.firestore.FieldValue.increment(pointsDiff),
          });

        functions.logger.log(
          pointsDiff > 0
            ? `Awarded ${pointsDiff} points to user ${userId}`
            : `Deducted ${Math.abs(pointsDiff)} points from user ${userId}`
        );
      }

      // 记录成就历史（如果是周期性成就且达到新等级）
      //       if (
      //         achievementType === "periodic" &&
      //         newLevel !== "none" &&
      //         newLevel !== existingLevel
      //       ) {
      //         await this.recordAchievementHistory(
      //           userId,
      //           achievementId,
      //           newLevel as "bronze" | "silver" | "gold"
      //         );
      //       }
    }
  }

  /**
   * 记录成就历史
   */
//   private static async recordAchievementHistory(
//     userId: string,
//     achievementId: string,
//     level: "bronze" | "silver" | "gold"
//   ): Promise<void> {
//     try {
//       const historyRef = db.collection("achievementHistory").doc();
//
//       await historyRef.set({
//         historyId: historyRef.id,
//         userId,
//         achievementId,
//         level,
//         achievedAt: Date.now(),
//       });
//
//       functions.logger.log(
//         `📝 Recorded achievement history: ${userId} - ${achievementId} - ${level}`
//       );
//     } catch (error) {
//       functions.logger.error("❌ Error recording achievement history:", error);
//     }
//   }
}