import {Request, Response} from "express";
import * as admin from "firebase-admin";

const PAYPAL_CLIENT_ID = process.env.PAYPAL_CLIENT_ID;
const PAYPAL_CLIENT_SECRET = process.env.PAYPAL_CLIENT_SECRET;
const PAYPAL_BASE_URL = "https://api-m.sandbox.paypal.com";

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
      "Accept": "application/json",
      "Accept-Language": "en_US",
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: "grant_type=client_credentials",
  });

  const data = await response.json();
  return data.access_token;
}

// ==================== 创建 PayPal Subscription ====================
export const createPayPalSubscription = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    // 1. 验证用户身份
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith("Bearer ")) {
      res.status(401).json({error: "Unauthorized"});
      return;
    }

    const idToken = authHeader.split("Bearer ")[1];
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const uid = decodedToken.uid;

    // 2. 获取请求数据
    const {planId} = req.body; // planId 是你的 Firestore plan ID

    if (!planId) {
      res.status(400).json({
        error: "Missing required field: planId",
      });
      return;
    }

    // 3. 从 Firestore 获取 plan 信息
    const db = admin.firestore();
    const planDoc = await db.collection("subscriptionPlans").doc(planId).get();

    if (!planDoc.exists) {
      res.status(404).json({error: "Plan not found"});
      return;
    }

    // const planData = planDoc.data();

    // 4. 获取 PayPal access token
    const accessToken = await getPayPalAccessToken();

    // 5. 创建 PayPal Subscription
    const subscriptionData = {
      plan_id: "P-2NG033986G966091DNEE44QQ", // 你的 PayPal Plan ID
      custom_id: `${uid}_${planId}`, // 用于识别用户和计划
      application_context: {
        brand_name: "Diatrack",
        locale: "en-US",
        shipping_preference: "NO_SHIPPING",
        user_action: "SUBSCRIBE_NOW",
        payment_method: {
          payer_selected: "PAYPAL",
          payee_preferred: "IMMEDIATE_PAYMENT_REQUIRED",
        },
        return_url: `diatrack://payment/paypal-success?userId=${uid}&planId=${planId}`,
        cancel_url: `diatrack://payment/paypal-cancel?userId=${uid}`,
      },
    };

    const paypalResponse = await fetch(`${PAYPAL_BASE_URL}/v1/billing/subscriptions`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${accessToken}`,
        "PayPal-Request-Id": `${uid}_${Date.now()}`,
      },
      body: JSON.stringify(subscriptionData),
    });

    const subscription = await paypalResponse.json();

    if (!paypalResponse.ok) {
      console.error("PayPal subscription creation failed:", subscription);
      res.status(400).json({
        error: "Failed to create PayPal subscription",
        details: subscription,
      });
      return;
    }

    console.log(`Created PayPal subscription: ${subscription.id} for user: ${uid}`);

    // 6. 返回 approval_url 让用户完成订阅
    const approvalLink = subscription.links.find((link: any) => link.rel === "approve");

    res.json({
      subscriptionId: subscription.id,
      status: subscription.status,
      links: subscription.links,
      approval_url: approvalLink?.href,
    });
  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : "Unknown error";
    console.error("Error creating PayPal subscription:", error);
    res.status(500).json({
      error: "Failed to create PayPal subscription",
      details: errorMessage,
    });
  }
};
