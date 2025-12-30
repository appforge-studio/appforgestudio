import { promises as fs } from 'node:fs';
import path from 'node:path';
import { ulid } from 'ulidx';

interface ChunkUploadSession {
  id: string;
  filename: string;
  totalChunks: number;
  uploadedChunks: Set<number>;
  directory: string;
  contentType?: string;
  createdAt: Date;
}

class ChunkUploadManager {
  private sessions = new Map<string, ChunkUploadSession>();
  private tempDir = path.join(process.cwd(), 'temp_uploads');

  constructor() {
    this.ensureTempDir();
    // Clean up old sessions every hour
    setInterval(() => this.cleanupOldSessions(), 60 * 60 * 1000);
  }

  private async ensureTempDir() {
    try {
      await fs.mkdir(this.tempDir, { recursive: true });
    } catch (error) {
      console.error('Failed to create temp directory:', error);
    }
  }

  async initializeUpload(filename: string, totalChunks: number, directory: string, contentType?: string): Promise<string> {
    const sessionId = ulid();
    const session: ChunkUploadSession = {
      id: sessionId,
      filename,
      totalChunks,
      uploadedChunks: new Set(),
      directory,
      contentType,
      createdAt: new Date(),
    };

    this.sessions.set(sessionId, session);
    
    // Create session directory
    const sessionDir = path.join(this.tempDir, sessionId);
    await fs.mkdir(sessionDir, { recursive: true });

    console.log(`Initialized chunked upload session: ${sessionId} for file: ${filename} (${totalChunks} chunks)`);
    return sessionId;
  }

  async uploadChunk(sessionId: string, chunkIndex: number, chunkData: Buffer): Promise<{ success: boolean; message: string; progress?: number }> {
    const session = this.sessions.get(sessionId);
    if (!session) {
      return { success: false, message: 'Upload session not found' };
    }

    try {
      const sessionDir = path.join(this.tempDir, sessionId);
      const chunkPath = path.join(sessionDir, `chunk_${chunkIndex}`);
      
      await fs.writeFile(chunkPath, chunkData);
      session.uploadedChunks.add(chunkIndex);

      const progress = Math.round((session.uploadedChunks.size / session.totalChunks) * 100);
      
      console.log(`Uploaded chunk ${chunkIndex + 1}/${session.totalChunks} for session ${sessionId} (${progress}%)`);

      return {
        success: true,
        message: `Chunk ${chunkIndex + 1}/${session.totalChunks} uploaded`,
        progress
      };
    } catch (error) {
      console.error(`Failed to upload chunk ${chunkIndex} for session ${sessionId}:`, error);
      return { success: false, message: 'Failed to save chunk' };
    }
  }

  async finalizeUpload(sessionId: string): Promise<{ success: boolean; message: string; filePath?: string }> {
    const session = this.sessions.get(sessionId);
    if (!session) {
      return { success: false, message: 'Upload session not found' };
    }

    // Check if all chunks are uploaded
    if (session.uploadedChunks.size !== session.totalChunks) {
      return { 
        success: false, 
        message: `Missing chunks. Expected ${session.totalChunks}, got ${session.uploadedChunks.size}` 
      };
    }

    try {
      const sessionDir = path.join(this.tempDir, sessionId);
      const finalDir = path.join(process.cwd(), 'uploads', session.directory);
      await fs.mkdir(finalDir, { recursive: true });

      const finalFilePath = path.join(finalDir, session.filename);
      const writeStream = await fs.open(finalFilePath, 'w');

      // Combine chunks in order
      for (let i = 0; i < session.totalChunks; i++) {
        const chunkPath = path.join(sessionDir, `chunk_${i}`);
        const chunkData = await fs.readFile(chunkPath);
        await writeStream.write(chunkData);
      }

      await writeStream.close();

      // Clean up session
      await this.cleanupSession(sessionId);

      console.log(`Finalized chunked upload: ${session.filename} (${session.totalChunks} chunks)`);
      
      return {
        success: true,
        message: 'File upload completed',
        filePath: finalFilePath
      };
    } catch (error) {
      console.error(`Failed to finalize upload for session ${sessionId}:`, error);
      return { success: false, message: 'Failed to combine chunks' };
    }
  }

  async getUploadProgress(sessionId: string): Promise<{ success: boolean; progress?: number; message: string }> {
    const session = this.sessions.get(sessionId);
    if (!session) {
      return { success: false, message: 'Upload session not found' };
    }

    const progress = Math.round((session.uploadedChunks.size / session.totalChunks) * 100);
    return {
      success: true,
      progress,
      message: `${session.uploadedChunks.size}/${session.totalChunks} chunks uploaded`
    };
  }

  private async cleanupSession(sessionId: string) {
    try {
      const sessionDir = path.join(this.tempDir, sessionId);
      await fs.rm(sessionDir, { recursive: true, force: true });
      this.sessions.delete(sessionId);
    } catch (error) {
      console.error(`Failed to cleanup session ${sessionId}:`, error);
    }
  }

  private cleanupOldSessions() {
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    
    for (const [sessionId, session] of this.sessions.entries()) {
      if (session.createdAt < oneHourAgo) {
        console.log(`Cleaning up old upload session: ${sessionId}`);
        this.cleanupSession(sessionId);
      }
    }
  }
}

export const chunkUploadManager = new ChunkUploadManager();