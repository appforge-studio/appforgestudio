import { createServer, IncomingMessage, ServerResponse } from "http";
import { Server, Socket } from "socket.io";

export class EventServer {
  static httpServer: any;
  static io: Server;
  // static sockets: Record<string, Socket> = {};

  static init() {
    if (!EventServer.io) {
      // Create a custom HTTP server that handles routes
      EventServer.httpServer = createServer(
        (req: IncomingMessage, res: ServerResponse) => {
          if (req.url === "/relay" && req.method === "POST") {
            let body = "";
            req.on("data", (chunk) => (body += chunk));
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

      // Attach Socket.IO
      EventServer.io = new Server(EventServer.httpServer, {
        cors: { origin: "*" },
      });

      // Handle socket connections
      EventServer.io.on("connection", (socket) => {
        console.log("Socket connected:", socket.id);
        
        // Handle general events
        socket.on("disconnect", () => {
          console.log("Socket disconnected:", socket.id);
        });
        
        // Pose-related events are handled by poseSocketService
        // which listens to the same EventServer.io instance
      });

      EventServer.httpServer.on("error", (err: any) => {
        if (err.code === "EADDRINUSE") {
          console.log("Port 5001 already in use");
        } else {
          console.error("Error starting Socket.IO server:", err);
        }
      });
      EventServer.httpServer.listen(5001, () => {
        console.log("Socket.IO + HTTP server running on port 5001");
      });
    }
  }
}

export async function send(
  socketId: string,
  event: string,
  data: unknown
): Promise<void> {
  const response = await fetch("http://192.168.1.13:5001/relay", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ socketId: socketId, event: event, data: data }),
  });
  const result = await response.json();
  console.log(result);
}
