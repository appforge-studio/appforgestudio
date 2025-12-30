import { a } from "@arrirpc/schema";
import { defineRpc } from "@arrirpc/server";
import { createComponentFiles, registerComponent } from "../../utils/component_utils";
import { getDrizzle } from "@database/postgres";
import { components } from "@database/schema/components";
import { ulid } from "ulidx";

export default defineRpc({
    params: a.object("CreateComponentParams", {
        name: a.string(), // e.g. "heroHeader" (enum value, folder name)
        className: a.string(), // e.g. "HeroHeader" (class name prefix)
        properties: a.array(
            a.object({
                name: a.string(),
                type: a.string(),
                initialValue: a.string(), // Passing as string for simplicity, parsed or used directly
            })
        ),
        componentCode: a.optional(a.string()),
    }),
    response: a.object("CreateComponentResponse", {
        success: a.boolean(),
        message: a.string(),
    }),
    async handler({ params }) {
        try {
            const { name, className, properties: props, componentCode } = params;
            // TODO: Add validation for name/className format

            // Map the properties to match the interface if needed, currently matching structure
            // initialValue is string, need to ensure it's treated correctly in utils

            // 1. Create files
            await createComponentFiles(name, className, props, componentCode || '');

            // 2. Register
            await registerComponent(name, className);

            const db = getDrizzle();
            await db.insert(components).values({
                id: ulid(),
                name,
                className,
                path: `/frontend/lib/components/${name}`, // Construct path
                properties: JSON.stringify(props),
                code: componentCode || '',
            });

            return {
                success: true,
                message: `Created component ${name}`,
            };
        } catch (error) {
            console.error("Error creating component:", error);
            return {
                success: false,
                message: error instanceof Error ? error.message : "Failed to create component",
            };
        }
    },
});
