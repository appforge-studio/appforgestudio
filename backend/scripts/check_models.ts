
import { GoogleGenerativeAI } from "@google/generative-ai";
import { config } from 'dotenv';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

// Load env just like env.ts but directly for this script
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
// Assuming this script is in backend/scripts/check_models.ts, so root is ../../
config({ path: join(__dirname, '..', '..', '.env') });

const apiKey = process.env.GOOGLE_STUDIO_API_KEY;

if (!apiKey) {
    console.error("❌ GOOGLE_STUDIO_API_KEY not found in environment.");
    process.exit(1);
}

console.log(`Checking models with API Key ending in ...${apiKey.slice(-4)}`);

/*
Since there isn't a direct listModels method on the client instance easily accessible in some versions,
we usually have to check documentation or use the REST API.
However, newer SDKs might expose it.
But typically 404 on a model means the model ID is wrong.
Let's try to just test a few known model names with a simple generateContent to see which one works.
*/

const modelsToTest = [
    "gemini-1.5-flash",
    "gemini-1.5-flash-latest",
    "gemini-1.5-flash-001",
    "gemini-1.5-pro",
    "gemini-1.5-pro-latest",
    "gemini-1.0-pro",
    "gemini-pro"
];

async function checkModels() {
    const genAI = new GoogleGenerativeAI(apiKey);

    console.log("\nTesting models...");

    for (const modelName of modelsToTest) {
        try {
            const model = genAI.getGenerativeModel({ model: modelName });
            // Try a minimal prompt
            const result = await model.generateContent("Hello");
            const response = await result.response;
            if (response) {
                console.log(`[OK] ${modelName}`);
            } else {
                console.log(`[WARN] ${modelName} returned empty response`);
            }
        } catch (error: any) {
            if (error.status === 404) {
                console.log(`[404] ${modelName} NOT FOUND`);
            } else {
                console.log(`[ERR] ${modelName}: ${error.message.split('\n')[0]}`);
            }
        }
    }
}

checkModels();
