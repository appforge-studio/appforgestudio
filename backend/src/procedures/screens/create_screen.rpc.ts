import { defineRpc } from "@arrirpc/server";
import { a } from "@arrirpc/schema";
import { getDrizzle } from "@database/postgres";
import { screens } from "@database/schema/screens";
import { ulid } from "ulidx";

export default defineRpc({
    params: a.object("CreateScreenParams", {
        name: a.string(),
    }),
    response: a.object("CreateScreenResponse", {
        id: a.string(),
        name: a.string(),
        content: a.string(),
        createdAt: a.timestamp(),
        updatedAt: a.timestamp(),
    }),
    handler: async ({ params }) => {
        const db = getDrizzle();
        const newScreenId = ulid();

        const [insertedScreen] = await db
            .insert(screens)
            .values({
                id: newScreenId,
                name: params.name,
                content: "[]",
            })
            .returning();

        if (!insertedScreen) {
            throw new Error("Failed to create screen");
        }

        return {
            id: insertedScreen.id,
            name: insertedScreen.name,
            content: insertedScreen.content,
            createdAt: insertedScreen.createdAt,
            updatedAt: insertedScreen.updatedAt,
        };
    },
});
