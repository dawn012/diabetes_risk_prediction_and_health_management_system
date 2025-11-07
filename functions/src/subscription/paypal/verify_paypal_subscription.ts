import {Request, Response} from "express";

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

export const verifyPayPalSubscription = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith("Bearer ")) {
      res.status(401).json({error: "Unauthorized"});
      return;
    }

    const {subscriptionId} = req.body;

    if (!subscriptionId) {
      res.status(400).json({error: "Missing subscriptionId"});
      return;
    }

    const accessToken = await getPayPalAccessToken();

    const paypalResponse = await fetch(
      `${PAYPAL_BASE_URL}/v1/billing/subscriptions/${subscriptionId}`,
      {
        method: "GET",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
      }
    );

    const subscription = await paypalResponse.json();

    if (!paypalResponse.ok) {
      res.status(400).json({
        error: "Failed to get PayPal subscription status",
        details: subscription,
      });
      return;
    }

    res.json({
      subscriptionId,
      status: subscription.status,
      planId: subscription.plan_id,
      startTime: subscription.start_time,
      customId: subscription.custom_id,
    });
  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : "Unknown error";
    console.error("Error verifying PayPal subscription:", error);
    res.status(500).json({
      error: "Failed to verify PayPal subscription",
      details: errorMessage,
    });
  }
};