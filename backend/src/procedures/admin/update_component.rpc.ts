import { a } from "@arrirpc/schema";
import { defineRpc } from "@arrirpc/server";
import { getDrizzle } from "@database/postgres";
import { components } from "@database/schema/components";
import { createComponentFiles } from "../../utils/component_utils";
import { eq } from "drizzle-orm";

export default defineRpc({
    params: a.object("UpdateComponentParams", {
        id: a.string(),
        properties: a.array(
            a.object({
                name: a.string(),
                type: a.stringEnum(["string", "number", "boolean", "color"]),
                initialValue: a.string(),
            })
        ),
        componentCode: a.string(),
    }),
    response: a.object("UpdateComponentResponse", {
        success: a.boolean(),
        message: a.string(),
    }),
    async handler({ params }) {
        try {
            const { id, properties, componentCode } = params;
            const db = getDrizzle();

            const existing = await db.select().from(components).where(eq(components.id, id)).limit(1);
            if (!existing.length) {
                return { success: false, message: "Component not found" };
            }
            const component = existing[0];

            // 1. Update files
            // createComponentFiles overwrites if files exist, which is what we want
            await createComponentFiles(component.name, component.className, properties, componentCode);

            // 2. Update DB
            await db.update(components)
                .set({
                    properties: JSON.stringify(properties),
                    code: componentCode,
                })
                .where(eq(components.id, id));

            return {
                success: true,
                message: `Updated component ${component.name}`,
            };
        } catch (error) {
            console.error("Error updating component:", error);
            return {
                success: false,
                message: error instanceof Error ? error.message : "Failed to update component",
            };
        }
    },
});
