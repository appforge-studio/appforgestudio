
import { GoogleGenerativeAI } from "@google/generative-ai";
import { config } from 'dotenv';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
config({ path: join(__dirname, '..', '..', '.env') });

const apiKey = process.env.GOOGLE_STUDIO_API_KEY || "";
const outputLog = join(__dirname, 'test_responsiveness_output.txt');

async function testResponse() {
    const genAI = new GoogleGenerativeAI(apiKey);
    const models = ["gemini-2.5-flash", "gemini-2.0-flash", "gemini-flash-latest"];
    let log = `Testing responsiveness at ${new Date().toISOString()}\n`;

    for (const modelName of models) {
        log += `\nTesting ${modelName}...\n`;
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
            log += `[OK] ${modelName} took ${Date.now() - start}ms\n`;
            log += `Response: ${text}\n`;
        } catch (e: any) {
            log += `[FAIL] ${modelName}: ${e.message}\n`;
        }
    }

    fs.writeFileSync(outputLog, log);
    console.log("Done.");
}

testResponse();
