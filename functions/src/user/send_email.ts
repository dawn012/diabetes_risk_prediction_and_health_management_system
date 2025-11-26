import * as functions from "firebase-functions";
import { onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { sendEmail } from "../utils/email/email_config";
import {
  generateUserBannedEmail,
  generateUserRestoredFromBanEmail,
  generateUserRestoredFromInactiveEmail,
  generateManagerRoleChangedEmail
} from "../utils/email/email_templates";

// Initialize Firebase Admin if not already initialize
if (!admin.apps.length) {
  admin.initializeApp();
}

// 1️⃣ Send email when user is banned
export const sendUserBannedEmail = onCall(async (request) => {
  // Check if the request is authenticated
  if (!request.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated to call this function."
    );
  }

  // Check if user has admin privileges
  const callerUid = request.auth.uid;
  const callerDoc = await admin
    .firestore()
    .collection("users")
    .doc(callerUid)
    .get();
  const callerRole = callerDoc.data()?.userType?.toLowerCase();

  if (!["admin", "user manager"].includes(callerRole)) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "User does not have permission to perform this action."
    );
  }

  try {
    const { userId, banReason } = request.data;

    if (!userId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "userId is required"
      );
    }

    // Get user data
    const userDoc = await admin
      .firestore()
      .collection("users")
      .doc(userId)
      .get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }

    const userData = userDoc.data();
    if (!userData?.email) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "User email not found"
      );
    }

    // Generate email
    const emailContent = generateUserBannedEmail(
      userData.username || "User",
      banReason
    );

    // Send email
    await sendEmail({
      to: userData.email,
      subject: emailContent.subject,
      html: emailContent.html,
      text: emailContent.text,
    });

    return { success: true, message: "Email sent successfully" };
  } catch (error) {
    console.error("Error sending banned email:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to send email",
      error
    );
  }
});

// 2️⃣ Send email when user is restored from ban
export const sendUserRestoredEmail = onCall(async (request) => {
  // Check if the request is authenticated
  if (!request.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated to call this function."
    );
  }

  // Check if user has admin privileges
  const callerUid = request.auth.uid;
  const callerDoc = await admin
    .firestore()
    .collection("users")
    .doc(callerUid)
    .get();
  const callerRole = callerDoc.data()?.userType?.toLowerCase();
  const callerName = callerDoc.data()?.username || "an administrator";

  if (!["admin", "user manager"].includes(callerRole)) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "User does not have permission to perform this action."
    );
  }

  try {
    const { userId, wasInactive } = request.data;

    if (!userId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "userId is required"
      );
    }

    // Get user data
    const userDoc = await admin
      .firestore()
      .collection("users")
      .doc(userId)
      .get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }

    const userData = userDoc.data();
    if (!userData?.email) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "User email not found"
      );
    }

    // Generate appropriate email based on restore type
    const emailContent = wasInactive
      ? generateUserRestoredFromInactiveEmail(
        userData.username || "User",
        callerName
      )
      : generateUserRestoredFromBanEmail(
        userData.username || "User",
        callerName
      );

    // Send email
    await sendEmail({
      to: userData.email,
      subject: emailContent.subject,
      html: emailContent.html,
      text: emailContent.text,
    });

    return { success: true, message: "Email sent successfully" };
  } catch (error) {
    console.error("Error sending restored email:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to send email",
      error
    );
  }
});

// 3️⃣ Batch send banned emails
export const sendBatchUserBannedEmails = onCall(async (request) => {
  // Check if the request is authenticated
  if (!request.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated to call this function."
    );
  }

  // Check if user has admin privileges
  const callerUid = request.auth.uid;
  const callerDoc = await admin
    .firestore()
    .collection("users")
    .doc(callerUid)
    .get();
  const callerRole = callerDoc.data()?.userType?.toLowerCase();

  if (!["admin", "user manager"].includes(callerRole)) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "User does not have permission to perform this action."
    );
  }

  try {
    const { userIds, banReason } = request.data;

    if (!userIds || !Array.isArray(userIds) || userIds.length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "userIds array is required"
      );
    }

    const results = await Promise.allSettled(
      userIds.map(async (userId: string) => {
        const userDoc = await admin
          .firestore()
          .collection("users")
          .doc(userId)
          .get();

        if (!userDoc.exists) {
          throw new Error(`User ${userId} not found`);
        }

        const userData = userDoc.data();
        if (!userData?.email) {
          throw new Error(`User ${userId} has no email`);
        }

        const emailContent = generateUserBannedEmail(
          userData.username || "User",
          banReason
        );

        await sendEmail({
          to: userData.email,
          subject: emailContent.subject,
          html: emailContent.html,
          text: emailContent.text,
        });

        return { userId, success: true };
      })
    );

    const succeeded = results.filter((r) => r.status === "fulfilled").length;
    const failed = results.filter((r) => r.status === "rejected").length;

    return {
      success: true,
      message: `Sent ${succeeded} emails successfully, ${failed} failed`,
      succeeded,
      failed,
    };
  } catch (error) {
    console.error("Error sending batch banned emails:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to send batch emails",
      error
    );
  }
});

// 4️⃣ Batch send restored emails
export const sendBatchUserRestoredEmails = onCall(async (request) => {
  // Check if the request is authenticated
  if (!request.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated to call this function."
    );
  }

  // Check if user has admin privileges
  const callerUid = request.auth.uid;
  const callerDoc = await admin
    .firestore()
    .collection("users")
    .doc(callerUid)
    .get();
  const callerRole = callerDoc.data()?.userType?.toLowerCase();
  const callerName = callerDoc.data()?.username || "an administrator";

  if (!["admin", "user manager"].includes(callerRole)) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "User does not have permission to perform this action."
    );
  }

  try {
    const { userIds, wasInactive } = request.data;

    if (!userIds || !Array.isArray(userIds) || userIds.length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "userIds array is required"
      );
    }

    const results = await Promise.allSettled(
      userIds.map(async (userId: string) => {
        const userDoc = await admin
          .firestore()
          .collection("users")
          .doc(userId)
          .get();

        if (!userDoc.exists) {
          throw new Error(`User ${userId} not found`);
        }

        const userData = userDoc.data();
        if (!userData?.email) {
          throw new Error(`User ${userId} has no email`);
        }

        const emailContent = wasInactive
          ? generateUserRestoredFromInactiveEmail(
            userData.username || "User",
            callerName
          )
          : generateUserRestoredFromBanEmail(
            userData.username || "User",
            callerName
          );

        await sendEmail({
          to: userData.email,
          subject: emailContent.subject,
          html: emailContent.html,
          text: emailContent.text,
        });

        return { userId, success: true };
      })
    );

    const succeeded = results.filter((r) => r.status === "fulfilled").length;
    const failed = results.filter((r) => r.status === "rejected").length;

    return {
      success: true,
      message: `Sent ${succeeded} emails successfully, ${failed} failed`,
      succeeded,
      failed,
    };
  } catch (error) {
    console.error("Error sending batch restored emails:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to send batch emails",
      error
    );
  }
});

// 5️⃣ Send email when manager role is changed
export const sendManagerRoleChangedEmail = onCall(async (request) => {
  // Check if the request is authenticated
  if (!request.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated to call this function."
    );
  }

  // Check if user has admin privileges
  const callerUid = request.auth.uid;
  const callerDoc = await admin
    .firestore()
    .collection("users")
    .doc(callerUid)
    .get();
  const callerRole = callerDoc.data()?.userType?.toLowerCase();
  const callerName = callerDoc.data()?.username || "an administrator";

  if (!["admin"].includes(callerRole)) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only administrators can change manager roles."
    );
  }

  try {
    const { userId, oldRole, newRole } = request.data;

    if (!userId || !oldRole || !newRole) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "userId, oldRole, and newRole are required"
      );
    }

    // Get user data
    const userDoc = await admin
      .firestore()
      .collection("users")
      .doc(userId)
      .get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }

    const userData = userDoc.data();
    if (!userData?.email) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "User email not found"
      );
    }

    // Generate email
    const emailContent = generateManagerRoleChangedEmail(
      userData.username || "Manager",
      oldRole,
      newRole,
      callerName
    );

    // Send email
    await sendEmail({
      to: userData.email,
      subject: emailContent.subject,
      html: emailContent.html,
      text: emailContent.text,
    });

    return { success: true, message: "Role change email sent successfully" };
  } catch (error) {
    console.error("Error sending role change email:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to send role change email",
      error
    );
  }
});