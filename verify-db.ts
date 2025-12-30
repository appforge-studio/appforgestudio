
import { config } from 'dotenv';
import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import { types } from './database/schema/types';
import { components } from './database/schema/components';

config({ path: '.env' });

const DATABASE_URL = process.env.DATABASE_URL;

async function verify() {
    const client = postgres(DATABASE_URL!);
    const db = drizzle(client);

    console.log('--- Types ---');
    const allTypes = await db.select().from(types);
    allTypes.forEach(t => console.log(`- ${t.name} (${t.isDefault ? 'Default' : 'Custom'})`));

    console.log('\n--- Components ---');
    const allComponents = await db.select().from(components);
    allComponents.forEach(c => console.log(`- ${c.name} (${c.isDefault ? 'Default' : 'Custom'})`));

    await client.end();
}

verify();
