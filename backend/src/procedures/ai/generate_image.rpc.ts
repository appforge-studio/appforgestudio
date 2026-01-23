import { defineRpc } from "@arrirpc/server";
import { a } from "@arrirpc/schema";
import { mediaServer } from "../../services/mediaServer";

export default defineRpc({
    params: a.object("GenerateImageParams", {
        prompt: a.string(),
        negativePrompt: a.optional(a.string()),
        width: a.optional(a.number()),
        height: a.optional(a.number()),
        steps: a.optional(a.number()),
    }),
    response: a.object("GenerateImageResponse", {
        success: a.boolean(),
        message: a.string(),
        url: a.optional(a.string()),
    }),
    handler: async ({ params }) => {
        console.log("!!! [Backend RPC] generate_image HIT !!!");
        console.log("Params:", JSON.stringify(params));
        try {
            const aiServerUrl = process.env['AI_BASE_URL'] || process.env['AI_SERVER_URL'] || "http://localhost:5000";
            const fullUrl = `${aiServerUrl}/generate-image`;
            console.log(`🔌 Connecting to AI server at: ${fullUrl}`);

            // Set a long timeout (e.g., 5 minutes) for image generation
            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), 300000); // 300,000ms = 5 minutes

            console.log("⏳ Waiting for AI server response...");
            const response = await fetch(fullUrl, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify({
                    prompt: params.prompt,
                    negative_prompt: params.negativePrompt || "",
                    width: params.width || 512,
                    height: params.height || 512,
                    steps: params.steps || 25,
                }),
                signal: controller.signal,
            });

            clearTimeout(timeoutId);

            if (!response.ok) {
                const errorData = await response.json().catch(() => ({}) as any);
                throw new Error((errorData as any).error || `AI server returned ${response.status}`);
            }

            const imageBuffer = await response.arrayBuffer();
            console.log("✅ Image received from AI server, size:", imageBuffer.byteLength);

            const uploadResult = await mediaServer.uploadMedia({
                originalName: `generated-${Date.now()}.png`,
                bytes: Buffer.from(imageBuffer),
                contentType: "image/png",
                directory: "generated",
            });

            return {
                success: true,
                message: "Image generated and uploaded successfully",
                url: uploadResult.url,
            };
        } catch (error: any) {
            console.error("❌ Image generation failed:", error);
            return {
                success: false,
                message: error.message || "Unknown error occurred during image generation",
            };
        }
    },
});
