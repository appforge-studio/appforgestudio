import { timestamp, varchar } from 'drizzle-orm/pg-core';

export const ulidField = (name: string) => varchar(name, { length: 36 });

export const defaultDateFields = {
    createdAt: timestamp('created_at', { mode: 'date' }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { mode: 'date' })
        .notNull()
        .$onUpdate(() => new Date())
        .defaultNow(),
};
