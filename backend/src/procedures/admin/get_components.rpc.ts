import { a } from "@arrirpc/schema";
import { defineRpc } from "@arrirpc/server";
import { getDrizzle } from "@database/postgres";
import { components } from "@database/schema/components";
import { readFile } from "fs/promises";
import { resolve, join } from "path";

export default defineRpc({
    params: a.object("GetComponentsParams", {}),
    response: a.object("GetComponentsResponse", {
        success: a.boolean(),
        message: a.string(),
        components: a.array(
            a.object("ComponentInfo", {
                id: a.string(),
                name: a.string(),
                className: a.string(),
                path: a.string(),
                properties: a.string(), // JSON string of properties
                code: a.string(),
            })
        ),
    }),
    async handler({ }) {
        try {
            const db = getDrizzle();
            const dbComponents = await db.select().from(components);

            const enhancedComponents = dbComponents.map((c) => {
                return {
                    id: c.id,
                    name: c.name,
                    className: c.className,
                    path: c.path,
                    properties: c.properties || "[]",
                    code: c.code || "",
                };
            });

            return {
                success: true,
                message: "Fetched components successfully",
                components: enhancedComponents,
            };
        } catch (error) {
            console.error("Error fetching components:", error);
            return {
                success: false,
                message: error instanceof Error ? error.message : "Failed to fetch components",
                components: [], // Fallback? Or we could throw/return error state strictly.
            };
        }
    },
});

