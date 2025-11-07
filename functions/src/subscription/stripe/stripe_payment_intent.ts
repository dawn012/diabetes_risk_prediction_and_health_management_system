import { Request, Response } from "express";
import * as admin from "firebase-admin";
import Stripe from "stripe";

const stripeSecret = process.env.STRIPE_SECRET_KEY;
if (!stripeSecret) throw new Error("STRIPE_SECRET not defined");

const stripe = new Stripe(stripeSecret, {apiVersion: "2024-06-20" as any});

// ==================== Create Subscription ====================
export const createSubscription = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    // 1. Verify user
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith("Bearer ")) {
      res.status(401).json({error: "Unauthorized: Missing or invalid token"});
      return;
    }

    const idToken = authHeader.split("Bearer ")[1];
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const uid = decodedToken.uid;

    // 2. Get request body
    const { priceId, planId } = req.body;

    if (!priceId) {
      res.status(400).json({error: "priceId is required"});
      return;
    }

    console.log(`Creating subscription for user ${uid}, Plan: ${planId}`);

    // 3. Create or get customer
    const customers = await stripe.customers.list({
      limit: 1,
      email: decodedToken.email,
    });

    let customer: Stripe.Customer;
    if (customers.data.length > 0) {
      customer = customers.data[0];
      console.log(`Existing customer found: ${customer.id}`);
    } else {
      customer = await stripe.customers.create({
        metadata: { uid },
        email: decodedToken.email,
        name: decodedToken.name,
      });
      console.log(`New customer created: ${customer.id}`);
    }

    // 4. Create subscription (initial status: incomplete)
    const subscription = await stripe.subscriptions.create({
      customer: customer.id,
      items: [{ price: priceId }],
      payment_behavior: "default_incomplete",
      payment_settings: { save_default_payment_method: "on_subscription" },
      expand: ["latest_invoice.payment_intent"],
      metadata: {
        planId,
        uid,
        appName: "Diatrack"
      }
    });

    // 5. Get client_secret for frontend payment verification
    const invoice = subscription.latest_invoice as Stripe.Invoice;
    const paymentIntent = (invoice as any).payment_intent as Stripe.PaymentIntent;

    // 6. Create Ephemeral Key
    const ephemeralKey = await stripe.ephemeralKeys.create(
      { customer: customer.id },
      { apiVersion: "2024-06-20" }
    );

    console.log(`Subscription created: ${subscription.id}, Status: ${subscription.status}`);

    res.json({
      subscriptionId: subscription.id,
      client_secret: paymentIntent.client_secret,
      customer_id: customer.id,
      ephemeral_key: ephemeralKey.secret,
      status: subscription.status,
    });
  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : "Unknown error";
    console.error("Error creating subscription:", error);
    res.status(500).json({
      error: "Failed to create subscription",
      details: errorMessage,
    });
  }
};