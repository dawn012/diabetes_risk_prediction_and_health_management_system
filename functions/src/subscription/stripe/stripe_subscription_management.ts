import { Request, Response } from "express";
import * as admin from "firebase-admin";
import Stripe from "stripe";

const stripeSecret = process.env.STRIPE_SECRET_KEY;
if (!stripeSecret) throw new Error("STRIPE_SECRET not defined");
const stripe = new Stripe(stripeSecret, {apiVersion: "2024-06-20"} as any);

// ==================== Cancel Subscription (立即取消) ====================
export const cancelSubscription = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith("Bearer ")) {
      res.status(401).json({error: "Unauthorized: Missing or invalid token"});
      return;
    }

    const idToken = authHeader.split("Bearer ")[1];
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const uid = decodedToken.uid;

    const { subscriptionId } = req.body;

    if (!subscriptionId) {
      res.status(400).json({ error: "Missing subscriptionId" });
      return;
    }

    if (!uid) {
      res.status(401).json({ error: "Unauthorized" });
      return;
    }

    const db = admin.firestore();

    // 1. 验证订阅是否属于该用户
    const subscriptionDoc = await db
      .collection("userSubscriptions")
      .doc(subscriptionId)
      .get();

    if (!subscriptionDoc.exists) {
      res.status(404).json({ error: "Subscription not found" });
      return;
    }

    const subscriptionData = subscriptionDoc.data();
    if (subscriptionData?.userId !== uid) {
      res.status(403).json({ error: "Forbidden" });
      return;
    }

    // 2. 立即取消 Stripe 订阅
    await stripe.subscriptions.cancel(subscriptionId);

    // 3. Webhook 会自动处理 Firestore 更新
    console.log(`Subscription cancelled: ${subscriptionId} for user ${uid}`);

    res.json({
      success: true,
      message: "Subscription cancelled successfully",
    });
  } catch (error: any) {
    console.error("Error cancelling subscription:", error);
    res.status(500).json({ error: error.message });
  }
};

// ==================== Cancel Subscription at Period End ====================
export const cancelSubscriptionAtPeriodEnd = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith("Bearer ")) {
      res.status(401).json({error: "Unauthorized: Missing or invalid token"});
      return;
    }

    const idToken = authHeader.split("Bearer ")[1];
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const uid = decodedToken.uid;

    const { subscriptionId } = req.body;

    if (!subscriptionId) {
      res.status(400).json({ error: "Missing subscriptionId" });
      return;
    }

    if (!uid) {
      res.status(401).json({ error: "Unauthorized" });
      return;
    }

    const db = admin.firestore();

    // 1. 验证订阅
    const subscriptionDoc = await db
      .collection("userSubscriptions")
      .doc(subscriptionId)
      .get();

    if (!subscriptionDoc.exists) {
      res.status(404).json({ error: "Subscription not found" });
      return;
    }

    const subscriptionData = subscriptionDoc.data();
    if (subscriptionData?.userId !== uid) {
      res.status(403).json({ error: "Forbidden" });
      return;
    }

    // 2. 设置在周期结束时取消
    const stripeSubscription = await stripe.subscriptions.update(
      subscriptionId,
      {
        cancel_at_period_end: true,
      }
    );

    console.log(`Subscription set to cancel at period end: ${subscriptionId}`);

    res.json({
      success: true,
      message: "Subscription will cancel at period end",
      cancelAtPeriodEnd: stripeSubscription.cancel_at_period_end,
    });
  } catch (error: any) {
    console.error("Error cancelling subscription at period end:", error);
    res.status(500).json({ error: error.message });
  }
};

// ==================== Toggle Auto-Renew ====================
export const toggleAutoRenew = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith("Bearer ")) {
      res.status(401).json({error: "Unauthorized: Missing or invalid token"});
      return;
    }

    const idToken = authHeader.split("Bearer ")[1];
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const uid = decodedToken.uid;

    const { subscriptionId, autoRenew } = req.body;

    if (!subscriptionId || typeof autoRenew !== "boolean") {
      res.status(400).json({ error: "Missing or invalid parameters" });
      return;
    }

    if (!uid) {
      res.status(401).json({ error: "Unauthorized" });
      return;
    }

    const db = admin.firestore();

    // 1. 验证订阅
    const subscriptionDoc = await db
      .collection("userSubscriptions")
      .doc(subscriptionId)
      .get();

    if (!subscriptionDoc.exists) {
      res.status(404).json({ error: "Subscription not found" });
      return;
    }

    const subscriptionData = subscriptionDoc.data();
    if (subscriptionData?.userId !== uid) {
      res.status(403).json({ error: "Forbidden" });
      return;
    }

    // 2. 更新 Stripe 订阅的 cancel_at_period_end
    const stripeSubscription = await stripe.subscriptions.update(
      subscriptionId,
      {
        cancel_at_period_end: !autoRenew, // autoRenew=true 表示不在周期结束时取消
      }
    );

    // 3. Webhook 会处理 Firestore 更新
    console.log(`Auto-renew toggled: ${subscriptionId} -> ${autoRenew}`);

    res.json({
      success: true,
      message: `Auto-renew ${autoRenew ? "enabled" : "disabled"}`,
      autoRenew: autoRenew,
      cancelAt: stripeSubscription.cancel_at,
    });
  } catch (error: any) {
    console.error("Error toggling auto-renew:", error);
    res.status(500).json({ error: error.message });
  }
};

// ==================== Resume Subscription ====================
export const resumeSubscription = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith("Bearer ")) {
      res.status(401).json({error: "Unauthorized: Missing or invalid token"});
      return;
    }

    const idToken = authHeader.split("Bearer ")[1];
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const uid = decodedToken.uid;

    const { subscriptionId } = req.body;

    if (!subscriptionId) {
      res.status(400).json({ error: "Missing subscriptionId" });
      return;
    }

    if (!uid) {
      res.status(401).json({ error: "Unauthorized" });
      return;
    }

    const db = admin.firestore();

    // 1. 验证订阅
    const subscriptionDoc = await db
      .collection("userSubscriptions")
      .doc(subscriptionId)
      .get();

    if (!subscriptionDoc.exists) {
      res.status(404).json({ error: "Subscription not found" });
      return;
    }

    const subscriptionData = subscriptionDoc.data();
    if (subscriptionData?.userId !== uid) {
      res.status(403).json({ error: "Forbidden" });
      return;
    }

    // 2. 恢复订阅（取消周期结束取消）
    const stripeSubscription = await stripe.subscriptions.update(
      subscriptionId,
      {
        cancel_at_period_end: false,
      }
    );

    console.log(`Subscription resumed: ${subscriptionId}`);

    res.json({
      success: true,
      message: "Subscription resumed successfully",
      cancelAtPeriodEnd: stripeSubscription.cancel_at_period_end,
    });
  } catch (error: any) {
    console.error("Error resuming subscription:", error);
    res.status(500).json({ error: error.message });
  }
};