# vyom

## Prerequisites

Before starting, ensure you have:
- Node.js v18+ ([nodejs.org](https://nodejs.org/))
- PostgreSQL ([postgresql.org](https://www.postgresql.org/download/))
- Flutter SDK ([flutter.dev](https://flutter.dev/docs/get-started/install))

## Environment Setup

**⚠️ Important: Complete this step first before proceeding!**

1. Create your environment configuration file:
   ```bash
   cp .env.example .env
   ```

2. Open `.env` and update with your own values:
   - `DATABASE_URL`: Your PostgreSQL connection string
   - `JWT_SECRET`: Generate a secure random string for JWT signing
   - `SMTP_*`: Your email service credentials (for OTP/notifications)
   - `FE_URL`: Your frontend URL (default: http://localhost:54502)

   **Note**: For Gmail SMTP, you'll need to generate an [App Password](https://support.google.com/accounts/answer/185833) instead of using your regular password.

## Server Setup

1. Enable Corepack (comes with Node.js):
   ```bash
   corepack enable
   ```
2. Prepare and activate pnpm:
   ```bash
   corepack prepare pnpm@latest --activate
   ```
3. Install dependencies:
   ```bash
   pnpm install
   ```

## Database Setup

1. Create the database:
   ```sql
   CREATE DATABASE VYOM;
   ```
2. Update the `DATABASE_URL` in your `.env` file with your database credentials
3. Push the database schema:
   ```bash
   pnpm db:push
   ```

## Frontend Setup

### Option 1: Download Pre-built APK

If you just want to try the app without building from source:

📱 **[Download APK from Google Drive](https://drive.google.com/drive/folders/1Ke8d4H7lsa4KCdTP3B01HK9XjSZOkNwR?usp=sharing)**

Install the APK on your Android device and you're ready to go!

### Option 2: Build from Source

1. Install Flutter from [flutter.dev](https://flutter.dev/docs/get-started/install)
2. Verify Flutter installation:
   ```bash
   flutter doctor
   ```
   Make sure checks for android pass before proceeding.
3. Run the mobile app:
   ```bash
   cd frontend
   flutter run
   ```
4. Run the TV app (connect to Android TV first):
   ```bash
   cd frontend_tv
   flutter run --no-enable-impeller
   ```
