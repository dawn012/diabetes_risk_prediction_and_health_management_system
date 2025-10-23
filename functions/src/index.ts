import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// 初始化 Firebase Admin（防止多次初始化）
if (admin.apps.length === 0) {
  admin.initializeApp();
}

// 导入其他文件的 Cloud Functions
import * as authentication from "./authentication";
import * as comments from "./comments";
import * as reminder from "./reminder/reminder";
import * as reminder_notification from "./reminder/reminder_notification";

// 导出 authentication 函数
export const {
  setDefaultUserRole,
  addUserWithRole
} = authentication;

// 导出 comments 函数
export const {
  updateReplyCountOnCreate,
  updateReplyCountOnDelete,
  deleteCommentAndReplies
} = comments;

// 导出 reminder 函数
export const {
  onReminderCreated,
  onReminderUpdated,
  onReminderDeleted,
  onScheduleProcessed,
  monitorReminderTriggers,
  checkExpiredReminders,
  cleanupOldSchedules
} = reminder;

// 导出 reminder_notification 函数
export const {
  onScheduleTriggered,
  handleSnoozeReminder,
  handleDismissReminder
} = reminder_notification;

// 其他独立函数
export const setAdminClaim = functions.https.onRequest(async (req, res) => {
  try {
    // 你可以通过 query 或 body 获取 uid
    const uid = req.query.uid as string || req.body.uid;
    if (!uid) {
      res.status(400).send("Missing UID");
      return;
    }

    // 设置 custom claims
    await admin.auth().setCustomUserClaims(uid, { role: "admin" });
    console.log(`Custom claim 'admin' set for user ${uid}`);

    // 标记 emailVerified
    await admin.auth().updateUser(uid, { emailVerified: true });
    console.log(`Email verified set for user ${uid}`);

    res.status(200).send(`User ${uid} updated: admin + emailVerified`);
  } catch (error) {
    console.error(error);
    res.status(500).send(error);
  }
});