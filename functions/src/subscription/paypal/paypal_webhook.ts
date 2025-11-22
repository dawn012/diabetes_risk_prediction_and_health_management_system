
import {Request, Response} from "express";
import * as admin from "firebase-admin";
import {
  generateSubscriptionActivatedEmail,
  generatePaymentSuccessEmail,
  generatePaymentFailedEmail,
  generateSubscriptionCancelledEmail,
} from "../../utils/email/email_templates";
import { sendEmail } from "../../utils/email/email_config";

const PAYPAL_CLIENT_ID = process.env.PAYPAL_CLIENT_ID;
const PAYPAL_CLIENT_SECRET = process.env.PAYPAL_CLIENT_SECRET;
const PAYPAL_BASE_URL = "https://api-m.sandbox.paypal.com";
const PAYPAL_WEBHOOK_ID = process.env.PAYPAL_WEBHOOK_ID;

// 时间转换函数
function convertDateToUTC8(dateString: string): number {
  const date = new Date(dateString);
  //   return date.getTime() + (8 * 60 * 60 * 1000); // +8 小时
  return date.getTime();
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

// 获取 PayPal Access Token
async function getPayPalAccessToken(): Promise<string> {
  if (!PAYPAL_CLIENT_ID || !PAYPAL_CLIENT_SECRET) {
    throw new Error("PayPal credentials are missing!");
  }

  const auth = Buffer.from(`${PAYPAL_CLIENT_ID}:${PAYPAL_CLIENT_SECRET}`).toString("base64");

  const response = await fetch(`${PAYPAL_BASE_URL}/v1/oauth2/token`, {
    method: "POST",
    headers: {
      "Authorization": `Basic ${auth}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: "grant_type=client_credentials",
  });

  const data = await response.json();
  return data.access_token;
}

// ==================== PayPal Webhook Handler ====================
export const handlePayPalWebhook = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const webhookEvent = req.body;

    console.log(`Received PayPal webhook event: ${webhookEvent.event_type}`);

    // 验证 webhook (可选但推荐)
    if (PAYPAL_WEBHOOK_ID) {
      const isValid = await verifyPayPalWebhook(req);
      if (!isValid) {
        console.error("Invalid PayPal webhook signature");
        res.status(400).send("Invalid webhook signature");
        return;
      }
    }

    // 处理不同的事件类型
    switch (webhookEvent.event_type) {
    case "BILLING.SUBSCRIPTION.ACTIVATED":
      await handleSubscriptionActivated(webhookEvent.resource);
      break;

    case "BILLING.SUBSCRIPTION.CANCELLED":
      await handleSubscriptionCancelled(webhookEvent.resource);
      break;

    case "BILLING.SUBSCRIPTION.SUSPENDED":
      await handleSubscriptionSuspended(webhookEvent.resource);
      break;

    case "BILLING.SUBSCRIPTION.EXPIRED":
      await handleSubscriptionExpired(webhookEvent.resource);
      break;

    case "BILLING.SUBSCRIPTION.UPDATED":
      await handleSubscriptionUpdated(webhookEvent.resource);
      break;

    case "PAYMENT.SALE.PENDING":
      await handlePaymentPending(webhookEvent.resource);
      break;

    case "PAYMENT.SALE.COMPLETED":
      await handlePaymentCompleted(webhookEvent.resource);
      break;

    case "PAYMENT.SALE.DENIED":
    case "BILLING.SUBSCRIPTION.PAYMENT.FAILED":
      await handlePaymentFailed(webhookEvent.resource);
      break;

    default:
      console.log(`Unhandled event type: ${webhookEvent.event_type}`);
    }

    res.json({received: true});
  } catch (error) {
    console.error("Error handling PayPal webhook:", error);
    res.status(500).json({error: "Webhook processing failed"});
  }
};

// 验证 PayPal Webhook 签名
async function verifyPayPalWebhook(req: Request): Promise<boolean> {
  try {
    const accessToken = await getPayPalAccessToken();

    const verificationData = {
      transmission_id: req.headers["paypal-transmission-id"],
      transmission_time: req.headers["paypal-transmission-time"],
      cert_url: req.headers["paypal-cert-url"],
      auth_algo: req.headers["paypal-auth-algo"],
      transmission_sig: req.headers["paypal-transmission-sig"],
      webhook_id: PAYPAL_WEBHOOK_ID,
      webhook_event: req.body,
    };

    const response = await fetch(
      `${PAYPAL_BASE_URL}/v1/notifications/verify-webhook-signature`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${accessToken}`,
        },
        body: JSON.stringify(verificationData),
      }
    );

    const result = await response.json();
    return result.verification_status === "SUCCESS";
  } catch (error) {
    console.error("Error verifying webhook:", error);
    return false;
  }
}

// ==================== 处理订阅激活 ====================
async function handleSubscriptionActivated(subscription: any) {
  try {
    console.log(`Subscription activated: ${subscription.id}`);

    const db = admin.firestore();
    const subscriptionId = subscription.id;
    const customId = subscription.custom_id; // format: "uid_planId"

    if (!customId) {
      console.error("No custom_id found in subscription");
      return;
    }

    const [uid, planId] = customId.split("_");

    // 获取用户信息
    const userDoc = await db.collection("users").doc(uid).get();
    const userData = userDoc.data();
    const userEmail = userData?.email;
    const userName = userData?.username || "User";

    // 获取 plan 信息
    const planDoc = await db.collection("subscriptionPlans").doc(planId).get();
    if (!planDoc.exists) {
      console.error(`Plan not found: ${planId}`);
      return;
    }

    const planData = planDoc.data();
    const now = Date.now();
    const startTime = convertDateToUTC8(subscription.start_time);

    // billing_info 包含下次计费信息
    const nextBillingTime = subscription.billing_info?.next_billing_time
      ? convertDateToUTC8(subscription.billing_info.next_billing_time)
      : now + (planData!.durationDays * 24 * 60 * 60 * 1000);

    // 检查是否已存在订阅记录
    const existingDoc = await db.collection("userSubscriptions").doc(subscriptionId).get();

    if (existingDoc.exists) {
      // 更新现有记录为 active
      await existingDoc.ref.update({
        status: "active",
        startDateTime: startTime,
        endDateTime: nextBillingTime,
        updatedAt: now,
      });
      console.log(`✅ Subscription updated to active: ${subscriptionId}`);
    } else {
      // 创建新订阅记录
      const subscriptionData = {
        subscriptionId: subscriptionId,
        userId: uid,
        subscriptionPlanId: planId,
        status: "active",
        autoRenew: false,
        startDateTime: startTime,
        endDateTime: nextBillingTime,
        createdAt: now,
        updatedAt: now,
      };

      await db.collection("userSubscriptions").doc(subscriptionId).set(subscriptionData);
      console.log(`✅ New subscription created: ${subscriptionId}`);
    }

    // 📧 发送订阅激活邮件
    if (userEmail && planData) {
      try {
        const activatedEmail = generateSubscriptionActivatedEmail(
          userName,
          planData.planName,
          formatDate(startTime),
          formatDate(nextBillingTime),
          subscriptionId
        );

        await sendEmail({
          to: userEmail,
          subject: activatedEmail.subject,
          html: activatedEmail.html,
          text: activatedEmail.text
        });

        console.log(`✅ Subscription activated email sent to: ${userEmail}`);
      } catch (emailError) {
        console.error("❌ Error sending subscription activated email:", emailError);
      }
    }

  } catch (error) {
    console.error("Error handling subscription activated:", error);
  }
}

// ==================== 处理支付待处理 ====================
async function handlePaymentPending(payment: any) {
  try {
    console.log(`Payment pending: ${payment.id}`);

    const db = admin.firestore();
    const subscriptionId = payment.billing_agreement_id;

    if (!subscriptionId) {
      console.log("No billing_agreement_id found in pending payment");
      return;
    }

    const subscriptionDoc = await db.collection("userSubscriptions").doc(subscriptionId).get();

    if (!subscriptionDoc.exists) {
      console.log(`Subscription not found: ${subscriptionId}`);
      return;
    }

    const subscriptionData = subscriptionDoc.data();

    // 检查 payment count 和 auto renew 设置
    const paymentCount = subscriptionData?.paymentCount || 0;
    const autoRenew = subscriptionData?.autoRenew || false;

    // 只有非首次付款且 autoRenew 为 false 时才取消
    const isFirstPayment = paymentCount === 0;

    if (!isFirstPayment && autoRenew === false) {
      console.log(`Auto-renew disabled for ${subscriptionId} (payment count: ${paymentCount}), cancelling subscription`);

      // 先更新 Firestore 状态
      await subscriptionDoc.ref.update({
        status: "expired",
        updatedAt: Date.now(),
      });

      console.log(`✅ Marked subscription as expired in Firestore: ${subscriptionId}`);

      // 取消 PayPal 订阅
      const accessToken = await getPayPalAccessToken();
      const cancelResponse = await fetch(
        `${PAYPAL_BASE_URL}/v1/billing/subscriptions/${subscriptionId}/cancel`,
        {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            reason: "User disabled auto-renew"
          })
        }
      );

      if (cancelResponse.ok) {
        console.log(`✅ PayPal subscription cancelled: ${subscriptionId}`);
      } else {
        console.error(`Failed to cancel PayPal subscription ${subscriptionId}, but Firestore updated`);
      }
    } else if (isFirstPayment) {
      console.log(`Allowing first payment for subscription: ${subscriptionId} (payment count: ${paymentCount})`);
    } else if (autoRenew === true) {
      console.log(`Auto-renew enabled for ${subscriptionId}, allowing payment to proceed (payment count: ${paymentCount})`);
    } else {
      console.log(`Allowing payment for ${subscriptionId} (first payment or auto-renew not set)`);
    }

  } catch (error) {
    console.error("Error handling payment pending:", error);
  }
}

// ==================== 处理支付完成 ====================
async function handlePaymentCompleted(payment: any) {
  try {
    console.log(`Payment completed: ${payment.id}`);

    const db = admin.firestore();
    const transactionId = `paypal_${payment.id}`;

    // 从 billing_agreement_id 获取 subscription ID
    const subscriptionId = payment.billing_agreement_id;

    if (!subscriptionId) {
      console.log("No billing_agreement_id found in payment");
      return;
    }

    // 检查 payment 是否已存在
    const existingPayment = await db.collection("payments").doc(transactionId).get();

    if (existingPayment.exists) {
      console.log(`Payment already recorded: ${transactionId}`);
      return;
    }

    // 判断是否为自动续订付款
    const subscriptionDoc = await db.collection("userSubscriptions").doc(subscriptionId).get();
    let isRenewal = false;
    let paymentCount = 0;
    let subscriptionData: any = null;

    if (subscriptionDoc.exists) {
      subscriptionData = subscriptionDoc.data();
      paymentCount = subscriptionData?.paymentCount || 0;

      // 如果已经有付款记录，这次就是续订
      isRenewal = paymentCount > 0;
    }

    // 创建 payment 记录
    const paymentData: any = {
      transactionId: transactionId,
      subscriptionId: subscriptionId,
      amount: parseFloat(payment.amount.total),
      currency: payment.amount.currency.toUpperCase(),
      paymentMethod: "paypal",
      transactionDateTime: convertDateToUTC8(payment.create_time),
      status: "succeeded",
      createdAt: Date.now(),
    };

    // 只有在自动续订时才添加 type 字段
    if (isRenewal) {
      paymentData.type = "renewal";
    }

    await db.collection("payments").doc(transactionId).set(paymentData);
    console.log(`✅ Payment recorded: ${transactionId}`);

    // 更新订阅的下次计费时间
    let newEndDateTime = Date.now();

    if (subscriptionDoc.exists) {
      // 获取最新的订阅信息来更新 next billing time
      const accessToken = await getPayPalAccessToken();
      const response = await fetch(
        `${PAYPAL_BASE_URL}/v1/billing/subscriptions/${subscriptionId}`,
        {
          headers: {
            "Authorization": `Bearer ${accessToken}`,
          },
        }
      );

      if (response.ok) {
        const subscriptionInfo = await response.json();
        const nextBillingTime = subscriptionInfo.billing_info?.next_billing_time;

        if (nextBillingTime) {
          newEndDateTime = convertDateToUTC8(nextBillingTime);

          await subscriptionDoc.ref.update({
            status: "active",
            endDateTime: newEndDateTime,
            paymentCount: paymentCount + 1, // 更新付款次数
            updatedAt: Date.now(),
          });
          console.log(`✅ Updated next billing time for ${subscriptionId}, payment count: ${paymentCount + 1}`);
        }
      }

      // 📧 发送支付成功邮件
      if (subscriptionData) {
        await sendPaymentSuccessEmail(
          subscriptionData,
          payment,
          transactionId,
          newEndDateTime,
          isRenewal
        );
      }
    }

  } catch (error) {
    console.error("Error handling payment completed:", error);
  }
}

// 📧 发送支付成功邮件
async function sendPaymentSuccessEmail(
  subscriptionData: any,
  payment: any,
  transactionId: string,
  nextBillingDate: number,
  isRenewal: boolean
) {
  try {
    const db = admin.firestore();

    // 获取用户信息
    const userDoc = await db.collection("users").doc(subscriptionData.userId).get();
    const userData = userDoc.data();
    if (!userData?.email) return;

    // 获取计划信息
    const planDoc = await db.collection("subscriptionPlans").doc(subscriptionData.subscriptionPlanId).get();
    const planData = planDoc.data();
    if (!planData) return;

    // 生成邮件
    const receiptEmail = generatePaymentSuccessEmail(
      userData.username || "User",
      planData.planName,
      parseFloat(payment.amount.total),
      formatDateTime(convertDateToUTC8(payment.create_time)),
      formatDate(nextBillingDate),
      transactionId,
      isRenewal
    );

    await sendEmail({
      to: userData.email,
      subject: receiptEmail.subject,
      html: receiptEmail.html,
      text: receiptEmail.text
    });

    console.log(`✅ Payment ${isRenewal ? "renewal" : "success"} email sent to: ${userData.email}`);
  } catch (error) {
    console.error("❌ Error sending payment success email:", error);
  }
}

// ==================== 处理订阅取消 ====================
async function handleSubscriptionCancelled(subscription: any) {
  try {
    console.log(`Subscription cancelled: ${subscription.id}`);

    const db = admin.firestore();
    const subscriptionId = subscription.id;

    const subscriptionDoc = await db
      .collection("userSubscriptions")
      .doc(subscriptionId)
      .get();

    if (subscriptionDoc.exists) {
      const subscriptionData = subscriptionDoc.data();

      if (!subscriptionData) {
        console.error(`❌ Subscription data not found for: ${subscriptionId}`);
        return;
      }

      // 检查是否已经被标记为 expired（由 schedule 设置）
      if (subscriptionData?.status === "expired") {
        console.log(`Subscription already marked as expired, skipping cancellation update: ${subscriptionId}`);
        return;
      }

      // 否则是手动取消
      await subscriptionDoc.ref.update({
        status: "cancelled",
        autoRenew: false,
        cancelAt: Date.now(),
        updatedAt: Date.now(),
      });
      console.log(`✅ Subscription cancelled in Firestore: ${subscriptionId}`);

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
              subscriptionId
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
    console.error("Error handling subscription cancelled:", error);
  }
}

// ==================== 处理订阅暂停 ====================
async function handleSubscriptionSuspended(subscription: any) {
  try {
    console.log(`Subscription suspended: ${subscription.id}`);

    const db = admin.firestore();
    const subscriptionId = subscription.id;

    const subscriptionDoc = await db
      .collection("userSubscriptions")
      .doc(subscriptionId)
      .get();

    if (subscriptionDoc.exists) {
      await subscriptionDoc.ref.update({
        status: "suspended",
        updatedAt: Date.now(),
      });
      console.log(`✅ Subscription suspended in Firestore: ${subscriptionId}`);
    }
  } catch (error) {
    console.error("Error handling subscription suspended:", error);
  }
}

// ==================== 处理订阅过期 ====================
async function handleSubscriptionExpired(subscription: any) {
  try {
    console.log(`Subscription expired: ${subscription.id}`);

    const db = admin.firestore();
    const subscriptionId = subscription.id;

    const subscriptionDoc = await db
      .collection("userSubscriptions")
      .doc(subscriptionId)
      .get();

    if (subscriptionDoc.exists) {
      await subscriptionDoc.ref.update({
        status: "expired",
        autoRenew: false,
        updatedAt: Date.now(),
      });
      console.log(`✅ Subscription expired in Firestore: ${subscriptionId}`);
    }
  } catch (error) {
    console.error("Error handling subscription expired:", error);
  }
}

// ==================== 处理订阅更新 ====================
async function handleSubscriptionUpdated(subscription: any) {
  try {
    console.log(`Subscription updated: ${subscription.id}`);

    const db = admin.firestore();
    const subscriptionId = subscription.id;

    const subscriptionDoc = await db
      .collection("userSubscriptions")
      .doc(subscriptionId)
      .get();

    if (subscriptionDoc.exists) {
      const updateData: any = {
        status: subscription.status.toLowerCase(),
        updatedAt: Date.now(),
      };

      await subscriptionDoc.ref.update(updateData);
      console.log(`✅ Subscription updated in Firestore: ${subscriptionId}`);
    }
  } catch (error) {
    console.error("Error handling subscription updated:", error);
  }
}

// ==================== 处理支付失败 ====================
async function handlePaymentFailed(payment: any) {
  try {
    console.log(`Payment failed: ${payment.id || payment.billing_agreement_id}`);

    const db = admin.firestore();
    const subscriptionId = payment.billing_agreement_id;

    if (!subscriptionId) {
      console.log("No billing_agreement_id found");
      return;
    }

    const transactionId = `paypal_${payment.id || Date.now()}`;

    // 记录失败的支付
    const existingPayment = await db.collection("payments").doc(transactionId).get();

    if (!existingPayment.exists) {
      const paymentData = {
        transactionId: transactionId,
        subscriptionId: subscriptionId,
        amount: payment.amount?.total ? parseFloat(payment.amount.total) : 0,
        currency: payment.amount?.currency?.toUpperCase() || "MYR",
        paymentMethod: "paypal",
        transactionDateTime: payment.create_time ? convertDateToUTC8(payment.create_time) : Date.now(),
        status: "failed",
        createdAt: Date.now(),
      };

      await db.collection("payments").doc(transactionId).set(paymentData);
      console.log(`✅ Failed payment recorded: ${transactionId}`);
    }

    // 更新订阅状态
    const subscriptionDoc = await db
      .collection("userSubscriptions")
      .doc(subscriptionId)
      .get();

    if (subscriptionDoc.exists) {
      const subscriptionData = subscriptionDoc.data();

      await subscriptionDoc.ref.update({
        status: "failed",
        updatedAt: Date.now(),
      });
      console.log(`✅ Subscription suspended due to payment failure: ${subscriptionId}`);

      // 📧 发送支付失败邮件
      try {
        const userDoc = await db.collection("users").doc(subscriptionData?.userId).get();
        const userData = userDoc.data();

        if (userData?.email) {
          const planDoc = await db.collection("subscriptionPlans").doc(subscriptionData?.subscriptionPlanId).get();
          const planData = planDoc.data();

          if (planData) {
            // 获取失败原因
            const failureReason = payment.reason_code ||
                                 "Payment could not be processed. Please check your PayPal account.";

            // PayPal 通常会自动重试
            const retryDate = formatDate(Date.now() + (3 * 24 * 60 * 60 * 1000)); // 3天后

            const failedEmail = generatePaymentFailedEmail(
              userData.username || "User",
              planData.planName,
              payment.amount?.total ? parseFloat(payment.amount.total) : 0,
              failureReason,
              retryDate,
              subscriptionId
            );

            await sendEmail({
              to: userData.email,
              subject: failedEmail.subject,
              html: failedEmail.html,
              text: failedEmail.text
            });

            console.log(`✅ Payment failed email sent to: ${userData.email}`);
          }
        }
      } catch (emailError) {
        console.error("❌ Error sending payment failed email:", emailError);
      }
    }

  } catch (error) {
    console.error("Error handling payment failed:", error);
  }
}

// ==================== Scheduled Function: 检查即将到期的订阅 ====================
export const checkExpiringPayPalSubscriptions = async (): Promise<void> => {
  try {
    const db = admin.firestore();
    const now = Date.now();
    const threeMinutesFromNow = now + (3 * 60 * 1000); // 3分钟后

    console.log("Checking expiring PayPal subscriptions in next 3 minutes...");

    // 查找3分钟内到期且 autoRenew 为 false 的订阅
    const expiringQuery = await db.collection("userSubscriptions")
      .where("status", "==", "active")
      .where("endDateTime", "<=", threeMinutesFromNow)
      .where("endDateTime", ">", now)
      .where("autoRenew", "==", false)
      .get();

    if (expiringQuery.empty) {
      console.log("No subscriptions expiring in 3 minutes with auto-renew disabled");
      return;
    }

    const accessToken = await getPayPalAccessToken();

    for (const doc of expiringQuery.docs) {
      const data = doc.data();
      const subscriptionId = data.subscriptionId;
      const endDateTime = data.endDateTime;

      // 计算剩余时间（毫秒）
      const timeRemaining = endDateTime - now;
      const minutesRemaining = Math.floor(timeRemaining / (60 * 1000));
      const secondsRemaining = Math.floor((timeRemaining % (60 * 1000)) / 1000);

      // 只处理 PayPal 订阅
      if (!subscriptionId.startsWith("I-")) {
        continue;
      }

      console.log(`Auto-renew disabled for subscription expiring in ${minutesRemaining}m ${secondsRemaining}s: ${subscriptionId}, cancelling now`);

      try {
        // 先更新 Firestore 状态
        await doc.ref.update({
          status: "expired",
          updatedAt: Date.now(),
        });

        console.log(`✅ Marked subscription as expired in Firestore: ${subscriptionId}`);

        // 然后取消 PayPal 订阅
        const cancelResponse = await fetch(
          `${PAYPAL_BASE_URL}/v1/billing/subscriptions/${subscriptionId}/cancel`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              "Authorization": `Bearer ${accessToken}`,
            },
            body: JSON.stringify({
              reason: "User disabled auto-renewal - cancelling before renewal",
            }),
          }
        );

        if (cancelResponse.ok || cancelResponse.status === 204) {
          console.log(`✅ PayPal subscription cancelled: ${subscriptionId}`);
        } else {
          console.error(`Failed to cancel PayPal subscription ${subscriptionId}, but Firestore updated`);
        }

      } catch (error) {
        console.error(`Error processing subscription ${subscriptionId}:`, error);
      }
    }

    console.log(`Processed ${expiringQuery.size} subscriptions expiring in 3 minutes with auto-renew disabled`);
  } catch (error) {
    console.error("Error checking expiring PayPal subscriptions:", error);
  }
};