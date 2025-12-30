import { a } from "@arrirpc/schema";
import { defineRpc } from "@arrirpc/server";
import { getDrizzle } from "@database/postgres";
import { types } from "@database/schema/types";
import { eq } from "drizzle-orm";
import { writeFile, mkdir } from "fs/promises";
import { join, resolve } from "path";

export default defineRpc({
    params: a.object("SaveTypeCodeParams", {
        typeId: a.string(),
        code: a.string(),
    }),
    response: a.object("SaveTypeCodeResponse", {
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

            const frontendModelsDir = resolve(process.cwd(), '../frontend/lib/models/types');
            await mkdir(frontendModelsDir, { recursive: true });

            const codePath = join(frontendModelsDir, `${type.name}.dart`);
            await writeFile(codePath, params.code, 'utf8');

            return {
                success: true,
                message: "Code saved successfully",
            };
        } catch (error) {
            console.error("Error saving code:", error);
            return {
                success: false,
                message: error instanceof Error ? error.message : "Failed to save code",
            };
        }
    },
});
