import { defineRpc } from "@arrirpc/server";
import { a } from "@arrirpc/schema";
import { AiService } from "../../services/aiService";

export default defineRpc({
    params: a.object({
        sessionId: a.string(),
        prompt: a.string(),
    }),
    response: a.object({
        success: a.boolean(),
        message: a.string(),
        data: a.any(),
    }),
    handler: async ({ params }) => {
        try {
            const resultJson = await AiService.iterateDesign(params.sessionId, params.prompt);
            return {
                success: true,
                message: "",
                data: resultJson,
            };
        } catch (error: any) {
            console.error("❌ Iterate Design Error:", error);
            return {
                success: false,
                message: error.message || "Failed to iterate design",
                data: null,
            };
        }
    },
});
