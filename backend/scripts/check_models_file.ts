
import { GoogleGenerativeAI } from "@google/generative-ai";
import { config } from 'dotenv';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
config({ path: join(__dirname, '..', '..', '.env') });

const apiKey = process.env.GOOGLE_STUDIO_API_KEY || "";
const outputLog = join(__dirname, 'model_check_output.txt');

const modelsToTest = [
    "gemini-1.5-flash",
    "gemini-1.5-flash-001",
    "gemini-1.5-pro",
    "gemini-pro",
    "gemini-1.0-pro"
];

async function checkModels() {
    const genAI = new GoogleGenerativeAI(apiKey);
    let log = `Checking models with key ...${apiKey.slice(-4)}\n`;

    // Also try to list models if possible using listModels
    // Though listModels is not on genAI instance directly in some versions, it's usually on a Manager.
    // But let's stick to testing generation.

    for (const modelName of modelsToTest) {
        try {
            const model = genAI.getGenerativeModel({ model: modelName });
            const result = await model.generateContent("Test");
            const response = await result.response;
            log += `[OK] ${modelName}\n`;
        } catch (error: any) {
            log += `[FAIL] ${modelName} - ${error.message}\n`;
        }
    }

    fs.writeFileSync(outputLog, log);
    console.log("Done writing log.");
}

checkModels();
