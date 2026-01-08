import { pgTable, text, varchar, boolean } from 'drizzle-orm/pg-core';
import { ulidField, defaultDateFields } from './common';

export const svgs = pgTable('svgs', {
    id: ulidField('id').primaryKey(),
    name: varchar('name', { length: 255 }).notNull(),
    svg: text('svg').notNull(),
    type: varchar('type', { length: 50 }).notNull(), // 'regular', 'solid', 'brands'
    isDefault: boolean('is_default').notNull().default(false),
    ...defaultDateFields,
});

export type Svg = typeof svgs.$inferSelect;
export type NewSvg = typeof svgs.$inferInsert;
