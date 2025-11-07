import * as functions from "firebase-functions";
import { onSchedule } from "firebase-functions/v2/scheduler";
import express from "express";
import cors from "cors";

// Stripe Import
import { createSubscription } from "./stripe/stripe_payment_intent";
import { verifySubscription } from "./stripe/verify_stripe_subscription";
import {
  cancelSubscription,
  cancelSubscriptionAtPeriodEnd,
  toggleAutoRenew,
  resumeSubscription
} from "./stripe/stripe_subscription_management";
import { handleStripeWebhook } from "./stripe/stripe_webhook";

// PayPal Import
import { createPayPalSubscription } from "./paypal/paypal_order";
import { verifyPayPalSubscription } from "./paypal/verify_paypal_subscription";
import { cancelPayPalSubscription } from "./paypal/paypal_subscription_management";
import { handlePayPalWebhook } from "./paypal/paypal_webhook";

const app = express();
app.use(cors({origin: true}));

// ==================== Webhook 路由（必须在 express.json() 之前）====================

app.post("/stripeWebhook",
  express.raw({type: "application/json"}),
  handleStripeWebhook
);

app.post("/paypalWebhook",
  express.json(),
  handlePayPalWebhook
);

// ==================== 其他路由使用 JSON 解析 ====================

app.use(express.json());

// Stripe 路由
app.post("/createSubscription", createSubscription);
app.post("/verifySubscription", verifySubscription);
app.post("/cancelSubscription", cancelSubscription);
app.post("/cancelSubscriptionAtPeriodEnd", cancelSubscriptionAtPeriodEnd);
app.post("/toggleAutoRenew", toggleAutoRenew);
app.post("/resumeSubscription", resumeSubscription);

// PayPal 路由
app.post("/createPayPalSubscription", createPayPalSubscription);
app.post("/verifyPayPalSubscription", verifyPayPalSubscription);
app.post("/cancelPayPalSubscription", cancelPayPalSubscription);

// 健康检查路由
app.get("/health", (req, res) => {
  res.json({ status: "ok", service: "subscription-api" });
});

// 根路由
app.get("/", (req, res) => {
  res.json({
    message: "Subscription API",
    version: "1.0.0",
    routes: [
      // Stripe
      "POST /createSubscription",
      "POST /verifySubscription",
      "POST /cancelSubscription",
      "POST /cancelSubscriptionAtPeriodEnd",
      "POST /toggleAutoRenew",
      "POST /resumeSubscription",
      "POST /stripeWebhook",
      // PayPal
      "POST /createPayPalSubscription",
      "POST /verifyPayPalSubscription",
      "POST /cancelPayPalSubscription",
      "POST /paypalWebhook",
      // Health
      "GET /health"
    ]
  });
});

export const subscriptionApi = functions.https.onRequest(app);

// ==================== Scheduled Functions ====================
import { checkExpiringPayPalSubscriptions } from "./paypal/paypal_webhook";
import { checkExpiringSubscriptions } from "./stripe/stripe_webhook";

/**
 * 每分钟检查即将到期的 PayPal 订阅（3分钟内到期且 autoRenew = false）
 */
export const checkExpiringPayPalSubscriptionsSchedule = onSchedule(
  {
    schedule: "* * * * *", // 每分钟执行
    timeZone: "Asia/Kuala_Lumpur",
  },
  async () => {
    try {
      functions.logger.log("🔄 Checking expiring PayPal subscriptions...");

      await checkExpiringPayPalSubscriptions();

      functions.logger.log("✅ Expiring PayPal subscriptions check completed");
    } catch (error) {
      functions.logger.error("❌ Error in expiring PayPal subscriptions check:", error);
    }
  }
);

/**
 * 每小时检查即将到期的 Stripe 订阅并发送提醒邮件
 * 会发送 3天提醒 和 1天提醒（通过内部逻辑控制避免重复）
 */
export const checkExpiringStripeSubscriptionsSchedule = onSchedule(
  {
    schedule: "0 * * * *", // 每小时执行一次
    timeZone: "Asia/Kuala_Lumpur",
  },
  async () => {
    try {
      functions.logger.log("🔔 [Hourly] Checking expiring Stripe subscriptions for reminders...");

      await checkExpiringSubscriptions();

      functions.logger.log("✅ [Hourly] Expiring Stripe subscriptions reminder check completed");
    } catch (error) {
      functions.logger.error("❌ Error in hourly expiring Stripe subscriptions reminder check:", error);
    }
  }
);