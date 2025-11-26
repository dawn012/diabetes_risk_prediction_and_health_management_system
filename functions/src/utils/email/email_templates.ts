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

// 1️⃣ USER BANNED EMAIL
export const generateUserBannedEmail = (
  userName: string,
  banReason?: string
) => {
  return {
    subject: "Your Diatrack account has been suspended",
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
          .info-box { background: #fff3cd; padding: 15px; border-radius: 5px; margin: 15px 0; border-left: 4px solid #ffc107; }
          .warning { color: #856404; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h2>Account Suspended</h2>
          </div>
          <div class="content">
            <h3>Dear ${userName},</h3>

            <p>We regret to inform you that your Diatrack account has been suspended by an administrator.</p>

            ${banReason ? `
              <div class="info-box">
                <p class="warning"><strong>Reason:</strong> ${banReason}</p>
              </div>
            ` : ""}

            <p><strong>What this means:</strong></p>
            <ul>
              <li>You cannot access your account at this time</li>
              <li>Your data is preserved and secure</li>
              <li>You cannot log in or use the app</li>
            </ul>

            <p><strong>What you can do:</strong></p>
            <ul>
              <li>If you believe this is an error, please contact our support team</li>
              <li>Review our Terms of Service and Community Guidelines</li>
              <li>Wait for further communication from our team</li>
            </ul>

            <p style="text-align: center;">
              <a href="https://diabetes-health-system.web.app/support" class="button">
                Contact Support
              </a>
            </p>

            <p>If you have any questions or concerns, our support team is available to assist you.</p>

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
⚠️ ACCOUNT SUSPENDED

Dear ${userName},

We regret to inform you that your Diatrack account has been suspended by an administrator.

${banReason ? `Reason: ${banReason}\n` : ""}
What this means:
- You cannot access your account at this time
- Your data is preserved and secure
- You cannot log in or use the app

What you can do:
- If you believe this is an error, please contact our support team
- Review our Terms of Service and Community Guidelines
- Wait for further communication from our team

Contact Support: https://diabetes-health-system.web.app/support

If you have any questions or concerns, our support team is available to assist you.

Best regards,
Diatrack Team

© ${new Date().getFullYear()} Diatrack. All rights reserved.
This is an automated message, please do not reply to this email.
    `,
  };
};

// 2️⃣ USER RESTORED FROM BAN EMAIL
export const generateUserRestoredFromBanEmail = (
  userName: string,
  restoredBy: string = "an administrator"
) => {
  return {
    subject: "Your Diatrack account has been restored",
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
          .info-box { background: #d4edda; padding: 15px; border-radius: 5px; margin: 15px 0; border-left: 4px solid #28a745; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h2>Account Restored!</h2>
          </div>
          <div class="content">
            <h3>Dear ${userName},</h3>

            <p>Good news! Your Diatrack account has been restored by ${restoredBy}. You can now access all features again.</p>

            <div class="info-box">
              <p><strong>✓ Your account is now active</strong></p>
              <p><strong>✓ All features are available</strong></p>
              <p><strong>✓ Your data is intact</strong></p>
            </div>

            <p>You can now:</p>
            <ul>
              <li>Log in to your account</li>
              <li>Access all your health data</li>
              <li>Use all app features</li>
              <li>Participate in the community</li>
            </ul>

            <p style="text-align: center;">
              <a href="https://diabetes-health-system.web.app/login" class="button">
                Log In Now
              </a>
            </p>

            <p>Welcome back! We're glad to have you with us again. If you have any questions, please don't hesitate to contact our support team.</p>

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
✅ ACCOUNT RESTORED!

Dear ${userName},

Good news! Your Diatrack account has been restored by ${restoredBy}. You can now access all features again.

✓ Your account is now active
✓ All features are available
✓ Your data is intact

You can now:
- Log in to your account
- Access all your health data
- Use all app features
- Participate in the community

Log In Now: https://diabetes-health-system.web.app/login

Welcome back! We're glad to have you with us again. If you have any questions, please don't hesitate to contact our support team.

Best regards,
Diatrack Team

© ${new Date().getFullYear()} Diatrack. All rights reserved.
This is an automated message, please do not reply to this email.
    `,
  };
};

// 3️⃣ USER RESTORED FROM INACTIVE EMAIL
export const generateUserRestoredFromInactiveEmail = (
  userName: string,
  restoredBy: string = "an administrator"
) => {
  return {
    subject: "🎉 Your Diatrack account has been reactivated",
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #e3f2fd; padding: 20px; text-align: center; }
          .content { padding: 30px; background: #fff; }
          .footer { padding: 20px; text-align: center; font-size: 12px; color: #666; }
          .button { background: #007bff; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; display: inline-block; }
          .info-box { background: #d1ecf1; padding: 15px; border-radius: 5px; margin: 15px 0; border-left: 4px solid #0c5460; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h2>🎉 Account Reactivated!</h2>
          </div>
          <div class="content">
            <h3>Dear ${userName},</h3>

            <p>We're excited to let you know that your Diatrack account has been reactivated by ${restoredBy}!</p>

            <div class="info-box">
              <p><strong>Your account status has changed from Inactive to Active</strong></p>
            </div>

            <p>What's been restored:</p>
            <ul>
              <li>✅ Full access to your account</li>
              <li>✅ All your health data and records</li>
              <li>✅ App features and functionality</li>
              <li>✅ Community access</li>
              <li>✅ Your achievements and progress</li>
            </ul>

            <p style="text-align: center;">
              <a href="https://diabetes-health-system.web.app/login" class="button">
                Access Your Account
              </a>
            </p>

            <p>We're happy to have you back! If you didn't request this reactivation or have any questions, please contact our support team.</p>

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
🎉 ACCOUNT REACTIVATED!

Dear ${userName},

We're excited to let you know that your Diatrack account has been reactivated by ${restoredBy}!

Your account status has changed from Inactive to Active

What's been restored:
- ✅ Full access to your account
- ✅ All your health data and records
- ✅ App features and functionality
- ✅ Community access
- ✅ Your achievements and progress

Access Your Account: https://diabetes-health-system.web.app/login

We're happy to have you back! If you didn't request this reactivation or have any questions, please contact our support team.

Best regards,
Diatrack Team

© ${new Date().getFullYear()} Diatrack. All rights reserved.
This is an automated message, please do not reply to this email.
    `,
  };
};

// Manager Welcome Email Template
export const generateManagerWelcomeEmail = (
  userName: string,
  role: string,
  passwordResetLink: string
) => {
  const formattedRole = role.split(" ").map(word =>
    word.charAt(0).toUpperCase() + word.slice(1)
  ).join(" ");

  return {
    subject: "🎉 Welcome to Diatrack Manager Portal - Set Your Password",
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #e3f2fd; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { padding: 30px; background: #fff; }
          .footer { padding: 20px; text-align: center; font-size: 12px; color: #666; }
          .button { background: #2196F3; color: white; padding: 15px 30px; text-decoration: none; border-radius: 8px; display: inline-block; font-size: 16px; font-weight: bold; margin: 20px 0; }
          .info-box { background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #2196F3; }
          .role-badge { background: #2196F3; color: white; padding: 8px 16px; border-radius: 20px; font-size: 14px; font-weight: bold; display: inline-block; }
          .steps { margin: 25px 0; }
          .step { display: flex; align-items: flex-start; margin-bottom: 15px; }
          .step-number { background: #2196F3; color: white; width: 30px; height: 30px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: bold; margin-right: 15px; flex-shrink: 0; padding-top: 2px; padding-left: 6px; }
          .step-content { flex: 1; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1 style="margin: 0; color: #1565C0;">Welcome to Diatrack!</h1>
            <p style="margin: 10px 0 0 0; font-size: 18px; color: #1976D2;">Manager Account Setup</p>
          </div>
          <div class="content">
            <h2>Dear ${userName},</h2>

            <p>Welcome to the Diatrack Manager Portal! Your manager account has been successfully created with the following role:</p>

            <div style="text-align: center; margin: 25px 0;">
              <span class="role-badge">${formattedRole}</span>
            </div>

            <div class="info-box">
              <h3 style="margin-top: 0; color: #1565C0;">Next Steps</h3>
              <p>To get started, you need to set your password and verify your account.</p>
            </div>

            <div class="steps">
              <div class="step">
                <div class="step-number">1</div>
                <div class="step-content">
                  <strong>Set Your Password</strong>
                  <p>Click the button below to set a secure password for your account.</p>
                </div>
              </div>

              <div class="step">
                <div class="step-number">2</div>
                <div class="step-content">
                  <strong>Log In</strong>
                  <p>After setting your password, you can log in to the Manager Portal.</p>
                </div>
              </div>

              <div class="step">
                <div class="step-number">3</div>
                <div class="step-content">
                  <strong>Access Dashboard</strong>
                  <p>Start managing users, content, and system operations.</p>
                </div>
              </div>
            </div>

            <div style="text-align: center;">
              <a href="${passwordResetLink}" class="button">
                🚀 Set Your Password
              </a>
            </div>

            <div style="background: #fff3cd; padding: 15px; border-radius: 5px; margin: 20px 0; border-left: 4px solid #ffc107;">
              <strong>⚠️ Important Security Notice:</strong>
              <p style="margin: 8px 0 0 0;">This link will expire in 24 hours for security reasons. If the link expires, you can request a new password reset from the login page.</p>
            </div>

            <p><strong>Need Help?</strong></p>
            <ul>
              <li>If you have trouble setting your password, contact the system administrator</li>
              <li>For technical support, reach out to the IT department</li>
              <li>Review the manager guidelines and documentation</li>
            </ul>

            <p>We're excited to have you on board as part of the Diatrack management team!</p>

            <p>Best regards,<br>
            <strong>Diatrack Administration Team</strong></p>
          </div>
          <div class="footer">
            <p>© ${new Date().getFullYear()} Diatrack - Diabetes Health Management System. All rights reserved.</p>
            <p>This is an automated message, please do not reply to this email.</p>
            <p>If you believe you received this email in error, please contact the system administrator.</p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `
🎉 WELCOME TO DIATRACK MANAGER PORTAL

Dear ${userName},

Welcome to the Diatrack Manager Portal! Your manager account has been successfully created with the role: ${formattedRole}

NEXT STEPS:
To get started, you need to set your password and verify your account.

SETUP STEPS:
1. Set Your Password
   Click the link below to set a secure password for your account.

2. Log In
   After setting your password, you can log in to the Manager Portal.

3. Access Dashboard
   Start managing users, content, and system operations.

SET YOUR PASSWORD:
${passwordResetLink}

⚠️ IMPORTANT SECURITY NOTICE:
This link will expire in 24 hours for security reasons. If the link expires, you can request a new password reset from the login page.

NEED HELP?
- If you have trouble setting your password, contact the system administrator
- For technical support, reach out to the IT department
- Review the manager guidelines and documentation

We're excited to have you on board as part of the Diatrack management team!

Best regards,
Diatrack Administration Team

© ${new Date().getFullYear()} Diatrack - Diabetes Health Management System. All rights reserved.
This is an automated message, please do not reply to this email.
If you believe you received this email in error, please contact the system administrator.
    `,
  };
};

// 4️⃣ MANAGER ROLE CHANGED EMAIL
export const generateManagerRoleChangedEmail = (
  userName: string,
  oldRole: string,
  newRole: string,
  changedBy: string = "an administrator"
) => {
  const formatRole = (role: string) => {
    return role.split(" ").map(word =>
      word.charAt(0).toUpperCase() + word.slice(1)
    ).join(" ");
  };

  const formattedOldRole = formatRole(oldRole);
  const formattedNewRole = formatRole(newRole);

  return {
    subject: "🔐 Your Diatrack Manager Role Has Been Updated",
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #fff3e0; padding: 25px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { padding: 30px; background: #fff; }
          .footer { padding: 20px; text-align: center; font-size: 12px; color: #666; }
          .role-change { background: #f8f9fa; padding: 25px; border-radius: 10px; margin: 25px 0; text-align: center; border: 2px dashed #dee2e6; }
          .old-role { color: #6c757d; text-decoration: line-through; font-size: 18px; margin-bottom: 10px; }
          .arrow { font-size: 24px; color: #ff9800; margin: 10px 0; }
          .new-role { color: #1976d2; font-size: 22px; font-weight: bold; margin-top: 10px; }
          .permissions-box { background: #e8f5e8; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #4caf50; }
          .security-notice { background: #fff3cd; padding: 15px; border-radius: 5px; margin: 20px 0; border-left: 4px solid #ffc107; }
          .button { background: #2196F3; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; display: inline-block; font-weight: bold; }
          .info-item { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #f0f0f0; }
          .info-label { font-weight: 600; color: #555; }
          .info-value { color: #333; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1 style="margin: 0; color: #ff9800;">🔐 Role Updated</h1>
            <p style="margin: 10px 0 0 0; font-size: 16px; color: #f57c00;">Your manager permissions have been changed</p>
          </div>
          <div class="content">
            <h2>Dear ${userName},</h2>

            <p>Your Diatrack manager role has been updated by ${changedBy}. This change affects your access permissions and responsibilities within the system.</p>

            <div class="role-change">
              <div class="old-role">${formattedOldRole}</div>
              <div class="arrow">↓</div>
              <div class="new-role">${formattedNewRole}</div>
            </div>

            <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
              <h3 style="margin-top: 0; color: #333;">Change Details</h3>
              <div class="info-item">
                <span class="info-label">Previous Role:</span>
                <span class="info-value">${formattedOldRole}</span>
              </div>
              <div class="info-item">
                <span class="info-label">New Role:</span>
                <span class="info-value"><strong>${formattedNewRole}</strong></span>
              </div>
              <div class="info-item">
                <span class="info-label">Changed By:</span>
                <span class="info-value">${changedBy}</span>
              </div>
              <div class="info-item">
                <span class="info-label">Effective Date:</span>
                <span class="info-value">${new Date().toLocaleDateString("en-MY", {
    year: "numeric",
    month: "long",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit"
  })}</span>
              </div>
            </div>

            <div class="permissions-box">
              <h3 style="margin-top: 0; color: #2e7d32;">What This Means For You</h3>
              <p><strong>Your new role includes:</strong></p>
              <ul>
                ${getRolePermissionsDescription(newRole)}
              </ul>
              <p>You may notice changes in the available features and options when you next log in.</p>
            </div>

            <div class="security-notice">
              <h4 style="margin-top: 0; color: #856404;">🔒 Security Notice</h4>
              <p style="margin: 8px 0;">
                <strong>If you did not expect this role change or believe it was made in error:</strong>
              </p>
              <ul style="margin: 8px 0; padding-left: 20px;">
                <li>Contact the system administrator immediately</li>
                <li>Verify this change with your supervisor</li>
                <li>Do not share your login credentials with anyone</li>
              </ul>
            </div>

            <p>Thank you for your continued contributions to the Diatrack platform.</p>

            <p>Best regards,<br>
            <strong>Diatrack Administration Team</strong></p>
          </div>
          <div class="footer">
            <p>© ${new Date().getFullYear()} Diatrack - Diabetes Health Management System. All rights reserved.</p>
            <p>This is an automated security notification. Please do not reply to this email.</p>
            <p>If you have concerns about this change, contact: admin@diatrack.com</p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `
🔐 MANAGER ROLE UPDATED

Dear ${userName},

Your Diatrack manager role has been updated by ${changedBy}. This change affects your access permissions and responsibilities within the system.

ROLE CHANGE:
${formattedOldRole} → ${formattedNewRole}

CHANGE DETAILS:
Previous Role: ${formattedOldRole}
New Role: ${formattedNewRole}
Changed By: ${changedBy}
Effective Date: ${new Date().toLocaleDateString("en-MY", {
    year: "numeric",
    month: "long",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit"
  })}

WHAT THIS MEANS FOR YOU:
${getRolePermissionsText(newRole)}

You may notice changes in the available features and options when you next log in.

🔒 SECURITY NOTICE:
If you did not expect this role change or believe it was made in error:
- Contact the system administrator immediately
- Verify this change with your supervisor
- Do not share your login credentials with anyone

Thank you for your continued contributions to the Diatrack platform.

Best regards,
Diatrack Administration Team

© ${new Date().getFullYear()} Diatrack - Diabetes Health Management System. All rights reserved.
This is an automated security notification. Please do not reply to this email.
If you have concerns about this change, contact: admin@diatrack.com
    `,
  };
};

// Helper function to generate role-specific permissions description
function getRolePermissionsDescription(role: string): string {
  const permissions: { [key: string]: string[] } = {
    "user manager": [
      "Manage user accounts and profiles",
      "Handle user support requests",
      "Monitor user activity and compliance",
      "Process account verification requests"
    ],
    "community manager": [
      "Moderate community discussions and content",
      "Manage forum topics and categories",
      "Handle user reports and flags",
      "Foster community engagement and guidelines"
    ],
    "achievement manager": [
      "Create and manage achievement systems",
      "Award achievements to users",
      "Monitor achievement progress and statistics",
      "Design achievement criteria and rewards"
    ],
    "reward manager": [
      "Manage reward catalog and inventory",
      "Process reward redemption requests",
      "Monitor reward distribution and tracking",
      "Coordinate with partners for reward fulfillment"
    ]
  };

  const rolePermissions = permissions[role] || [
    "Access to general manager features",
    "System monitoring capabilities",
    "Basic administrative functions"
  ];

  return rolePermissions.map(permission =>
    `<li>${permission}</li>`
  ).join("");
}

// Helper function for text version
function getRolePermissionsText(role: string): string {
  const permissions: { [key: string]: string[] } = {
    "user manager": [
      "• Manage user accounts and profiles",
      "• Handle user support requests",
      "• Monitor user activity and compliance",
      "• Process account verification requests"
    ],
    "community manager": [
      "• Moderate community discussions and content",
      "• Manage forum topics and categories",
      "• Handle user reports and flags",
      "• Foster community engagement and guidelines"
    ],
    "achievement manager": [
      "• Create and manage achievement systems",
      "• Award achievements to users",
      "• Monitor achievement progress and statistics",
      "• Design achievement criteria and rewards"
    ],
    "reward manager": [
      "• Manage reward catalog and inventory",
      "• Process reward redemption requests",
      "• Monitor reward distribution and tracking",
      "• Coordinate with partners for reward fulfillment"
    ]
  };

  const rolePermissions = permissions[role] || [
    "• Access to general manager features",
    "• System monitoring capabilities",
    "• Basic administrative functions"
  ];

  return rolePermissions.join("\n");
}