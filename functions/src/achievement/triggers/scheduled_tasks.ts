/**
 * 定时任务
 */

import { onSchedule } from "firebase-functions/v2/scheduler";
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { HealthLogAchievementService } from "../services/health_log_achievement_service";
import { CommunityAchievementService } from "../services/community_achievement_service";
// import { DateUtils } from "../utils/date_utils";
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

export const saveLeaderboardMonthlySnapshot = onSchedule(
  {
    schedule: "0 0 1 * *",
    timeZone: "Asia/Kuala_Lumpur",
  },
  async () => {
    try {
      functions.logger.log("🚀 Starting monthly leaderboard snapshot...");

      const now = new Date();
      const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
      const year = lastMonth.getFullYear();
      const month = lastMonth.getMonth() + 1;

      // 1. 取前 100，按你 Dart 的规则，生成快照（这段你已经写好了）
      const querySnapshot = await db
        .collection("users")
        .where("accountAvailable", "==", true)
        .where("totalScore", ">", 0)
        .orderBy("totalScore", "desc")
        .orderBy("lastScoreUpdateTime", "asc")
        .orderBy("username", "asc")
        .limit(100)
        .get();

      if (querySnapshot.empty) {
        functions.logger.log("No users found for leaderboard snapshot");
      } else {
        const users: any[] = querySnapshot.docs.map((doc) => {
          const data = doc.data();
          return {
            userId: doc.id,
            username: data.username ?? "",
            totalScore: data.totalScore ?? 0,
            lastScoreUpdateTime: data.lastScoreUpdateTime ?? 0,
            profileImg: data.profileImg ?? "",
          };
        });

        let currentRank = 1;
        let lastScore: number | null = null;
        let lastUpdateTime: number | null = null;

        for (let i = 0; i < users.length; i++) {
          const user = users[i];
          const score = user.totalScore as number;
          const updateTime = user.lastScoreUpdateTime as number;

          if (
            lastScore !== null &&
            lastUpdateTime !== null &&
            score === lastScore &&
            updateTime === lastUpdateTime
          ) {
            user.rank = currentRank;
          } else {
            currentRank = i + 1;
            user.rank = currentRank;
          }

          lastScore = score;
          lastUpdateTime = updateTime;
        }

        const snapshotBatch = db.batch();
        for (const user of users) {
          const docRef = db.collection("leaderboard").doc();
          snapshotBatch.set(docRef, {
            userId: user.userId,
            username: user.username,
            score: user.totalScore,
            rank: user.rank,
            year: year,
            month: month,
            profileImg: user.profileImg,
            lastScoreUpdateTime: user.lastScoreUpdateTime,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
        await snapshotBatch.commit();
        functions.logger.log(`Leaderboard snapshot saved for ${year}-${month}!`);
      }

      // 2. 清零所有用户的 totalScore（新月份从 0 开始）
      functions.logger.log("🧹 Resetting all users' totalScore for new month...");

      const usersRef = db.collection("users");
      const usersSnapshot = await usersRef.get();

      if (usersSnapshot.empty) {
        functions.logger.log("No users found to reset scores");
      } else {
        const resetBatch = db.batch();
        usersSnapshot.docs.forEach((doc) => {
          resetBatch.update(doc.ref, {
            totalScore: 0,
            lastScoreUpdateTime: 0, // 跟你现在 int 毫秒类型对齐；如果要用 null，可以改成 null
          });
        });

        await resetBatch.commit();
        functions.logger.log(`✅ Reset totalScore for ${usersSnapshot.size} users`);
      }
    } catch (error) {
      functions.logger.error("❌ Error in monthly snapshot & reset:", error);
      throw error;
    }
  }
);

/**
 * 每月1号凌晨12:10点分配排行榜奖励
 * 在保存月度快照之后执行
 */
export const distributeLeaderboardRewards = onSchedule(
  {
    schedule: "10 0 1 * *", // 每月1号 12:10 AM
    timeZone: "Asia/Kuala_Lumpur",
  },
  async () => {
    try {
      functions.logger.log("Starting leaderboard rewards distribution...");

      // 获取上个月的年份和月份
      const now = new Date();
      const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1);
      const year = lastMonth.getFullYear();
      const month = lastMonth.getMonth() + 1;

      functions.logger.log(`Processing rewards for ${year}-${month}`);

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
 * 每月 1 号凌晨 12 点重置所有 periodic 成就并记录历史
 */
export const monthlyAchievementReset = onSchedule(
  {
    schedule: "0 0 1 * *", // 每月 1 号 00:00 AM
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

    // 只对这些健康类型的周期成就做“月结写 history”
    const healthTypesNeedingMonthlyHistory = [
      "bloodGlucose",
      "bloodPressure",
      "bodyWeight",
      "physicalActivity",
      // 如果 steps 也要按月结算 Gold 次数，就加 "steps"
      // "steps",
    ];

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

      // 先取出对应的 achievement 配置
      const achievementDoc = await db
        .collection("achievements")
        .doc(data.achievementId)
        .get();

      if (!achievementDoc.exists) continue;

      const achievement = achievementDoc.data();

      // 只记录：
      // 1. 周期性成就（periodic）
      // 2. 当前等级不是 none（至少拿到 bronze 以上）
      // 3. dataType 是需要月结的健康类型（会回退的）
      if (
        achievement?.achievementType === "periodic" &&
        data.currentLevel !== "none" &&
        healthTypesNeedingMonthlyHistory.includes(achievement.dataType)
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
    } else {
      functions.logger.log("ℹ️ No periodic health achievements to record");
    }
  } catch (error) {
    functions.logger.error("❌ Error recording achievement history:", error);
  }
}

/**
 * 重置社区相关的周期性成就（只删除 periodic 类型）
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
    schedule: "every 1 minutes",
    timeZone: "Asia/Kuala_Lumpur",
  },
  async () => {
    try {
      functions.logger.log("🔍 Running hourly achievement sync check...");

      const now = new Date();
      const daysInMonth = new Date(
        now.getFullYear(),
        now.getMonth() + 1,
        0
      ).getDate();

      // 取所有 active periodic 成就
      const achievementsSnapshot = await db
        .collection("achievements")
        .where("isActive", "==", true)
        .where("achievementType", "==", "periodic")
        .get();

      if (achievementsSnapshot.empty) {
        functions.logger.log(
          "ℹ️ No active periodic achievements found, skip sync"
        );
        functions.logger.log("✅ Hourly sync check completed");
        return;
      }

      // 在所有 periodic 里找“第一条有 dynamic Gold 的成就”
      let sampleGoldLevel: any | null = null;

      for (const doc of achievementsSnapshot.docs) {
        const data = doc.data();
        const goldLevel = data.levels?.find(
          (l: any) => l.level === "gold" && l.isDynamic === true
        );
        if (goldLevel) {
          sampleGoldLevel = goldLevel;
          break;
        }
      }

      if (!sampleGoldLevel) {
        functions.logger.log(
          "ℹ️ No dynamic Gold level found in periodic achievements, skip sync"
        );
        functions.logger.log("✅ Hourly sync check completed");
        return;
      }

      if (sampleGoldLevel.criteria !== daysInMonth) {
        functions.logger.warn(
          `⚠️ Gold criteria not updated! Expected: ${daysInMonth}, Got: ${sampleGoldLevel.criteria}`
        );
        await HealthLogAchievementService.updateGoldDynamicCriteria();
      } else {
        functions.logger.log(
          `✅ Gold criteria already correct for this month (${daysInMonth} days)`
        );
      }

      functions.logger.log("✅ Hourly sync check completed");
    } catch (error) {
      functions.logger.error("❌ Error in hourly sync check:", error);
    }
  }
);

/**
 * 每5分钟更新所有用户的非社区类永久成就
 * （社区类永久成就已通过增量更新实时处理）
 */
export const dailyPermanentAchievementUpdate = onSchedule(
  {
    schedule: "every 5 minutes",
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
          // 只更新非社区类的永久成就（Gold 次数、总等级次数、终身步数等）
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

export const manualCloseLastMonthAndReset = functions.https.onRequest(
  async (req, res) => {
    try {
      const year = 2025;
      const month = 11;

      // 1. 跟 saveLeaderboardMonthlySnapshot 一样，先存快照（year=2024, month=11）
      const querySnapshot = await db
        .collection("users")
        .where("accountAvailable", "==", true)
        .where("totalScore", ">", 0)
        .orderBy("totalScore", "desc")
        .orderBy("lastScoreUpdateTime", "asc")
        .orderBy("username", "asc")
        .limit(100)
        .get();

      if (!querySnapshot.empty) {
        const users: any[] = querySnapshot.docs.map((doc) => {
          const data = doc.data();
          return {
            userId: doc.id,
            username: data.username ?? "",
            totalScore: data.totalScore ?? 0,
            lastScoreUpdateTime: data.lastScoreUpdateTime ?? 0,
            profileImg: data.profileImg ?? "",
          };
        });

        let currentRank = 1;
        let lastScore: number | null = null;
        let lastUpdateTime: number | null = null;

        for (let i = 0; i < users.length; i++) {
          const user = users[i];
          const score = user.totalScore as number;
          const updateTime = user.lastScoreUpdateTime as number;

          if (
            lastScore !== null &&
            lastUpdateTime !== null &&
            score === lastScore &&
            updateTime === lastUpdateTime
          ) {
            user.rank = currentRank;
          } else {
            currentRank = i + 1;
            user.rank = currentRank;
          }

          lastScore = score;
          lastUpdateTime = updateTime;
        }

        const snapshotBatch = db.batch();
        for (const user of users) {
          const docRef = db.collection("leaderboard").doc();
          snapshotBatch.set(docRef, {
            userId: user.userId,
            username: user.username,
            score: user.totalScore,
            rank: user.rank,
            year: year,
            month: month, // 手动当成 11 月
            profileImg: user.profileImg,
            lastScoreUpdateTime: user.lastScoreUpdateTime,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
        await snapshotBatch.commit();
      }

      // 2. 清零所有用户的 totalScore + lastScoreUpdateTime
      const usersRef = db.collection("users");
      const usersSnapshot = await usersRef.get();

      if (!usersSnapshot.empty) {
        const resetBatch = db.batch();
        usersSnapshot.docs.forEach((doc) => {
          resetBatch.update(doc.ref, {
            totalScore: 0,
            lastScoreUpdateTime: 0,
          });
        });
        await resetBatch.commit();
      }

      res.send("Manual close for 2024-11 done, scores reset");
    } catch (e) {
      console.error(e);
      res.status(500).send("Error");
    }
  }
);
