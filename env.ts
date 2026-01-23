import { config } from 'dotenv';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

// Load environment variables from .env file in root directory
// The env.ts file is compiled to .output, so we need to go up to the root
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Try loading from current directory (source mode) or from root relative to .output (build mode)
const possiblePaths = [
    join(__dirname, '.env'),
    join(__dirname, '..', '..', '.env'),
];

for (const envPath of possiblePaths) {
    config({ path: envPath });
}

// Export environment variables for use in other modules
export const DATABASE_URL = process.env['DATABASE_URL'];
export const JWT_SECRET = process.env['JWT_SECRET'];
export const SMTP_HOST = process.env['SMTP_HOST'];
export const SMTP_PORT = process.env['SMTP_PORT'];
export const SMTP_USER = process.env['SMTP_USER'];
export const SMTP_PASS = process.env['SMTP_PASS'];
export const FROM_EMAIL = process.env['FROM_EMAIL'];
export const FE_URL = process.env['FE_URL'];
export const GOOGLE_STUDIO_API_KEY = process.env['GOOGLE_STUDIO_API_KEY'];
export const ELEVEN_LABS_API_KEY = process.env['ELEVEN_LABS_API_KEY'];
export const AI_BASE_URL = process.env['AI_BASE_URL'];

if (!DATABASE_URL) {
    throw new Error('Missing required environment var DATABASE_URL');
}

// Export env object for compatibility
export const env = {
    DATABASE_URL,
    JWT_SECRET,
    GOOGLE_STUDIO_API_KEY,
};
