import {Request, Response} from "express";
import * as admin from "firebase-admin";

const PAYPAL_CLIENT_ID = process.env.PAYPAL_CLIENT_ID;
const PAYPAL_CLIENT_SECRET = process.env.PAYPAL_CLIENT_SECRET;
const PAYPAL_BASE_URL = "https://api-m.sandbox.paypal.com";

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

export const cancelPayPalSubscription = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith("Bearer ")) {
      res.status(401).json({error: "Unauthorized"});
      return;
    }

    const idToken = authHeader.split("Bearer ")[1];
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const uid = decodedToken.uid;

    const {subscriptionId, reason} = req.body;

    if (!subscriptionId) {
      res.status(400).json({error: "Missing subscriptionId"});
      return;
    }

    // 验证订阅属于该用户
    const db = admin.firestore();
    const subscriptionDoc = await db
      .collection("userSubscriptions")
      .doc(subscriptionId)
      .get();

    if (!subscriptionDoc.exists) {
      res.status(404).json({error: "Subscription not found"});
      return;
    }

    const subscriptionData = subscriptionDoc.data();
    if (subscriptionData?.userId !== uid) {
      res.status(403).json({error: "Forbidden"});
      return;
    }

    const accessToken = await getPayPalAccessToken();

    const paypalResponse = await fetch(
      `${PAYPAL_BASE_URL}/v1/billing/subscriptions/${subscriptionId}/cancel`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          reason: reason || "User requested cancellation",
        }),
      }
    );

    if (!paypalResponse.ok) {
      const error = await paypalResponse.json();
      console.error("PayPal cancel failed:", error);
      res.status(400).json({
        error: "Failed to cancel PayPal subscription",
        details: error,
      });
      return;
    }

    console.log(`PayPal subscription cancelled: ${subscriptionId}`);

    res.json({
      success: true,
      message: "Subscription cancelled successfully",
    });
  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : "Unknown error";
    console.error("Error cancelling PayPal subscription:", error);
    res.status(500).json({
      error: "Failed to cancel PayPal subscription",
      details: errorMessage,
    });
  }
};