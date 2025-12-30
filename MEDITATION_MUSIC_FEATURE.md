# Meditation Music Management Feature

## Overview
Added meditation music management functionality to the Vyom meditation screen, allowing users to upload, manage, and organize meditation music tracks.

## Features

### Backend (API)
- **Database Schema**: New `meditation_music` table with fields:
  - `id`: Unique identifier
  - `title`: Music track title
  - `description`: Optional description
  - `audioUrl`: Processed audio URL
  - `rawAudioUrl`: Original audio URL
  - `duration`: Track duration in seconds
  - `createdAt`, `updatedAt`: Timestamps

- **API Endpoints**:
  - `GET /meditation/get-meditation-music` - Retrieve all music tracks
  - `POST /meditation/create-meditation-music` - Create new music track
  - `DELETE /meditation/delete-meditation-music` - Delete music track
  - `POST /media/upload` - Upload audio files (existing endpoint)

### Frontend (Flutter)
- **Music Management UI**: 
  - Music library icon in meditation screen header
  - Full-screen overlay for music management
  - Upload button for adding new tracks
  - List view of existing tracks with category icons
  - Delete functionality with confirmation dialog

- **Upload Flow**:
  1. Name input dialog for track details (title, description)
  2. File picker for audio files
  3. Upload to backend media server
  4. Save track metadata to database

## Technical Implementation

### Database Migration
```bash
pnpm run db:push
```

### API Client Generation
The arri framework automatically generates typed client code for Flutter:
- `ArriClient.meditation.get_meditation_music()`
- `ArriClient.meditation.create_meditation_music()`
- `ArriClient.meditation.delete_meditation_music()`

### File Structure
```
backend/src/procedures/meditation/
├── get_meditation_music.rpc.ts
├── create_meditation_music.rpc.ts
└── delete_meditation_music.rpc.ts

database/schema/
└── meditation_music.ts

frontend/lib/screens/
└── meditation_screen.dart (updated)
```

## Usage

1. **Access Music Manager**: Go to Admin Panel → Meditation tab
2. **Add Music**: Click "Add Music" button
3. **Enter Details**: Fill in music name and optional description
4. **Select File**: Choose audio file from device
5. **Manage Tracks**: View all tracks with duration and total library stats
6. **Delete Tracks**: Tap delete icon and confirm removal

## Sample Data
The seed file includes sample meditation tracks:
- Ocean Waves (10 min)
- Forest Ambience (15 min)
- Night Rain (30 min)

## Dependencies
- `file_picker`: For audio file selection
- `http`: For multipart file uploads
- `arri_client`: For typed API calls

## Future Enhancements
- Audio playback integration
- Playlist creation
- Favorite tracks
- Music streaming from external sources
- Audio waveform visualization