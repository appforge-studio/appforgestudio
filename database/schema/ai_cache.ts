import { pgTable, text, varchar, index } from 'drizzle-orm/pg-core';
import { ulidField, defaultDateFields } from './common';

export const aiDesignCache = pgTable('ai_design_cache', {
    id: ulidField('id').primaryKey(),
    prompt: text('prompt').notNull().unique(),
    designJson: text('design_json').notNull(),
    modelUsed: varchar('model_used', { length: 255 }).notNull(),
    ...defaultDateFields,
}, (table) => {
    return {
        promptIndex: index('ai_design_cache_prompt_idx').on(table.prompt),
    };
});

export type AiDesignCache = typeof aiDesignCache.$inferSelect;
export type NewAiDesignCache = typeof aiDesignCache.$inferInsert;
