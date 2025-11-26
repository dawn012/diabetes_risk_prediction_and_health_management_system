/**
 * 定时任务
 */

import { onSchedule } from "firebase-functions/v2/scheduler";
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { HealthLogAchievementService } from "../services/health_log_achievement_service";
import { CommunityAchievementService } from "../services/community_achievement_service";
import { DateUtils } from "../utils/date_utils";
import { clearAchievementConfigCache } from "../config/achievement_config";

const db = admin.firestore();

/**
 * 排行榜奖励分配规则
 */
const LEADERBOARD_REWARDS = {
  1: 1000,      // 第1名: 1000 points
  2: 800,       // 第2名: 800 points
  3: 600,       // 第3名: 600 points
  4: 400,       // 4-10名: 400 points each
  11: 200,      // 11-50名: 200 points each
  51: 100,      // 51-100名: 100 points each
};

/**
 * 获取用户应得的奖励积分
 */
function getRewardPoints(rank: number): number {
  if (rank === 1) return LEADERBOARD_REWARDS[1];
  if (rank === 2) return LEADERBOARD_REWARDS[2];
  if (rank === 3) return LEADERBOARD_REWARDS[3];
  if (rank >= 4 && rank <= 10) return LEADERBOARD_REWARDS[4];
  if (rank >= 11 && rank <= 50) return LEADERBOARD_REWARDS[11];
  if (rank >= 51 && rank <= 100) return LEADERBOARD_REWARDS[51];
  return 0;
}

/**
 * 每月1号凌晨3点分配排行榜奖励
 * 在保存月度快照之后执行
 */
export const distributeLeaderboardRewards = onSchedule(
  {
    schedule: "0 3 1 * *", // 每月1号 3:00 AM
    timeZone: "Asia/Kuala_Lumpur",
  },
  async () => {
    try {
      functions.logger.log("🎁 Starting leaderboard rewards distribution...");

      // 获取上个月的年份和月份
      const now = new Date();
      const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1);
      const year = lastMonth.getFullYear();
      const month = lastMonth.getMonth() + 1;

      functions.logger.log(`📅 Processing rewards for ${year}-${month}`);

      // 从 leaderboard collection 获取上个月的前100名
      const leaderboardSnapshot = await db
        .collection("leaderboard")
        .where("year", "==", year)
        .where("month", "==", month)
        .orderBy("rank", "asc")
        .limit(100)
        .get();

      if (leaderboardSnapshot.empty) {
        functions.logger.log("ℹ️ No leaderboard data found for last month");
        return;
      }

      functions.logger.log(
        `Found ${leaderboardSnapshot.docs.length} users in top 100`
      );

      const batch = db.batch();
      let rewardCount = 0;
      let totalPointsDistributed = 0;

      for (const doc of leaderboardSnapshot.docs) {
        const data = doc.data();
        const userId = data.userId;
        const rank = data.rank;
        const rewardPoints = getRewardPoints(rank);

        if (rewardPoints > 0) {
          // 更新用户的 rewardPoints
          const userRef = db.collection("users").doc(userId);

          batch.update(userRef, {
            rewardPoints: admin.firestore.FieldValue.increment(rewardPoints),
          });

          // 记录奖励分配历史（可选）
          const rewardHistoryRef = db.collection("rewardHistory").doc();
          batch.set(rewardHistoryRef, {
            historyId: rewardHistoryRef.id,
            userId: userId,
            rewardType: "leaderboard",
            rank: rank,
            points: rewardPoints,
            year: year,
            month: month,
            distributedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          rewardCount++;
          totalPointsDistributed += rewardPoints;

          functions.logger.log(
            `✅ User ${userId} (Rank ${rank}): +${rewardPoints} points`
          );
        }
      }

      // 提交批量写入
      if (rewardCount > 0) {
        await batch.commit();
        functions.logger.log(
          "🎉 Rewards distributed successfully!"
        );
        functions.logger.log(
          `Total: ${rewardCount} users received ${totalPointsDistributed} points`
        );
      } else {
        functions.logger.log("ℹ️ No rewards to distribute");
      }
    } catch (error) {
      functions.logger.error(
        "❌ Error distributing leaderboard rewards:",
        error
      );
      throw error;
    }
  }
);

/**
 * 获取奖励分配规则（供前端查询）
 */
export const getLeaderboardRewardRules = functions.https.onCall(async () => {
  return {
    success: true,
    rules: [
      { rank: "1st Place", points: LEADERBOARD_REWARDS[1] },
      { rank: "2nd Place", points: LEADERBOARD_REWARDS[2] },
      { rank: "3rd Place", points: LEADERBOARD_REWARDS[3] },
      { rank: "4th - 10th Place", points: LEADERBOARD_REWARDS[4] },
      { rank: "11th - 50th Place", points: LEADERBOARD_REWARDS[11] },
      { rank: "51st - 100th Place", points: LEADERBOARD_REWARDS[51] },
    ],
  };
});


/**
 * 每月 1 号凌晨 2 点重置所有 periodic 成就并记录历史
 */
export const monthlyAchievementReset = onSchedule(
  {
    schedule: "0 2 1 * *", // 每月 1 号 2:00 AM
    timeZone: "Asia/Kuala_Lumpur",
  },
  async () => {
    try {
      functions.logger.log("Starting monthly achievement reset...");

      // 第一步：记录所有用户的成就历史
      await recordAllUsersAchievementHistory();

      // 第二步：更新所有 Achievement 的 Gold 动态天数
      await HealthLogAchievementService.updateGoldDynamicCriteria();

      // 清除配置缓存，确保后续使用最新配置
      clearAchievementConfigCache();

      // 第三步：获取所有用户并重置成就
      const usersSnapshot = await db.collection("users").get();

      if (usersSnapshot.empty) {
        functions.logger.log("✅ No users to reset");
        return;
      }

      let resetCount = 0;

      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;

        try {
          // 重置健康数据相关的周期性成就
          await HealthLogAchievementService.resetPeriodicAchievements(userId);

          // 重置社区相关的周期性成就（只删除 periodic 的 userAchievement）
          await resetPeriodicCommunityAchievements(userId);

          resetCount++;
        } catch (error) {
          functions.logger.error(
            `❌ Error resetting achievements for user ${userId}:`,
            error
          );
        }
      }

      functions.logger.log(
        `✅ Monthly reset completed: ${resetCount} users processed`
      );
    } catch (error) {
      functions.logger.error("❌ Error in monthly achievement reset:", error);
    }
  }
);

/**
 * 记录所有用户的成就历史
 */
async function recordAllUsersAchievementHistory(): Promise<void> {
  try {
    functions.logger.log("📝 Recording achievement history...");

    const userAchievementsSnapshot = await db
      .collection("userAchievements")
      .get();

    if (userAchievementsSnapshot.empty) {
      functions.logger.log("ℹ️ No achievements to record");
      return;
    }

    const batch = db.batch();
    let recordCount = 0;

    for (const doc of userAchievementsSnapshot.docs) {
      const data = doc.data();

      // 只记录周期性成就且已达成某等级的
      const achievementDoc = await db
        .collection("achievements")
        .doc(data.achievementId)
        .get();

      if (!achievementDoc.exists) continue;

      const achievement = achievementDoc.data();

      if (
        achievement?.achievementType === "periodic" &&
        data.currentLevel !== "none"
      ) {
        const historyRef = db.collection("achievementHistory").doc();

        batch.set(historyRef, {
          historyId: historyRef.id,
          userId: data.userId,
          achievementId: data.achievementId,
          level: data.currentLevel,
          achievedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        recordCount++;
      }
    }

    if (recordCount > 0) {
      await batch.commit();
      functions.logger.log(
        `✅ Recorded ${recordCount} achievement histories`
      );
    }
  } catch (error) {
    functions.logger.error("❌ Error recording achievement history:", error);
  }
}

/**
 * 🆕 重置社区相关的周期性成就（只删除 periodic 类型）
 */
async function resetPeriodicCommunityAchievements(
  userId: string
): Promise<void> {
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

      // 只删除 periodic 类型的社区成就，保留 permanent 类型
      if (
        achievement &&
        achievement.achievementType === "periodic" &&
        (achievement.dataType === "communityPost" ||
          achievement.dataType === "communityComment" ||
          achievement.dataType === "communityActiveDay")
      ) {
        batch.delete(doc.ref);
        deletedCount++;

        functions.logger.log(
          `Deleted periodic community achievement: ${achievementId} for user ${userId}`
        );
      }
    }

    if (deletedCount > 0) {
      await batch.commit();
      functions.logger.log(
        `✅ Deleted ${deletedCount} periodic community achievements for user ${userId}`
      );
    }
  } catch (error) {
    functions.logger.error(
      "❌ Error resetting periodic community achievements:",
      error
    );
  }
}

/**
 * 每小时检查并同步成就进度
 */
export const hourlySyncCheck = onSchedule(
  {
    schedule: "every 1 hours",
    timeZone: "Asia/Kuala_Lumpur",
  },
  async () => {
    try {
      functions.logger.log("🔍 Running hourly achievement sync check...");

      // 检查是否是新月份的第一天
      if (DateUtils.isFirstDayOfMonth()) {
        const now = new Date();
        const hour = now.getUTCHours() + 8; // Malaysia time

        // 如果是第一天且已过凌晨 3 点，确保重置已执行
        if (hour >= 3) {
          functions.logger.log(
            "⚠️ First day of month detected, verifying reset status"
          );

          // 验证 Gold 天数是否已更新
          const daysInMonth = new Date(
            new Date().getFullYear(),
            new Date().getMonth() + 1,
            0
          ).getDate();

          const sampleAchievement = await db
            .collection("achievements")
            .where("isActive", "==", true)
            .where("achievementType", "==", "periodic")
            .limit(1)
            .get();

          if (!sampleAchievement.empty) {
            const data = sampleAchievement.docs[0].data();
            const goldLevel = data.levels?.find(
              (l: any) => l.level === "gold" && l.isDynamic === true
            );

            if (goldLevel && goldLevel.criteria !== daysInMonth) {
              functions.logger.warn(
                `⚠️ Gold criteria not updated! Expected: ${daysInMonth}, Got: ${goldLevel.criteria}`
              );
              // 重新触发更新
              await HealthLogAchievementService.updateGoldDynamicCriteria();
            }
          }
        }
      }

      functions.logger.log("✅ Hourly sync check completed");
    } catch (error) {
      functions.logger.error("❌ Error in hourly sync check:", error);
    }
  }
);

/**
 * 🆕 每天凌晨 1 点更新所有用户的非社区类永久成就
 * （社区类永久成就已通过增量更新实时处理）
 */
export const dailyPermanentAchievementUpdate = onSchedule(
  {
    schedule: "0 1 * * *", // 每天 1:00 AM
    timeZone: "Asia/Kuala_Lumpur",
  },
  async () => {
    try {
      functions.logger.log(
        "🔄 Starting daily non-community permanent achievement update..."
      );

      const usersSnapshot = await db.collection("users").get();

      if (usersSnapshot.empty) {
        functions.logger.log("✅ No users to update");
        return;
      }

      let updateCount = 0;

      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;

        try {
          // 🆕 只更新非社区类的永久成就（Gold 次数、总等级次数、终身步数等）
          // 社区类永久成就（总发帖、分类发帖、支持性成员）已通过增量更新实时处理
          await CommunityAchievementService.updateNonCommunityPermanentAchievements(
            userId
          );

          updateCount++;
        } catch (error) {
          functions.logger.error(
            `❌ Error updating permanent achievements for user ${userId}:`,
            error
          );
        }
      }

      functions.logger.log(
        `✅ Daily non-community permanent achievement update completed: ${updateCount} users processed`
      );
    } catch (error) {
      functions.logger.error(
        "❌ Error in daily permanent achievement update:",
        error
      );
    }
  }
);