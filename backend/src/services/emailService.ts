import nodemailer from 'nodemailer';
import { SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, FROM_EMAIL } from '@env';

// Create reusable transporter
const transporter = nodemailer.createTransport({
  host: SMTP_HOST,
  port: parseInt(SMTP_PORT || '587'),
  secure: false, // true for 465, false for other ports
  auth: {
    user: SMTP_USER,
    pass: SMTP_PASS,
  },
});

export interface SendOtpEmailParams {
  to: string;
  otp: string;
  userName: string;
}

export async function sendOtpEmail({ to, otp, userName }: SendOtpEmailParams): Promise<void> {
  const mailOptions = {
    from: `"Vyom" <${FROM_EMAIL}>`,
    to,
    subject: 'Verify Your Email - Vyom',
    html: `
      <!DOCTYPE html>
      <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .otp-box { background: white; border: 2px dashed #4CAF50; padding: 20px; text-align: center; margin: 20px 0; border-radius: 8px; }
            .otp-code { font-size: 32px; font-weight: bold; color: #4CAF50; letter-spacing: 8px; }
            .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>🧘 Vyom</h1>
              <p>Verify Your Email Address</p>
            </div>
            <div class="content">
              <p>Hi ${userName},</p>
              <p>Thank you for signing up with Vyom! To complete your registration, please verify your email address using the 4-digit code below:</p>
              
              <div class="otp-box">
                <p style="margin: 0; color: #666;">Your verification code:</p>
                <div class="otp-code">${otp}</div>
              </div>
              
              <p><strong>This code will expire in 10 minutes.</strong></p>
              <p>If you didn't create an account with Vyom, please ignore this email.</p>
              
              <div class="footer">
                <p>© ${new Date().getFullYear()} Vyom. All rights reserved.</p>
              </div>
            </div>
          </div>
        </body>
      </html>
    `,
    text: `Hi ${userName},\n\nYour Vyom email verification code is: ${otp}\n\nThis code will expire in 10 minutes.\n\nIf you didn't create an account with Vyom, please ignore this email.`,
  };

  await transporter.sendMail(mailOptions);
}

// Generate 4-digit OTP
export function generateOtp(): string {
  return Math.floor(1000 + Math.random() * 9000).toString();
}

// Check if OTP is expired (10 minutes validity)
export function isOtpExpired(expiresAt: string): boolean {
  return new Date() > new Date(expiresAt);
}

// Get OTP expiry timestamp (10 minutes from now)
export function getOtpExpiry(): string {
  const expiryDate = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes
  return expiryDate.toISOString();
}
