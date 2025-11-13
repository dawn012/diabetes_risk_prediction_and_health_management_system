import { onDocumentCreated, onDocumentUpdated, onDocumentDeleted } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

const db = admin.firestore();

/**
 * 当健康记录创建、更新或删除时，同步最新体重到用户档案
 */

// 健康记录创建时的处理
export const onHealthLogCreated = onDocumentCreated(
  "healthLogs/{userId}/logs/{logId}",
  async (event) => {
    await syncLatestWeightToUserProfile(event.params.userId);
  }
);

// 健康记录更新时的处理
export const onHealthLogUpdated = onDocumentUpdated(
  "healthLogs/{userId}/logs/{logId}",
  async (event) => {
    await syncLatestWeightToUserProfile(event.params.userId);
  }
);

// 健康记录删除时的处理
export const onHealthLogDeleted = onDocumentDeleted(
  "healthLogs/{userId}/logs/{logId}",
  async (event) => {
    await syncLatestWeightToUserProfile(event.params.userId);
  }
);

/**
 * 同步最新体重到用户档案的主要函数
 */
async function syncLatestWeightToUserProfile(userId: string): Promise<void> {
  try {
    functions.logger.log(`🔄 Starting weight sync for user: ${userId}`);

    // 1. 获取用户最新的体重记录
    const latestWeight = await getLatestWeightLog(userId);

    if (latestWeight) {
      // 2. 更新用户档案中的体重信息
      await updateUserProfileWeight(userId, latestWeight);
      functions.logger.log(`✅ Successfully synced weight ${latestWeight.weight}kg to user profile for ${userId}`);
    } else {
      // 如果没有找到体重记录，可以选择清空或保持原值
      // 这里我们选择不清空，只记录日志
      functions.logger.log(`ℹ️ No weight records found for user ${userId}, keeping existing profile weight`);
    }

  } catch (error) {
    functions.logger.error(`❌ Error syncing weight for user ${userId}:`, error);
    throw error;
  }
}

/**
 * 获取用户最新的体重记录
 */
async function getLatestWeightLog(userId: string): Promise<{ weight: number; timestamp: Date } | null> {
  try {
    const healthLogsRef = db.collection("healthLogs").doc(userId).collection("logs");

    // 查询包含体重数据的记录，按时间降序排列，取第一条
    const querySnapshot = await healthLogsRef
      .where("bodyComposition.weight", ">", 0) // 只查询有体重数据的记录
      .orderBy("logDateTime", "desc") // 主要按时间降序
      .limit(1)
      .get();

    if (querySnapshot.empty) {
      functions.logger.log(`📊 No weight records found for user ${userId}`);
      return null;
    }

    const latestLog = querySnapshot.docs[0];
    const logData = latestLog.data();

    // 提取体重数据
    const weight = logData.bodyComposition?.weight;
    const logDateTime = logData.logDateTime;

    if (!weight || weight <= 0) {
      return null;
    }

    const timestamp = logDateTime ? new Date(logDateTime) : new Date();

    functions.logger.log(`📊 Found latest weight: ${weight}kg recorded at ${timestamp} for user ${userId}`);

    return {
      weight,
      timestamp
    };

  } catch (error) {
    functions.logger.error(`❌ Error fetching latest weight for user ${userId}:`, error);
    throw error;
  }
}

/**
 * 更新用户档案中的体重信息
 */
async function updateUserProfileWeight(userId: string, weightData: { weight: number; timestamp: Date }): Promise<void> {
  try {
    const userRef = db.collection("users").doc(userId);

    const updateData = {
      "profile.weight": weightData.weight,
    };

    await userRef.update(updateData);

    functions.logger.log(`✅ Updated user profile weight to ${weightData.weight}kg for user ${userId}`);

  } catch (error) {
    functions.logger.error(`❌ Error updating user profile weight for ${userId}:`, error);
    throw error;
  }
}
