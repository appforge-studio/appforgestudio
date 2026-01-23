
import { GoogleGenerativeAI } from "@google/generative-ai";
import { config } from 'dotenv';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
config({ path: join(__dirname, '..', '..', '.env') });

const apiKey = process.env.GOOGLE_STUDIO_API_KEY || "";

async function testResponse() {
    const genAI = new GoogleGenerativeAI(apiKey);
    const models = ["gemini-2.5-flash", "gemini-2.0-flash", "gemini-flash-latest"];

    for (const modelName of models) {
        console.log(`\nTesting ${modelName}...`);
        try {
            const model = genAI.getGenerativeModel({
                model: modelName,
                generationConfig: {
                    responseMimeType: "application/json",
                }
            });
            const start = Date.now();
            const result = await model.generateContent("Respond with valid JSON: { \"status\": \"ok\" }");
            const response = await result.response;
            const text = response.text();
            console.log(`[OK] ${modelName} took ${Date.now() - start}ms`);
            console.log(`Response: ${text}`);
        } catch (e: any) {
            console.log(`[FAIL] ${modelName}: ${e.message}`);
        }
    }
}

testResponse();
