import { Request, Response } from "express";
import * as admin from "firebase-admin";
import Stripe from "stripe";

const stripeSecret = process.env.STRIPE_SECRET_KEY;
if (!stripeSecret) throw new Error("STRIPE_SECRET not defined");
const stripe = new Stripe(stripeSecret, {apiVersion: "2024-06-20"} as any);

// ==================== Verify Subscription ====================
export const verifySubscription = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    // 1. Verify user identity
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith("Bearer ")) {
      res.status(401).json({error: "Unauthorized: Missing or invalid token"});
      return;
    }

    const idToken = authHeader.split("Bearer ")[1];
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const uid = decodedToken.uid;

    // 2. Get request parameters
    const { subscriptionId } = req.body;
    if (!subscriptionId) {
      res.status(400).json({error: "Missing subscriptionId"});
      return;
    }

    console.log(`Verifying subscription for user ${uid}, Subscription: ${subscriptionId}`);

    // 3. Retrieve subscription details from Stripe
    const subscription = await stripe.subscriptions.retrieve(subscriptionId, {
      expand: ["latest_invoice", "latest_invoice.payment_intent"]
    });

    console.log(`Subscription status: ${subscription.status}`);

    // 4. Check if subscription belongs to current user
    if (subscription.metadata.uid !== uid) {
      res.status(403).json({error: "Forbidden: Subscription does not belong to user"});
      return;
    }

    // 5. Get latest payment information - 正确处理展开的字段
    const latestInvoice = subscription.latest_invoice as Stripe.Invoice;
    let paymentIntent: Stripe.PaymentIntent | undefined;

    // 方法1：使用类型断言访问 payment_intent
    if (latestInvoice) {
      paymentIntent = (latestInvoice as any).payment_intent as Stripe.PaymentIntent;
    }

    // 方法2：或者使用更安全的方式检查
    // if (latestInvoice && 'payment_intent' in latestInvoice) {
    //   paymentIntent = (latestInvoice as any).payment_intent;
    // }

    // 6. Check database status
    const db = admin.firestore();
    const subscriptionDoc = await db.collection("userSubscriptions").doc(subscriptionId).get();
    let databaseStatus = null;

    if (subscriptionDoc.exists) {
      const subscriptionData = subscriptionDoc.data();
      databaseStatus = subscriptionData?.status;
      console.log(`Database status: ${databaseStatus}`);
    }

    // 7. 获取 period 信息 - 从 subscription items 中获取
    const firstItem = subscription.items.data[0];
    const currentPeriodStart = firstItem?.current_period_start;
    const currentPeriodEnd = firstItem?.current_period_end;

    // 8. Comprehensive status check
    const overallStatus = {
      subscriptionStatus: subscription.status,
      paymentStatus: paymentIntent?.status || "unknown",
      requiresAction: paymentIntent?.status === "requires_action",
      isActive: subscription.status === "active",
      isIncomplete: subscription.status === "incomplete",
      isPastDue: subscription.status === "past_due",
    };
    //
    //     // 9. If payment succeeded and subscription is active, update database
    //     if (subscription.status === "active" && (!subscriptionDoc.exists || databaseStatus !== "active")) {
    //       console.log(`Activating subscription in database for user ${uid}`);
    //
    //       // Check if user already has an active subscription
    //       const existingActiveQuery = await db.collection("userSubscriptions")
    //         .where("userId", "==", uid)
    //         .where("status", "==", "active")
    //         .limit(1)
    //         .get();
    //
    //       if (existingActiveQuery.empty) {
    //         const subscriptionData: any = {
    //           userId: uid,
    //           subscriptionId: subscription.id,
    //           planId: subscription.metadata.planId,
    //           status: "active",
    //           createdAt: admin.firestore.FieldValue.serverTimestamp(),
    //           updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    //         };
    //
    //         // 添加 period 信息 - 从 items 中获取
    //         if (currentPeriodStart) {
    //           subscriptionData.startDateTime = admin.firestore.Timestamp.fromMillis(currentPeriodStart * 1000);
    //         }
    //         if (currentPeriodEnd) {
    //           subscriptionData.endDateTime = admin.firestore.Timestamp.fromMillis(currentPeriodEnd * 1000);
    //         }
    //
    //         await db.collection("userSubscriptions").doc(subscriptionId).set(subscriptionData);
    //         console.log(`Subscription activated in database: ${subscriptionId}`);
    //       } else {
    //         console.log(`User ${uid} already has an active subscription`);
    //       }
    //     }

    // 10. Return subscription status information
    const responseData: any = {
      subscriptionId: subscription.id,
      ...overallStatus,
      databaseStatus: databaseStatus,
      planId: subscription.metadata.planId,
      paymentIntentId: paymentIntent?.id,
      paymentIntentStatus: paymentIntent?.status,
      invoiceStatus: latestInvoice?.status,
      clientSecret: paymentIntent?.client_secret,
      latestInvoiceId: latestInvoice?.id,
    };

    // 添加 period 信息到响应 - 从 items 中获取
    if (currentPeriodStart) {
      responseData.currentPeriodStart = currentPeriodStart;
    }
    if (currentPeriodEnd) {
      responseData.currentPeriodEnd = currentPeriodEnd;
    }

    res.json(responseData);

  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : "Unknown error";
    console.error("Error verifying subscription:", error);

    if (error instanceof Stripe.errors.StripeError) {
      res.status(400).json({
        error: "Stripe error",
        details: errorMessage,
        type: error.type,
      });
      return;
    }

    res.status(500).json({
      error: "Failed to verify subscription",
      details: errorMessage,
    });
  }
};