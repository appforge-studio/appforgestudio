import { a } from "@arrirpc/schema";
import { defineRpc } from "@arrirpc/server";
import { getDrizzle } from "@database/postgres";
import { svgs } from "@database/schema/svgs";
import { like, or, count, ilike, desc } from "drizzle-orm";

export default defineRpc({
    params: a.object("GetSvgsParams", {
        limit: a.int32(),
        offset: a.int32(),
        search: a.nullable(a.string()),
    }),
    response: a.object("GetSvgsResponse", {
        success: a.boolean(),
        message: a.string(),
        total: a.int32(),
        svgs: a.array(
            a.object("SvgInfo", {
                id: a.string(),
                name: a.string(),
                svg: a.string(),
                type: a.string(),
            })
        ),
    }),
    async handler({ limit, offset, search }) {
        console.log(`[get_svgs] params: limit=${limit}, offset=${offset}, search=${search}`);
        try {
            const db = getDrizzle();
            const pageSize = limit || 50;
            const pageOffset = offset || 0;

            let query = db.select().from(svgs).$dynamic();

            if (search) {
                const searchPattern = `%${search}%`;
                query = query.where(
                    or(
                        ilike(svgs.name, searchPattern),
                        ilike(svgs.type, searchPattern)
                    )
                );
            }

            // Get total count for pagination
            // Clone query for count? database specific. 
            // Ideally we do a separate count query or use window function.
            // For simplicity, let's just run a count query.

            let countQuery = db.select({ count: count() }).from(svgs).$dynamic();
            if (search) {
                const searchPattern = `%${search}%`;
                countQuery = countQuery.where(
                    or(
                        ilike(svgs.name, searchPattern),
                        ilike(svgs.type, searchPattern)
                    )
                );
            }

            const totalResult = await countQuery;
            const total = totalResult[0]?.count || 0;

            const results = await query.limit(pageSize).offset(pageOffset).orderBy(desc(svgs.createdAt), desc(svgs.id));

            return {
                success: true,
                message: "Fetched SVGs successfully",
                total: total,
                svgs: results.map(s => ({
                    id: s.id,
                    name: s.name,
                    svg: s.svg,
                    type: s.type
                })),
            };
        } catch (error) {
            console.error("Error fetching SVGs:", error);
            return {
                success: false,
                message: error instanceof Error ? error.message : "Failed to fetch SVGs",
                total: 0,
                svgs: [],
            };
        }
    },
});
