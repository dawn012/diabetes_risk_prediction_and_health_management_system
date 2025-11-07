/**
 * 成就配置
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

export interface AchievementConfig {
  achievementId: string;
  achievementTitle: string;
  achievementType: "periodic" | "permanent";
  dataType: "bloodGlucose" | "bloodPressure" | "bodyWeight" | "physicalActivity" | "steps";
  trackingStrategy: "uniqueDays" | "sumDuration" | "totalSteps" | "qualifiedDays";

  makeupConfig: {
    enabled: boolean;
    maxDaysBack: number;
    maxMakeupCount?: number;
  };

  stepsConfig?: {
    dailyTarget?: number;
    monthlyTarget?: number;
  };

  levels: {
    level: "bronze" | "silver" | "gold";
    criteria: number;
    criteriaUnit: string;
    points: number;
    isDynamic?: boolean;        // 仅用于标记，不影响使用
  }[];

  isActive: boolean;
  createdAt: admin.firestore.Timestamp;
}

// 缓存
let achievementConfigsCache: AchievementConfig[] | null = null;
let lastCacheTime = 0;
const CACHE_DURATION = 5 * 60 * 1000;

/**
 * 获取所有活跃的成就配置
 */
export async function getAchievementConfigs(): Promise<AchievementConfig[]> {
  if (achievementConfigsCache && Date.now() - lastCacheTime < CACHE_DURATION) {
    return achievementConfigsCache;
  }

  try {
    const snapshot = await admin.firestore()
      .collection("achievements")
      .where("isActive", "==", true)
      .where("achievementType", "==", "periodic")
      .get();

    const configs: AchievementConfig[] = [];

    snapshot.forEach(doc => {
      const data = doc.data();

      // 将毫秒数转换为 Timestamp
      const createdAtMs = data.createdAt; // 从 Firestore 读取的毫秒数
      const createdAtTimestamp = admin.firestore.Timestamp.fromMillis(createdAtMs);

      configs.push({
        achievementId: doc.id,
        achievementTitle: data.achievementTitle,
        achievementType: data.achievementType,
        dataType: data.dataType,
        trackingStrategy: data.trackingStrategy,
        makeupConfig: data.makeupConfig || { enabled: true, maxDaysBack: 7 },
        stepsConfig: data.stepsConfig,
        levels: data.levels,
        isActive: data.isActive,
        createdAt: createdAtTimestamp,
      });
    });

    achievementConfigsCache = configs;
    lastCacheTime = Date.now();

    functions.logger.log(`✅ Loaded ${configs.length} achievement configs`);
    return configs;
  } catch (error) {
    functions.logger.error("❌ Error fetching achievement configs:", error);
    return achievementConfigsCache || [];
  }
}

/**
 * 清除缓存
 */
export function clearAchievementConfigCache(): void {
  achievementConfigsCache = null;
  lastCacheTime = 0;
  functions.logger.log("🔄 Achievement config cache cleared");
}
