import { defineRpc } from "@arrirpc/server";
import { a } from "@arrirpc/schema";
import { getDrizzle } from "@database/postgres";
import { screens } from "@database/schema/screens";
import { eq } from "drizzle-orm";

export default defineRpc({
    params: a.object("DeleteScreenParams", {
        id: a.string(),
    }),
    response: a.object("DeleteScreenResponse", {
        success: a.boolean(),
    }),
    handler: async ({ params }) => {
        const db = getDrizzle();

        await db.delete(screens).where(eq(screens.id, params.id));

        return {
            success: true,
        };
    },
});
