# Pose Detection API

This document describes the pose detection functionality implemented in the vyom-main backend using Socket.IO for real-time communication with admin panels.

## Overview

The pose detection system provides the following functionality:
- Basic pose detection using HybrIK API
- Advanced pose detection with bone rotation calculations
- Socket.IO communication with admin panels for enhanced calculations
- Fallback to server-side calculations when admin panel is not available

## API Endpoints

### 1. Basic Pose Detection
**GET** `/yoga/detect-pose`

Detects pose landmarks using the HybrIK API.

**Response:**
```json
{
  "success": true,
  "message": "Pose detected successfully using HybrIK API",
  "landmarks": [
    [x1, y1, z1],
    [x2, y2, z2],
    ...
  ]
}
```

### 2. Pose Detection with Bone Rotations
**GET** `/yoga/detect-pose-with-rotations`

Detects pose landmarks and calculates bone rotations. Uses admin panel via Socket.IO if available, otherwise falls back to server-side calculations.

**Response:**
```json
{
  "success": true,
  "message": "Pose detected and bone rotations calculated successfully",
  "landmarks": [
    [x1, y1, z1],
    [x2, y2, z2],
    ...
  ],
  "boneRotations": [
    {
      "name": "Spine",
      "x": 10.5,
      "y": -5.2,
      "z": 0.8
    },
    ...
  ]
}
```

### 3. Socket Server Status
**GET** `/yoga/socket-status`

Returns the current status of the Socket.IO server.

**Response:**
```json
{
  "isRunning": true,
  "hasAdminConnected": true,
  "connectedClients": 2,
  "port": 5001
}
```

### 4. Initialize Socket Server
**POST** `/yoga/initialize-socket-server`

Initializes the Socket.IO server if not already running.

**Response:**
```json
{
  "success": true,
  "message": "Socket server initialized successfully"
}
```

### 5. Save Pose Data
**POST** `/yoga/save-pose`

Saves pose data (placeholder implementation).

**Request Body:**
```json
{
  "poseType": "warrior_pose"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Pose data saved successfully for type: warrior_pose"
}
```

## Socket.IO Communication

The system uses Socket.IO for real-time communication between the backend and admin panels (Unity applications).

### Server Events (Backend → Admin Panel)

#### `calculate_bone_rotations`
Sent when the backend needs bone rotation calculations from the admin panel.

**Payload:**
```json
{
  "requestId": "req_1234567890_abc123",
  "landmarks": [
    [x1, y1, z1],
    [x2, y2, z2],
    ...
  ]
}
```

### Client Events (Admin Panel → Backend)

#### `identify_admin`
Sent by admin panel to identify itself to the server.

**Response:** `admin_identified`
```json
{
  "success": true
}
```

#### `bone_rotations_response`
Sent by admin panel in response to `calculate_bone_rotations`.

**Payload:**
```json
{
  "requestId": "req_1234567890_abc123",
  "rotations": [
    {
      "name": "Spine",
      "x": 10.5,
      "y": -5.2,
      "z": 0.8
    },
    ...
  ]
}
```

## Admin Panel Integration

### Connection Process
1. Admin panel connects to Socket.IO server at `ws://localhost:5001`
2. Admin panel sends `identify_admin` event
3. Server responds with `admin_identified` confirmation
4. Admin panel is now ready to receive calculation requests

### Calculation Flow
1. Client requests pose detection with rotations
2. Backend calls HybrIK API for landmarks
3. If admin panel is connected:
   - Backend sends `calculate_bone_rotations` event with landmarks
   - Admin panel calculates rotations using Unity/3D engine
   - Admin panel responds with `bone_rotations_response`
   - Backend returns combined result to client
4. If admin panel is not connected:
   - Backend falls back to server-side calculation
   - Backend returns result with server-calculated rotations

## Testing

### Test Admin Client
A test admin client is provided at `src/utils/testAdminClient.ts` that simulates an admin panel connection.

**Usage:**
```bash
cd vyom-main/backend
npx tsx src/utils/testAdminClient.ts
```

### Manual Testing
1. Start the backend server: `pnpm run dev` (EventServer/Socket.IO starts automatically)
2. (Optional) Run the test admin client in another terminal
3. Test the endpoints using curl or Postman:

```bash
# Basic pose detection
curl http://localhost:3000/yoga/detect-pose

# Pose detection with rotations
curl http://localhost:3000/yoga/detect-pose-with-rotations

# Check socket status
curl http://localhost:3000/yoga/socket-status

# Initialize socket server
curl -X POST http://localhost:3000/yoga/initialize-socket-server

# Save pose data
curl -X POST http://localhost:3000/yoga/save-pose \
  -H "Content-Type: application/json" \
  -d '{"poseType": "warrior_pose"}'
```

## Architecture

### Components
- **Pose Procedures**: API endpoints for pose detection (`src/procedures/yoga/`)
- **Pose Socket Service**: Manages Socket.IO communication (`src/services/poseSocketService.ts`)
- **Bone Rotation Calculator**: Server-side fallback calculations (`src/utils/boneRotationCalculator.ts`)
- **Event Server**: Base Socket.IO server (`src/services/eventServer.ts`)

### Data Flow
```
Client Request → Pose Procedure → HybrIK API → Landmarks
                                      ↓
Admin Panel ← Socket.IO ← Pose Socket Service ← Landmarks
                                      ↓
Bone Rotations → Socket.IO → Pose Socket Service → Response
```

## Configuration

### Environment Variables
- Socket.IO server runs on port 5001 (configurable in `eventServer.ts`)
- HybrIK API endpoint: `http://appforgestudio.in:5000/api/detect_pose`

### Dependencies
- `socket.io`: Real-time communication
- `@arrirpc/server`: API framework
- Built-in `fetch`: HTTP requests to HybrIK API

## Error Handling

The system includes comprehensive error handling:
- Network errors when calling HybrIK API
- Socket.IO connection failures
- Timeout handling for admin panel responses (30 seconds)
- Graceful fallback to server-side calculations
- Detailed error logging

## Future Enhancements

1. **Database Integration**: Implement actual pose data storage
2. **Authentication**: Add user authentication for pose saving
3. **Multiple Admin Panels**: Support multiple connected admin panels with load balancing
4. **Pose Comparison**: Add functionality to compare poses against reference poses
5. **Real-time Streaming**: Support continuous pose detection for live sessions