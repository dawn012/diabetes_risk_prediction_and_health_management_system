import * as functions from "firebase-functions/v1"; // 明确使用 V1
import * as admin from "firebase-admin";

// 初始化 Admin SDK
if (!admin.apps.length) {
  admin.initializeApp();
}

// 用户注册默认 role - 使用 V1 Auth 触发器
export const setDefaultUserRole = functions.auth.user().onCreate(async (user: admin.auth.UserRecord) => {
  try {
    // 检查用户是否已经有 role
    const userRecord = await admin.auth().getUser(user.uid);
    const currentClaims = userRecord.customClaims || {};

    if (!currentClaims.role) {
      await admin.auth().setCustomUserClaims(user.uid, { role: "user" });
      functions.logger.info(`Set default 'user' role for new user: ${user.uid}`);
    } else {
      functions.logger.info(`User ${user.uid} already has role: ${currentClaims.role}`);
    }
  } catch (error) {
    functions.logger.error(`Error setting claims for user ${user.uid}:`, error);
  }
});

// 用户删除触发器 - 使用 V1
export const onUserDeleted = functions.auth.user().onDelete(async (user: admin.auth.UserRecord) => {
  try {
    // 这里可以清理用户相关的数据，比如 Firestore 中的用户文档
    const db = admin.firestore();
    await db.collection("users").doc(user.uid).delete();
    functions.logger.info(`Cleaned up data for deleted user: ${user.uid}`);
  } catch (error) {
    functions.logger.error(`Error cleaning up data for user ${user.uid}:`, error);
  }
});

// 定义请求数据类型
interface AddUserRoleRequest {
  uid: string;
  role: string;
}

// 管理员分配角色 - 使用 V1 HTTP 触发器
export const addUserWithRole = functions.https.onCall(async (data: AddUserRoleRequest, context: functions.https.CallableContext) => {
  const { uid, role } = data;

  // 检查认证和管理员权限
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  // 检查管理员权限
  const customClaims = context.auth.token as any;
  if (!customClaims.role || customClaims.role !== "admin") {
    throw new functions.https.HttpsError(
      "permission-denied",
      "You do not have permission to assign this role"
    );
  }

  // 验证角色值
  const validRoles = ["user", "admin"];
  if (!validRoles.includes(role)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `Invalid role: ${role}. Valid roles are: ${validRoles.join(", ")}`
    );
  }

  try {
    await admin.auth().setCustomUserClaims(uid, { role });
    functions.logger.info(`Role ${role} set for user ${uid} by admin ${context.auth.uid}`);
    return {
      success: true,
      message: `Role ${role} set for user ${uid}`
    };
  } catch (error) {
    functions.logger.error(`Error setting role for user ${uid}:`, error);
    throw new functions.https.HttpsError(
      "internal",
      "Unable to set user role"
    );
  }
});
