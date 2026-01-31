import { defineRpc } from "@arrirpc/server";
import { a } from "@arrirpc/schema";
import { AiService } from "../../services/aiService";

export default defineRpc({
    params: a.object("GenerateDesignParams", {
        prompt: a.string(),
        sessionId: a.string(), // Changed from optional to avoid generator bug
        apiKey: a.optional(a.string()),
    }),
    response: a.object("GenerateDesignResponse", {
        success: a.boolean(),
        message: a.string(), // Changed from nullable
        data: a.any(),
    }),
    handler: async ({ params }) => {
        try {
            const effectiveSessionId = params.sessionId || undefined;
            const designJson = await AiService.generateDesign(params.prompt, effectiveSessionId, false, params.apiKey);
            const responseStr = JSON.stringify(designJson);
            console.log(`✅ Design generated. Size: ${(responseStr.length / 1024).toFixed(2)} KB`);
            return {
                success: true,
                data: designJson,
                message: ""
            };
        } catch (error: any) {
            console.error("Design generation failed:", error);
            return {
                success: false,
                message: error.message || "Unknown error occurred during generation",
                data: null
            };
        }
    },
});
