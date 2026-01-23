import { getDrizzle } from '../database/postgres';
import { aiDesignCache } from '../database/schema/ai_cache';

async function clearCache() {
    const db = getDrizzle();
    console.log('🗑️ Clearing AI Design Cache...');
    try {
        await db.delete(aiDesignCache);
        console.log('✅ AI Design Cache cleared successfully');
    } catch (e) {
        console.error('❌ Failed to clear AI Design Cache:', e);
    }
}

clearCache();
