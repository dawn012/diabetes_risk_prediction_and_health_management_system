/**
 * ============================================================
 * REMINDER NOTIFICATION FUNCTIONS
 * 负责发送通知和处理用户交互（Snooze/Dismiss）
 * ============================================================
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";

const db = admin.firestore();

// Snooze 时间窗口（分钟）
// const SNOOZE_WINDOW_MINUTES = 5;

/**
 * ============================================================
 * NOTIFICATION TRIGGER FUNCTION
 * ============================================================
 */

/**
 * 当 Schedule 被标记为 "triggered" 时发送通知
 */
export const onScheduleTriggered = onDocumentUpdated(
  "reminders/{reminderId}/reminderSchedules/{scheduleId}",
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();
    const { reminderId, scheduleId } = event.params;

    if (!beforeData || !afterData) {
      functions.logger.log("No schedule data found");
      return;
    }

    // 只在状态从 pending 变为 triggered 时发送通知
    if (beforeData.status === "pending" && afterData.status === "triggered") {
      functions.logger.log(`Schedule ${scheduleId} triggered, sending notification`);

      try {
        const reminderDoc = await db.collection("reminders").doc(reminderId).get();

        if (!reminderDoc.exists) {
          functions.logger.error(`❌ Reminder ${reminderId} not found`);
          return;
        }

        const reminderData = reminderDoc.data();

        if (reminderData) {
          const userId = reminderData.userId;
          if (!userId) {
            functions.logger.error(`❌ Reminder ${reminderId} has no userId`);
            return;
          }

          // 发送通知
          await sendReminderNotification(userId, reminderId, reminderData, scheduleId);

          // 标记通知已发送
          await event.data?.after.ref.update({
            notificationSent: true,
            notificationSentAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          functions.logger.log(`✅ Notification sent for reminder ${reminderId}`);
        } else {
          functions.logger.log(`⚠️ Reminder ${reminderId} is not active, skipping notification`);
        }
      } catch (error) {
        functions.logger.error("❌ Error processing triggered schedule:", error);

        // 标记为失败
        await event.data?.after.ref.update({
          status: "failed",
          error: (error as Error).message,
          failedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }
  }
);

/**
 * ============================================================
 * CALLABLE FUNCTIONS - USER ACTIONS
 * ============================================================
 */

/**
 * 处理用户的 Snooze 操作
 * 🔧 重构：创建新的 snooze schedule，而不是更新现有的
 */
export const handleSnoozeReminder = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const { reminderId, scheduleId, snoozeDuration = 5 } = request.data;
  const userId = request.auth.uid;

  try {
    // 1️⃣ 检查 reminder 是否存在
    const reminderDoc = await db.collection("reminders").doc(reminderId).get();

    if (!reminderDoc.exists) {
      throw new HttpsError("not-found", "Reminder not found");
    }

    const reminderData = reminderDoc.data();
    if (reminderData?.userId !== userId) {
      throw new HttpsError("permission-denied", "Not authorized for this reminder");
    }

    // 2️⃣ 获取当前 schedule
    const scheduleRef = db
      .collection("reminders")
      .doc(reminderId)
      .collection("reminderSchedules")
      .doc(scheduleId);

    const scheduleDoc = await scheduleRef.get();
    if (!scheduleDoc.exists) {
      throw new HttpsError("not-found", "Schedule not found");
    }

    const scheduleData = scheduleDoc.data();

    // 3️⃣ 验证 schedule 状态
    if (scheduleData?.status !== "triggered") {
      throw new HttpsError(
        "failed-precondition",
        "Can only snooze triggered reminders"
      );
    }

    // 4️⃣ 检查 snooze 时间窗口（防止延迟 snooze）
    //     const triggeredAt = scheduleData.triggeredAt?.toDate();
    //     if (triggeredAt) {
    //       const now = new Date();
    //       const minutesSinceTrigger = (now.getTime() - triggeredAt.getTime()) / (1000 * 60);
    //
    //       if (minutesSinceTrigger > SNOOZE_WINDOW_MINUTES) {
    //         throw new HttpsError(
    //           "deadline-exceeded",
    //           `Snooze window expired (${SNOOZE_WINDOW_MINUTES} minutes)`
    //         );
    //       }
    //     }

    // 5️⃣ 计算 snooze 时间（Malaysia 时区）
    const nowMalaysia = new Date(new Date().toLocaleString("en-US", { timeZone: "Asia/Kuala_Lumpur" }));
    const snoozeUntilMalaysia = new Date(nowMalaysia.getTime() + snoozeDuration * 60 * 1000);
    snoozeUntilMalaysia.setSeconds(0, 0);

    // 转换为 UTC
    const snoozeUntilUTC = new Date(snoozeUntilMalaysia.getTime() - 8 * 60 * 60 * 1000);

    // 6️⃣ 检查是否已有 pending 的 snooze schedule（防止重复 snooze）
    const existingSnooze = await db
      .collection("reminders")
      .doc(reminderId)
      .collection("reminderSchedules")
      .where("status", "==", "pending")
      .where("parentScheduleId", "==", scheduleId)
      .limit(1)
      .get();

    if (!existingSnooze.empty) {
      throw new HttpsError(
        "already-exists",
        "A snooze schedule already exists for this reminder"
      );
    }

    // 7️⃣ 使用事务创建新的 snooze schedule 并更新原 schedule
    const newScheduleRef = db
      .collection("reminders")
      .doc(reminderId)
      .collection("reminderSchedules")
      .doc();

    await db.runTransaction(async (transaction) => {
      // 标记原 schedule 为 snoozed
      transaction.update(scheduleRef, {
        status: "snoozed",
        snoozedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 创建新的 snooze schedule
      const newScheduleData = {
        scheduleId: newScheduleRef.id,
        triggerTime: admin.firestore.Timestamp.fromDate(snoozeUntilUTC),
        originalTime: scheduleData.originalTime, // 保留原始时间
        parentScheduleId: scheduleId, // 记录父 schedule
        snoozeCount: (scheduleData.snoozeCount || 0) + 1, // 累计 snooze 次数
        status: "pending",
        isSnooze: true, // 标记为 snooze schedule
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      transaction.set(newScheduleRef, newScheduleData);

      // 更新 reminder 的 nextTriggerTime
      transaction.update(db.collection("reminders").doc(reminderId), {
        nextTriggerTime: admin.firestore.Timestamp.fromDate(snoozeUntilUTC),
      });
    });

    functions.logger.log(
      `Snooze schedule created: Malaysia=${snoozeUntilMalaysia.toISOString()}, ` +
      `UTC=${snoozeUntilUTC.toISOString()}, snoozeCount=${(scheduleData.snoozeCount || 0) + 1}`
    );

    return {
      success: true,
      snoozedUntil: snoozeUntilMalaysia.toISOString(),
      newScheduleId: newScheduleRef.id,
      snoozeCount: (scheduleData.snoozeCount || 0) + 1,
    };

  } catch (error) {
    functions.logger.error("❌ Error snoozing reminder:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", "Failed to snooze reminder");
  }
});

/**
 * 处理用户的 Dismiss 操作
 */
export const handleDismissReminder = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const { reminderId, scheduleId } = request.data;
  const userId = request.auth.uid;

  try {
    // 验证 reminder 存在
    const reminderDoc = await db.collection("reminders").doc(reminderId).get();

    if (!reminderDoc.exists) {
      throw new HttpsError("not-found", "Reminder not found");
    }

    const reminderData = reminderDoc.data();
    if (reminderData?.userId !== userId) {
      throw new HttpsError("permission-denied", "Not authorized for this reminder");
    }

    // 获取 schedule
    const scheduleRef = db
      .collection("reminders")
      .doc(reminderId)
      .collection("reminderSchedules")
      .doc(scheduleId);

    const scheduleDoc = await scheduleRef.get();
    if (!scheduleDoc.exists) {
      throw new HttpsError("not-found", "Schedule not found");
    }

    const scheduleData = scheduleDoc.data();

    // 验证状态
    if (scheduleData?.status !== "triggered") {
      throw new HttpsError(
        "failed-precondition",
        "Can only dismiss triggered reminders"
      );
    }

    // 标记为 dismissed
    await scheduleRef.update({
      status: "dismissed",
      dismissedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    functions.logger.log(`✅ Reminder ${reminderId} dismissed`);

    return { success: true };
  } catch (error) {
    functions.logger.error("❌ Error dismissing reminder:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", "Failed to dismiss reminder");
  }
});

/**
 * ============================================================
 * HELPER FUNCTIONS
 * ============================================================
 */

/**
 * 发送 FCM 推送通知给用户（data-only）
 */
async function sendReminderNotification(
  userId: string,
  reminderId: string,
  reminderData: any,
  scheduleId: string
): Promise<void> {
  try {
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) {
      functions.logger.error(`❌ User ${userId} does not exist`);
      return;
    }

    const userData = userDoc.data();
    const fcmTokens = userData?.fcmTokens || [];

    if (fcmTokens.length === 0) {
      functions.logger.warn(`⚠️ User ${userId} has no registered FCM tokens`);
      return;
    }

    const isMealReminder = reminderData.isMealReminder || false;
    const mealTimeSlot = reminderData.mealTimeSlot || "";

    const message: admin.messaging.MulticastMessage = {
      tokens: fcmTokens,
      // 不再使用 notification，改为纯 data-only
      data: {
        type: isMealReminder ? "meal_reminder_notification" : "reminder_notification",
        reminderId,
        scheduleId,
        userId,
        reminderTitle: reminderData.reminderTitle || "",
        reminderDescription: reminderData.reminderDescription || "",
        snoozeDuration: (reminderData.snoozeDuration || 5).toString(),
        ...(isMealReminder && {
          isMealReminder: "true",
          mealTimeSlot: mealTimeSlot,
          mealPlanId: reminderData.mealPlanId || "",
        }),
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        screen: "reminder_detail",
        id: reminderId,
      },
      android: {
        priority: "high",
        // ❌ 如果全部走本地通知，可以不需要 android.notification
        // 保留 priority 确保后台送达可靠
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            // 对 data-only 推送，让 iOS 后台可唤醒
            contentAvailable: true as any,
            category: "reminder_category",
          },
        },
      },
      webpush: {
        headers: {
          Urgency: "high",
        },
      },
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    functions.logger.info(`Successfully sent ${response.successCount} notifications`);

    if (response.failureCount > 0) {
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          functions.logger.error(`❌ Failed to send to token ${fcmTokens[idx]}:`, resp.error);

          if (resp.error?.code === "messaging/registration-token-not-registered") {
            removeInvalidToken(userId, fcmTokens[idx]);
          }
        }
      });
    }

    await logNotificationSent(userId, reminderId, scheduleId, response.successCount);
  } catch (error) {
    functions.logger.error("❌ Error sending notification:", error);
    throw error;
  }
}

/**
 * 移除无效的 FCM token
 */
async function removeInvalidToken(userId: string, invalidToken: string): Promise<void> {
  try {
    await db.collection("users").doc(userId).update({
      fcmTokens: admin.firestore.FieldValue.arrayRemove(invalidToken),
    });
    functions.logger.info(`Removed invalid token for user ${userId}`);
  } catch (error) {
    functions.logger.error("❌ Error removing invalid token:", error);
  }
}

/**
 * 记录通知发送日志
 */
async function logNotificationSent(
  userId: string,
  reminderId: string,
  scheduleId: string,
  successCount: number
): Promise<void> {
  try {
    await db
      .collection("reminders")
      .doc(reminderId)
      .collection("notificationLogs")
      .add({
        userId: userId,
        scheduleId: scheduleId,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        successCount: successCount,
        status: successCount > 0 ? "delivered" : "failed",
      });
    functions.logger.log(`Notification log created for reminder ${reminderId}`);
  } catch (error) {
    functions.logger.error("❌ Error logging notification:", error);
  }
}