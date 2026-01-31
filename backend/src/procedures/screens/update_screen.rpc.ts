import { defineRpc } from "@arrirpc/server";
import { a } from "@arrirpc/schema";
import { getDrizzle } from "@database/postgres";
import { screens } from "@database/schema/screens";
import { eq } from "drizzle-orm";

export default defineRpc({
    params: a.object("UpdateScreenParams", {
        id: a.string(),
        content: a.string(),
    }),
    response: a.object("UpdateScreenResponse", {
        success: a.boolean(),
        updatedAt: a.timestamp(),
    }),
    handler: async ({ params }) => {
        const db = getDrizzle();

        const [updatedScreen] = await db
            .update(screens)
            .set({
                content: params.content,
                updatedAt: new Date(),
            })
            .where(eq(screens.id, params.id))
            .returning();

        if (!updatedScreen) {
            throw new Error(`Screen with ID ${params.id} not found`);
        }

        return {
            success: true,
            updatedAt: updatedScreen.updatedAt,
        };
    },
});
