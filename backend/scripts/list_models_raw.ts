
import { config } from 'dotenv';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
config({ path: join(__dirname, '..', '..', '.env') });

const apiKey = process.env.GOOGLE_STUDIO_API_KEY || "";
const outputLog = join(__dirname, 'models_list_raw.txt');

async function listModels() {
    const url = `https://generativelanguage.googleapis.com/v1beta/models?key=${apiKey}`;
    try {
        const response = await fetch(url);
        const data = await response.json();

        let log = `Status: ${response.status}\n`;
        if (data.models) {
            log += "Available Models:\n";
            data.models.forEach((m: any) => {
                log += `- ${m.name} (${m.supportedGenerationMethods?.join(', ')})\n`;
            });
        } else {
            log += `Error/No models: ${JSON.stringify(data, null, 2)}`;
        }

        fs.writeFileSync(outputLog, log);
        console.log("Done writing list.");
    } catch (e: any) {
        fs.writeFileSync(outputLog, `Fetch error: ${e.message}`);
        console.log("Error writing list.");
    }
}

listModels();
