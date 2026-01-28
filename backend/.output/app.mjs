// .arri/__arri_app.ts
import sourceMapSupport from "source-map-support";

// ../env.ts
import { config } from "dotenv";
import { join, dirname } from "path";
import { fileURLToPath } from "url";
var __filename = fileURLToPath(import.meta.url);
var __dirname = dirname(__filename);
var possiblePaths = [
  join(__dirname, ".env"),
  join(__dirname, "..", "..", ".env")
];
for (const envPath of possiblePaths) {
  config({ path: envPath });
}
var DATABASE_URL = process.env["DATABASE_URL"];
var JWT_SECRET = process.env["JWT_SECRET"];
var SMTP_HOST = process.env["SMTP_HOST"];
var SMTP_PORT = process.env["SMTP_PORT"];
var SMTP_USER = process.env["SMTP_USER"];
var SMTP_PASS = process.env["SMTP_PASS"];
var FROM_EMAIL = process.env["FROM_EMAIL"];
var FE_URL = process.env["FE_URL"];
var GOOGLE_STUDIO_API_KEY = process.env["GOOGLE_STUDIO_API_KEY"];
var ELEVEN_LABS_API_KEY = process.env["ELEVEN_LABS_API_KEY"];
var AI_BASE_URL = process.env["AI_BASE_URL"];
if (!DATABASE_URL) {
  throw new Error("Missing required environment var DATABASE_URL");
}
var env = {
  DATABASE_URL,
  JWT_SECRET,
  GOOGLE_STUDIO_API_KEY
};

// src/app.ts
import {
  ArriApp,
  defineRoute,
  readMultipartFormData,
  defineMiddleware,
  getHeader,
  readBody,
  getRouterParam
} from "@arrirpc/server";
import { promises as fs3 } from "node:fs";
import path3 from "node:path";

// src/services/mediaServer.ts
import { promises as fs } from "node:fs";
import path from "node:path";
import { randomUUID } from "node:crypto";
import { execSync } from "node:child_process";
import ffmpeg from "fluent-ffmpeg";
var MediaServer = class {
  uploadRoot;
  constructor(uploadRootDir) {
    this.uploadRoot = uploadRootDir ?? path.resolve(process.cwd(), "uploads");
  }
  async uploadMedia(input) {
    console.log("got upload request");
    const { originalName, bytes, contentType, directory } = input;
    const targetDir = directory ? path.join(this.uploadRoot, directory) : this.uploadRoot;
    await this.ensureDirectory(targetDir);
    const ext = this.getSafeExtension(originalName);
    const fileName = `${randomUUID()}${ext}`;
    const absolutePath = path.join(targetDir, fileName);
    await fs.writeFile(absolutePath, bytes);
    if (this.isAudioFile(contentType, ext)) {
      console.log("Audio file detected, saving raw file");
      const rawFileUrl = `/uploads/${directory ? `${directory}/` : ""}${fileName}`;
      let duration;
      if (this.isFFmpegAvailable()) {
        try {
          duration = await this.getAudioDuration(absolutePath);
          console.log("Audio duration extracted:", duration, "milliseconds");
        } catch (error) {
          console.error("Audio duration extraction failed:", error);
        }
      }
      const shouldConvertToOpus = !directory?.includes("raw");
      if (shouldConvertToOpus && this.isFFmpegAvailable()) {
        console.log("FFmpeg available, attempting Opus conversion");
        try {
          const opusResult = await this.convertToOpus(absolutePath, targetDir, fileName);
          console.log("Opus conversion successful, returning both URLs");
          return {
            url: opusResult.url,
            rawUrl: rawFileUrl,
            duration,
            path: opusResult.path,
            originalName,
            contentType: "audio/ogg"
            // Opus in Ogg container
          };
        } catch (error) {
          console.error("Opus conversion failed, returning raw file URL as main URL:", error);
          return {
            url: rawFileUrl,
            rawUrl: rawFileUrl,
            duration,
            path: absolutePath,
            originalName,
            ...contentType !== void 0 ? { contentType } : {}
          };
        }
      } else {
        console.log("FFmpeg not available or raw upload, returning raw file URL");
        return {
          url: rawFileUrl,
          rawUrl: rawFileUrl,
          duration,
          path: absolutePath,
          originalName,
          ...contentType !== void 0 ? { contentType } : {}
        };
      }
    }
    if (this.isVideoFile(contentType, ext)) {
      console.log("Video file detected, saving raw file");
      const rawFileUrl = `/uploads/${directory ? `${directory}/` : ""}${fileName}`;
      let coverImageUrl;
      let duration;
      if (this.isFFmpegAvailable()) {
        try {
          coverImageUrl = await this.extractCoverImage(absolutePath, targetDir, fileName);
          console.log("Cover image extracted:", coverImageUrl);
        } catch (error) {
          console.error("Cover image extraction failed:", error);
        }
        try {
          duration = await this.getVideoDuration(absolutePath);
          console.log("Video duration extracted:", duration, "seconds");
        } catch (error) {
          console.error("Duration extraction failed:", error);
        }
      }
      const shouldConvertToHLS = !directory?.includes("raw");
      if (shouldConvertToHLS && this.isFFmpegAvailable()) {
        console.log("FFmpeg available, attempting HLS conversion");
        try {
          const hlsResult = await this.convertToHLS(absolutePath, targetDir, fileName);
          console.log("HLS conversion successful, returning both URLs");
          return {
            url: hlsResult.url,
            rawUrl: rawFileUrl,
            coverImageUrl,
            duration,
            path: hlsResult.path,
            originalName,
            contentType: "application/x-mpegURL"
            // HLS manifest MIME type
          };
        } catch (error) {
          console.error("HLS conversion failed, returning raw file URL as main URL:", error);
          return {
            url: rawFileUrl,
            rawUrl: rawFileUrl,
            coverImageUrl,
            duration,
            path: absolutePath,
            originalName,
            ...contentType !== void 0 ? { contentType } : {}
          };
        }
      } else {
        console.log("FFmpeg not available or raw upload, returning raw file URL");
        return {
          url: rawFileUrl,
          rawUrl: rawFileUrl,
          coverImageUrl,
          duration,
          path: absolutePath,
          originalName,
          ...contentType !== void 0 ? { contentType } : {}
        };
      }
    }
    const fileUrl = `/uploads/${directory ? `${directory}/` : ""}${fileName}`;
    return {
      url: fileUrl,
      path: absolutePath,
      originalName,
      ...contentType !== void 0 ? { contentType } : {}
    };
  }
  async ensureDirectory(dir) {
    try {
      await fs.mkdir(dir, { recursive: true });
    } catch (_) {
    }
  }
  isVideoFile(contentType, extension) {
    if (contentType && contentType.startsWith("video/")) return true;
    if (extension && /^\.(mp4|mov|m4v|avi|mkv|webm|flv|wmv)$/.test(extension)) return true;
    return false;
  }
  isAudioFile(contentType, extension) {
    if (contentType && contentType.startsWith("audio/")) return true;
    if (extension && /^\.(mp3|wav|ogg|m4a|aac|flac|wma)$/.test(extension)) return true;
    return false;
  }
  isFFmpegAvailable() {
    try {
      execSync("ffmpeg -version", { stdio: "ignore" });
      return true;
    } catch (error) {
      return false;
    }
  }
  async convertToHLS(inputPath, targetDir, fileName) {
    return new Promise((resolve5, reject) => {
      const baseName = path.parse(fileName).name;
      const hlsDir = path.join(targetDir, baseName);
      const manifestPath = path.join(hlsDir, "playlist.m3u8");
      console.log("Starting HLS conversion...");
      console.log("Input path:", inputPath);
      console.log("HLS directory:", hlsDir);
      console.log("Manifest path:", manifestPath);
      this.ensureDirectory(hlsDir).then(() => {
        console.log("HLS directory created, starting FFmpeg conversion");
        try {
          ffmpeg.setFfmpegPath("ffmpeg");
        } catch (e) {
          console.log("Using default FFmpeg path");
        }
        ffmpeg(inputPath).inputOptions(["-hwaccel auto"]).outputOptions([
          "-c:v h264",
          "-c:a aac",
          "-b:v 1000k",
          "-b:a 128k",
          "-hls_time 10",
          "-hls_list_size 0",
          "-f hls",
          "-hls_segment_filename",
          path.join(hlsDir, "segment_%03d.ts")
        ]).output(manifestPath).on("start", (commandLine) => {
          console.log("FFmpeg command: " + commandLine);
        }).on("progress", (progress) => {
          console.log("FFmpeg progress: " + progress.percent + "% done");
        }).on("end", () => {
          console.log("HLS conversion completed successfully");
          const hlsUrl = `/uploads/${path.relative(this.uploadRoot, hlsDir).replace(/\\/g, "/")}/playlist.m3u8`;
          console.log("HLS URL:", hlsUrl);
          resolve5({
            url: hlsUrl,
            path: manifestPath,
            originalName: fileName,
            contentType: "application/x-mpegURL"
          });
        }).on("error", (err) => {
          console.error("HLS conversion failed:", err);
          reject(err);
        }).run();
      }).catch((err) => {
        console.error("Failed to create HLS directory:", err);
        reject(err);
      });
    });
  }
  async extractCoverImage(inputPath, targetDir, fileName) {
    return new Promise((resolve5, reject) => {
      const baseName = path.parse(fileName).name;
      const coverImagePath = path.join(targetDir, `${baseName}_cover.jpg`);
      console.log("Extracting cover image...");
      console.log("Input path:", inputPath);
      console.log("Cover image path:", coverImagePath);
      try {
        ffmpeg.setFfmpegPath("ffmpeg");
      } catch (e) {
        console.log("Using default FFmpeg path");
      }
      ffmpeg(inputPath).inputOptions(["-ss", "00:00:01"]).outputOptions(["-vframes", "1", "-q:v", "2"]).output(coverImagePath).on("start", (commandLine) => {
        console.log("FFmpeg cover extraction command: " + commandLine);
      }).on("end", () => {
        console.log("Cover image extraction completed successfully");
        const coverImageUrl = `/uploads/${path.relative(this.uploadRoot, coverImagePath).replace(/\\/g, "/")}`;
        console.log("Cover image URL:", coverImageUrl);
        resolve5(coverImageUrl);
      }).on("error", (err) => {
        console.error("Cover image extraction failed:", err);
        reject(err);
      }).run();
    });
  }
  async getVideoDuration(inputPath) {
    return new Promise((resolve5, reject) => {
      ffmpeg.ffprobe(inputPath, (err, metadata) => {
        if (err) {
          reject(err);
          return;
        }
        const duration = metadata.format.duration;
        if (duration) {
          resolve5(Math.round(duration));
        } else {
          reject(new Error("Duration not found in video metadata"));
        }
      });
    });
  }
  async getAudioDuration(inputPath) {
    return new Promise((resolve5, reject) => {
      ffmpeg.ffprobe(inputPath, (err, metadata) => {
        if (err) {
          reject(err);
          return;
        }
        const duration = metadata.format.duration;
        if (duration) {
          resolve5(Math.round(duration * 1e3));
        } else {
          reject(new Error("Duration not found in audio metadata"));
        }
      });
    });
  }
  async convertToOpus(inputPath, targetDir, fileName) {
    return new Promise((resolve5, reject) => {
      const baseName = path.parse(fileName).name;
      const opusFileName = `${baseName}.opus`;
      const opusPath = path.join(targetDir, opusFileName);
      console.log("Starting Opus conversion...");
      console.log("Input path:", inputPath);
      console.log("Output path:", opusPath);
      try {
        ffmpeg.setFfmpegPath("ffmpeg");
      } catch (e) {
        console.log("Using default FFmpeg path");
      }
      ffmpeg(inputPath).audioCodec("libopus").audioBitrate("64k").audioChannels(1).audioFrequency(48e3).outputOptions(["-vn"]).output(opusPath).on("start", (commandLine) => {
        console.log("FFmpeg command: " + commandLine);
      }).on("progress", (progress) => {
        console.log("FFmpeg progress: " + progress.percent + "% done");
      }).on("end", () => {
        console.log("Opus conversion completed successfully");
        const opusUrl = `/uploads/${path.relative(this.uploadRoot, opusPath).replace(/\\/g, "/")}`;
        console.log("Opus URL:", opusUrl);
        resolve5({
          url: opusUrl,
          path: opusPath,
          originalName: fileName,
          contentType: "audio/ogg"
        });
      }).on("error", (err) => {
        console.error("Opus conversion failed:", err);
        reject(err);
      }).run();
    });
  }
  getSafeExtension(fileName) {
    const idx = fileName.lastIndexOf(".");
    if (idx === -1) return "";
    const ext = fileName.slice(idx).toLowerCase();
    if (/^\.(png|jpg|jpeg|gif|webp|mp4|mov|m4v|mp3|wav|ogg|m4a|aac|flac|opus|heic|heif|pdf)$/.test(ext)) return ext;
    return "";
  }
};
var mediaServer = new MediaServer();

// src/services/eventServer.ts
import { createServer } from "http";
import { Server } from "socket.io";
var EventServer = class _EventServer {
  static httpServer;
  static io;
  // static sockets: Record<string, Socket> = {};
  static init() {
    if (!_EventServer.io) {
      _EventServer.httpServer = createServer(
        (req, res) => {
          if (req.url === "/relay" && req.method === "POST") {
            let body = "";
            req.on("data", (chunk) => body += chunk);
            req.on("end", () => {
              console.log(body);
              const { socketId, event, data } = JSON.parse(body);
              this.io.to(socketId).emit(event, data);
              res.writeHead(200, { "Content-Type": "application/json" });
              res.end(JSON.stringify({ success: true }));
            });
          }
        }
      );
      _EventServer.io = new Server(_EventServer.httpServer, {
        cors: { origin: "*" }
      });
      _EventServer.io.on("connection", (socket) => {
        console.log("Socket connected:", socket.id);
        socket.on("disconnect", () => {
          console.log("Socket disconnected:", socket.id);
        });
      });
      _EventServer.httpServer.on("error", (err) => {
        if (err.code === "EADDRINUSE") {
          console.log("Port 5001 already in use");
        } else {
          console.error("Error starting Socket.IO server:", err);
        }
      });
      _EventServer.httpServer.listen(5001, () => {
        console.log("Socket.IO + HTTP server running on port 5001");
      });
    }
  }
};

// src/utils/chunkUploadManager.ts
import { promises as fs2 } from "node:fs";
import path2 from "node:path";
import { ulid } from "ulidx";
var ChunkUploadManager = class {
  sessions = /* @__PURE__ */ new Map();
  tempDir = path2.join(process.cwd(), "temp_uploads");
  constructor() {
    this.ensureTempDir();
    setInterval(() => this.cleanupOldSessions(), 60 * 60 * 1e3);
  }
  async ensureTempDir() {
    try {
      await fs2.mkdir(this.tempDir, { recursive: true });
    } catch (error) {
      console.error("Failed to create temp directory:", error);
    }
  }
  async initializeUpload(filename, totalChunks, directory, contentType) {
    const sessionId = ulid();
    const session = {
      id: sessionId,
      filename,
      totalChunks,
      uploadedChunks: /* @__PURE__ */ new Set(),
      directory,
      contentType,
      createdAt: /* @__PURE__ */ new Date()
    };
    this.sessions.set(sessionId, session);
    const sessionDir = path2.join(this.tempDir, sessionId);
    await fs2.mkdir(sessionDir, { recursive: true });
    console.log(`Initialized chunked upload session: ${sessionId} for file: ${filename} (${totalChunks} chunks)`);
    return sessionId;
  }
  async uploadChunk(sessionId, chunkIndex, chunkData) {
    const session = this.sessions.get(sessionId);
    if (!session) {
      return { success: false, message: "Upload session not found" };
    }
    try {
      const sessionDir = path2.join(this.tempDir, sessionId);
      const chunkPath = path2.join(sessionDir, `chunk_${chunkIndex}`);
      await fs2.writeFile(chunkPath, chunkData);
      session.uploadedChunks.add(chunkIndex);
      const progress = Math.round(session.uploadedChunks.size / session.totalChunks * 100);
      console.log(`Uploaded chunk ${chunkIndex + 1}/${session.totalChunks} for session ${sessionId} (${progress}%)`);
      return {
        success: true,
        message: `Chunk ${chunkIndex + 1}/${session.totalChunks} uploaded`,
        progress
      };
    } catch (error) {
      console.error(`Failed to upload chunk ${chunkIndex} for session ${sessionId}:`, error);
      return { success: false, message: "Failed to save chunk" };
    }
  }
  async finalizeUpload(sessionId) {
    const session = this.sessions.get(sessionId);
    if (!session) {
      return { success: false, message: "Upload session not found" };
    }
    if (session.uploadedChunks.size !== session.totalChunks) {
      return {
        success: false,
        message: `Missing chunks. Expected ${session.totalChunks}, got ${session.uploadedChunks.size}`
      };
    }
    try {
      const sessionDir = path2.join(this.tempDir, sessionId);
      const finalDir = path2.join(process.cwd(), "uploads", session.directory);
      await fs2.mkdir(finalDir, { recursive: true });
      const finalFilePath = path2.join(finalDir, session.filename);
      const writeStream = await fs2.open(finalFilePath, "w");
      for (let i = 0; i < session.totalChunks; i++) {
        const chunkPath = path2.join(sessionDir, `chunk_${i}`);
        const chunkData = await fs2.readFile(chunkPath);
        await writeStream.write(chunkData);
      }
      await writeStream.close();
      await this.cleanupSession(sessionId);
      console.log(`Finalized chunked upload: ${session.filename} (${session.totalChunks} chunks)`);
      return {
        success: true,
        message: "File upload completed",
        filePath: finalFilePath
      };
    } catch (error) {
      console.error(`Failed to finalize upload for session ${sessionId}:`, error);
      return { success: false, message: "Failed to combine chunks" };
    }
  }
  async getUploadProgress(sessionId) {
    const session = this.sessions.get(sessionId);
    if (!session) {
      return { success: false, message: "Upload session not found" };
    }
    const progress = Math.round(session.uploadedChunks.size / session.totalChunks * 100);
    return {
      success: true,
      progress,
      message: `${session.uploadedChunks.size}/${session.totalChunks} chunks uploaded`
    };
  }
  async cleanupSession(sessionId) {
    try {
      const sessionDir = path2.join(this.tempDir, sessionId);
      await fs2.rm(sessionDir, { recursive: true, force: true });
      this.sessions.delete(sessionId);
    } catch (error) {
      console.error(`Failed to cleanup session ${sessionId}:`, error);
    }
  }
  cleanupOldSessions() {
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1e3);
    for (const [sessionId, session] of this.sessions.entries()) {
      if (session.createdAt < oneHourAgo) {
        console.log(`Cleaning up old upload session: ${sessionId}`);
        this.cleanupSession(sessionId);
      }
    }
  }
};
var chunkUploadManager = new ChunkUploadManager();

// src/app.ts
EventServer.init();
var app = new ArriApp({
  onError: (error, event) => {
    console.error("\u274C APP ERROR:", error);
    console.error("Stack trace:", error.stack);
    console.error("Request:", event?.node?.req?.method, event?.node?.req?.url);
    console.error("Headers:", event?.node?.req?.headers);
  },
  onRequest: (event) => {
    console.log("\u{1F4E5} Incoming request:", event.node.req.method, event.node.req.url);
    const origin = event.node.req.headers.origin;
    const allowedOrigins = [
      "http://192.168.141.133:3000",
      "http://127.0.0.1:3000"
    ];
    const isLocalhost = origin?.startsWith("http://localhost:") || origin?.startsWith("http://127.0.0.1:");
    if (origin && (isLocalhost || allowedOrigins.includes(origin))) {
      event.node.res.setHeader("Access-Control-Allow-Origin", origin);
      event.node.res.setHeader("Vary", "Origin");
      event.node.res.setHeader("Access-Control-Allow-Credentials", "true");
    } else if (!origin) {
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
    if (event.node.req.method === "OPTIONS") {
      event.node.res.statusCode = 204;
      event.node.res.end();
      return;
    }
  },
  disableDefinitionRoute: false
});
var authMiddleware = defineMiddleware(async (event) => {
  try {
    const authHeader = getHeader(event, "Authorization");
    console.log("\u{1F510} Auth middleware - Authorization header:", authHeader ? "Present" : "Missing");
    if (authHeader) {
      const decodedToken = JSON.parse(authHeader);
      event.context.user = decodedToken;
      console.log("\u2705 Auth middleware - User set:", { id: decodedToken.id, email: decodedToken.email });
    } else {
      console.log("\u26A0\uFE0F Auth middleware - No authorization header found");
    }
  } catch (err) {
    console.error("\u274C Auth validation error:", err);
  }
});
app.use(authMiddleware);
app.route(
  defineRoute({
    path: "/media/upload",
    method: ["post"],
    handler: async (event) => {
      console.log("Media upload route called");
      try {
        const user = event.context.user;
        console.log("User context:", user);
        const form = await readMultipartFormData(event).catch((parseError) => {
          console.error("Multipart parsing error:", parseError);
          if (parseError?.message?.includes("Invalid array length") || parseError?.message?.includes("Maximum call stack") || parseError?.message?.includes("out of memory")) {
            throw new Error("File too large for processing. Please try a smaller file (under 50MB).");
          }
          throw new Error("Failed to parse upload data: " + (parseError?.message || "Unknown error"));
        });
        console.log("Form received, length:", form?.length);
        console.log("All form parts:", form?.map((p) => ({ name: p.name, type: p.type, filename: p.filename, dataLength: p.data?.length })));
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
            message: "Missing file in multipart form-data"
          };
        }
        const directory = user?.id || // 🧩 automatically use the logged-in user’s ID if available
        userIdField?.data?.toString("utf8") || directoryField?.data?.toString("utf8");
        console.log("Resolved directory:", directory);
        const result = await mediaServer.uploadMedia({
          originalName: filePart.filename,
          bytes: filePart.data,
          contentType: filePart.type ?? void 0,
          directory
        });
        console.log("Upload result:", result);
        return {
          success: true,
          url: result.url,
          rawUrl: result.rawUrl,
          coverImageUrl: result.coverImageUrl,
          duration: result.duration
        };
      } catch (err) {
        console.error("Upload error", err);
        if (err?.message?.includes("Invalid array length") || err?.message?.includes("Maximum call stack") || err?.message?.includes("out of memory")) {
          return {
            success: false,
            message: "File too large to process. Please try a smaller file (under 50MB)."
          };
        }
        return { success: false, message: "Upload failed: " + (err?.message || "Unknown error") };
      }
    }
  })
);
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
      } catch (err) {
        console.error("Chunked upload init error:", err);
        return { success: false, message: "Failed to initialize upload: " + (err?.message || "Unknown error") };
      }
    }
  })
);
app.route(
  defineRoute({
    path: "/media/upload/chunk",
    method: ["post"],
    handler: async (event) => {
      console.log("Chunked upload chunk called");
      try {
        const form = await readMultipartFormData(event).catch((parseError) => {
          console.error("Chunk multipart parsing error:", parseError);
          throw new Error("Failed to parse chunk data: " + (parseError?.message || "Unknown error"));
        });
        if (!form || form.length === 0) {
          return { success: false, message: "No chunk data received" };
        }
        const sessionIdField = form.find((p) => p.name === "sessionId");
        const chunkIndexField = form.find((p) => p.name === "chunkIndex");
        const chunkFile = form.find((p) => p.name === "chunk");
        if (!sessionIdField || !chunkIndexField || !chunkFile) {
          return {
            success: false,
            message: "Missing required fields: sessionId, chunkIndex, chunk"
          };
        }
        const sessionId = sessionIdField.data.toString("utf8");
        const chunkIndex = parseInt(chunkIndexField.data.toString("utf8"));
        const result = await chunkUploadManager.uploadChunk(
          sessionId,
          chunkIndex,
          chunkFile.data
        );
        return result;
      } catch (err) {
        console.error("Chunked upload chunk error:", err);
        return { success: false, message: "Failed to upload chunk: " + (err?.message || "Unknown error") };
      }
    }
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
        const fileStats = await fs3.stat(result.filePath);
        const fileBuffer = await fs3.readFile(result.filePath);
        const filename = path3.basename(result.filePath);
        const directory = path3.dirname(result.filePath).split(path3.sep).pop() || "default";
        const mediaResult = await mediaServer.uploadMedia({
          originalName: filename,
          bytes: fileBuffer,
          contentType: "audio/mpeg",
          // Default to MP3, could be detected
          directory
        });
        await fs3.unlink(result.filePath);
        return {
          success: true,
          message: "Chunked upload completed successfully",
          url: mediaResult.url,
          rawUrl: mediaResult.rawUrl,
          coverImageUrl: mediaResult.coverImageUrl,
          duration: mediaResult.duration
        };
      } catch (err) {
        console.error("Chunked upload finalize error:", err);
        return { success: false, message: "Failed to finalize upload: " + (err?.message || "Unknown error") };
      }
    }
  })
);
app.route(
  defineRoute({
    path: "/media/upload/progress/:sessionId",
    method: ["get"],
    handler: async (event) => {
      try {
        const sessionId = getRouterParam(event, "sessionId");
        if (!sessionId) {
          return { success: false, message: "Missing sessionId" };
        }
        const result = await chunkUploadManager.getUploadProgress(sessionId);
        return result;
      } catch (err) {
        console.error("Upload progress error:", err);
        return { success: false, message: "Failed to get progress: " + (err?.message || "Unknown error") };
      }
    }
  })
);
app.route(
  defineRoute({
    path: "/uploads/**",
    method: ["get"],
    handler: async (event) => {
      console.log("Upload route handler called!");
      const url = event.node.req.url;
      console.log("Full URL:", url);
      const uploadPath = url.replace("/uploads/", "");
      const filePath = path3.join(process.cwd(), "uploads", uploadPath);
      console.log("Requested file path:", filePath);
      try {
        const stat = await fs3.stat(filePath);
        if (!stat.isFile()) {
          event.node.res.statusCode = 404;
          event.node.res.end("Not Found");
          return;
        }
        const ext = path3.extname(filePath).toLowerCase();
        const mimeTypes = {
          ".png": "image/png",
          ".jpg": "image/jpeg",
          ".jpeg": "image/jpeg",
          ".gif": "image/gif",
          ".webp": "image/webp",
          ".mp4": "video/mp4",
          ".mov": "video/quicktime",
          ".m4v": "video/x-m4v",
          ".mp3": "audio/mpeg",
          ".wav": "audio/wav",
          ".ogg": "audio/ogg",
          ".heic": "image/heic",
          ".heif": "image/heif",
          ".pdf": "application/pdf",
          ".m3u8": "application/x-mpegURL",
          ".ts": "video/MP2T"
        };
        const contentType = mimeTypes[ext] || "application/octet-stream";
        event.node.res.setHeader("Content-Type", contentType);
        event.node.res.setHeader("Content-Length", stat.size);
        const fileStream = await fs3.readFile(filePath);
        event.node.res.end(fileStream);
      } catch (err) {
        console.error("File read error:", err);
        event.node.res.statusCode = 404;
        event.node.res.end("Not Found");
      }
    }
  })
);
var app_default = app;

// src/procedures/admin/create_component.rpc.ts
import { a } from "@arrirpc/schema";
import { defineRpc } from "@arrirpc/server";

// src/utils/component_utils.ts
import { promises as fs4 } from "fs";
import { join as join2, resolve } from "path";
function getProjectRoot() {
  const cwd = process.cwd();
  if (cwd.endsWith("backend")) {
    return resolve(cwd, "..");
  }
  return cwd;
}
function toPascalCase(str) {
  return str.replace(/(^\w|-\w)/g, clearAndUpper);
}
function fillTemplate(template, replacements) {
  return template.replace(/\{\{(\w+)\}\}/g, (match, key) => {
    return replacements[key] || match;
  });
}
async function readAndFillTemplate(templatePath, replacements) {
  const template = await fs4.readFile(templatePath, "utf8");
  return fillTemplate(template, replacements);
}
function clearAndUpper(text6) {
  return text6.replace(/-/, "").toUpperCase();
}
async function getAvailableComponents(rootDir) {
  const componentsDir = join2(rootDir, "frontend", "lib", "components");
  if (!await fs4.stat(componentsDir).catch(() => false)) {
    return [];
  }
  const entries = await fs4.readdir(componentsDir, { withFileTypes: true });
  const components2 = [];
  for (const entry of entries) {
    if (entry.isDirectory()) {
      const compPath = join2(componentsDir, entry.name);
      try {
        await fs4.access(join2(compPath, "component.dart"));
        await fs4.access(join2(compPath, "properties.dart"));
        components2.push({ name: entry.name, className: toPascalCase(entry.name) });
      } catch (e) {
      }
    }
  }
  return components2;
}
async function generateComponentFactories() {
  const rootDir = getProjectRoot();
  const components2 = await getAvailableComponents(rootDir);
  const templatesDir = join2(rootDir, "backend", "src", "templates", "components");
  components2.sort((a13, b) => a13.name.localeCompare(b.name));
  const imports = components2.map(
    (c) => `import '../components/${c.name}/component.dart';
import '../components/${c.name}/properties.dart';`
  ).join("\n");
  const componentTypeEnum = components2.map((c) => c.name).join(", ");
  const casesCreateComponent = components2.map(
    (c) => `      case ComponentType.${c.name}:
        return ${c.className}Component(id: componentId, x: x, y: y);`
  ).join("\n");
  const casesFromJson = components2.map(
    (c) => `      case ComponentType.${c.name}:
        return ${c.className}Component.fromJson(json);`
  ).join("\n");
  const casesGetDefaultProperties = components2.map(
    (c) => `      case ComponentType.${c.name}:
        return createDefault${c.className}Properties();`
  ).join("\n");
  const casesGetDefaultPropertiesFactory = components2.map(
    (c) => `      case ComponentType.${c.name}:
        return ${c.className}Properties.createDefault();`
  ).join("\n");
  const casesGetValidators = components2.map(
    (c) => `      case ComponentType.${c.name}:
        return ${c.className}Properties.validators;`
  ).join("\n");
  const casesCreateWithProperties = components2.map(
    (c) => `      case ComponentType.${c.name}:
        return ${c.className}Component(
          id: componentId,
          x: x,
          y: y,
          properties: properties,
        );`
  ).join("\n");
  const utilityMethods = components2.map(
    (c) => `  static ComponentProperties createDefault${c.className}Properties() {
    return ${c.className}Properties.createDefault();
  }`
  ).join("\n\n");
  const exports = components2.map((c) => `export '${c.name}/component.dart';`).join("\n");
  const componentFactoryContent = await readAndFillTemplate(join2(templatesDir, "component_factory.dart.tpl"), {
    IMPORTS: imports,
    COMPONENT_TYPE_ENUM: componentTypeEnum,
    CASES_CREATE_COMPONENT: casesCreateComponent,
    CASES_FROM_JSON: casesFromJson,
    UTILITY_METHODS: utilityMethods,
    CASES_GET_DEFAULT_PROPERTIES: casesGetDefaultProperties,
    CASES_CREATE_WITH_PROPERTIES: casesCreateWithProperties
  });
  const propertiesFactoryImports = components2.map((c) => `import '${c.name}/properties.dart';`).join("\n");
  const componentPropertiesFactoryContent = await readAndFillTemplate(join2(templatesDir, "component_properties_factory.dart.tpl"), {
    IMPORTS: propertiesFactoryImports,
    CASES_GET_DEFAULT_PROPERTIES: casesGetDefaultPropertiesFactory,
    CASES_GET_VALIDATORS: casesGetValidators
  });
  const componentsExportContent = await readAndFillTemplate(join2(templatesDir, "components.dart.tpl"), {
    EXPORTS: exports
  });
  const factoryPath = join2(rootDir, "frontend", "lib", "components", "component_factory.dart");
  const propertiesFactoryPath = join2(rootDir, "frontend", "lib", "components", "component_properties_factory.dart");
  const exportsPath = join2(rootDir, "frontend", "lib", "components", "components.dart");
  await fs4.writeFile(factoryPath, componentFactoryContent);
  await fs4.writeFile(propertiesFactoryPath, componentPropertiesFactoryContent);
  await fs4.writeFile(exportsPath, componentsExportContent);
}
async function createComponentFiles(options) {
  const { name, className, properties = [], componentCode = "", isResizable = true } = options;
  const rootDir = getProjectRoot();
  const componentDir = join2(rootDir, "frontend", "lib", "components", name);
  const templatesDir = join2(rootDir, "backend", "src", "templates", "components");
  await fs4.mkdir(componentDir, { recursive: true });
  const propertiesCode = properties.map((prop) => {
    const displayName = prop.displayName || prop.name;
    switch (prop.type) {
      case "string":
        return `      const StringProperty(
        key: '${prop.name}',
        displayName: '${displayName}',
        value: '${prop.initialValue}',
        group: '${prop.group ?? "General"}',
        enable: Enabled(show: true, enabled: true),
      ),`;
      case "number":
        return `      const NumberProperty(
        key: '${prop.name}',
        displayName: '${displayName}',
        value: ${prop.initialValue},
        min: 0.0,
        max: 1000.0,
        group: '${prop.group ?? "General"}',
        enable: Enabled(show: true, enabled: true),
      ),`;
      case "boolean":
        return `      const BooleanProperty(
        key: '${prop.name}',
        displayName: '${displayName}',
        value: ${prop.initialValue},
        group: '${prop.group ?? "General"}',
        enable: Enabled(show: true, enabled: true),
      ),`;
      case "color":
        return `      const ComponentColorProperty(
        key: '${prop.name}',
        displayName: '${displayName}',
        value: XDColor(
             ['${prop.initialValue}'],
             type: ColorType.solid,
             stops: [],
             begin: Alignment.topLeft,
             end: Alignment.bottomRight,
         ),
        enable: Enabled(show: true, enabled: true),
        group: '${prop.group ?? "General"}',
      ),`;
      case "icon":
        return `      const IconProperty(
            key: '${prop.name}',
            displayName: '${displayName}',
            value: '${prop.initialValue}',
            group: '${prop.group ?? "General"}',
            enable: Enabled(show: false, enabled: true),
          ),`;
      default:
        return "";
    }
  }).join("\n");
  const validationLogic = `static Map<String, String? Function(dynamic)> get validators => {
${properties.map((prop) => {
    switch (prop.type) {
      case "string":
      case "icon":
        return `    '${prop.name}': (value) => value is String ? null : '${prop.name} must be a string',`;
      case "number":
        return `    '${prop.name}': (value) => value is num ? null : '${prop.name} must be a number',`;
      case "boolean":
        return `    '${prop.name}': (value) => value is bool ? null : '${prop.name} must be a boolean',`;
      case "color":
        return `    '${prop.name}': (value) {
      if (value is XDColor) return null;
      if (value is String && (value.startsWith('#') || value.startsWith('0x'))) return null;
      if (value is Map && value.containsKey('value')) return null; // JSON structure for color
      return '${prop.name} must be a valid color (Hex string, XDColor, or JSON object)';
    },`;
      default:
        return `    '${prop.name}': (value) => null,`;
    }
  }).join("\n")}
  };`;
  let componentContent = componentCode;
  if (!componentContent || componentContent.trim().length === 0) {
    componentContent = await readAndFillTemplate(join2(templatesDir, "component_class.dart.tpl"), {
      CLASS_NAME: className,
      COMPONENT_NAME: name,
      IS_RESIZABLE: isResizable.toString()
    });
  }
  const propertiesContent = await readAndFillTemplate(join2(templatesDir, "component_properties.dart.tpl"), {
    CLASS_NAME: className,
    PROPERTIES_CODE: propertiesCode,
    VALIDATION_LOGIC: validationLogic
  });
  await fs4.writeFile(join2(componentDir, "component.dart"), componentContent);
  await fs4.writeFile(join2(componentDir, "properties.dart"), propertiesContent);
}
async function registerComponent(name, className) {
  await generateComponentFactories();
}

// ../database/postgres.ts
import { drizzle } from "drizzle-orm/postgres-js";
import postgres from "postgres";
var db;
var client;
function getDrizzle() {
  if (db) return db;
  if (!client) {
    client = postgres(DATABASE_URL);
  }
  db = drizzle(client);
  return db;
}

// ../database/schema/components.ts
import { pgTable, text, varchar as varchar2, boolean } from "drizzle-orm/pg-core";

// ../database/schema/common.ts
import { timestamp, varchar } from "drizzle-orm/pg-core";
var ulidField = (name) => varchar(name, { length: 36 });
var defaultDateFields = {
  createdAt: timestamp("created_at", { mode: "date" }).notNull().defaultNow(),
  updatedAt: timestamp("updated_at", { mode: "date" }).notNull().$onUpdate(() => /* @__PURE__ */ new Date()).defaultNow()
};

// ../database/schema/components.ts
var components = pgTable("components", {
  id: ulidField("id").primaryKey(),
  name: varchar2("name", { length: 255 }).notNull().unique(),
  className: varchar2("class_name", { length: 255 }).notNull(),
  path: text("path").notNull(),
  properties: text("properties").notNull().default("[]"),
  // JSON string type definition
  code: text("code").notNull().default(""),
  isDefault: boolean("is_default").notNull().default(false),
  isResizable: boolean("is_resizable").notNull().default(true),
  ...defaultDateFields
});

// src/procedures/admin/create_component.rpc.ts
import { ulid as ulid2 } from "ulidx";
var create_component_rpc_default = defineRpc({
  params: a.object("CreateComponentParams", {
    name: a.string(),
    // e.g. "heroHeader" (enum value, folder name)
    className: a.string(),
    // e.g. "HeroHeader" (class name prefix)
    properties: a.array(
      a.object({
        name: a.string(),
        type: a.string(),
        initialValue: a.string()
        // Passing as string for simplicity, parsed or used directly
      })
    ),
    componentCode: a.optional(a.string())
  }),
  response: a.object("CreateComponentResponse", {
    success: a.boolean(),
    message: a.string()
  }),
  async handler({ params }) {
    try {
      const { name, className, properties: props, componentCode } = params;
      await createComponentFiles(name, className, props, componentCode || "");
      await registerComponent(name, className);
      const db2 = getDrizzle();
      await db2.insert(components).values({
        id: ulid2(),
        name,
        className,
        path: `/frontend/lib/components/${name}`,
        // Construct path
        properties: JSON.stringify(props),
        code: componentCode || ""
      });
      return {
        success: true,
        message: `Created component ${name}`
      };
    } catch (error) {
      console.error("Error creating component:", error);
      return {
        success: false,
        message: error instanceof Error ? error.message : "Failed to create component"
      };
    }
  }
});

// src/procedures/admin/create_type.rpc.ts
import { a as a2 } from "@arrirpc/schema";
import { defineRpc as defineRpc2 } from "@arrirpc/server";

// ../database/schema/types.ts
import { pgTable as pgTable2, text as text2, varchar as varchar3, boolean as boolean2 } from "drizzle-orm/pg-core";
var types = pgTable2("types", {
  id: ulidField("id").primaryKey(),
  name: varchar3("name", { length: 255 }).notNull().unique(),
  className: varchar3("class_name", { length: 255 }).notNull(),
  path: text2("path").notNull(),
  structure: varchar3("structure", { length: 50 }).notNull().default("object"),
  // 'object' | 'enum'
  enumValues: text2("enum_values"),
  // JSON string array for enum values
  isDefault: boolean2("is_default").notNull().default(false),
  ...defaultDateFields
});

// src/procedures/admin/create_type.rpc.ts
import { ulid as ulid3 } from "ulidx";

// src/utils/type_utils.ts
import { resolve as resolve2, join as join3, dirname as dirname2 } from "path";
import { mkdir, writeFile } from "fs/promises";
function getProjectRoot2() {
  const cwd = process.cwd();
  if (cwd.endsWith("backend")) {
    return resolve2(cwd, "..");
  }
  return cwd;
}
function resolveTypePath(name, structure) {
  const subDir = structure === "enum" ? "enums" : "objects";
  const rootDir = getProjectRoot2();
  const absoluteDir = resolve2(rootDir, `./frontend/lib/models/${subDir}`);
  const absolutePath = join3(absoluteDir, `${name}.dart`);
  const relativePath = `/frontend/lib/models/${subDir}/${name}.dart`;
  return { absolutePath, relativePath };
}
function generateTypeContent(className, structure, enumValues = [], rawCode = "") {
  if (structure === "enum") {
    const values = enumValues.length > 0 ? enumValues : ["placeholder"];
    return `enum ${className} {
${values.map((v) => `  ${v},`).join("\n")}
}`;
  } else {
    return rawCode || `class ${className} {
  final String id;
  // Add properties here
  
  const ${className}({required this.id});
}`;
  }
}
async function writeTypeFile(absolutePath, content) {
  await mkdir(dirname2(absolutePath), { recursive: true });
  await writeFile(absolutePath, content, "utf8");
}

// src/procedures/admin/create_type.rpc.ts
var create_type_rpc_default = defineRpc2({
  params: a2.object("CreateTypeParams", {
    name: a2.string(),
    className: a2.string(),
    structure: a2.string()
    // 'object' | 'enum'
  }),
  response: a2.object("CreateTypeResponse", {
    success: a2.boolean(),
    message: a2.string()
  }),
  async handler({ params }) {
    try {
      const db2 = getDrizzle();
      const structure = params.structure === "enum" ? "enum" : "object";
      const { absolutePath, relativePath } = resolveTypePath(params.name, structure);
      const content = generateTypeContent(params.className, structure, ["placeholder"], "");
      await writeTypeFile(absolutePath, content);
      await db2.insert(types).values({
        id: ulid3(),
        name: params.name,
        className: params.className,
        path: relativePath,
        structure,
        enumValues: structure === "enum" ? '["placeholder"]' : null
      });
      return {
        success: true,
        message: `Created ${params.name}`
      };
    } catch (error) {
      console.error("Error creating type:", error);
      return {
        success: false,
        message: error instanceof Error ? `Failed: ${error.message} (CWD: ${process.cwd()})` : "Failed to create type"
      };
    }
  }
});

// src/procedures/admin/get_components.rpc.ts
import { a as a3 } from "@arrirpc/schema";
import { defineRpc as defineRpc3 } from "@arrirpc/server";
var get_components_rpc_default = defineRpc3({
  params: a3.object("GetComponentsParams", {}),
  response: a3.object("GetComponentsResponse", {
    success: a3.boolean(),
    message: a3.string(),
    components: a3.array(
      a3.object("ComponentInfo", {
        id: a3.string(),
        name: a3.string(),
        className: a3.string(),
        path: a3.string(),
        properties: a3.string(),
        // JSON string of properties
        code: a3.string()
      })
    )
  }),
  async handler({}) {
    try {
      const db2 = getDrizzle();
      const dbComponents = await db2.select().from(components);
      const enhancedComponents = dbComponents.map((c) => {
        return {
          id: c.id,
          name: c.name,
          className: c.className,
          path: c.path,
          properties: c.properties || "[]",
          code: c.code || ""
        };
      });
      return {
        success: true,
        message: "Fetched components successfully",
        components: enhancedComponents
      };
    } catch (error) {
      console.error("Error fetching components:", error);
      return {
        success: false,
        message: error instanceof Error ? error.message : "Failed to fetch components",
        components: []
        // Fallback? Or we could throw/return error state strictly.
      };
    }
  }
});

// src/procedures/admin/get_types.rpc.ts
import { a as a4 } from "@arrirpc/schema";
import { defineRpc as defineRpc4 } from "@arrirpc/server";
import { desc } from "drizzle-orm";
import { readFile } from "fs/promises";
import { resolve as resolve3 } from "path";
var get_types_rpc_default = defineRpc4({
  params: a4.object("GetTypesParams", {}),
  response: a4.object("GetTypesResponse", {
    success: a4.boolean(),
    message: a4.string(),
    types: a4.array(
      a4.object("Type", {
        id: a4.string(),
        name: a4.string(),
        className: a4.string(),
        path: a4.string(),
        code: a4.string(),
        structure: a4.string(),
        enumValues: a4.string(),
        // JSON string
        createdAt: a4.string(),
        updatedAt: a4.string()
      })
    )
  }),
  async handler({}) {
    try {
      const db2 = getDrizzle();
      const allTypes = await db2.select().from(types).orderBy(desc(types.createdAt));
      const typesWithCode = await Promise.all(allTypes.map(async (t) => {
        let code = "";
        try {
          const projectRoot = resolve3(process.cwd(), "..");
          const relativePath = t.path.startsWith("/") ? t.path.slice(1) : t.path;
          const codePath = resolve3(projectRoot, relativePath);
          code = await readFile(codePath, "utf8");
        } catch (e) {
        }
        return {
          id: t.id,
          name: t.name,
          className: t.className,
          path: t.path,
          code,
          structure: t.structure,
          enumValues: t.enumValues ?? "[]",
          createdAt: t.createdAt.toISOString(),
          updatedAt: t.updatedAt.toISOString()
        };
      }));
      return {
        success: true,
        message: "Types fetched successfully",
        types: typesWithCode
      };
    } catch (error) {
      console.error("Error fetching types:", error);
      return {
        success: false,
        message: "Failed to fetch types",
        types: []
      };
    }
  }
});

// src/procedures/admin/save_type_code.rpc.ts
import { a as a5 } from "@arrirpc/schema";
import { defineRpc as defineRpc5 } from "@arrirpc/server";
import { eq } from "drizzle-orm";
import { writeFile as writeFile2, mkdir as mkdir2 } from "fs/promises";
import { join as join5, resolve as resolve4 } from "path";
var save_type_code_rpc_default = defineRpc5({
  params: a5.object("SaveTypeCodeParams", {
    typeId: a5.string(),
    code: a5.string()
  }),
  response: a5.object("SaveTypeCodeResponse", {
    success: a5.boolean(),
    message: a5.string()
  }),
  async handler({ params }) {
    try {
      const db2 = getDrizzle();
      const [type] = await db2.select().from(types).where(eq(types.id, params.typeId));
      if (!type) {
        return {
          success: false,
          message: "Type not found"
        };
      }
      const frontendModelsDir = resolve4(process.cwd(), "../frontend/lib/models/types");
      await mkdir2(frontendModelsDir, { recursive: true });
      const codePath = join5(frontendModelsDir, `${type.name}.dart`);
      await writeFile2(codePath, params.code, "utf8");
      return {
        success: true,
        message: "Code saved successfully"
      };
    } catch (error) {
      console.error("Error saving code:", error);
      return {
        success: false,
        message: error instanceof Error ? error.message : "Failed to save code"
      };
    }
  }
});

// src/procedures/admin/update_component.rpc.ts
import { a as a6 } from "@arrirpc/schema";
import { defineRpc as defineRpc6 } from "@arrirpc/server";
import { eq as eq2 } from "drizzle-orm";
var update_component_rpc_default = defineRpc6({
  params: a6.object("UpdateComponentParams", {
    id: a6.string(),
    properties: a6.array(
      a6.object({
        name: a6.string(),
        type: a6.stringEnum(["string", "number", "boolean", "color"]),
        initialValue: a6.string()
      })
    ),
    componentCode: a6.string()
  }),
  response: a6.object("UpdateComponentResponse", {
    success: a6.boolean(),
    message: a6.string()
  }),
  async handler({ params }) {
    try {
      const { id, properties, componentCode } = params;
      const db2 = getDrizzle();
      const existing = await db2.select().from(components).where(eq2(components.id, id)).limit(1);
      if (!existing.length) {
        return { success: false, message: "Component not found" };
      }
      const component = existing[0];
      await createComponentFiles(component.name, component.className, properties, componentCode);
      await db2.update(components).set({
        properties: JSON.stringify(properties),
        code: componentCode
      }).where(eq2(components.id, id));
      return {
        success: true,
        message: `Updated component ${component.name}`
      };
    } catch (error) {
      console.error("Error updating component:", error);
      return {
        success: false,
        message: error instanceof Error ? error.message : "Failed to update component"
      };
    }
  }
});

// src/procedures/admin/update_type_definition.rpc.ts
import { a as a7 } from "@arrirpc/schema";
import { defineRpc as defineRpc7 } from "@arrirpc/server";
import { eq as eq3 } from "drizzle-orm";
var update_type_definition_rpc_default = defineRpc7({
  params: a7.object("UpdateTypeDefinitionParams", {
    typeId: a7.string(),
    code: a7.string(),
    enumValues: a7.string(),
    structure: a7.string()
  }),
  response: a7.object("UpdateTypeDefinitionResponse", {
    success: a7.boolean(),
    message: a7.string()
  }),
  async handler({ params }) {
    try {
      const db2 = getDrizzle();
      const [type] = await db2.select().from(types).where(eq3(types.id, params.typeId));
      if (!type) {
        return {
          success: false,
          message: "Type not found"
        };
      }
      const structure = params.structure === "enum" ? "enum" : "object";
      const { absolutePath, relativePath } = resolveTypePath(type.name, structure);
      const values = JSON.parse(params.enumValues || "[]");
      const content = generateTypeContent(type.className, structure, values, params.code);
      await writeTypeFile(absolutePath, content);
      await db2.update(types).set({
        enumValues: params.enumValues,
        path: relativePath,
        structure
        // Ensure structure is updated if switched (though UI might not allow switching easily)
      }).where(eq3(types.id, params.typeId));
      return {
        success: true,
        message: "Type updated successfully"
      };
    } catch (error) {
      console.error("Error updating type definition:", error);
      return {
        success: false,
        message: error instanceof Error ? `${error.message}` : "Failed to update type"
      };
    }
  }
});

// src/procedures/ai/generate_design.rpc.ts
import { defineRpc as defineRpc8 } from "@arrirpc/server";
import { a as a8 } from "@arrirpc/schema";

// src/services/aiService.ts
import { GoogleGenerativeAI } from "@google/generative-ai";

// ../database/schema/svgs.ts
import { pgTable as pgTable3, text as text3, varchar as varchar4, boolean as boolean3 } from "drizzle-orm/pg-core";
var svgs = pgTable3("svgs", {
  id: ulidField("id").primaryKey(),
  name: varchar4("name", { length: 255 }).notNull(),
  svg: text3("svg").notNull(),
  type: varchar4("type", { length: 50 }).notNull(),
  // 'regular', 'solid', 'brands'
  isDefault: boolean3("is_default").notNull().default(false),
  ...defaultDateFields
});

// ../database/schema/ai_cache.ts
import { pgTable as pgTable4, text as text4, varchar as varchar5, index } from "drizzle-orm/pg-core";
var aiDesignCache = pgTable4("ai_design_cache", {
  id: ulidField("id").primaryKey(),
  prompt: text4("prompt").notNull().unique(),
  designJson: text4("design_json").notNull(),
  modelUsed: varchar5("model_used", { length: 255 }).notNull(),
  ...defaultDateFields
}, (table) => {
  return {
    promptIndex: index("ai_design_cache_prompt_idx").on(table.prompt)
  };
});

// ../database/schema/ai_sessions.ts
import { pgTable as pgTable5, text as text5, varchar as varchar6, timestamp as timestamp2, index as index2 } from "drizzle-orm/pg-core";
var aiDesignSessions = pgTable5("ai_design_sessions", {
  id: ulidField("id").primaryKey(),
  // Usually generated by frontend
  ...defaultDateFields
});
var aiDesignMessages = pgTable5("ai_design_messages", {
  id: ulidField("id").primaryKey(),
  sessionId: ulidField("session_id").notNull().references(() => aiDesignSessions.id, { onDelete: "cascade" }),
  role: varchar6("role", { length: 20 }).notNull(),
  // 'user' | 'assistant'
  content: text5("content").notNull(),
  // Prompt or JSON
  createdAt: timestamp2("created_at", { mode: "date" }).notNull().defaultNow()
}, (table) => {
  return {
    sessionIdx: index2("ai_design_messages_session_idx").on(table.sessionId)
  };
});

// src/services/aiService.ts
import { eq as eq4, asc } from "drizzle-orm";
import { ulid as ulid4 } from "ulidx";
var AiService = class {
  static genAI = new GoogleGenerativeAI(env.GOOGLE_STUDIO_API_KEY || "");
  static async generateDesign(prompt, sessionId, isIteration = false) {
    const model = this.genAI.getGenerativeModel({
      model: "gemini-flash-latest",
      generationConfig: {
        responseMimeType: "application/json"
      }
    });
    const db2 = getDrizzle();
    const allComponents = await db2.select().from(components);
    const allSvgs = await db2.select({ name: svgs.name }).from(svgs);
    const componentTypesList = allComponents.map((c) => `"${c.name}"`).join(" | ");
    const svgNamesList = allSvgs.map((s) => `"${s.name}"`).join(", ");
    const dynamicPropertiesSchema = allComponents.map((comp) => {
      let props = [];
      try {
        props = JSON.parse(comp.properties);
      } catch (e) {
        return "";
      }
      const propLines = props.map((p) => {
        let typeDesc = "any";
        switch (p.type) {
          case "string":
            typeDesc = "string";
            break;
          case "number":
            typeDesc = "double";
            break;
          case "boolean":
            typeDesc = "boolean";
            break;
          case "color":
            typeDesc = '"#AARRGGBB" (Hex String)';
            break;
          case "icon":
            typeDesc = "string (Material Icon name)";
            break;
          default:
            typeDesc = "any";
        }
        return `"${p.name}": ${typeDesc}`;
      }).join(",\n        ");
      return `// PROPERTIES FOR "${comp.name}"
        ${propLines}`;
    }).join("\n\n        ");
    const schemaDescription = `
    You are a UI design generator. Output strictly valid JSON matching this schema for a Flutter app design canvas.
    
    ROOT OBJECT:
    {
      "components": [ ... list of component objects ... ],
      "canvasSize": { "width": 375.0, "height": 812.0 }, // Standard mobile size
      "selectedComponent": null, // Always null initially
      "isDragging": false,
      "isPropertyEditorVisible": false
    }

    COMPONENT OBJECT:
    {
      "id": "unique_string_id",
      "type": ${componentTypesList},
      "x": double (position),
      "y": double (position),
      "resizable": true,
      "properties": {
        // Use simple direct values for properties
        
        // DYNAMICALLY GENERATED PROPERTIES FROM DATABASE
        ${dynamicPropertiesSchema}
      }
    }

    IMPORTANT RULES:
    1. Every component MUST have a unique "id".
    2. All properties MUST be simple direct values (string, number, boolean, or hex string for colors).
    3. Colors MUST be Hex strings (e.g. "#FF0000" or "#AARRGGBB").
    4. For any "icon" property, you MUST use ONLY one of these valid names: [${svgNamesList}].
    5. Generate a complete, beautiful design based on the user prompt: "${prompt}".
    6. Ensure components are positioned logically.
    `;
    let currentPrompt = schemaDescription;
    let attempts = 0;
    const maxAttempts = 3;
    const modelName = "gemini-flash-latest";
    if (!isIteration) {
      try {
        const cached = await db2.select().from(aiDesignCache).where(eq4(aiDesignCache.prompt, prompt)).limit(1);
        if (cached && cached.length > 0) {
          const entry = cached[0];
          if (entry) {
            console.log("\u{1F680} Cache HIT for prompt:", prompt);
            return JSON.parse(entry.designJson);
          }
        }
        console.log("\u{1F311} Cache MISS for prompt:", prompt);
      } catch (e) {
        console.error("\u26A0\uFE0F Cache lookup error:", e);
      }
    }
    console.log("----------------------------------------------------------------");
    console.log("\u{1F916} GENERATED AI PROMPT:");
    console.log(currentPrompt);
    console.log("----------------------------------------------------------------");
    while (attempts < maxAttempts) {
      try {
        console.log(`\u{1F916} AI Generation Attempt ${attempts + 1}/${maxAttempts}`);
        console.log("\u23F3 Waiting for Gemini API response...");
        const result = await model.generateContent(currentPrompt);
        console.log("\u2705 Received response from Gemini API");
        console.log("\u23F3 Extracting text from response...");
        const responseText = result.response.text();
        console.log("\u2705 Text extracted");
        let json;
        try {
          console.log("\u23F3 Parsing JSON...");
          json = JSON.parse(responseText);
          console.log("\u2705 JSON parsed successfully");
        } catch (e) {
          console.error("\u274C Failed to parse JSON:", responseText);
          throw new Error("Invalid JSON returned by AI");
        }
        const errors = this.validateDesignJson(json);
        if (errors.length === 0) {
          if (!isIteration && attempts === 0) {
            try {
              await db2.insert(aiDesignCache).values({
                id: ulid4(),
                prompt,
                designJson: JSON.stringify(json),
                modelUsed: modelName
              }).onConflictDoUpdate({
                target: aiDesignCache.prompt,
                set: { designJson: JSON.stringify(json), modelUsed: modelName }
              });
              console.log("\u2705 Saved to cache (initial successful attempt)");
            } catch (e) {
              console.error("\u26A0\uFE0F Failed to save to cache:", e);
            }
          } else if (attempts > 0) {
            console.log("\u2139\uFE0F Skipping cache save for fixing prompt (attempt > 0)");
          } else if (isIteration) {
            console.log("\u2139\uFE0F Skipping cache save for iteration prompt");
          }
          if (sessionId) {
            try {
              const db3 = getDrizzle();
              await db3.insert(aiDesignSessions).values({ id: sessionId }).onConflictDoNothing();
              await db3.insert(aiDesignMessages).values({
                id: ulid4(),
                sessionId,
                role: "user",
                content: prompt
              });
              await db3.insert(aiDesignMessages).values({
                id: ulid4(),
                sessionId,
                role: "assistant",
                content: JSON.stringify(json)
              });
              console.log("\u2705 Recorded messages in session:", sessionId);
            } catch (e) {
              console.error("\u26A0\uFE0F Failed to record session message:", e);
            }
          }
          return json;
        }
        console.warn("\u26A0\uFE0F Validation Errors:", errors);
        currentPrompt = `
        The previous JSON had the following errors:
${errors.join("\n")}

        Please fix these errors and return the valid JSON again.
        Original Prompt: ${schemaDescription}
        `;
        attempts++;
      } catch (error) {
        console.error("\u274C AI Generation Error:", error);
        attempts++;
        if (attempts < maxAttempts) {
          console.log("Waiting 5 seconds before retry...");
          await new Promise((resolve5) => setTimeout(resolve5, 5e3));
        }
      }
    }
    throw new Error("Failed to generate valid design after multiple attempts");
  }
  static async iterateDesign(sessionId, prompt) {
    const db2 = getDrizzle();
    const history = await db2.select().from(aiDesignMessages).where(eq4(aiDesignMessages.sessionId, sessionId)).orderBy(asc(aiDesignMessages.createdAt));
    if (history.length === 0) {
      return this.generateDesign(prompt, sessionId, false);
    }
    let lastDesignJson = "";
    for (let i = history.length - 1; i >= 0; i--) {
      const entry = history[i];
      if (entry && entry.role === "assistant") {
        lastDesignJson = entry.content;
        break;
      }
    }
    const contextPrompt = `
    The user is iterating on a previous design.
    ${lastDesignJson ? `PREVIOUS DESIGN JSON:
${lastDesignJson}
` : ""}
    
    USER FEEDBACK / REQUEST:
    "${prompt}"
    
    Based on the previous design and the user's feedback, provide an updated, corrected JSON.
    Maintain the overall structure but apply the requested changes carefully.
    `;
    return this.generateDesign(contextPrompt, sessionId, true);
  }
  static validateDesignJson(json) {
    const errors = [];
    if (!json.components || !Array.isArray(json.components)) {
      errors.push("Root object missing 'components' array");
      return errors;
    }
    json.components.forEach((comp, index3) => {
      if (!comp.type) errors.push(`Component[${index3}] missing type`);
      if (typeof comp.x === "string") {
        const parsed = parseFloat(comp.x);
        if (!isNaN(parsed)) comp.x = parsed;
      }
      if (typeof comp.y === "string") {
        const parsed = parseFloat(comp.y);
        if (!isNaN(parsed)) comp.y = parsed;
      }
      if (typeof comp.x !== "number") errors.push(`Component[${index3}] invalid x`);
      if (typeof comp.y !== "number") errors.push(`Component[${index3}] invalid y`);
      if (!comp.properties) {
        errors.push(`Component[${index3}] missing properties`);
      } else {
        Object.keys(comp.properties).forEach((key) => {
          const val = comp.properties[key];
          if (typeof val === "string" && val.trim() !== "" && !isNaN(Number(val)) && !val.startsWith("#")) {
            comp.properties[key] = parseFloat(val);
          }
        });
      }
    });
    return errors;
  }
};

// src/procedures/ai/generate_design.rpc.ts
var generate_design_rpc_default = defineRpc8({
  params: a8.object("GenerateDesignParams", {
    prompt: a8.string(),
    sessionId: a8.string()
    // Changed from optional to avoid generator bug
  }),
  response: a8.object("GenerateDesignResponse", {
    success: a8.boolean(),
    message: a8.string(),
    // Changed from nullable
    data: a8.any()
  }),
  handler: async ({ params }) => {
    try {
      const effectiveSessionId = params.sessionId || void 0;
      const designJson = await AiService.generateDesign(params.prompt, effectiveSessionId);
      const responseStr = JSON.stringify(designJson);
      console.log(`\u2705 Design generated. Size: ${(responseStr.length / 1024).toFixed(2)} KB`);
      return {
        success: true,
        data: designJson,
        message: ""
      };
    } catch (error) {
      console.error("Design generation failed:", error);
      return {
        success: false,
        message: error.message || "Unknown error occurred during generation",
        data: null
      };
    }
  }
});

// src/procedures/ai/generate_image.rpc.ts
import { defineRpc as defineRpc9 } from "@arrirpc/server";
import { a as a9 } from "@arrirpc/schema";
var generate_image_rpc_default = defineRpc9({
  params: a9.object("GenerateImageParams", {
    prompt: a9.string(),
    negativePrompt: a9.optional(a9.string()),
    width: a9.optional(a9.number()),
    height: a9.optional(a9.number()),
    steps: a9.optional(a9.number()),
    socketId: a9.optional(a9.string())
  }),
  response: a9.object("GenerateImageResponse", {
    success: a9.boolean(),
    message: a9.string(),
    url: a9.optional(a9.string())
  }),
  handler: async ({ params }) => {
    console.log("!!! [Backend RPC] generate_image HIT !!!");
    console.log("Params:", JSON.stringify(params));
    try {
      const aiServerUrl = AI_BASE_URL || "http://localhost:5000";
      const fullUrl = `${aiServerUrl}/generate-image`;
      console.log(`\u{1F50C} Connecting to AI server at: ${fullUrl}`);
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 3e5);
      console.log("\u23F3 Waiting for AI server response...");
      const response = await fetch(fullUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          prompt: params.prompt,
          negative_prompt: params.negativePrompt || "",
          width: params.width || 512,
          height: params.height || 512,
          steps: params.steps || 25,
          socketId: params.socketId
        }),
        signal: controller.signal
      });
      clearTimeout(timeoutId);
      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.error || `AI server returned ${response.status}`);
      }
      const imageBuffer = await response.arrayBuffer();
      console.log("\u2705 Image received from AI server, size:", imageBuffer.byteLength);
      const uploadResult = await mediaServer.uploadMedia({
        originalName: `generated-${Date.now()}.png`,
        bytes: Buffer.from(imageBuffer),
        contentType: "image/png",
        directory: "generated"
      });
      return {
        success: true,
        message: "Image generated and uploaded successfully",
        url: uploadResult.url
      };
    } catch (error) {
      console.error("\u274C Image generation failed:", error);
      return {
        success: false,
        message: error.message || "Unknown error occurred during image generation"
      };
    }
  }
});

// src/procedures/ai/inpaint_image.rpc.ts
import { defineRpc as defineRpc10 } from "@arrirpc/server";
import { a as a10 } from "@arrirpc/schema";
var inpaint_image_rpc_default = defineRpc10({
  params: a10.object("InpaintImageParams", {
    prompt: a10.string(),
    negativePrompt: a10.optional(a10.string()),
    width: a10.optional(a10.number()),
    height: a10.optional(a10.number()),
    steps: a10.optional(a10.number()),
    socketId: a10.optional(a10.string()),
    image: a10.string(),
    // Base64 image or URL
    mask: a10.string()
    // Base64 mask
  }),
  response: a10.object("InpaintImageResponse", {
    success: a10.boolean(),
    message: a10.string(),
    url: a10.optional(a10.string())
  }),
  handler: async ({ params }) => {
    console.log("!!! [Backend RPC] inpaint_image HIT !!!");
    try {
      const aiServerUrl = AI_BASE_URL || "http://localhost:5000";
      const fullUrl = `${aiServerUrl}/inpaint-image`;
      console.log(`\u{1F50C} Connecting to AI server at: ${fullUrl}`);
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 3e5);
      const response = await fetch(fullUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          prompt: params.prompt,
          negative_prompt: params.negativePrompt || "",
          width: params.width || 512,
          height: params.height || 512,
          steps: params.steps || 25,
          socketId: params.socketId,
          image: params.image,
          mask: params.mask
        }),
        signal: controller.signal
      });
      clearTimeout(timeoutId);
      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.error || `AI server returned ${response.status}`);
      }
      const imageBuffer = await response.arrayBuffer();
      const uploadResult = await mediaServer.uploadMedia({
        originalName: `inpainted-${Date.now()}.png`,
        bytes: Buffer.from(imageBuffer),
        contentType: "image/png",
        directory: "generated"
      });
      return {
        success: true,
        message: "Image inpainted and uploaded successfully",
        url: uploadResult.url
      };
    } catch (error) {
      console.error("\u274C Image inpainting failed:", error);
      return {
        success: false,
        message: error.message || "Unknown error occurred during image inpainting"
      };
    }
  }
});

// src/procedures/ai/iterate_design.rpc.ts
import { defineRpc as defineRpc11 } from "@arrirpc/server";
import { a as a11 } from "@arrirpc/schema";
var iterate_design_rpc_default = defineRpc11({
  params: a11.object({
    sessionId: a11.string(),
    prompt: a11.string()
  }),
  response: a11.object({
    success: a11.boolean(),
    message: a11.string(),
    data: a11.any()
  }),
  handler: async ({ params }) => {
    try {
      const resultJson = await AiService.iterateDesign(params.sessionId, params.prompt);
      return {
        success: true,
        message: "",
        data: resultJson
      };
    } catch (error) {
      console.error("\u274C Iterate Design Error:", error);
      return {
        success: false,
        message: error.message || "Failed to iterate design",
        data: null
      };
    }
  }
});

// src/procedures/svg/get_svgs.rpc.ts
import { a as a12 } from "@arrirpc/schema";
import { defineRpc as defineRpc12 } from "@arrirpc/server";
import { or, count, ilike, desc as desc2 } from "drizzle-orm";
var get_svgs_rpc_default = defineRpc12({
  params: a12.object("GetSvgsParams", {
    limit: a12.int32(),
    offset: a12.int32(),
    search: a12.string()
  }),
  response: a12.object("GetSvgsResponse", {
    success: a12.boolean(),
    message: a12.string(),
    total: a12.int32(),
    svgs: a12.array(
      a12.object("SvgInfo", {
        id: a12.string(),
        name: a12.string(),
        svg: a12.string(),
        type: a12.string()
      })
    )
  }),
  async handler({ limit, offset, search }) {
    console.log(`[get_svgs] params: limit=${limit}, offset=${offset}, search=${search}`);
    try {
      const db2 = getDrizzle();
      const pageSize = limit || 50;
      const pageOffset = offset || 0;
      let query = db2.select().from(svgs).$dynamic();
      if (search) {
        const searchPattern = `%${search}%`;
        query = query.where(
          or(
            ilike(svgs.name, searchPattern),
            ilike(svgs.type, searchPattern)
          )
        );
      }
      let countQuery = db2.select({ count: count() }).from(svgs).$dynamic();
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
      const results = await query.limit(pageSize).offset(pageOffset).orderBy(desc2(svgs.createdAt), desc2(svgs.id));
      return {
        success: true,
        message: "Fetched SVGs successfully",
        total,
        svgs: results.map((s) => ({
          id: s.id,
          name: s.name,
          svg: s.svg,
          type: s.type
        }))
      };
    } catch (error) {
      console.error("Error fetching SVGs:", error);
      return {
        success: false,
        message: error instanceof Error ? error.message : "Failed to fetch SVGs",
        total: 0,
        svgs: []
      };
    }
  }
});

// .arri/__arri_app.ts
sourceMapSupport.install();
app_default.rpc("admin.create_component", create_component_rpc_default);
app_default.rpc("admin.create_type", create_type_rpc_default);
app_default.rpc("admin.get_components", get_components_rpc_default);
app_default.rpc("admin.get_types", get_types_rpc_default);
app_default.rpc("admin.save_type_code", save_type_code_rpc_default);
app_default.rpc("admin.update_component", update_component_rpc_default);
app_default.rpc("admin.update_type_definition", update_type_definition_rpc_default);
app_default.rpc("ai.generate_design", generate_design_rpc_default);
app_default.rpc("ai.generate_image", generate_image_rpc_default);
app_default.rpc("ai.inpaint_image", inpaint_image_rpc_default);
app_default.rpc("ai.iterate_design", iterate_design_rpc_default);
app_default.rpc("svg.get_svgs", get_svgs_rpc_default);
var arri_app_default = app_default;
export {
  arri_app_default as default
};
//# sourceMappingURL=app.mjs.map
