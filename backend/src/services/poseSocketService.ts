import { Server, Socket } from "socket.io";
import { EventServer } from "./eventServer";

interface BoneRotation {
  name: string;
  x: number;
  y: number;
  z: number;
}

class PoseSocketService {
  private adminSocket: Socket | null = null;
  private pendingRequests: Map<string, {
    resolve: (rotations: BoneRotation[]) => void;
    reject: (error: Error) => void;
    timeout: NodeJS.Timeout;
  }> = new Map();

  constructor() {
    // Initialize socket listeners when EventServer is ready
    this.initializeListeners();
  }

  private initializeListeners() {
    // Wait for EventServer to be initialized
    if (!EventServer.io) {
      setTimeout(() => this.initializeListeners(), 100);
      return;
    }

    // Listen for admin panel connections
    EventServer.io.on("connection", (socket: Socket) => {
      console.log(`Socket connected: ${socket.id}`);

      // Listen for admin panel identification
      socket.on("identify_admin", () => {
        console.log(`Admin panel connected: ${socket.id}`);
        this.adminSocket = socket;
        socket.emit("admin_identified", { success: true });
      });

      // Listen for bone rotation responses from admin panel
      socket.on("bone_rotations_response", (data: { requestId: string; rotations: BoneRotation[] }) => {
        console.log(`Received bone rotations response for request: ${data.requestId}`);
        const pending = this.pendingRequests.get(data.requestId);
        
        if (pending) {
          clearTimeout(pending.timeout);
          pending.resolve(data.rotations);
          this.pendingRequests.delete(data.requestId);
        }
      });

      // Handle disconnection
      socket.on("disconnect", () => {
        console.log(`Socket disconnected: ${socket.id}`);
        if (this.adminSocket?.id === socket.id) {
          console.log("Admin panel disconnected");
          this.adminSocket = null;
        }
      });
    });
  }

  async startServer(): Promise<void> {
    // EventServer is already initialized in app.ts
    // Just ensure listeners are set up
    this.initializeListeners();
  }

  isRunning(): boolean {
    return EventServer.io !== undefined && EventServer.io !== null;
  }

  hasAdminConnected(): boolean {
    return this.adminSocket !== null && this.adminSocket.connected;
  }

  async requestBoneRotations(landmarks: number[][]): Promise<BoneRotation[]> {
    if (!this.hasAdminConnected()) {
      throw new Error("No admin panel connected");
    }

    const requestId = `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    return new Promise<BoneRotation[]>((resolve, reject) => {
      // Set timeout for request (30 seconds)
      const timeout = setTimeout(() => {
        this.pendingRequests.delete(requestId);
        reject(new Error("Bone rotation request timed out"));
      }, 30000);

      // Store pending request
      this.pendingRequests.set(requestId, { resolve, reject, timeout });

      // Send request to admin panel
      this.adminSocket!.emit("calculate_bone_rotations", {
        requestId,
        landmarks,
      });

      console.log(`Sent bone rotation request to admin panel: ${requestId}`);
    });
  }

  getStatus(): {
    isRunning: boolean;
    hasAdminConnected: boolean;
    connectedClients: number;
    port: number;
  } {
    return {
      isRunning: this.isRunning(),
      hasAdminConnected: this.hasAdminConnected(),
      connectedClients: EventServer.io ? EventServer.io.sockets.sockets.size : 0,
      port: 5001,
    };
  }
}

// Export singleton instance
export const poseSocketService = new PoseSocketService();