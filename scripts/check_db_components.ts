
import { getDrizzle } from "./database/postgres";
import { components } from "./database/schema/components";
import { config } from 'dotenv';
import { join } from 'path';

config();

async function checkComponents() {
    const db = getDrizzle();
    const all = await db.select().from(components);
    console.log(`Total components: ${all.length}`);
    all.forEach(c => {
        console.log(`- ${c.name}`);
    });
    process.exit(0);
}

checkComponents();
