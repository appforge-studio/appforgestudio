# Pose Detection Integration - Admin Panel

This document describes the pose detection functionality integrated into the vyom-main admin panel.

## Overview

The admin panel now includes pose detection capabilities that communicate with the vyom-main backend via Socket.IO for real-time bone rotation calculations.

## Features Implemented

### 1. **Debug Pose Screen with Full 3D Visualization**
- Real-time Socket.IO connection to backend server (port 5001)
- HybrIK API pose detection integration
- **Full 3D pose visualization** using three_dart and OpenGL
- **Interactive 3D model** with bone rotation display
- **Real-time pose application** to 3D avatar
- Status monitoring and error handling
- Admin panel identification for server communication

### 2. **Advanced Pose Processing**
- **HybrIK to BlazePose mapping** using proper joint mappings
- **Face landmark estimation** from head position
- **Hand landmark interpolation** from wrist positions
- **Coordinate system conversion** (meters to centimeters, axis flipping)
- **33-point BlazePose format** output for 3D model compatibility

### 3. **3D Rendering System**
- **OpenGL-based rendering** using flutter_gl
- **Three.dart 3D engine** for pose visualization
- **Real-time bone rotation calculations** and display
- **Interactive 3D scene** with grid and axes helpers
- **Bone rotation overlay** showing live rotation values
- **Observable bone highlighting** system

### 4. **Yoga Management Integration**
- Enhanced yoga management screen with pose detection section
- Dedicated pose detection launch capability
- Seamless navigation to full 3D pose detection screen

### 5. **Services & Controllers**
- **PoseService**: HTTP client for backend API communication
- **SocketClientService**: Socket.IO client for real-time communication
- **PoseController**: Advanced state management with 3D integration
- **OpenPoseEditor**: Full 3D pose visualization component

### 6. **Models & Mappings**
- **Observable**: Model for bone observation configuration
- **HybrIK Joint Mapping**: 29-joint SMPL format support
- **BlazePose Mapping**: 33-landmark format conversion
- **Coordinate System Handling**: Proper 3D space transformations

## Architecture

```
Admin Panel (Flutter)
├── Debug Pose Screen (Full 3D Visualization)
│   ├── OpenPoseEditor (3D Scene Management)
│   ├── ThreeDartRenderer (OpenGL Rendering)
│   └── BodyEditor (3D Model Control)
├── Pose Controller (Advanced State Management)
├── Socket Client Service ←→ Socket.IO (Port 5001) ←→ Backend Server
└── Pose Service ←→ HTTP API (Port 3000) ←→ Backend Server

3D Rendering Pipeline:
HybrIK API → Landmarks → BlazePose Mapping → 3D Model → OpenGL → Display
```

## API Endpoints Used

- `GET /yoga/detect-pose` - Basic pose detection
- `GET /yoga/detect-pose-with-rotations` - Pose detection with bone rotations
- `GET /yoga/socket-status` - Socket server status
- `POST /yoga/initialize-socket-server` - Initialize socket server
- `POST /yoga/save-pose` - Save pose data

## Socket.IO Events

### Admin Panel → Backend
- `identify_admin` - Identify as admin panel
- `bone_rotations_response` - Send calculated bone rotations

### Backend → Admin Panel
- `admin_identified` - Confirmation of admin identification
- `calculate_bone_rotations` - Request bone rotation calculations

## Usage

1. **Start the backend server**: `pnpm run backend`
2. **Launch admin panel**: `flutter run` in admin_pannel directory
3. **Navigate to Yoga tab**
4. **Click "Pose Detection" or "Launch Pose Detection"**
5. **Test socket connection and pose detection**

## Current Status

✅ **Fully Implemented**: 
- Socket.IO communication with backend
- HTTP API integration for pose detection
- **Full 3D visualization with OpenGL rendering**
- **Real-time pose application to 3D avatar**
- **HybrIK to BlazePose landmark mapping**
- **Interactive 3D scene with bone rotation display**
- UI navigation and status monitoring

🔄 **Advanced Features**: 
- Unity-based bone rotation calculations (currently using server fallback)
- Pose comparison and accuracy metrics
- Session recording and playback

## Dependencies Added

```yaml
dependencies:
  socket_io_client: ^2.0.3+1  # Socket.IO client
  three_dart:                 # 3D rendering engine
    path: local_plugins/three_dart/
  flutter_gl:                 # OpenGL integration
    path: local_plugins/flutter_gl/
```

## File Structure

```
lib/
├── controllers/
│   └── pose_controller.dart (Enhanced with 3D integration)
├── models/
│   └── observable.dart
├── openpose/ (Full 3D Visualization System)
│   ├── body.dart (3D body model management)
│   ├── defines.dart (Joint mappings and constants)
│   ├── editor.dart (3D scene editor)
│   ├── models.dart (3D model definitions)
│   ├── openpose_editor.dart (Main 3D pose editor)
│   └── three_dart_renderer.dart (OpenGL renderer)
├── screens/
│   ├── debug_pose_screen.dart (Full 3D visualization)
│   └── yoga_management_screen.dart (Enhanced with pose section)
├── services/
│   ├── pose_service.dart
│   └── socket_client_service.dart
└── globals.dart
```

## Testing

1. **Install Dependencies**: `flutter pub get` in admin_pannel directory
2. Ensure backend server is running with pose detection endpoints
3. Launch admin panel and navigate to Yoga section
4. Click "Launch Pose Detection" to open full 3D debug screen
5. **Test 3D Visualization**: Verify 3D model loads and displays correctly
6. **Test Socket Connection**: Use "Test Socket" button to verify connectivity
7. **Test Pose Detection**: Use "HybrIK Pose" button to detect and apply pose to 3D model
8. **Test Rotation Comparison**: Use "Test Rotations" to compare server vs client calculations
9. **Monitor 3D Display**: Verify bone rotations update in real-time on 3D model
10. **Check Rotation Overlay**: Verify bone rotation values display correctly

The integration now provides a complete 3D pose detection and visualization system with real-time pose application to an interactive 3D avatar, matching the functionality of the original vyom admin panel.