import { defineRpc } from "@arrirpc/server";
import { a } from "@arrirpc/schema";
import { mediaServer } from "../../services/mediaServer";
import { AI_BASE_URL } from "@env";

export default defineRpc({
    params: a.object("EditImageParams", {
        prompt: a.string(),
        image: a.string(), // Base64 image or URL
        steps: a.optional(a.number()),
    }),
    response: a.object("EditImageResponse", {
        success: a.boolean(),
        message: a.string(),
        data: a.any(),
    }),
    handler: async ({ params }) => {
        console.log("!!! [Backend RPC] edit-image HIT !!!");
        try {
            const aiServerUrl = AI_BASE_URL || "http://localhost:5000";
            const fullUrl = `${aiServerUrl}/edit-image`;
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
                    image: params.image,
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

            const uploadResult = await mediaServer.uploadMedia({
                originalName: `edit-image-${Date.now()}.png`,
                bytes: Buffer.from(imageBuffer),
                contentType: "image/png",
                directory: "generated",
            });

            return {
                success: true,
                message: "Image edited and uploaded successfully",
                data: uploadResult.url,
            };
        } catch (error: any) {
            console.error("❌ Edit Image failed:", error);
            return {
                success: false,
                message: error.message || "Unknown error occurred during image editing",
                data: null,
            };
        }
    },
});
