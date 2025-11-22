import * as functions from "firebase-functions";
import { onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { sendEmail } from "../utils/email/email_config";
import { generateManagerWelcomeEmail } from "../utils/email/email_templates";

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp();
}

// Create manager account using Admin SDK
export const createManager = onCall(async (request) => {
  // Check if the request is authenticated
  if (!request.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated to call this function."
    );
  }

  // Check if user has admin privileges
  const callerUid = request.auth.uid;
  const callerUser = await admin.auth().getUser(callerUid);
  const callerClaims = callerUser.customClaims || {};

  if (callerClaims.role !== "admin") {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only administrators can create managers."
    );
  }

  try {
    const { email, role, username } = request.data;

    // 只做基本验证
    if (!email || !role || !username) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Email, role and username are required."
      );
    }

    console.log(`Starting manager creation for email: ${email}`);

    // 1. Generate temporary password
    const tempPassword = generateTempPassword();
    console.log("Generated temporary password");

    // 2. Create user in Firebase Auth
    const userRecord = await admin.auth().createUser({
      email: email,
      emailVerified: false,
      password: tempPassword,
      disabled: false,
    });

    console.log(`User created successfully: ${userRecord.uid}`);

    // 3. Set custom claims for role
    await admin.auth().setCustomUserClaims(userRecord.uid, {
      role: role,
      isManager: true
    });

    console.log(`Custom claims set for role: ${role}`);

    // 4. Generate password reset link
    console.log(`Generating password reset link for: ${email}`);

    const passwordResetLink = await admin.auth().generatePasswordResetLink(email);

    console.log("Password reset link generated successfully");

    // 5. Send custom welcome email using your email system
    console.log(`Sending welcome email to: ${email}`);

    const emailContent = generateManagerWelcomeEmail(
      username,
      role,
      passwordResetLink
    );

    await sendEmail({
      to: email,
      subject: emailContent.subject,
      html: emailContent.html,
      text: emailContent.text,
    });

    console.log(`Welcome email sent successfully to: ${email}`);

    return {
      success: true,
      userId: userRecord.uid,
      message: "Manager user created successfully. Welcome email sent."
    };

  } catch (error: any) {
    console.error("Error creating manager:", error);

    // 简化错误处理
    if (error.code === "auth/email-already-exists") {
      throw new functions.https.HttpsError(
        "already-exists",
        "Email is already in use."
      );
    }

    throw new functions.https.HttpsError(
      "internal",
      "Failed to create manager: " + error.message
    );
  }
});

// Helper function to generate temporary password
function generateTempPassword(): string {
  const chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*";
  let password = "";

  for (let i = 0; i < 16; i++) {
    password += chars.charAt(Math.floor(Math.random() * chars.length));
  }

  return password;
}