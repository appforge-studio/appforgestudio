import { a } from "@arrirpc/schema";
import { defineRpc } from "@arrirpc/server";
import { getDrizzle } from "@database/postgres";
import { types } from "@database/schema/types";
import { eq } from "drizzle-orm";
import { resolveTypePath, generateTypeContent, writeTypeFile } from "../../utils/type_utils";

export default defineRpc({
    params: a.object("UpdateTypeDefinitionParams", {
        typeId: a.string(),
        code: a.string(),
        enumValues: a.string(),
        structure: a.string(),
    }),
    response: a.object("UpdateTypeDefinitionResponse", {
        success: a.boolean(),
        message: a.string(),
    }),
    async handler({ params }) {
        try {
            const db = getDrizzle();
            const [type] = await db.select().from(types).where(eq(types.id, params.typeId));

            if (!type) {
                return {
                    success: false,
                    message: "Type not found",
                };
            }

            // AUTO-CORRECTION LOGIC:
            // Always resolve path based on current structure preference, ignorning potentially stale DB path.
            // This fixes "legacy" types created before the folder split.
            const structure = params.structure === 'enum' ? 'enum' : 'object';
            const { absolutePath, relativePath } = resolveTypePath(type.name, structure);

            const values: string[] = JSON.parse(params.enumValues || "[]");
            const content = generateTypeContent(type.className, structure, values, params.code);

            await writeTypeFile(absolutePath, content);

            // Update DB (including path if it changed!)
            await db.update(types)
                .set({
                    enumValues: params.enumValues,
                    path: relativePath,
                    structure: structure // Ensure structure is updated if switched (though UI might not allow switching easily)
                })
                .where(eq(types.id, params.typeId));

            return {
                success: true,
                message: "Type updated successfully",
            };
        } catch (error) {
            console.error("Error updating type definition:", error);
            return {
                success: false,
                message: error instanceof Error ? `${error.message}` : "Failed to update type",
            };
        }
    },
});
