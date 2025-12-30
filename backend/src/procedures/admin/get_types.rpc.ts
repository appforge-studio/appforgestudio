import { a } from "@arrirpc/schema";
import { defineRpc } from "@arrirpc/server";
import { getDrizzle } from "@database/postgres";
import { types } from "@database/schema/types";
import { desc } from "drizzle-orm";
import { readFile } from "fs/promises";
import { join, resolve } from "path";

export default defineRpc({
    params: a.object("GetTypesParams", {}),
    response: a.object("GetTypesResponse", {
        success: a.boolean(),
        message: a.string(),
        types: a.array(
            a.object("Type", {
                id: a.string(),
                name: a.string(),
                className: a.string(),
                path: a.string(),
                code: a.string(),
                structure: a.string(),
                enumValues: a.string(), // JSON string
                createdAt: a.string(),
                updatedAt: a.string(),
            })
        ),
    }),
    async handler({ }) {
        try {
            const db = getDrizzle();
            const allTypes = await db.select().from(types).orderBy(desc(types.createdAt));

            const typesWithCode = await Promise.all(allTypes.map(async (t) => {
                let code = "";
                try {
                    // Stored path example: /frontend/lib/models/enums/status.dart
                    // We need to resolve this relative to the project root (.. from backend)

                    // t.path contains path relative to project root
                    // resolve(process.cwd(), '..', t.path.replace(/^\//,''))

                    const projectRoot = resolve(process.cwd(), '..');
                    const relativePath = t.path.startsWith('/') ? t.path.slice(1) : t.path;
                    const codePath = resolve(projectRoot, relativePath);

                    code = await readFile(codePath, 'utf8');
                } catch (e) {
                    // File might not exist
                }

                return {
                    id: t.id,
                    name: t.name,
                    className: t.className,
                    path: t.path,
                    code: code,
                    structure: t.structure,
                    enumValues: t.enumValues ?? "[]",
                    createdAt: t.createdAt.toISOString(),
                    updatedAt: t.updatedAt.toISOString(),
                };
            }));

            return {
                success: true,
                message: "Types fetched successfully",
                types: typesWithCode,
            };
        } catch (error) {
            console.error("Error fetching types:", error);
            return {
                success: false,
                message: "Failed to fetch types",
                types: [],
            };
        }
    },
});
