import { defineRpc } from "@arrirpc/server";
import { a } from "@arrirpc/schema";
import { mediaServer } from "../../services/mediaServer";
import { AI_BASE_URL } from "@env";

export default defineRpc({
    params: a.object("InpaintImageParams", {
        prompt: a.string(),
        negativePrompt: a.optional(a.string()),
        width: a.optional(a.number()),
        height: a.optional(a.number()),
        steps: a.optional(a.number()),
        socketId: a.optional(a.string()),
        image: a.string(), // Base64 image or URL
        mask: a.string(), // Base64 mask
    }),
    response: a.object("InpaintImageResponse", {
        success: a.boolean(),
        message: a.string(),
        url: a.optional(a.string()),
    }),
    handler: async ({ params }) => {
        console.log("!!! [Backend RPC] inpaint_image HIT !!!");
        try {
            const aiServerUrl = AI_BASE_URL || "http://localhost:5000";
            const fullUrl = `${aiServerUrl}/inpaint-image`;
            console.log(`🔌 Connecting to AI server at: ${fullUrl}`);

            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), 300000);

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
                    socketId: params.socketId,
                    image: params.image,
                    mask: params.mask,
                }),
                signal: controller.signal,
            });

            clearTimeout(timeoutId);

            if (!response.ok) {
                const errorData = await response.json().catch(() => ({}) as any);
                throw new Error((errorData as any).error || `AI server returned ${response.status}`);
            }

            const imageBuffer = await response.arrayBuffer();

            const uploadResult = await mediaServer.uploadMedia({
                originalName: `inpainted-${Date.now()}.png`,
                bytes: Buffer.from(imageBuffer),
                contentType: "image/png",
                directory: "generated",
            });

            return {
                success: true,
                message: "Image inpainted and uploaded successfully",
                url: uploadResult.url,
            };
        } catch (error: any) {
            console.error("❌ Image inpainting failed:", error);
            return {
                success: false,
                message: error.message || "Unknown error occurred during image inpainting",
            };
        }
    },
});
