import { a } from "@arrirpc/schema";
import { defineRpc } from "@arrirpc/server";
import { getDrizzle } from "@database/postgres";
import { types } from "@database/schema/types";
import { ulid } from "ulidx";
import { resolveTypePath, generateTypeContent, writeTypeFile } from "../../utils/type_utils";

export default defineRpc({
    params: a.object("CreateTypeParams", {
        name: a.string(),
        className: a.string(),
        structure: a.string(), // 'object' | 'enum'
    }),
    response: a.object("CreateTypeResponse", {
        success: a.boolean(),
        message: a.string(),
    }),
    async handler({ params }) {
        try {
            const db = getDrizzle();
            const structure = params.structure === 'enum' ? 'enum' : 'object';

            const { absolutePath, relativePath } = resolveTypePath(params.name, structure);

            const content = generateTypeContent(params.className, structure, ["placeholder"], ""); // Initial placeholder for enum

            await writeTypeFile(absolutePath, content);

            await db.insert(types).values({
                id: ulid(),
                name: params.name,
                className: params.className,
                path: relativePath,
                structure: structure,
                enumValues: structure === 'enum' ? '["placeholder"]' : null,
            });

            return {
                success: true,
                message: `Created ${params.name}`,
            };
        } catch (error) {
            console.error("Error creating type:", error);
            return {
                success: false,
                message: error instanceof Error ?
                    `Failed: ${error.message} (CWD: ${process.cwd()})` :
                    "Failed to create type",
            };
        }
    },
});
