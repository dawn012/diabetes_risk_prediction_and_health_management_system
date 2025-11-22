import { Request, Response } from "express";
import * as admin from "firebase-admin";
import Stripe from "stripe";
import {
  generateSubscriptionActivatedEmail,
  generatePaymentSuccessEmail,
  generatePaymentFailedEmail,
  generateSubscriptionCancelledEmail,
  generateExpirationReminderEmail,
} from "../../utils/email/email_templates";
import { sendEmail } from "../../utils/email/email_config";

const stripeSecret = process.env.STRIPE_SECRET_KEY;
if (!stripeSecret) throw new Error("STRIPE_SECRET not defined");
const stripe = new Stripe(stripeSecret, {apiVersion: "2024-06-20"} as any);

// ==================== Stripe Webhook Handler ====================
export const handleStripeWebhook = async (
  req: Request,
  res: Response
): Promise<void> => {
  const sig = req.headers["stripe-signature"] as string;
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET!;

  const rawBody = (req as any).rawBody as Buffer | string | undefined;

  let payload: Buffer | string;

  if (Buffer.isBuffer(rawBody)) {
    payload = rawBody;
  } else if (typeof rawBody === "string") {
    payload = rawBody;
  } else {
    console.warn("req.rawBody not available, using alternative approach");
    if (typeof req.body === "string") {
      payload = req.body;
    } else if (Buffer.isBuffer(req.body)) {
      payload = req.body;
    } else {
      payload = JSON.stringify(req.body);
    }
  }

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(payload, sig, webhookSecret);
  } catch (err) {
    console.error("Webhook signature verification failed:", err);
    res.status(400).send(`Webhook Error: ${err}`);
    return;
  }

  console.log(`Received webhook event: ${event.type}`);

  // Handle different event types
  switch (event.type) {
  case "invoice.created":
    await handleInvoiceCreated(event.data.object as Stripe.Invoice);
    break;
  case "invoice.payment_succeeded":
    await handleInvoicePaymentSucceeded(event.data.object as Stripe.Invoice);
    break;
  case "invoice.payment_failed":
    await handleInvoicePaymentFailed(event.data.object as Stripe.Invoice);
    break;
  case "customer.subscription.deleted":
    await handleSubscriptionDeleted(event.data.object as Stripe.Subscription);
    break;
  case "customer.subscription.updated":
    await handleSubscriptionUpdated(event.data.object as Stripe.Subscription);
    break;
  default:
    console.log(`Unhandled event type: ${event.type}`);
  }

  res.json({ received: true });
};

// 时间转换函数
function convertToUTC8(timestamp: number): number {
//   return timestamp * 1000 + (8 * 60 * 60 * 1000); // +8 小时
  return timestamp;
}

function convertToUTC8FromSeconds(seconds: number): number {
//   return seconds * 1000 + (8 * 60 * 60 * 1000); // +8 小时
  return seconds;
}

// 格式化日期函数
function formatDate(timestamp: number): string {
  return new Date(timestamp).toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric"
  });
}

function formatDateTime(timestamp: number): string {
  return new Date(timestamp).toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit"
  });
}

// 从 invoice 中提取 subscriptionId
function extractSubscriptionIdFromInvoice(invoice: Stripe.Invoice): string | null {
  const extInvoice = invoice as any;
  let subscriptionId: string | null = null;

  if (typeof extInvoice.subscription === "string") {
    subscriptionId = extInvoice.subscription;
  } else if (extInvoice.subscription && typeof extInvoice.subscription === "object") {
    subscriptionId = extInvoice.subscription.id;
  }

  if (!subscriptionId && invoice.lines.data.length > 0) {
    const lineItem = invoice.lines.data[0] as any;
    if (lineItem.parent?.subscription_item_details?.subscription) {
      subscriptionId = lineItem.parent.subscription_item_details.subscription;
    }
  }

  return subscriptionId;
}

// ==================== 处理发票创建 ====================
async function handleInvoiceCreated(invoice: Stripe.Invoice) {
  try {
    console.log(`Invoice created: ${invoice.id}, billing reason: ${invoice.billing_reason}`);

    if (invoice.billing_reason === "subscription_cycle") {
      console.log("This is an auto-renewal invoice, checking auto-renew settings");

      const shouldProceed = await checkStripeAutoRenew(invoice);
      if (!shouldProceed) {
        console.log("Auto-renew disabled, cancelling subscription and voiding invoice");
        await stripe.invoices.voidInvoice(invoice.id);
        console.log(`Invoice voided: ${invoice.id}`);
        return;
      }

      console.log(`✅ Auto-renew enabled, allowing invoice to proceed: ${invoice.id}`);
    }

  } catch (error) {
    console.error("❌ Error handling invoice created:", error);
  }
}

async function checkStripeAutoRenew(invoice: Stripe.Invoice): Promise<boolean> {
  try {
    const db = admin.firestore();
    const subscriptionId = extractSubscriptionIdFromInvoice(invoice);

    if (!subscriptionId) {
      console.log("❌ No subscription ID found for auto-renew check");
      return true;
    }

    const subscriptionDoc = await db.collection("userSubscriptions").doc(subscriptionId).get();

    if (!subscriptionDoc.exists) {
      console.log(`❌ Subscription not found for auto-renew check: ${subscriptionId}`);
      return true;
    }

    const subscriptionData = subscriptionDoc.data();
    const autoRenew = subscriptionData?.autoRenew;

    if (autoRenew === false) {
      console.log(`Auto-renew disabled for ${subscriptionId}, cancelling subscription`);

      await stripe.subscriptions.update(subscriptionId, {
        cancel_at_period_end: true
      });

      await subscriptionDoc.ref.update({
        status: "expired",
        updatedAt: Date.now(),
      });

      return false;
    }

    console.log(`✅ Auto-renew enabled for ${subscriptionId}, allowing payment`);
    return true;

  } catch (error) {
    console.error("❌ Error checking Stripe auto-renew:", error);
    return true;
  }
}

// ==================== Handle successful invoice payment ====================
async function handleInvoicePaymentSucceeded(invoice: Stripe.Invoice) {
  try {
    // 检测续订支付
    if (invoice.billing_reason === "subscription_cycle") {
      console.log("🔄 This is an auto-renewal payment");
      await handleAutoRenewPayment(invoice);
      return;
    }

    console.log(`Invoice payment succeeded: ${invoice.id}`);

    //     const extInvoice = invoice as any;
    const subscriptionId = extractSubscriptionIdFromInvoice(invoice);

    if (!subscriptionId) {
      console.log("❌ No subscription ID found in invoice or line items");
      return;
    }

    console.log(`✅ Processing subscription: ${subscriptionId}`);

    const subscription = await stripe.subscriptions.retrieve(subscriptionId);
    const lineItem = invoice.lines.data[0];
    const metadata = lineItem?.metadata || {};

    const uid = metadata.uid;
    const planId = metadata.planId;

    if (!uid || !planId) {
      console.log("❌ Missing uid or planId in metadata:", metadata);
      return;
    }

    console.log("⏱️ Waiting 2 seconds for Flutter to create pending record...");
    await new Promise(resolve => setTimeout(resolve, 2000));

    await processSuccessfulPayment(invoice, subscription, uid, planId, false);

  } catch (error) {
    console.error("❌ Error handling invoice payment succeeded:", error);
  }
}

// ==================== 处理自动续订支付 ====================
async function handleAutoRenewPayment(invoice: Stripe.Invoice) {
  try {
    console.log(`🔄 Processing auto-renewal payment for invoice: ${invoice.id}`);

    const subscriptionId = extractSubscriptionIdFromInvoice(invoice);

    if (!subscriptionId) {
      console.log("❌ No subscription ID found in renewal invoice");
      return;
    }

    const subscription = await stripe.subscriptions.retrieve(subscriptionId);
    const firstItem = subscription.items.data[0];

    if (!firstItem) {
      console.log("❌ No subscription items found for renewal");
      return;
    }

    const db = admin.firestore();
    const now = Date.now();

    // 1. 创建续订支付记录
    const transactionId = `stripe_${invoice.id}`;
    const existingPayment = await db.collection("payments").doc(transactionId).get();

    if (!existingPayment.exists) {
      const paymentData = {
        transactionId: transactionId,
        subscriptionId: subscriptionId,
        amount: invoice.amount_paid / 100,
        currency: invoice.currency.toUpperCase(),
        paymentMethod: "stripe",
        transactionDateTime: convertToUTC8(invoice.created),
        status: "succeeded",
        type: "renewal",
        createdAt: now,
      };
      await db.collection("payments").doc(transactionId).set(paymentData);
      console.log(`✅ Renewal payment recorded: ${transactionId}`);
    } else {
      console.log(`Renewal payment record already exists: ${transactionId}`);
    }

    // 2. 更新现有订阅的结束时间
    const subscriptionDoc = await db.collection("userSubscriptions")
      .doc(subscriptionId)
      .get();

    if (subscriptionDoc.exists) {
      const newEndDateTime = convertToUTC8FromSeconds(firstItem.current_period_end);

      await subscriptionDoc.ref.update({
        status: "active",
        endDateTime: newEndDateTime,
        updatedAt: now,
      });

      console.log(`🔄 Subscription auto-renewed: ${subscriptionId}, new end: ${new Date(newEndDateTime).toISOString()}`);

    } else {
      console.log(`⚠️ Subscription not found for renewal: ${subscriptionId}, creating new record`);

      const lineItem = invoice.lines.data[0];
      const metadata = lineItem?.metadata || {};
      const uid = metadata.uid;
      const planId = metadata.planId;

      if (uid && planId) {
        const subscriptionData = {
          subscriptionId: subscriptionId,
          userId: uid,
          subscriptionPlanId: planId,
          status: "active",
          autoRenew: !subscription.cancel_at_period_end,
          startDateTime: convertToUTC8FromSeconds(firstItem.current_period_start),
          endDateTime: convertToUTC8FromSeconds(firstItem.current_period_end),
          createdAt: now,
          updatedAt: now,
        };

        await db.collection("userSubscriptions").doc(subscriptionId).set(subscriptionData);
        console.log(`✅ New subscription record created for renewal: ${subscriptionId}`);
      }
    }

  } catch (error) {
    console.error("❌ Error handling auto-renewal payment:", error);
  }
}

// ==================== 处理成功支付 ====================
async function processSuccessfulPayment(
  invoice: Stripe.Invoice,
  subscription: Stripe.Subscription,
  uid: string,
  planId: string,
  isRenewal: boolean
) {
  try {
    const db = admin.firestore();

    // 获取用户信息
    const userDoc = await db.collection("users").doc(uid).get();
    const userData = userDoc.data();
    const userEmail = userData?.email;
    const userName = userData?.username || "User";

    // 获取 subscription plan 信息
    const planDoc = await db.collection("subscriptionPlans").doc(planId).get();
    if (!planDoc.exists) {
      console.error(`Plan not found: ${planId}`);
      return;
    }

    const planData = planDoc.data();
    if (!planData) {
      console.error(`Plan data not found for: ${planId}`);
      return;
    }

    const firstItem = subscription.items.data[0];
    const currentPeriodStart = firstItem?.current_period_start;
    const currentPeriodEnd = firstItem?.current_period_end;
    const now = Date.now();

    const transactionId = `stripe_${invoice.id}`;

    // ✅ 1. 创建唯一的 payment record
    const existingPayment = await db.collection("payments").doc(transactionId).get();

    if (!existingPayment.exists) {
      const paymentData = {
        transactionId: transactionId,
        subscriptionId: subscription.id,
        amount: invoice.amount_paid / 100,
        currency: invoice.currency.toUpperCase(),
        paymentMethod: "stripe",
        transactionDateTime: convertToUTC8(invoice.created),
        status: "succeeded",
        createdAt: now,
      };
      await db.collection("payments").doc(transactionId).set(paymentData);
      console.log(`✅ Payment record created: ${transactionId}`);
    } else {
      console.log(`Payment record already exists: ${transactionId}`);
    }

    // ✅ 2. 更新 subscription
    const subscriptionDoc = await db.collection("userSubscriptions")
      .doc(subscription.id)
      .get();

    const startDateTime = currentPeriodStart ? convertToUTC8FromSeconds(currentPeriodStart) : now;
    const endDateTime = currentPeriodEnd ? convertToUTC8FromSeconds(currentPeriodEnd) : now + (planData.durationDays * 24 * 60 * 60 * 1000);

    if (subscriptionDoc.exists) {
      await subscriptionDoc.ref.update({
        status: "active",
        autoRenew: false,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        updatedAt: now,
      });
      console.log(`✅ Subscription updated: pending → active (${subscription.id})`);
    } else {
      console.log(`⚠️ No pending record found, creating new subscription: ${subscription.id}`);

      const subscriptionData = {
        subscriptionId: subscription.id,
        userId: uid,
        subscriptionPlanId: planId,
        status: "active",
        autoRenew: false,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        createdAt: now,
        updatedAt: now,
      };

      await db.collection("userSubscriptions").doc(subscription.id).set(subscriptionData);
      console.log(`✅ New subscription created: ${subscription.id}`);
    }

    // ✅ 3. 发送邮件
    if (userEmail) {
      try {
        // 📧 1. Subscription Activated Email (仅新订阅)
        if (!isRenewal) {
          const activatedEmail = generateSubscriptionActivatedEmail(
            userName,
            planData.planName,
            formatDate(startDateTime),
            formatDate(endDateTime),
            subscription.id
          );

          await sendEmail({
            to: userEmail,
            subject: activatedEmail.subject,
            html: activatedEmail.html,
            text: activatedEmail.text
          });

          console.log(`✅ Subscription activated email sent to: ${userEmail}`);
        }

        // 📧 2. Payment Success Email (所有支付)
        const nextBillingDate = formatDate(endDateTime);
        const receiptEmail = generatePaymentSuccessEmail(
          userName,
          planData.planName,
          invoice.amount_paid / 100,
          formatDateTime(convertToUTC8(invoice.created)),
          nextBillingDate,
          transactionId,
          isRenewal
        );

        await sendEmail({
          to: userEmail,
          subject: receiptEmail.subject,
          html: receiptEmail.html,
          text: receiptEmail.text
        });

        console.log(`✅ Payment receipt email sent to: ${userEmail}`);

      } catch (emailError) {
        console.error("❌ Error sending email:", emailError);
      }
    }

  } catch (error) {
    console.error("Error processing successful payment:", error);
  }
}

// ==================== Handle failed invoice payment ====================
async function handleInvoicePaymentFailed(invoice: Stripe.Invoice) {
  try {
    console.log(`Invoice payment failed: ${invoice.id}`);

    const subscriptionId = (invoice as any).subscription as string;
    if (!subscriptionId) {
      console.log("No subscription ID found in invoice");
      return;
    }

    const subscription = await stripe.subscriptions.retrieve(subscriptionId);
    const lineItem = invoice.lines.data[0];
    const metadata = lineItem?.metadata || {};

    const uid = metadata.uid;
    const planId = metadata.planId;

    if (!uid || !planId) {
      console.log("Missing uid or planId in metadata:", metadata);
      return;
    }

    await processFailedPayment(invoice, subscription, uid, planId);

  } catch (error) {
    console.error("Error handling invoice payment failed:", error);
  }
}

// ==================== 处理失败支付 ====================
async function processFailedPayment(
  invoice: Stripe.Invoice,
  subscription: Stripe.Subscription,
  uid: string,
  planId: string
) {
  try {
    const db = admin.firestore();

    // 获取用户信息
    const userDoc = await db.collection("users").doc(uid).get();
    const userData = userDoc.data();
    const userEmail = userData?.email;
    const userName = userData?.username || "User";

    const planDoc = await db.collection("subscriptionPlans").doc(planId).get();
    if (!planDoc.exists) {
      console.error(`Plan not found: ${planId}`);
      return;
    }

    const planData = planDoc.data();
    if (!planData) {
      console.error(`Plan data not found for: ${planId}`);
      return;
    }

    const now = Date.now();
    const transactionId = `stripe_${invoice.id}`;

    // 创建失败支付记录
    const existingPayment = await db.collection("payments").doc(transactionId).get();

    if (!existingPayment.exists) {
      const paymentData = {
        transactionId: transactionId,
        subscriptionId: subscription.id,
        amount: invoice.amount_due / 100,
        currency: invoice.currency.toUpperCase(),
        paymentMethod: "stripe",
        transactionDateTime: convertToUTC8(invoice.created),
        status: "failed",
        createdAt: now,
      };
      await db.collection("payments").doc(transactionId).set(paymentData);
    }

    // 更新订阅状态
    const subscriptionDoc = await db.collection("userSubscriptions")
      .doc(subscription.id)
      .get();

    if (subscriptionDoc.exists) {
      await subscriptionDoc.ref.update({
        status: "failed",
        autoRenew: false,
        updatedAt: now,
      });
      console.log(`Subscription updated to failed: ${subscription.id}`);
    } else {
      const subscriptionData = {
        subscriptionId: subscription.id,
        userId: uid,
        subscriptionPlanId: planId,
        status: "failed",
        autoRenew: false,
        startDateTime: now,
        endDateTime: now + (planData.durationDays * 24 * 60 * 60 * 1000),
        createdAt: now,
        updatedAt: now,
      };

      await db.collection("userSubscriptions").doc(subscription.id).set(subscriptionData);
      console.log(`Failed subscription recorded: ${subscription.id}`);
    }

    // 📧 发送支付失败邮件
    if (userEmail) {
      try {
        // 获取失败原因
        const failureReason = invoice.last_finalization_error?.message ||
                             "Payment could not be processed. Please check your payment method.";

        // Stripe 通常会自动重试，下次重试时间
        const retryDate = formatDate(Date.now() + (3 * 24 * 60 * 60 * 1000)); // 3天后

        const failedEmail = generatePaymentFailedEmail(
          userName,
          planData.planName,
          invoice.amount_due / 100,
          failureReason,
          retryDate,
          subscription.id
        );

        await sendEmail({
          to: userEmail,
          subject: failedEmail.subject,
          html: failedEmail.html,
          text: failedEmail.text
        });

        console.log(`✅ Payment failed email sent to: ${userEmail}`);
      } catch (emailError) {
        console.error("❌ Error sending payment failed email:", emailError);
      }
    }

  } catch (error) {
    console.error("Error processing failed payment:", error);
  }
}

// ==================== Handle subscription deletion/cancellation ====================
async function handleSubscriptionDeleted(subscription: Stripe.Subscription) {
  try {
    console.log(`Subscription deleted: ${subscription.id}`);

    const db = admin.firestore();

    const subscriptionQuery = await db.collection("userSubscriptions")
      .where("subscriptionId", "==", subscription.id)
      .limit(1)
      .get();

    if (!subscriptionQuery.empty) {
      const subscriptionDoc = subscriptionQuery.docs[0];
      const subscriptionData = subscriptionDoc.data();

      await subscriptionDoc.ref.update({
        status: "cancelled",
        autoRenew: false,
        cancelAt: Date.now(),
      });
      console.log(`Subscription cancelled in Firestore: ${subscription.id}`);

      // 📧 发送取消邮件
      try {
        const userDoc = await db.collection("users").doc(subscriptionData.userId).get();
        const userData = userDoc.data();

        if (userData?.email) {
          const planDoc = await db.collection("subscriptionPlans").doc(subscriptionData.subscriptionPlanId).get();
          const planData = planDoc.data();

          if (planData) {
            const endDateTime = subscriptionData.endDateTime || Date.now();
            const remainingDays = Math.max(0, Math.ceil((endDateTime - Date.now()) / (24 * 60 * 60 * 1000)));

            const cancelledEmail = generateSubscriptionCancelledEmail(
              userData.username || "User",
              planData.planName,
              formatDate(endDateTime),
              remainingDays,
              subscription.id
            );

            await sendEmail({
              to: userData.email,
              subject: cancelledEmail.subject,
              html: cancelledEmail.html,
              text: cancelledEmail.text
            });

            console.log(`✅ Subscription cancelled email sent to: ${userData.email}`);
          }
        }
      } catch (emailError) {
        console.error("❌ Error sending cancellation email:", emailError);
      }
    }
  } catch (error) {
    console.error("Error handling subscription deleted:", error);
  }
}

// ==================== Handle subscription updates ====================
async function handleSubscriptionUpdated(subscription: Stripe.Subscription) {
  try {
    console.log(`Subscription updated: ${subscription.id}, Status: ${subscription.status}`);

    const db = admin.firestore();
    const firstItem = subscription.items.data[0];
    const currentPeriodStart = firstItem?.current_period_start;
    const currentPeriodEnd = firstItem?.current_period_end;

    const subscriptionQuery = await db.collection("userSubscriptions")
      .where("subscriptionId", "==", subscription.id)
      .limit(1)
      .get();

    if (!subscriptionQuery.empty) {
      const updateData: any = {
        status: subscription.status,
        autoRenew: !subscription.cancel_at_period_end,
        updatedAt: Date.now(),
      };

      if (currentPeriodStart) {
        updateData.startDateTime = convertToUTC8FromSeconds(currentPeriodStart);
      }
      if (currentPeriodEnd) {
        updateData.endDateTime = convertToUTC8FromSeconds(currentPeriodEnd);
      }

      await subscriptionQuery.docs[0].ref.update(updateData);
      console.log(`Subscription updated: ${subscription.id}, Status: ${subscription.status}, AutoRenew: ${updateData.autoRenew}`);
    }

  } catch (error) {
    console.error("Error handling subscription updated:", error);
  }
}

// ==================== Scheduled Function: Check Expired Subscriptions ====================
export const checkExpiredSubscriptions = async (): Promise<void> => {
  try {
    const db = admin.firestore();
    const now = Date.now();
    console.log("Checking for expired subscriptions...");

    const expiredQuery = await db.collection("userSubscriptions")
      .where("status", "==", "active")
      .where("endDateTime", "<", now)
      .where("autoRenew", "==", false)
      .get();

    if (expiredQuery.empty) {
      console.log("No expired subscriptions found");
      return;
    }

    const batch = db.batch();
    expiredQuery.docs.forEach(doc => {
      batch.update(doc.ref, {
        status: "expired",
        updatedAt: Date.now(),
      });
    });

    await batch.commit();
    console.log(`Expired ${expiredQuery.size} subscriptions`);
  } catch (error) {
    console.error("Error checking expired subscriptions:", error);
  }
};

// ==================== Scheduled Function: Check Expiring Subscriptions (发送提醒邮件) ====================
export const checkExpiringSubscriptions = async (): Promise<void> => {
  try {
    const db = admin.firestore();
    const now = Date.now();
    console.log("🔔 Checking for expiring subscriptions...");

    // 检查即将到期的订阅（3天内和1天内）
    const threeDaysFromNow = now + (3 * 24 * 60 * 60 * 1000);

    // 查询即将到期的订阅（active状态，autoRenew为false，endDateTime在未来3天内）
    const expiringQuery = await db.collection("userSubscriptions")
      .where("status", "==", "active")
      .where("autoRenew", "==", false)
      .where("endDateTime", ">", now)
      .where("endDateTime", "<=", threeDaysFromNow)
      .get();

    if (expiringQuery.empty) {
      console.log("No expiring subscriptions found");
      return;
    }

    console.log(`Found ${expiringQuery.size} expiring subscriptions`);

    for (const doc of expiringQuery.docs) {
      const subscriptionData = doc.data();
      const endDateTime = subscriptionData.endDateTime;
      const daysUntilExpiry = Math.ceil((endDateTime - now) / (24 * 60 * 60 * 1000));

      // 检查是否已发送过提醒邮件
      const reminderKey = daysUntilExpiry <= 1 ? "reminder1day" : "reminder3days";
      const lastReminderSent = subscriptionData[reminderKey];

      // 如果已经发送过该提醒，跳过
      if (lastReminderSent) {
        console.log(`Reminder already sent for ${doc.id} (${daysUntilExpiry} days)`);
        continue;
      }

      try {
        // 获取用户信息
        const userDoc = await db.collection("users").doc(subscriptionData.userId).get();
        const userData = userDoc.data();

        if (!userData?.email) {
          console.log(`No email found for user: ${subscriptionData.userId}`);
          continue;
        }

        // 获取计划信息
        const planDoc = await db.collection("subscriptionPlans").doc(subscriptionData.subscriptionPlanId).get();
        const planData = planDoc.data();

        if (!planData) {
          console.log(`Plan not found: ${subscriptionData.subscriptionPlanId}`);
          continue;
        }

        // 📧 发送到期提醒邮件
        const reminderEmail = generateExpirationReminderEmail(
          userData.username || "User",
          planData.planName,
          formatDate(endDateTime),
          daysUntilExpiry,
          false, // hasAutoRenew = false
          doc.id
        );

        await sendEmail({
          to: userData.email,
          subject: reminderEmail.subject,
          html: reminderEmail.html,
          text: reminderEmail.text
        });

        // 更新提醒状态，避免重复发送
        await doc.ref.update({
          [reminderKey]: Date.now()
        });

        console.log(`✅ Expiration reminder sent to: ${userData.email} (${daysUntilExpiry} days until expiry)`);

      } catch (emailError) {
        console.error(`❌ Error sending expiration reminder for ${doc.id}:`, emailError);
      }
    }

    console.log("✅ Expiring subscriptions check completed");

  } catch (error) {
    console.error("❌ Error checking expiring subscriptions:", error);
  }
};
