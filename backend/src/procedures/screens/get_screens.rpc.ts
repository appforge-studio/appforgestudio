import { defineRpc } from "@arrirpc/server";
import { a } from "@arrirpc/schema";
import { getDrizzle } from "@database/postgres";
import { screens } from "@database/schema/screens";
import { desc } from "drizzle-orm";

export default defineRpc({
    params: a.object("GetScreensParams", {}),
    response: a.object("GetScreensResponse", {
        screens: a.array(
            a.object({
                id: a.string(),
                name: a.string(),
                content: a.string(),
                createdAt: a.timestamp(),
                updatedAt: a.timestamp(),
            })
        ),
    }),
    handler: async () => {
        const db = getDrizzle();
        const results = await db
            .select()
            .from(screens)
            .orderBy(desc(screens.updatedAt));

        return {
            screens: results.map((s) => ({
                id: s.id,
                name: s.name,
                content: s.content,
                createdAt: s.createdAt,
                updatedAt: s.updatedAt,
            })),
        };
    },
});
