// 1️⃣ BILLING.SUBSCRIPTION.ACTIVATED
export const generateSubscriptionActivatedEmail = (
  userName: string,
  planName: string,
  startDate: string,
  expiryDate: string,
  subscriptionId: string
) => {
  return {
    subject: `🎉 Your ${planName} subscription is now active!`,
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #e8f5e8; padding: 20px; text-align: center; }
          .content { padding: 30px; background: #fff; }
          .footer { padding: 20px; text-align: center; font-size: 12px; color: #666; }
          .button { background: #28a745; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; display: inline-block; }
          .info-box { background: #f8f9fa; padding: 15px; border-radius: 5px; margin: 15px 0; }
          .plan-name { font-size: 24px; color: #28a745; font-weight: bold; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h2>🎉 Subscription Activated!</h2>
          </div>
          <div class="content">
            <h3>Dear ${userName},</h3>

            <p>Great news! Your subscription is now active and ready to use.</p>

            <div class="info-box">
              <p><strong>Plan:</strong> <span class="plan-name">${planName}</span></p>
              <p><strong>Start Date:</strong> ${startDate}</p>
              <p><strong>Expiry Date:</strong> ${expiryDate}</p>
            </div>

            <p style="text-align: center;">
              <a href="https://diabetes-health-system.web.app/subscription/${subscriptionId}" class="button">
                See Your Plan
              </a>
            </p>

            <p>You can now enjoy all the benefits of your ${planName} plan. If you have any questions or need assistance, our support team is here to help.</p>

            <p>Thank you for choosing Diatrack!</p>

            <p>Best regards,<br>Diatrack Team</p>
          </div>
          <div class="footer">
            <p>© ${new Date().getFullYear()} Diatrack. All rights reserved.</p>
            <p>This is an automated message, please do not reply to this email.</p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `
🎉 SUBSCRIPTION ACTIVATED!

Dear ${userName},

Great news! Your subscription is now active and ready to use.

Plan: ${planName}
Start Date: ${startDate}
Expiry Date: ${expiryDate}

See Your Plan: https://diabetes-health-system.web.app/subscription/${subscriptionId}

You can now enjoy all the benefits of your ${planName} plan. If you have any questions or need assistance, our support team is here to help.

Thank you for choosing Diatrack!

Best regards,
Diatrack Team

© ${new Date().getFullYear()} Diatrack. All rights reserved.
This is an automated message, please do not reply to this email.
    `,
  };
};

// 2️⃣ PAYMENT.SALE.COMPLETED
export const generatePaymentSuccessEmail = (
  userName: string,
  planName: string,
  amount: number,
  paymentDate: string,
  nextBillingDate: string,
  transactionId: string,
  isRenewal: boolean = false
) => {
  return {
    subject: `${isRenewal ? "✅ Payment successful - Subscription renewed" : `✅ Your payment for ${planName} was successful`}`,
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #e8f5e8; padding: 20px; text-align: center; }
          .content { padding: 30px; background: #fff; }
          .footer { padding: 20px; text-align: center; font-size: 12px; color: #666; }
          .button { background: #28a745; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; display: inline-block; margin: 5px; }
          .amount { font-size: 24px; color: #28a745; font-weight: bold; }
          .info-box { background: #f8f9fa; padding: 15px; border-radius: 5px; margin: 15px 0; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h2>✅ Payment ${isRenewal ? "Successful - Subscription Renewed" : "Confirmed"}</h2>
          </div>
          <div class="content">
            <h3>Dear ${userName},</h3>

            <p>${isRenewal ? "Your subscription has been successfully renewed!" : "Thank you for your payment!"}</p>

            <div class="info-box">
              <p><strong>Plan:</strong> ${planName}</p>
              <p><strong>Payment Date:</strong> ${paymentDate}</p>
              <p><strong>Next Billing Date:</strong> ${nextBillingDate}</p>
            </div>

            <p style="text-align: center;">
              <span class="amount">RM${amount.toFixed(2)}</span>
            </p>

            <p style="text-align: center;">
              <a href="https://diabetes-health-system.web.app/receipt/${transactionId}" class="button">
                Download Receipt
              </a>
            </p>

            <p>Your payment has been processed successfully. ${isRenewal ? "Your subscription will continue without interruption." : "You can continue enjoying your plan benefits."}</p>

            <p>If you have any questions about this payment, please contact our support team.</p>

            <p>Thank you,<br>Diatrack</p>
          </div>
          <div class="footer">
            <p>© ${new Date().getFullYear()} Diatrack. All rights reserved.</p>
            <p>This is an automated message, please do not reply to this email.</p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `
✅ PAYMENT ${isRenewal ? "SUCCESSFUL - SUBSCRIPTION RENEWED" : "CONFIRMED"}

Dear ${userName},

${isRenewal ? "Your subscription has been successfully renewed!" : "Thank you for your payment!"}

Plan: ${planName}
Payment Date: ${paymentDate}
Next Billing Date: ${nextBillingDate}

Amount Paid: RM${amount.toFixed(2)}

Download Receipt: https://diabetes-health-system.web.app/receipt/${transactionId}

Your payment has been processed successfully. ${isRenewal ? "Your subscription will continue without interruption." : "You can continue enjoying your plan benefits."}

If you have any questions about this payment, please contact our support team.

Thank you,
Diatrack

© ${new Date().getFullYear()} Diatrack. All rights reserved.
This is an automated message, please do not reply to this email.
    `,
  };
};

// 3️⃣ PAYMENT.SALE.FAILED / DENIED
export const generatePaymentFailedEmail = (
  userName: string,
  planName: string,
  amount: number,
  failureReason: string,
  retryDate: string,
  subscriptionId: string
) => {
  return {
    subject: `⚠️ We couldn't process your payment for ${planName}`,
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #ffebee; padding: 20px; text-align: center; }
          .content { padding: 30px; background: #fff; }
          .footer { padding: 20px; text-align: center; font-size: 12px; color: #666; }
          .button { background: #dc3545; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; display: inline-block; }
          .amount { font-size: 24px; color: #dc3545; font-weight: bold; }
          .info-box { background: #fff3cd; padding: 15px; border-radius: 5px; margin: 15px 0; border-left: 4px solid #ffc107; }
          .warning { color: #856404; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h2>⚠️ Payment Failed</h2>
          </div>
          <div class="content">
            <h3>Dear ${userName},</h3>

            <p>We were unable to process your payment for your ${planName} subscription.</p>

            <div class="info-box">
              <p class="warning"><strong>Reason:</strong> ${failureReason}</p>
              <p><strong>Amount:</strong> RM${amount.toFixed(2)}</p>
              <p><strong>Next Retry:</strong> ${retryDate}</p>
            </div>

            <p>Our system will automatically retry the payment. However, to ensure uninterrupted service, we recommend updating your payment method now.</p>

            <p style="text-align: center;">
              <a href="https://diabetes-health-system.web.app/subscription/${subscriptionId}/payment" class="button">
                Update Payment Method
              </a>
            </p>

            <p><strong>Common reasons for payment failure:</strong></p>
            <ul>
              <li>Insufficient funds</li>
              <li>Expired card</li>
              <li>Incorrect card details</li>
              <li>Bank security restrictions</li>
            </ul>

            <p>If the payment continues to fail, your subscription may be suspended. Please contact your bank or update your payment information as soon as possible.</p>

            <p>If you need assistance, our support team is ready to help.</p>

            <p>Thank you,<br>Diatrack</p>
          </div>
          <div class="footer">
            <p>© ${new Date().getFullYear()} Diatrack. All rights reserved.</p>
            <p>This is an automated message, please do not reply to this email.</p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `
⚠️ PAYMENT FAILED

Dear ${userName},

We were unable to process your payment for your ${planName} subscription.

Reason: ${failureReason}
Amount: RM${amount.toFixed(2)}
Next Retry: ${retryDate}

Our system will automatically retry the payment. However, to ensure uninterrupted service, we recommend updating your payment method now.

Update Payment Method: https://diabetes-health-system.web.app/subscription/${subscriptionId}/payment

Common reasons for payment failure:
- Insufficient funds
- Expired card
- Incorrect card details
- Bank security restrictions

If the payment continues to fail, your subscription may be suspended. Please contact your bank or update your payment information as soon as possible.

If you need assistance, our support team is ready to help.

Thank you,
Diatrack

© ${new Date().getFullYear()} Diatrack. All rights reserved.
This is an automated message, please do not reply to this email.
    `,
  };
};

// 4️⃣ BILLING.SUBSCRIPTION.CANCELLED
export const generateSubscriptionCancelledEmail = (
  userName: string,
  planName: string,
  expiryDate: string,
  remainingDays: number,
  subscriptionId: string
) => {
  return {
    subject: `Your ${planName} subscription has been cancelled`,
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #f8f9fa; padding: 20px; text-align: center; }
          .content { padding: 30px; background: #fff; }
          .footer { padding: 20px; text-align: center; font-size: 12px; color: #666; }
          .button { background: #007bff; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; display: inline-block; }
          .info-box { background: #f8f9fa; padding: 15px; border-radius: 5px; margin: 15px 0; }
          .highlight { font-size: 20px; color: #007bff; font-weight: bold; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h2>Subscription Cancelled</h2>
          </div>
          <div class="content">
            <h3>Dear ${userName},</h3>

            <p>Your ${planName} subscription has been cancelled as requested.</p>

            <div class="info-box">
              <p><strong>Plan:</strong> ${planName}</p>
              <p><strong>Access Until:</strong> ${expiryDate}</p>
              <p class="highlight">${remainingDays} days of access remaining</p>
            </div>

            <p>You will continue to have full access to your plan benefits until <strong>${expiryDate}</strong>. After this date, your subscription will expire and you will no longer be charged.</p>

            <p>We're sorry to see you go! If you change your mind, you can reactivate your subscription at any time.</p>

            <p style="text-align: center;">
              <a href="https://diabetes-health-system.web.app/subscription/${subscriptionId}/reactivate" class="button">
                Reactivate Subscription
              </a>
            </p>

            <p>If you cancelled by mistake or have any feedback about your experience, please let us know. We'd love to hear from you and help if there's anything we can do.</p>

            <p>Thank you for being part of Diatrack. We hope to see you again!</p>

            <p>Best regards,<br>Diatrack Team</p>
          </div>
          <div class="footer">
            <p>© ${new Date().getFullYear()} Diatrack. All rights reserved.</p>
            <p>This is an automated message, please do not reply to this email.</p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `
SUBSCRIPTION CANCELLED

Dear ${userName},

Your ${planName} subscription has been cancelled as requested.

Plan: ${planName}
Access Until: ${expiryDate}
${remainingDays} days of access remaining

You will continue to have full access to your plan benefits until ${expiryDate}. After this date, your subscription will expire and you will no longer be charged.

We're sorry to see you go! If you change your mind, you can reactivate your subscription at any time.

Reactivate Subscription: https://diabetes-health-system.web.app/subscription/${subscriptionId}/reactivate

If you cancelled by mistake or have any feedback about your experience, please let us know. We'd love to hear from you and help if there's anything we can do.

Thank you for being part of Diatrack. We hope to see you again!

Best regards,
Diatrack Team

© ${new Date().getFullYear()} Diatrack. All rights reserved.
This is an automated message, please do not reply to this email.
    `,
  };
};

// 5️⃣ Subscription Expiration Reminder (Cloud Scheduler)
export const generateExpirationReminderEmail = (
  userName: string,
  planName: string,
  expiryDate: string,
  daysUntilExpiry: number,
  hasAutoRenew: boolean,
  subscriptionId: string
) => {
  const isUrgent = daysUntilExpiry <= 1;
  
  return {
    subject: `${isUrgent ? "🚨 " : ""}Your ${planName} subscription ${isUrgent ? "expires tomorrow" : `expires in ${daysUntilExpiry} days`}`,
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: ${isUrgent ? "#ffebee" : "#fff8e1"}; padding: 20px; text-align: center; }
          .content { padding: 30px; background: #fff; }
          .footer { padding: 20px; text-align: center; font-size: 12px; color: #666; }
          .button { background: ${hasAutoRenew ? "#28a745" : "#ff9800"}; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; display: inline-block; }
          .info-box { background: ${isUrgent ? "#ffebee" : "#fff8e1"}; padding: 15px; border-radius: 5px; margin: 15px 0; border-left: 4px solid ${isUrgent ? "#f44336" : "#ff9800"}; }
          .days-left { font-size: 36px; color: ${isUrgent ? "#f44336" : "#ff9800"}; font-weight: bold; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h2>${isUrgent ? "🚨 " : "⏰ "}Subscription Expiring Soon</h2>
          </div>
          <div class="content">
            <h3>Dear ${userName},</h3>

            <p>${isUrgent ? "This is an urgent reminder!" : "This is a friendly reminder."} Your ${planName} subscription is about to expire.</p>

            <div class="info-box">
              <p style="text-align: center;">
                <span class="days-left">${daysUntilExpiry}</span><br>
                <span style="color: #666;">${daysUntilExpiry === 1 ? "day" : "days"} remaining</span>
              </p>
              <p style="text-align: center;"><strong>Expiry Date:</strong> ${expiryDate}</p>
            </div>

            ${hasAutoRenew ? `
              <p>✅ <strong>Good news!</strong> Your subscription is set to auto-renew. You don't need to do anything - we'll automatically renew your subscription on ${expiryDate}.</p>
              
              <p style="text-align: center;">
                <a href="https://diabetes-health-system.web.app/subscription/${subscriptionId}" class="button">
                  View Subscription Details
                </a>
              </p>

              <p style="font-size: 14px; color: #666;">If you wish to cancel auto-renewal, you can do so from your subscription settings.</p>
            ` : `
              <p>⚠️ Your subscription is <strong>not set to auto-renew</strong>. To continue enjoying your plan benefits without interruption, please renew your subscription before it expires.</p>
              
              <p style="text-align: center;">
                <a href="https://diabetes-health-system.web.app/subscription/${subscriptionId}/renew" class="button">
                  Renew Now
                </a>
              </p>

              <p><strong>What happens if you don't renew:</strong></p>
              <ul>
                <li>You will lose access to all plan features</li>
                <li>Your data will be preserved for 30 days</li>
                <li>You can resubscribe at any time</li>
              </ul>
            `}

            <p>If you have any questions about your subscription, please don't hesitate to contact our support team.</p>

            <p>Thank you,<br>Diatrack</p>
          </div>
          <div class="footer">
            <p>© ${new Date().getFullYear()} Diatrack. All rights reserved.</p>
            <p>This is an automated message, please do not reply to this email.</p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `
${isUrgent ? "🚨 " : "⏰ "}SUBSCRIPTION EXPIRING SOON

Dear ${userName},

${isUrgent ? "This is an urgent reminder!" : "This is a friendly reminder."} Your ${planName} subscription is about to expire.

${daysUntilExpiry} ${daysUntilExpiry === 1 ? "day" : "days"} remaining
Expiry Date: ${expiryDate}

${hasAutoRenew ? `
✅ Good news! Your subscription is set to auto-renew. You don't need to do anything - we'll automatically renew your subscription on ${expiryDate}.

View Subscription Details: https://diabetes-health-system.web.app/subscription/${subscriptionId}

If you wish to cancel auto-renewal, you can do so from your subscription settings.
` : `
⚠️ Your subscription is not set to auto-renew. To continue enjoying your plan benefits without interruption, please renew your subscription before it expires.

Renew Now: https://diabetes-health-system.web.app/subscription/${subscriptionId}/renew

What happens if you don't renew:
- You will lose access to all plan features
- Your data will be preserved for 30 days
- You can resubscribe at any time
`}

If you have any questions about your subscription, please don't hesitate to contact our support team.

Thank you,
Diatrack

© ${new Date().getFullYear()} Diatrack. All rights reserved.
This is an automated message, please do not reply to this email.
    `,
  };
};