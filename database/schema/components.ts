import { pgTable, text, varchar, boolean } from 'drizzle-orm/pg-core';
import { ulidField, defaultDateFields } from './common';

export const components = pgTable('components', {
    id: ulidField('id').primaryKey(),
    name: varchar('name', { length: 255 }).notNull().unique(),
    className: varchar('class_name', { length: 255 }).notNull(),
    path: text('path').notNull(),
    properties: text('properties').notNull().default("[]"), // JSON string type definition
    code: text('code').notNull().default(""),
    isDefault: boolean('is_default').notNull().default(false),
    isResizable: boolean('is_resizable').notNull().default(true),
    ...defaultDateFields,
});

export type Component = typeof components.$inferSelect;
export type NewComponent = typeof components.$inferInsert;
