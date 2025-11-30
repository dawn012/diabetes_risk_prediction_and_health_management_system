/**
 * ============================================================
 * REMINDER SCHEDULE FUNCTIONS
 * 负责 Reminder 生命周期和 Schedule 管理
 * ============================================================
 */

import { onDocumentCreated, onDocumentUpdated, onDocumentDeleted } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

const db = admin.firestore();

/**
 * ============================================================
 * REMINDER LIFECYCLE FUNCTIONS
 * ============================================================
 */

/**
 * 当新 Reminder 创建时，创建初始 Schedule
 */
export const onReminderCreated = onDocumentCreated(
  "reminders/{reminderId}",
  async (event) => {
    const reminderData = event.data?.data();
    const { reminderId } = event.params;

    if (!reminderData) {
      functions.logger.log("No reminder data found");
      return;
    }

    if (!reminderData.isActive) {
      functions.logger.log(`Reminder ${reminderId} is not active, skipping schedule creation`);
      return;
    }

    try {
      await createNextSchedule(reminderId, reminderData);
      functions.logger.log(`✅ Initial schedule created for reminder ${reminderId}`);
    } catch (error) {
      functions.logger.error("❌ Error creating initial schedule:", error);
      throw error;
    }
  }
);

/**
 * 当 Reminder 更新时，处理激活/停用逻辑
 */
export const onReminderUpdated = onDocumentUpdated(
  "reminders/{reminderId}",
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();
    const { reminderId } = event.params;

    if (!beforeData || !afterData) {
      functions.logger.log("No reminder data found");
      return;
    }

    // 检查 isActive 状态变化
    if (beforeData.isActive !== afterData.isActive) {
      if (afterData.isActive) {
        functions.logger.log(`✅ Reminder ${reminderId} re-enabled, recreating schedule`);
        await deleteAllPendingSchedules(reminderId);
        await createNextSchedule(reminderId, afterData);
      } else {
        functions.logger.log(`⏸️ Reminder ${reminderId} disabled, deleting schedules`);
        await deleteAllPendingSchedules(reminderId);
      }
      return;
    }

    // 检查配置变化（仅当 reminder 活跃时）
    if (afterData.isActive) {
      const baseTimeChanged = beforeData.baseTime?.toMillis() !== afterData.baseTime?.toMillis();
      const repeatTypeChanged = beforeData.repeatType !== afterData.repeatType;
      const customDaysChanged = JSON.stringify(beforeData.customDays) !== JSON.stringify(afterData.customDays);
      const intervalTimeChanged = beforeData.intervalTime !== afterData.intervalTime;

      if (baseTimeChanged || repeatTypeChanged || customDaysChanged || intervalTimeChanged) {
        functions.logger.log(`🔄 Reminder ${reminderId} configuration changed, recreating schedule`);
        await deleteAllPendingSchedules(reminderId);
        await createNextSchedule(reminderId, afterData);
      }
    }
  }
);

/**
 * 当 Reminder 删除时，删除所有相关的 Schedules
 */
export const onReminderDeleted = onDocumentDeleted(
  "reminders/{reminderId}",
  async (event) => {
    const { reminderId } = event.params;

    try {
      await deleteAllSchedules(reminderId);
      functions.logger.log(`🗑️ All schedules deleted for reminder ${reminderId}`);
    } catch (error) {
      functions.logger.error("❌ Error deleting schedules:", error);
    }
  }
);

/**
 * ============================================================
 * SCHEDULE PROCESSING FUNCTIONS
 * ============================================================
 */

/**
 * 当 Schedule 完成后，创建下一个 Schedule
 * 🔧 重构：增加防护逻辑，避免重复创建
 */
export const onScheduleProcessed = onDocumentUpdated(
  "reminders/{reminderId}/reminderSchedules/{scheduleId}",
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();
    const { reminderId, scheduleId } = event.params;

    if (!beforeData || !afterData) {
      functions.logger.log("No schedule data found");
      return;
    }

    // 只有当状态从 pending 变为完成状态时才处理
    const completedStates = ["triggered", "dismissed", "completed"];
    if (beforeData.status === "pending" && completedStates.includes(afterData.status)) {
      functions.logger.log(`📋 Schedule ${scheduleId} processed with status: ${afterData.status}`);

      const reminderDoc = await db.collection("reminders").doc(reminderId).get();

      if (!reminderDoc.exists) {
        functions.logger.log(`⚠️ Reminder ${reminderId} not found`);
        return;
      }

      const reminderData = reminderDoc.data();

      if (!reminderData || !reminderData.isActive) {
        functions.logger.log(`⚠️ Reminder ${reminderId} is not active, skipping`);
        return;
      }

      // 🔧 检查是否已有 pending schedule（防止重复创建）
      const existingPending = await db
        .collection("reminders")
        .doc(reminderId)
        .collection("reminderSchedules")
        .where("status", "==", "pending")
        .where("isSnooze", "==", false) // 🔧 排除 snooze schedules
        .limit(1)
        .get();

      if (!existingPending.empty) {
        functions.logger.log(`⚠️ Pending schedule already exists for reminder ${reminderId}, skipping creation`);
        return;
      }

      // Once 类型：触发后自动 disable
      if (reminderData.repeatType === "once") {
        functions.logger.log(`🔔 One-time reminder ${reminderId} triggered, auto-disabling`);
        await db.collection("reminders").doc(reminderId).update({
          isActive: false
        });
        return;
      }

      // 重复提醒：创建下一个 schedule
      try {
        await createNextSchedule(reminderId, reminderData);
      } catch (error) {
        functions.logger.error(`❌ Error creating next schedule for ${reminderId}:`, error);
      }
    }

    // 🔧 处理 snooze schedule 触发后的情况
    if (beforeData.status === "pending" && afterData.status === "triggered" && afterData.isSnooze) {
      functions.logger.log(`⏰ Snooze schedule ${scheduleId} triggered, will create next regular schedule after user action`);
      // Note: 下一个 regular schedule 会在 snooze 被 dismiss 后由上面的逻辑创建
    }
  }
);

/**
 * ============================================================
 * SCHEDULED MONITORING FUNCTIONS
 * ============================================================
 */

/**
 * 每分钟检查并触发到期的 Schedules
 */
export const monitorReminderTriggers = onSchedule(
  {
    schedule: "every 1 minutes",
    timeZone: "Asia/Kuala_Lumpur",
  },
  async () => {
    try {
      const now = new Date();
      now.setSeconds(0, 0);

      const currentTime = admin.firestore.Timestamp.fromDate(now);

      functions.logger.log(`🔍 Checking schedules at Malaysia time: ${now.toISOString()}`);

      const dueSchedules = await db
        .collectionGroup("reminderSchedules")
        .where("status", "==", "pending")
        .where("triggerTime", "<=", currentTime)
        .get();

      functions.logger.log(`📊 Found ${dueSchedules.size} due schedules`);

      for (const scheduleDoc of dueSchedules.docs) {
        const scheduleId = scheduleDoc.id;
        const pathParts = scheduleDoc.ref.path.split("/");
        const reminderId = pathParts[1];

        try {
          await scheduleDoc.ref.update({
            status: "triggered",
            triggeredAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          functions.logger.log(`⏰ Triggered schedule ${scheduleId} for reminder ${reminderId}`);
        } catch (error) {
          functions.logger.error(`❌ Error triggering schedule ${scheduleId}:`, error);
          await scheduleDoc.ref.update({
            status: "failed",
            error: (error as Error).message,
            failedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (error) {
      functions.logger.error("❌ Error monitoring reminder triggers:", error);
    }
  }
);

/**
 * 每小时检查并停用过期的 Reminders
 */
export const checkExpiredReminders = onSchedule(
  {
    schedule: "every 1 hours",
    timeZone: "Asia/Kuala_Lumpur",
  },
  async () => {
    const now = admin.firestore.Timestamp.now();

    try {
      const expiredRemindersSnapshot = await db
        .collection("reminders")
        .where("isActive", "==", true)
        .where("endDate", "<", now)
        .get();

      if (expiredRemindersSnapshot.empty) {
        functions.logger.log("✅ No expired reminders found");
        return;
      }

      const batch = db.batch();
      expiredRemindersSnapshot.forEach((reminderDoc) => {
        functions.logger.log(`⏸️ Deactivating expired reminder: ${reminderDoc.id}`);
        batch.update(reminderDoc.ref, { isActive: false });
      });

      await batch.commit();
      functions.logger.log(`✅ Deactivated ${expiredRemindersSnapshot.size} expired reminders`);
    } catch (error) {
      functions.logger.error("❌ Error checking expired reminders:", error);
    }
  }
);

/**
 * 每天凌晨 2 点清理 30 天前的旧 Schedules
 */
export const cleanupOldSchedules = onSchedule(
  {
    schedule: "0 2 * * *",
    timeZone: "Asia/Kuala_Lumpur",
  },
  async () => {
    try {
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      const cutoffTime = admin.firestore.Timestamp.fromDate(thirtyDaysAgo);

      let totalDeleted = 0;

      const remindersSnapshot = await db.collection("reminders").get();

      for (const reminderDoc of remindersSnapshot.docs) {
        const reminderId = reminderDoc.id;

        const oldSchedules = await db
          .collection("reminders")
          .doc(reminderId)
          .collection("reminderSchedules")
          .where("triggerTime", "<", cutoffTime)
          .where("status", "in", ["triggered", "dismissed", "completed", "failed", "snoozed"])
          .get();

        if (!oldSchedules.empty) {
          const batch = db.batch();
          oldSchedules.docs.forEach((doc) => batch.delete(doc.ref));
          await batch.commit();

          totalDeleted += oldSchedules.size;
          functions.logger.log(`🗑️ Deleted ${oldSchedules.size} old schedules for reminder ${reminderId}`);
        }
      }

      functions.logger.log(`✅ Cleanup completed: ${totalDeleted} old schedules deleted`);
    } catch (error) {
      functions.logger.error("❌ Error cleaning up old schedules:", error);
    }
  }
);

/**
 * ============================================================
 * HELPER FUNCTIONS
 * ============================================================
 */

/**
 * 为 Reminder 创建下一个 Schedule
 * 🔧 增加了重复创建检测
 */
async function createNextSchedule(reminderId: string, reminderData: any) {
  const nowMalaysia = new Date(new Date().toLocaleString("en-US", { timeZone: "Asia/Kuala_Lumpur" }));

  if (reminderData.repeatType !== "once") {
    const endDateUTC = reminderData.endDate ? reminderData.endDate.toDate() : null;
    const endDate = endDateUTC ? new Date(endDateUTC.getTime() + 8 * 60 * 60 * 1000) : null;

    // 检查是否是占位符日期（2099）
    const isPlaceholderDate = endDate && endDate.getFullYear() === 2099;

    if (endDate && !isPlaceholderDate && nowMalaysia > endDate) {
      functions.logger.log(`⏰ Reminder ${reminderId} has expired, deactivating`);
      await db.collection("reminders").doc(reminderId).update({ isActive: false });
      return;
    }
  }

  const endDateUTC = reminderData.endDate ? reminderData.endDate.toDate() : null;
  const endDate = endDateUTC ? new Date(endDateUTC.getTime() + 8 * 60 * 60 * 1000) : null;

  if (endDate && nowMalaysia > endDate) {
    functions.logger.log(`⏰ Reminder ${reminderId} has expired, deactivating`);
    await db.collection("reminders").doc(reminderId).update({ isActive: false });
    return;
  }

  let nextTriggerTime: Date;

  const baseTimeUTC = reminderData.baseTime.toDate();
  const baseTimeMalaysia = new Date(baseTimeUTC.getTime() + 8 * 60 * 60 * 1000);

  if (reminderData.repeatType === "once") {
    const todayTrigger = new Date(nowMalaysia);
    todayTrigger.setHours(baseTimeMalaysia.getHours(), baseTimeMalaysia.getMinutes(), 0, 0);

    if (todayTrigger <= nowMalaysia) {
      todayTrigger.setDate(todayTrigger.getDate() + 1);
      functions.logger.log(`📅 Once reminder ${reminderId}: base time passed, scheduling for tomorrow`);
    }

    nextTriggerTime = todayTrigger;
  }
  else if (reminderData.repeatType === "custom days") {
    nextTriggerTime = calculateNextCustomDayTrigger(
      baseTimeMalaysia,
      reminderData.customDays,
      nowMalaysia
    );
  }
  else if (reminderData.repeatType === "fixed interval") {
    const intervalMinutes = reminderData.intervalTime || 5;

    if (baseTimeMalaysia > nowMalaysia) {
      nextTriggerTime = new Date(baseTimeMalaysia);
      functions.logger.log("⏰ Fixed interval: base time is in future, using it directly");
    } else {
      const diffMinutes = Math.floor((nowMalaysia.getTime() - baseTimeMalaysia.getTime()) / (1000 * 60));
      const intervalsPassed = Math.floor(diffMinutes / intervalMinutes);
      const nextIntervalCount = intervalsPassed + 1;

      nextTriggerTime = new Date(baseTimeMalaysia);
      nextTriggerTime.setMinutes(nextTriggerTime.getMinutes() + (nextIntervalCount * intervalMinutes));

      functions.logger.log(
        `⏰ Fixed interval: base time passed, calculated next trigger after ${nextIntervalCount} intervals`
      );
    }
  }
  else {
    functions.logger.error(`❌ Unknown repeat type: ${reminderData.repeatType}`);
    return;
  }

  nextTriggerTime.setSeconds(0, 0);

  if (endDate && nextTriggerTime > endDate) {
    functions.logger.log(`⏰ Next trigger beyond end date, deactivating reminder ${reminderId}`);
    await db.collection("reminders").doc(reminderId).update({ isActive: false });
    return;
  }

  const nextTriggerTimeUTC = new Date(nextTriggerTime.getTime() - 8 * 60 * 60 * 1000);

  // 🔧 再次检查是否已有相同时间的 pending schedule（防护双重创建）
  const existingSchedules = await db
    .collection("reminders")
    .doc(reminderId)
    .collection("reminderSchedules")
    .where("status", "==", "pending")
    .where("triggerTime", "==", admin.firestore.Timestamp.fromDate(nextTriggerTimeUTC))
    .where("isSnooze", "==", false) // 🔧 排除 snooze schedules
    .limit(1)
    .get();

  if (!existingSchedules.empty) {
    functions.logger.log(`⚠️ Schedule already exists for reminder ${reminderId} at ${nextTriggerTime.toISOString()}`);
    return;
  }

  const scheduleData = {
    scheduleId: "",
    triggerTime: admin.firestore.Timestamp.fromDate(nextTriggerTimeUTC),
    originalTime: admin.firestore.Timestamp.fromDate(nextTriggerTimeUTC),
    snoozeCount: 0,
    status: "pending",
    isSnooze: false, // 🔧 标记为非 snooze schedule
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  const scheduleRef = await db
    .collection("reminders")
    .doc(reminderId)
    .collection("reminderSchedules")
    .add(scheduleData);

  await scheduleRef.update({ scheduleId: scheduleRef.id });

  await db.collection("reminders").doc(reminderId).update({
    nextTriggerTime: admin.firestore.Timestamp.fromDate(nextTriggerTimeUTC),
  });

  functions.logger.log(
    `✅ Schedule created: Malaysia time=${nextTriggerTime.toISOString()}, UTC=${nextTriggerTimeUTC.toISOString()}`
  );
}

/**
 * 计算自定义天数的下一次触发时间
 */
function calculateNextCustomDayTrigger(baseTime: Date, customDays: string[], fromDate: Date): Date {
  const dayMap: { [key: string]: number } = {
    Sun: 0, Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6,
  };

  const selectedDayNumbers = customDays
    .map((day) => dayMap[day])
    .filter((num) => num !== undefined)
    .sort((a, b) => a - b);

  if (selectedDayNumbers.length === 0) {
    functions.logger.error("❌ No valid custom days provided");
    const tomorrow = new Date(fromDate);
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(baseTime.getHours(), baseTime.getMinutes(), 0, 0);
    return tomorrow;
  }

  const result = new Date(fromDate);
  result.setHours(baseTime.getHours(), baseTime.getMinutes(), 0, 0);

  // 检查今天是否符合
  if (result > fromDate && selectedDayNumbers.includes(result.getDay())) {
    return result;
  }

  // 找下一个符合的日期
  for (let i = 1; i <= 7; i++) {
    result.setDate(result.getDate() + 1);
    if (selectedDayNumbers.includes(result.getDay())) {
      return result;
    }
  }

  return result;
}

/**
 * 删除所有 pending 状态的 schedules
 */
async function deleteAllPendingSchedules(reminderId: string) {
  const schedulesSnapshot = await db
    .collection("reminders")
    .doc(reminderId)
    .collection("reminderSchedules")
    .where("status", "==", "pending")
    .get();

  if (schedulesSnapshot.empty) {
    functions.logger.log(`✅ No pending schedules to delete for reminder ${reminderId}`);
    return;
  }

  const batch = db.batch();
  schedulesSnapshot.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();

  functions.logger.log(`🗑️ Deleted ${schedulesSnapshot.size} pending schedules for reminder ${reminderId}`);
}

/**
 * 删除所有 schedules（用于删除 reminder 时）
 */
async function deleteAllSchedules(reminderId: string) {
  const schedulesSnapshot = await db
    .collection("reminders")
    .doc(reminderId)
    .collection("reminderSchedules")
    .get();

  if (schedulesSnapshot.empty) {
    functions.logger.log(`✅ No schedules to delete for reminder ${reminderId}`);
    return;
  }

  const batch = db.batch();
  schedulesSnapshot.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();

  functions.logger.log(`🗑️ Deleted ${schedulesSnapshot.size} total schedules for reminder ${reminderId}`);
}