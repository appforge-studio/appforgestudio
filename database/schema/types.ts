import { pgTable, text, varchar, boolean } from 'drizzle-orm/pg-core';
import { ulidField, defaultDateFields } from './common';

export const types = pgTable('types', {
    id: ulidField('id').primaryKey(),
    name: varchar('name', { length: 255 }).notNull().unique(),
    className: varchar('class_name', { length: 255 }).notNull(),
    path: text('path').notNull(),
    structure: varchar('structure', { length: 50 }).notNull().default('object'), // 'object' | 'enum'
    enumValues: text('enum_values'), // JSON string array for enum values
    isDefault: boolean('is_default').notNull().default(false),
    ...defaultDateFields,
});

export type Type = typeof types.$inferSelect;
export type NewType = typeof types.$inferInsert;
