import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
// import { onBeforeUserSignedIn } from "firebase-functions/v2/identity";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as dotenv from "dotenv";

dotenv.config();

// 初始化 Firebase Admin（防止多次初始化）
if (admin.apps.length === 0) {
  admin.initializeApp();
}

// 导入其他文件的 Cloud Functions
import * as authentication from "./authentication";
import * as comments from "./comments";
import * as reminder from "./reminder/reminder";
import * as reminderNotification from "./reminder/reminder_notification";
import * as user from "./user/weight_sync";
import * as emailFunctions from "./user/send_email";
import * as manager from "./user/create_manager";
import {analyzeMealPhotos} from "./fatsecret/meal_analysis";

// 导出 authentication 函数
export const {
  setDefaultUserRole,
  addUserWithRole
} = authentication;

// 导出 comments 函数
export const {
//   updateReplyCountOnCreate,
//   updateReplyCountOnDelete,
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

// 导出 reminderNotification 函数
export const {
  onScheduleTriggered,
  handleSnoozeReminder,
  handleDismissReminder
} = reminderNotification;

export const {
  onHealthLogCreated,
  onHealthLogUpdated,
  onHealthLogDeleted
} = user;

// 导出邮件功能
export const {
  sendUserBannedEmail,
  sendUserRestoredEmail,
  sendBatchUserBannedEmails,
  sendBatchUserRestoredEmails,
  sendManagerRoleChangedEmail
} = emailFunctions;

export const {
  createManager
} = manager

export { analyzeMealPhotos };

// 从成就模块导入所有功能
export * from "./achievement";

// 导出 subscription 模块的 subscriptionApi
export { subscriptionApi, checkExpiringPayPalSubscriptionsSchedule } from "./subscription";

// 其他独立函数
// 手动设置用户角色的HTTP函数
export const setCustomRole = onCall(async (request) => {
  try {
    // 验证调用者是否是管理员
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    // 从 request.data 获取参数
    const { uid, role } = request.data;

    // 验证必需参数
    if (!uid || !role) {
      throw new HttpsError("invalid-argument", "Missing required fields: uid and role");
    }

    // 验证角色值
    const validRoles = [
      "user",
      "admin",
      "user manager",
      "community manager",
      "achievement manager",
    ];

    if (!validRoles.includes(role)) {
      throw new HttpsError(
        "invalid-argument",
        `Invalid role. Must be one of: ${validRoles.join(", ")}`
      );
    }

    console.log(`Setting role "${role}" for user: ${uid}`);

    // 只设置自定义声明
    await admin.auth().setCustomUserClaims(uid, { role });
    console.log(`Custom claim 'role: ${role}' set for user ${uid}`);

    return {
      success: true,
      message: `Role "${role}" set for user ${uid}`,
      uid: uid,
      role: role,
    };

  } catch (error) {
    console.error("Error setting custom claims:", error);
    throw new HttpsError("internal", `Error setting role: ${error instanceof Error ? error.message : "Unknown error"}`);
  }
});

// 用户自行验证邮箱的 Callable Function
export const selfVerifyEmail = onCall(async (request) => {
  try {
    // 验证调用者是否已登录
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    // 用户只能验证自己的邮箱
    const callerUid = request.auth.uid;

    console.log(`User ${callerUid} requesting self email verification`);

    // 1. 检查用户角色是否是 manager
    const userRecord = await admin.auth().getUser(callerUid);
    const userClaims = userRecord.customClaims as { role?: string } || {};
    const userRole = userClaims.role;

    // 只有 manager 角色可以自助验证
    if (!userRole || !userRole.includes("manager")) {
      throw new HttpsError(
        "permission-denied",
        "Only managers can self-verify email. Please contact administrator."
      );
    }

    // 2. 如果已经是验证状态，直接返回
    if (userRecord.emailVerified) {
      return {
        success: true,
        message: "Email is already verified",
        uid: callerUid,
        emailVerified: true,
      };
    }

    console.log(`Self-verifying email for manager: ${callerUid}`);

    // 3. 在 Authentication 中验证邮箱
    await admin.auth().updateUser(callerUid, {
      emailVerified: true,
    });
    console.log(`Email self-verified in Authentication for manager: ${callerUid}`);

    // 4. 在 Firestore 中更新验证状态
    await admin
      .firestore()
      .collection("users")
      .doc(callerUid)
      .update({
        isVerify: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    console.log(`Email self-verification updated in Firestore for manager: ${callerUid}`);

    return {
      success: true,
      message: "Email verified successfully",
      uid: callerUid,
      email: userRecord.email,
      emailVerified: true,
      verifiedAt: new Date().toISOString(),
    };

  } catch (error) {
    console.error("Error in self email verification:", error);

    if (error instanceof HttpsError) {
      throw error;
    }

    throw new HttpsError(
      "internal",
      `Error verifying email: ${error instanceof Error ? error.message : "Unknown error"}`
    );
  }
});

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
