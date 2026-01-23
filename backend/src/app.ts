// Import environment variables first
import "@env";

import {
  ArriApp,
  defineRoute,
  readMultipartFormData,
  defineMiddleware,
  getHeader,
  readBody,
  getRouterParam,
} from "@arrirpc/server";
import { promises as fs } from 'node:fs';
import path from 'node:path';
import { mediaServer } from "./services/mediaServer";
import { EventServer } from "./services/eventServer";
import { chunkUploadManager } from "./utils/chunkUploadManager";

// Initialize event server for real-time notifications
EventServer.init();

const app = new ArriApp({
  onError: (error, event) => {
    console.error('❌ APP ERROR:', error);
    console.error('Stack trace:', error.stack);
    console.error('Request:', event?.node?.req?.method, event?.node?.req?.url);
    console.error('Headers:', event?.node?.req?.headers);
  },
  onRequest: (event) => {
    console.log("📥 Incoming request:", event.node.req.method, event.node.req.url);

    // Add CORS headers
    const origin = event.node.req.headers.origin;
    const allowedOrigins = [
      "http://192.168.141.133:3000",
      "http://127.0.0.1:3000",
    ];

    // Allow all localhost ports
    const isLocalhost = origin?.startsWith('http://localhost:') || origin?.startsWith('http://127.0.0.1:');

    if (origin && (isLocalhost || allowedOrigins.includes(origin))) {
      event.node.res.setHeader("Access-Control-Allow-Origin", origin);
      event.node.res.setHeader("Vary", "Origin");
      event.node.res.setHeader("Access-Control-Allow-Credentials", "true");
    } else if (!origin) {
      // Allow requests without origin (like from Postman or same-origin)
      event.node.res.setHeader("Access-Control-Allow-Origin", "*");
    }

    event.node.res.setHeader(
      "Access-Control-Allow-Methods",
      "GET, POST, PUT, DELETE, OPTIONS"
    );
    event.node.res.setHeader(
      "Access-Control-Allow-Headers",
      "Content-Type, Authorization"
    );
    event.node.res.setHeader("Access-Control-Max-Age", "86400");

    // Handle preflight requests
    if (event.node.req.method === "OPTIONS") {
      event.node.res.statusCode = 204;
      event.node.res.end();
      return;
    }
  },
  disableDefinitionRoute: false,
});

// ✅ Authentication middleware — injects event.context.user
const authMiddleware = defineMiddleware(async (event) => {
  try {
    const authHeader = getHeader(event, "Authorization");
    console.log('🔐 Auth middleware - Authorization header:', authHeader ? 'Present' : 'Missing');

    if (authHeader) {
      const decodedToken = JSON.parse(authHeader);
      event.context.user = decodedToken;
      console.log('✅ Auth middleware - User set:', { id: decodedToken.id, email: decodedToken.email });
    } else {
      console.log('⚠️ Auth middleware - No authorization header found');
    }
  } catch (err) {
    console.error("❌ Auth validation error:", err);
  }
});

// ✅ Register the middleware
app.use(authMiddleware);

// ✅ Media upload route
app.route(
  defineRoute({
    path: "/media/upload",
    method: ["post"],
    handler: async (event) => {
      console.log("Media upload route called");
      try {
        // You now have event.context.user available here 👇
        const user = event.context.user;
        console.log("User context:", user);

        // Use h3's readMultipartFormData with better error handling
        const form = await readMultipartFormData(event).catch((parseError: any) => {
          console.error("Multipart parsing error:", parseError);

          // If parsing fails due to size, provide helpful error message
          if (parseError?.message?.includes('Invalid array length') ||
            parseError?.message?.includes('Maximum call stack') ||
            parseError?.message?.includes('out of memory')) {
            throw new Error("File too large for processing. Please try a smaller file (under 50MB).");
          }

          throw new Error("Failed to parse upload data: " + (parseError?.message || 'Unknown error'));
        });

        console.log("Form received, length:", form?.length);
        console.log("All form parts:", form?.map(p => ({ name: p.name, type: p.type, filename: p.filename, dataLength: p.data?.length })));

        if (!form || form.length === 0) {
          console.log("No form data received");
          return { success: false, message: "No form data received" };
        }

        const filePart = form.find((p) => p.name === "file");
        const directoryField = form.find((p) => p.name === "directory");
        const userIdField = form.find((p) => p.name === "userId");

        console.log("File part:", filePart ? { filename: filePart.filename, type: filePart.type, dataLength: filePart.data?.length } : null);
        console.log("UserId field:", userIdField?.data?.toString("utf8"));
        console.log("Directory field:", directoryField?.data?.toString("utf8"));

        if (!filePart || !filePart.data || !filePart.filename) {
          console.log("Missing file in multipart form-data");
          return {
            success: false,
            message: "Missing file in multipart form-data",
          };
        }

        const directory =
          user?.id || // 🧩 automatically use the logged-in user’s ID if available
          userIdField?.data?.toString("utf8") ||
          directoryField?.data?.toString("utf8");
        console.log("Resolved directory:", directory);

        const result = await mediaServer.uploadMedia({
          originalName: filePart.filename,
          bytes: filePart.data,
          contentType: filePart.type ?? undefined,
          directory,
        });
        console.log("Upload result:", result);

        return {
          success: true,
          url: result.url,
          rawUrl: result.rawUrl,
          coverImageUrl: result.coverImageUrl,
          duration: result.duration,
        };
      } catch (err: any) {
        console.error("Upload error", err);

        // Provide more specific error messages
        if (err?.message?.includes('Invalid array length') ||
          err?.message?.includes('Maximum call stack') ||
          err?.message?.includes('out of memory')) {
          return {
            success: false,
            message: "File too large to process. Please try a smaller file (under 50MB)."
          };
        }

        return { success: false, message: "Upload failed: " + (err?.message || 'Unknown error') };
      }
    },
  })
);

// ✅ Chunked upload routes for large files
app.route(
  defineRoute({
    path: "/media/upload/init",
    method: ["post"],
    handler: async (event) => {
      console.log("Chunked upload initialization called");
      try {
        const body = await readBody(event);
        const { filename, totalChunks, directory, contentType } = body;

        if (!filename || !totalChunks || !directory) {
          return {
            success: false,
            message: "Missing required parameters: filename, totalChunks, directory"
          };
        }

        const sessionId = await chunkUploadManager.initializeUpload(
          filename,
          parseInt(totalChunks),
          directory,
          contentType
        );

        return {
          success: true,
          sessionId,
          message: "Upload session initialized"
        };
      } catch (err: any) {
        console.error("Chunked upload init error:", err);
        return { success: false, message: "Failed to initialize upload: " + (err?.message || 'Unknown error') };
      }
    },
  })
);

app.route(
  defineRoute({
    path: "/media/upload/chunk",
    method: ["post"],
    handler: async (event) => {
      console.log("Chunked upload chunk called");
      try {
        const form = await readMultipartFormData(event).catch((parseError: any) => {
          console.error("Chunk multipart parsing error:", parseError);
          throw new Error("Failed to parse chunk data: " + (parseError?.message || 'Unknown error'));
        });

        if (!form || form.length === 0) {
          return { success: false, message: "No chunk data received" };
        }

        const sessionIdField = form.find(p => p.name === "sessionId");
        const chunkIndexField = form.find(p => p.name === "chunkIndex");
        const chunkFile = form.find(p => p.name === "chunk");

        if (!sessionIdField || !chunkIndexField || !chunkFile) {
          return {
            success: false,
            message: "Missing required fields: sessionId, chunkIndex, chunk"
          };
        }

        const sessionId = sessionIdField.data.toString('utf8');
        const chunkIndex = parseInt(chunkIndexField.data.toString('utf8'));

        const result = await chunkUploadManager.uploadChunk(
          sessionId,
          chunkIndex,
          chunkFile.data
        );

        return result;
      } catch (err: any) {
        console.error("Chunked upload chunk error:", err);
        return { success: false, message: "Failed to upload chunk: " + (err?.message || 'Unknown error') };
      }
    },
  })
);

app.route(
  defineRoute({
    path: "/media/upload/finalize",
    method: ["post"],
    handler: async (event) => {
      console.log("Chunked upload finalize called");
      try {
        const body = await readBody(event);
        const { sessionId, title, description } = body;

        if (!sessionId) {
          return { success: false, message: "Missing sessionId" };
        }

        const result = await chunkUploadManager.finalizeUpload(sessionId);

        if (!result.success || !result.filePath) {
          return result;
        }

        // Process the finalized file with mediaServer
        const fileStats = await fs.stat(result.filePath);
        const fileBuffer = await fs.readFile(result.filePath);
        const filename = path.basename(result.filePath);
        const directory = path.dirname(result.filePath).split(path.sep).pop() || 'default';

        const mediaResult = await mediaServer.uploadMedia({
          originalName: filename,
          bytes: fileBuffer,
          contentType: 'audio/mpeg', // Default to MP3, could be detected
          directory,
        });

        // Clean up the temporary file
        await fs.unlink(result.filePath);

        return {
          success: true,
          message: "Chunked upload completed successfully",
          url: mediaResult.url,
          rawUrl: mediaResult.rawUrl,
          coverImageUrl: mediaResult.coverImageUrl,
          duration: mediaResult.duration,
        };
      } catch (err: any) {
        console.error("Chunked upload finalize error:", err);
        return { success: false, message: "Failed to finalize upload: " + (err?.message || 'Unknown error') };
      }
    },
  })
);

app.route(
  defineRoute({
    path: "/media/upload/progress/:sessionId",
    method: ["get"],
    handler: async (event) => {
      try {
        const sessionId = getRouterParam(event, 'sessionId');
        if (!sessionId) {
          return { success: false, message: "Missing sessionId" };
        }

        const result = await chunkUploadManager.getUploadProgress(sessionId);
        return result;
      } catch (err: any) {
        console.error("Upload progress error:", err);
        return { success: false, message: "Failed to get progress: " + (err?.message || 'Unknown error') };
      }
    },
  })
);

// ✅ Static file serving route for uploads
app.route(
  defineRoute({
    path: "/uploads/**",
    method: ["get"],
    handler: async (event) => {
      console.log("Upload route handler called!");
      const url = event.node.req.url;
      console.log("Full URL:", url);

      // Extract the path after /uploads/
      const uploadPath = url!.replace('/uploads/', '');
      const filePath = path.join(process.cwd(), 'uploads', uploadPath);
      console.log("Requested file path:", filePath);

      try {
        const stat = await fs.stat(filePath);
        if (!stat.isFile()) {
          event.node.res.statusCode = 404;
          event.node.res.end("Not Found");
          return;
        }

        const ext = path.extname(filePath).toLowerCase();
        const mimeTypes: Record<string, string> = {
          '.png': 'image/png',
          '.jpg': 'image/jpeg',
          '.jpeg': 'image/jpeg',
          '.gif': 'image/gif',
          '.webp': 'image/webp',
          '.mp4': 'video/mp4',
          '.mov': 'video/quicktime',
          '.m4v': 'video/x-m4v',
          '.mp3': 'audio/mpeg',
          '.wav': 'audio/wav',
          '.ogg': 'audio/ogg',
          '.heic': 'image/heic',
          '.heif': 'image/heif',
          '.pdf': 'application/pdf',
          '.m3u8': 'application/x-mpegURL',
          '.ts': 'video/MP2T',
        };

        const contentType = mimeTypes[ext] || 'application/octet-stream';
        event.node.res.setHeader('Content-Type', contentType);
        event.node.res.setHeader('Content-Length', stat.size);

        const fileStream = await fs.readFile(filePath);
        event.node.res.end(fileStream);
      } catch (err) {
        console.error("File read error:", err);
        event.node.res.statusCode = 404;
        event.node.res.end("Not Found");
      }
    },
  })
);

export default app;
