import { pgTable, text, varchar } from 'drizzle-orm/pg-core';
import { ulidField, defaultDateFields } from './common';

export const screens = pgTable('screens', {
    id: ulidField('id').primaryKey(),
    name: varchar('name', { length: 255 }).notNull(),
    content: text('content').notNull().default("[]"), // JSON string of components
    ...defaultDateFields,
});

export type Screen = typeof screens.$inferSelect;
export type NewScreen = typeof screens.$inferInsert;
