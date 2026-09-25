# API Documentation

**Zikire Kdusan (StreamHub) - REST API Reference**

This document provides comprehensive documentation for the Zikire Kdusan REST API, organized by functional domain.

---

## Table of Contents

1. [API Overview](#api-overview)
2. [Authentication & Authorization](#authentication--authorization)
3. [Users & Profiles](#users--profiles)
4. [Videos](#videos)
5. [Video Channels](#video-channels)
6. [Video Playlists](#video-playlists)
7. [Live Streaming](#live-streaming)
8. [Groups](#groups)
9. [Channels (Group Channels)](#channels-group-channels)
10. [Messaging](#messaging)
11. [Social Features](#social-features)
12. [Ethiopian Calendar](#ethiopian-calendar)
13. [Discovery & Search](#discovery--search)
14. [Notifications](#notifications)
15. [Admin & Moderation](#admin--moderation)
16. [Error Handling](#error-handling)
17. [Rate Limiting](#rate-limiting)

---

## API Overview

### Base URL

**Production**: `https://api.zkirekdusan.com/v1`  
**Development**: `http://localhost:3000`

### API Versioning

Current version: **v1**

All endpoints are prefixed with `/v1` (or no prefix if v1 is default).

### Authentication

Most endpoints require authentication via **JWT Bearer token**:

```http
Authorization: Bearer <access_token>
```

Endpoints marked with 🔓 are **public** and don't require authentication.

### Request Format

- **Content-Type**: `application/json` (default)
- **Content-Type**: `multipart/form-data` (for file uploads)

### Response Format

**Success Response**:
```json
{
  "success": true,
  "data": { ... },
  "message": "Operation successful",
  "timestamp": "2026-09-25T10:30:00Z"
}
```

**Error Response**:
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": [ ... ]
  },
  "timestamp": "2026-09-25T10:30:00Z"
}
```

### Pagination

**Query Parameters**:
- `page` - Page number (1-indexed)
- `limit` - Items per page (default: 20, max: 100)

**Paginated Response**:
```json
{
  "data": [ ... ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 150,
    "totalPages": 8
  }
}
```

**Cursor-based Pagination** (for large datasets):
```json
{
  "data": [ ... ],
  "pagination": {
    "nextCursor": "abc123xyz",
    "hasMore": true,
    "limit": 20
  }
}
```

---

## Authentication & Authorization

### Register New Account

**Endpoint**: `POST /auth/register` 🔓

**Description**: Register a new user account.

**Rate Limit**: 5 requests per minute

**Request Body**:
```json
{
  "username": "johndoe",
  "email": "john@example.com",
  "password": "SecurePass123!",
  "displayName": "John Doe",
  "phoneNumber": "+1234567890"
}
```

**Validation**:
- `username` - Required, 3-30 characters, alphanumeric + underscore/hyphen
- `email` - Required, valid email format
- `password` - Required, minimum 8 characters
- `displayName` - Optional
- `phoneNumber` - Optional

**Response** (201 Created):
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "user_123",
      "username": "johndoe",
      "email": "john@example.com",
      "displayName": "John Doe",
      "role": "USER"
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
    "expiresIn": 900
  }
}
```

**Errors**:
- `400` - Validation error (username/email already exists)
- `429` - Rate limit exceeded

---

### Login

**Endpoint**: `POST /auth/login` 🔓

**Description**: Authenticate user and obtain JWT tokens.

**Rate Limit**: 5 requests per minute

**Request Body**:
```json
{
  "usernameOrEmail": "johndoe",
  "password": "SecurePass123!"
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "user_123",
      "username": "johndoe",
      "email": "john@example.com",
      "displayName": "John Doe",
      "role": "USER"
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
    "expiresIn": 900
  }
}
```

**Errors**:
- `401` - Invalid credentials
- `403` - Account locked (too many failed attempts)
- `429` - Rate limit exceeded

**Brute Force Protection**:
- After 5 failed attempts, account is locked for 15 minutes
- Lockout applies per user account, not per IP

---

### Refresh Token

**Endpoint**: `POST /auth/refresh` 🔓

**Description**: Obtain new access token using refresh token.

**Rate Limit**: 5 requests per minute

**Request Body**:
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "expiresIn": 900
  }
}
```

**Errors**:
- `401` - Invalid or expired refresh token

**Token Expiry**:
- Access Token: 15 minutes
- Refresh Token: 7 days

---

### Logout

**Endpoint**: `POST /auth/logout` 🔒

**Description**: Revoke refresh tokens and logout.

**Headers**: `Authorization: Bearer <access_token>`

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Logout successful"
}
```

---

## Users & Profiles

### Get Current User

**Endpoint**: `GET /users/me` 🔒

**Description**: Get authenticated user's profile.

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "id": "user_123",
    "username": "johndoe",
    "email": "john@example.com",
    "displayName": "John Doe",
    "bio": "Video creator and tech enthusiast",
    "avatarUrl": "https://res.cloudinary.com/.../avatar.jpg",
    "coverImageUrl": "https://res.cloudinary.com/.../cover.jpg",
    "role": "USER",
    "createdAt": "2026-01-15T10:00:00Z",
    "profile": {
      "birthDate": "1995-05-20",
      "location": "New York, USA",
      "website": "https://johndoe.com"
    }
  }
}
```

---

### Get User by Username

**Endpoint**: `GET /users/:username` 🔓

**Description**: Get public user profile by username.

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "id": "user_123",
    "username": "johndoe",
    "displayName": "John Doe",
    "bio": "Video creator and tech enthusiast",
    "avatarUrl": "https://res.cloudinary.com/.../avatar.jpg",
    "coverImageUrl": "https://res.cloudinary.com/.../cover.jpg",
    "createdAt": "2026-01-15T10:00:00Z",
    "stats": {
      "followers": 1523,
      "following": 342,
      "videoCount": 87
    }
  }
}
```

---

### Update Profile

**Endpoint**: `PATCH /users/me` 🔒

**Description**: Update authenticated user's profile.

**Request Body**:
```json
{
  "displayName": "John D.",
  "bio": "Content creator | Tech reviewer",
  "location": "San Francisco, CA",
  "website": "https://newwebsite.com"
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "id": "user_123",
    "username": "johndoe",
    "displayName": "John D.",
    "bio": "Content creator | Tech reviewer"
  }
}
```

---

### Upload Avatar

**Endpoint**: `POST /users/me/avatar` 🔒

**Description**: Upload profile avatar image.

**Content-Type**: `multipart/form-data`

**Request Body**:
```
avatar: [image file]
```

**Validation**:
- File types: JPG, PNG, HEIC, WebP
- Max size: 5 MB
- Recommended: 400x400px or larger (square)

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "avatarUrl": "https://res.cloudinary.com/.../avatar.jpg"
  }
}
```

---

### Upload Cover Image

**Endpoint**: `POST /users/me/cover` 🔒

**Description**: Upload profile cover/banner image.

**Content-Type**: `multipart/form-data`

**Request Body**:
```
cover: [image file]
```

**Validation**:
- File types: JPG, PNG, HEIC, WebP
- Max size: 10 MB
- Recommended: 1500x500px (3:1 ratio)

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "coverImageUrl": "https://res.cloudinary.com/.../cover.jpg"
  }
}
```

---

### Follow User

**Endpoint**: `POST /users/:userId/follow` 🔒

**Description**: Follow a user.

**Response** (200 OK):
```json
{
  "success": true,
  "message": "User followed successfully"
}
```

---

### Unfollow User

**Endpoint**: `DELETE /users/:userId/follow` 🔒

**Description**: Unfollow a user.

**Response** (200 OK):
```json
{
  "success": true,
  "message": "User unfollowed successfully"
}
```

---

### Get Followers

**Endpoint**: `GET /users/:userId/followers` 🔓

**Description**: Get list of user's followers.

**Query Parameters**:
- `page` - Page number
- `limit` - Items per page

**Response** (200 OK):
```json
{
  "success": true,
  "data": [
    {
      "id": "user_456",
      "username": "janedoe",
      "displayName": "Jane Doe",
      "avatarUrl": "https://...",
      "followedAt": "2026-08-10T14:30:00Z"
    }
  ],
  "pagination": { ... }
}
```

---

### Get Following

**Endpoint**: `GET /users/:userId/following` 🔓

**Description**: Get list of users that this user follows.

**Query Parameters**:
- `page` - Page number
- `limit` - Items per page

**Response**: Same format as Get Followers

---

## Videos

### Initiate Video Upload

**Endpoint**: `POST /videos` 🔒

**Description**: Create video metadata and prepare for upload.

**Required Permission**: `create:video`

**Request Body**:
```json
{
  "title": "My Awesome Video",
  "description": "A description of the video content",
  "tags": ["tech", "tutorial"],
  "categoryId": "category_123",
  "visibility": "PUBLIC",
  "videoChannelId": "channel_123"
}
```

**Fields**:
- `title` - Required, 1-200 characters
- `description` - Optional, up to 5000 characters
- `tags` - Optional array of strings
- `categoryId` - Optional
- `visibility` - `PUBLIC`, `UNLISTED`, or `PRIVATE` (default: `PUBLIC`)
- `videoChannelId` - Required if user has channels

**Response** (201 Created):
```json
{
  "success": true,
  "data": {
    "id": "video_123",
    "title": "My Awesome Video",
    "slug": "my-awesome-video-abc123",
    "status": "DRAFT",
    "uploadUrl": "https://upload.example.com/...",
    "createdAt": "2026-09-25T10:30:00Z"
  }
}
```

---

### Upload Video File

**Endpoint**: `POST /videos/:videoId/upload` 🔒

**Description**: Upload video file for processing.

**Content-Type**: `multipart/form-data`

**Request Body**:
```
video: [video file]
```

**Validation**:
- File types: MP4, MOV, AVI, MKV, WebM
- Max size: 500 MB (configurable)
- Codecs: H.264, H.265, VP8, VP9

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "id": "video_123",
    "status": "PROCESSING",
    "message": "Video uploaded successfully. Processing in progress."
  }
}
```

**Processing Steps**:
1. Upload to Cloudinary
2. Transcode to HLS (adaptive bitrate)
3. Generate thumbnail
4. Extract metadata (duration, resolution)
5. Update video status to `READY`

---

### Upload Custom Thumbnail

**Endpoint**: `POST /videos/:videoId/thumbnail` 🔒

**Description**: Upload custom thumbnail image for video.

**Content-Type**: `multipart/form-data`

**Request Body**:
```
thumbnail: [image file]
```

**Validation**:
- File types: JPG, PNG
- Max size: 5 MB
- Recommended: 1280x720px (16:9 ratio)

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "thumbnailUrl": "https://res.cloudinary.com/.../thumbnail.jpg"
  }
}
```

---

### Get Video by ID

**Endpoint**: `GET /videos/:videoId` 🔓

**Description**: Get video details by ID or slug.

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "id": "video_123",
    "title": "My Awesome Video",
    "slug": "my-awesome-video-abc123",
    "description": "A description of the video content",
    "url": "https://res.cloudinary.com/.../video.m3u8",
    "thumbnailUrl": "https://res.cloudinary.com/.../thumbnail.jpg",
    "duration": 320,
    "viewCount": 1523,
    "likeCount": 142,
    "dislikeCount": 8,
    "commentCount": 34,
    "visibility": "PUBLIC",
    "status": "READY",
    "createdAt": "2026-09-20T10:00:00Z",
    "publishedAt": "2026-09-20T12:00:00Z",
    "user": {
      "id": "user_123",
      "username": "johndoe",
      "displayName": "John Doe",
      "avatarUrl": "https://..."
    },
    "videoChannel": {
      "id": "channel_123",
      "name": "Tech Reviews",
      "subscriberCount": 5420
    }
  }
}
```

---

### List Videos

**Endpoint**: `GET /videos` 🔓

**Description**: Get paginated list of public videos.

**Query Parameters**:
- `page` - Page number (default: 1)
- `limit` - Items per page (default: 20, max: 100)
- `sort` - Sort order: `latest`, `popular`, `trending` (default: `latest`)
- `categoryId` - Filter by category
- `userId` - Filter by uploader
- `channelId` - Filter by channel

**Response** (200 OK):
```json
{
  "success": true,
  "data": [
    {
      "id": "video_123",
      "title": "My Awesome Video",
      "thumbnailUrl": "https://...",
      "duration": 320,
      "viewCount": 1523,
      "createdAt": "2026-09-20T10:00:00Z",
      "user": {
        "username": "johndoe",
        "avatarUrl": "https://..."
      }
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 150,
    "totalPages": 8
  }
}
```

---

### Update Video

**Endpoint**: `PATCH /videos/:videoId` 🔒

**Description**: Update video metadata (owner only).

**Required Permission**: Must be video owner or admin

**Request Body**:
```json
{
  "title": "Updated Video Title",
  "description": "Updated description",
  "tags": ["tech", "tutorial", "2026"],
  "visibility": "UNLISTED"
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "id": "video_123",
    "title": "Updated Video Title",
    "description": "Updated description",
    "visibility": "UNLISTED"
  }
}
```

---

### Publish Video

**Endpoint**: `POST /videos/:videoId/publish` 🔒

**Description**: Publish a draft video (makes it visible).

**Required Permission**: Must be video owner

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "id": "video_123",
    "status": "PUBLISHED",
    "publishedAt": "2026-09-25T10:30:00Z"
  }
}
```

---

### Delete Video

**Endpoint**: `DELETE /videos/:videoId` 🔒

**Description**: Delete a video (owner only).

**Required Permission**: Must be video owner or admin

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Video deleted successfully"
}
```

---

### Like Video

**Endpoint**: `POST /videos/:videoId/like` 🔒

**Description**: Like a video.

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Video liked"
}
```

---

### Dislike Video

**Endpoint**: `POST /videos/:videoId/dislike` 🔒

**Description**: Dislike a video.

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Video disliked"
}
```

---

### Remove Like/Dislike

**Endpoint**: `DELETE /videos/:videoId/like` 🔒

**Description**: Remove like or dislike from video.

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Like/dislike removed"
}
```

---

### Get Like Status

**Endpoint**: `GET /videos/:videoId/like-status` 🔒

**Description**: Check if current user liked/disliked video.

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "liked": true,
    "disliked": false
  }
}
```

---

### Update Watch Progress

**Endpoint**: `POST /videos/:videoId/progress` 🔒

**Description**: Save video watch progress for resume feature.

**Request Body**:
```json
{
  "progressSeconds": 145
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Progress saved"
}
```

---

### Get Watch Progress

**Endpoint**: `GET /videos/:videoId/progress` 🔒

**Description**: Get saved watch progress for video.

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "videoId": "video_123",
    "progressSeconds": 145,
    "totalDuration": 320,
    "percentComplete": 45.3,
    "updatedAt": "2026-09-25T10:30:00Z"
  }
}
```

---

### Bookmark Video

**Endpoint**: `POST /videos/:videoId/bookmark` 🔒

**Description**: Save video to bookmarks.

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Video bookmarked"
}
```

---

### Remove Bookmark

**Endpoint**: `DELETE /videos/:videoId/bookmark` 🔒

**Description**: Remove video from bookmarks.

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Bookmark removed"
}
```

---

### Get Bookmarked Videos

**Endpoint**: `GET /videos/bookmarks` 🔒

**Description**: Get user's bookmarked videos.

**Query Parameters**:
- `page` - Page number
- `limit` - Items per page

**Response** (200 OK):
```json
{
  "success": true,
  "data": [
    {
      "id": "video_123",
      "title": "My Awesome Video",
      "thumbnailUrl": "https://...",
      "bookmarkedAt": "2026-09-23T14:20:00Z"
    }
  ],
  "pagination": { ... }
}
```

---

### Get Recommended Videos

**Endpoint**: `GET /videos/recommended` 🔒

**Description**: Get personalized video recommendations.

**Query Parameters**:
- `limit` - Number of recommendations (default: 20)

**Response** (200 OK):
```json
{
  "success": true,
  "data": [
    {
      "id": "video_456",
      "title": "Recommended Video",
      "thumbnailUrl": "https://...",
      "reason": "Based on your watch history"
    }
  ]
}
```

---

### Get Watch History

**Endpoint**: `GET /videos/history` 🔒

**Description**: Get user's video watch history.

**Query Parameters**:
- `page` - Page number
- `limit` - Items per page

**Response** (200 OK):
```json
{
  "success": true,
  "data": [
    {
      "video": {
        "id": "video_123",
        "title": "My Awesome Video",
        "thumbnailUrl": "https://..."
      },
      "watchedAt": "2026-09-25T10:30:00Z",
      "progressSeconds": 145
    }
  ],
  "pagination": { ... }
}
```

---

### Clear Watch History

**Endpoint**: `DELETE /videos/history` 🔒

**Description**: Clear all watch history for current user.

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Watch history cleared"
}
```

---

## Video Channels

### Create Channel

**Endpoint**: `POST /video-channels` 🔒

**Description**: Create a new video channel.

**Required Permission**: `create:video-channel`

**Request Body**:
```json
{
  "name": "Tech Reviews",
  "handle": "tech-reviews",
  "description": "In-depth tech product reviews",
  "category": "Technology"
}
```

**Response** (201 Created):
```json
{
  "success": true,
  "data": {
    "id": "channel_123",
    "name": "Tech Reviews",
    "handle": "tech-reviews",
    "description": "In-depth tech product reviews",
    "subscriberCount": 0,
    "videoCount": 0,
    "createdAt": "2026-09-25T10:30:00Z"
  }
}
```

---

### Get Channel

**Endpoint**: `GET /video-channels/:channelId` 🔓

**Description**: Get channel details.

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "id": "channel_123",
    "name": "Tech Reviews",
    "handle": "tech-reviews",
    "description": "In-depth tech product reviews",
    "avatarUrl": "https://...",
    "bannerUrl": "https://...",
    "subscriberCount": 5420,
    "videoCount": 87,
    "createdAt": "2026-01-15T10:00:00Z",
    "owner": {
      "id": "user_123",
      "username": "johndoe"
    }
  }
}
```

---

### Subscribe to Channel

**Endpoint**: `POST /video-channels/:channelId/subscribe` 🔒

**Description**: Subscribe to a channel.

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Subscribed to channel"
}
```

---

### Unsubscribe from Channel

**Endpoint**: `DELETE /video-channels/:channelId/subscribe` 🔒

**Description**: Unsubscribe from a channel.

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Unsubscribed from channel"
}
```

---

### Get Channel Videos

**Endpoint**: `GET /video-channels/:channelId/videos` 🔓

**Description**: Get videos from a specific channel.

**Query Parameters**:
- `page` - Page number
- `limit` - Items per page
- `sort` - `latest`, `popular`, `oldest`

**Response**: Same format as List Videos

---

## Video Playlists

### Create Playlist

**Endpoint**: `POST /video-playlists` 🔒

**Description**: Create a new video playlist.

**Request Body**:
```json
{
  "title": "My Favorite Tech Videos",
  "description": "A collection of my favorite tech content",
  "visibility": "PUBLIC"
}
```

**Response** (201 Created):
```json
{
  "success": true,
  "data": {
    "id": "playlist_123",
    "title": "My Favorite Tech Videos",
    "description": "A collection of my favorite tech content",
    "visibility": "PUBLIC",
    "videoCount": 0,
    "createdAt": "2026-09-25T10:30:00Z"
  }
}
```

---

### Add Video to Playlist

**Endpoint**: `POST /video-playlists/:playlistId/videos` 🔒

**Description**: Add a video to playlist.

**Request Body**:
```json
{
  "videoId": "video_123"
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Video added to playlist"
}
```

---

### Remove Video from Playlist

**Endpoint**: `DELETE /video-playlists/:playlistId/videos/:videoId` 🔒

**Description**: Remove a video from playlist.

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Video removed from playlist"
}
```

---

### Get Playlist Videos

**Endpoint**: `GET /video-playlists/:playlistId/videos` 🔓

**Description**: Get all videos in a playlist.

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "playlist": {
      "id": "playlist_123",
      "title": "My Favorite Tech Videos",
      "videoCount": 15
    },
    "videos": [
      {
        "id": "video_123",
        "title": "My Awesome Video",
        "position": 1,
        "addedAt": "2026-09-20T10:00:00Z"
      }
    ]
  }
}
```

---

## Live Streaming

### Create Live Stream

**Endpoint**: `POST /live-streams` 🔒

**Description**: Create a new live stream session.

**Required Permission**: `create:livestream`

**Request Body**:
```json
{
  "title": "Live Q&A Session",
  "description": "Ask me anything about tech!",
  "groupId": "group_123",
  "visibility": "PUBLIC"
}
```

**Response** (201 Created):
```json
{
  "success": true,
  "data": {
    "id": "stream_123",
    "title": "Live Q&A Session",
    "status": "PENDING",
    "rtmpUrl": "rtmp://rtmp.cloudinary.com/live",
    "streamKey": "abc123xyz789",
    "hlsUrl": "https://res.cloudinary.com/.../stream.m3u8",
    "createdAt": "2026-09-25T10:30:00Z"
  }
}
```

**RTMP Streaming**:
- Broadcaster uses `rtmpUrl` + `streamKey` to stream via RTMP
- Viewers watch via `hlsUrl` (HLS adaptive streaming)

---

### Start Live Stream

**Endpoint**: `POST /live-streams/:streamId/start` 🔒

**Description**: Mark stream as started (called when RTMP stream is live).

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "id": "stream_123",
    "status": "LIVE",
    "startedAt": "2026-09-25T10:35:00Z"
  }
}
```

**Notification Delay**:
- System waits 2 minutes before sending "went live" notifications
- Prevents spam from test streams

---

### End Live Stream

**Endpoint**: `POST /live-streams/:streamId/end` 🔒

**Description**: End the live stream.

**Required Permission**: Must be stream owner

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "id": "stream_123",
    "status": "ENDED",
    "endedAt": "2026-09-25T11:30:00Z",
    "vodUrl": "https://res.cloudinary.com/.../recording.m3u8"
  }
}
```

**Recording**:
- Stream automatically recorded by Cloudinary
- VOD (Video on Demand) available after stream ends

---

### Get Live Stream

**Endpoint**: `GET /live-streams/:streamId` 🔓

**Description**: Get live stream details.

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "id": "stream_123",
    "title": "Live Q&A Session",
    "description": "Ask me anything about tech!",
    "status": "LIVE",
    "hlsUrl": "https://res.cloudinary.com/.../stream.m3u8",
    "thumbnailUrl": "https://...",
    "viewerCount": 342,
    "likeCount": 87,
    "startedAt": "2026-09-25T10:35:00Z",
    "user": {
      "id": "user_123",
      "username": "johndoe",
      "displayName": "John Doe",
      "avatarUrl": "https://..."
    }
  }
}
```

---

### Get Active Live Streams

**Endpoint**: `GET /live-streams/active` 🔓

**Description**: Get all currently live streams.

**Query Parameters**:
- `page` - Page number
- `limit` - Items per page

**Response** (200 OK):
```json
{
  "success": true,
  "data": [
    {
      "id": "stream_123",
      "title": "Live Q&A Session",
      "thumbnailUrl": "https://...",
      "viewerCount": 342,
      "user": {
        "username": "johndoe",
        "avatarUrl": "https://..."
      }
    }
  ],
  "pagination": { ... }
}
```

---

### Join Stream (WebSocket)

**WebSocket Event**: `join_stream`

**Description**: Join a live stream room for real-time features.

**Payload**:
```json
{
  "streamId": "stream_123"
}
```

**Server Response**: `viewer_count` event with updated count

**Note**: See REALTIME_AND_LIVE.md for complete WebSocket documentation

---

## Groups

### Create Group

**Endpoint**: `POST /groups` 🔒

**Description**: Create a new group/community.

**Required Permission**: `create:group`

**Request Body**:
```json
{
  "name": "Tech Enthusiasts",
  "handle": "tech-enthusiasts",
  "description": "A community for tech lovers",
  "visibility": "PUBLIC",
  "type": "OPEN"
}
```

**Fields**:
- `name` - Required, 3-100 characters
- `handle` - Required, unique, URL-safe
- `description` - Optional
- `visibility` - `PUBLIC` or `PRIVATE`
- `type` - `OPEN` (anyone can join) or `CLOSED` (requires approval)

**Response** (201 Created):
```json
{
  "success": true,
  "data": {
    "id": "group_123",
    "name": "Tech Enthusiasts",
    "handle": "tech-enthusiasts",
    "description": "A community for tech lovers",
    "visibility": "PUBLIC",
    "type": "OPEN",
    "memberCount": 1,
    "createdAt": "2026-09-25T10:30:00Z"
  }
}
```

---

### Get Group

**Endpoint**: `GET /groups/:groupId` 🔓

**Description**: Get group details.

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "id": "group_123",
    "name": "Tech Enthusiasts",
    "handle": "tech-enthusiasts",
    "description": "A community for tech lovers",
    "avatarUrl": "https://...",
    "coverImageUrl": "https://...",
    "visibility": "PUBLIC",
    "type": "OPEN",
    "memberCount": 1523,
    "createdAt": "2026-01-15T10:00:00Z",
    "currentUserRole": "MEMBER"
  }
}
```

---

### List Groups

**Endpoint**: `GET /groups` 🔓

**Description**: List all public groups.

**Query Parameters**:
- `page` - Page number
- `limit` - Items per page
- `sort` - `popular`, `latest`, `name`
- `search` - Search query

**Response** (200 OK):
```json
{
  "success": true,
  "data": [
    {
      "id": "group_123",
      "name": "Tech Enthusiasts",
      "handle": "tech-enthusiasts",
      "memberCount": 1523,
      "avatarUrl": "https://..."
    }
  ],
  "pagination": { ... }
}
```

---

### Join Group

**Endpoint**: `POST /groups/:groupId/join` 🔒

**Description**: Join a group or request to join.

**Response** (200 OK):

For `OPEN` groups:
```json
{
  "success": true,
  "message": "Joined group successfully",
  "data": {
    "role": "MEMBER"
  }
}
```

For `CLOSED` groups:
```json
{
  "success": true,
  "message": "Join request sent. Awaiting approval.",
  "data": {
    "status": "PENDING"
  }
}
```

---

### Leave Group

**Endpoint**: `POST /groups/:groupId/leave` 🔒

**Description**: Leave a group.

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Left group successfully"
}
```

---

### Get Group Members

**Endpoint**: `GET /groups/:groupId/members` 🔒

**Description**: Get list of group members.

**Required Permission**: Must be group member

**Query Parameters**:
- `page` - Page number
- `limit` - Items per page
- `role` - Filter by role: `GROUP_ADMIN`, `MODERATOR`, `MEMBER`, `GUEST`

**Response** (200 OK):
```json
{
  "success": true,
  "data": [
    {
      "user": {
        "id": "user_123",
        "username": "johndoe",
        "displayName": "John Doe",
        "avatarUrl": "https://..."
      },
      "role": "MEMBER",
      "joinedAt": "2026-08-10T14:30:00Z"
    }
  ],
  "pagination": { ... }
}
```

---

### Update Member Role

**Endpoint**: `PATCH /groups/:groupId/members/:userId/role` 🔒

**Description**: Update a member's role in the group.

**Required Permission**: Must be GROUP_ADMIN

**Request Body**:
```json
{
  "role": "MODERATOR"
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Member role updated successfully"
}
```

---

### Remove Member

**Endpoint**: `DELETE /groups/:groupId/members/:userId` 🔒

**Description**: Remove a member from the group.

**Required Permission**: Must be GROUP_ADMIN or MODERATOR

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Member removed from group"
}
```

---

### Get Join Requests

**Endpoint**: `GET /groups/:groupId/join-requests` 🔒

**Description**: Get pending join requests for group.

**Required Permission**: Must be GROUP_ADMIN or MODERATOR

**Response** (200 OK):
```json
{
  "success": true,
  "data": [
    {
      "id": "request_123",
      "user": {
        "id": "user_456",
        "username": "janedoe",
        "avatarUrl": "https://..."
      },
      "status": "PENDING",
      "createdAt": "2026-09-24T10:00:00Z"
    }
  ]
}
```

---

### Approve Join Request

**Endpoint**: `POST /groups/:groupId/join-requests/:requestId/approve` 🔒

**Description**: Approve a join request.

**Required Permission**: Must be GROUP_ADMIN or MODERATOR

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Join request approved"
}
```

---

### Reject Join Request

**Endpoint**: `POST /groups/:groupId/join-requests/:requestId/reject` 🔒

**Description**: Reject a join request.

**Required Permission**: Must be GROUP_ADMIN or MODERATOR

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Join request rejected"
}
```

---

## Channels (Group Channels)

### Create Channel in Group

**Endpoint**: `POST /groups/:groupId/channels` 🔒

**Description**: Create a new channel within a group.

**Required Permission**: Must be GROUP_ADMIN

**Request Body**:
```json
{
  "name": "General Discussion",
  "description": "General chat for all members",
  "type": "TEXT"
}
```

**Response** (201 Created):
```json
{
  "success": true,
  "data": {
    "id": "channel_123",
    "name": "General Discussion",
    "description": "General chat for all members",
    "type": "TEXT",
    "groupId": "group_123",
    "createdAt": "2026-09-25T10:30:00Z"
  }
}
```

---

### Get Group Channels

**Endpoint**: `GET /groups/:groupId/channels` 🔒

**Description**: Get all channels in a group.

**Required Permission**: Must be group member

**Response** (200 OK):
```json
{
  "success": true,
  "data": [
    {
      "id": "channel_123",
      "name": "General Discussion",
      "type": "TEXT",
      "unreadCount": 5
    },
    {
      "id": "channel_456",
      "name": "Announcements",
      "type": "ANNOUNCEMENT",
      "unreadCount": 0
    }
  ]
}
```

---

## Messaging

### Get Conversations

**Endpoint**: `GET /conversations` 🔒

**Description**: Get list of user's conversations.

**Query Parameters**:
- `page` - Page number
- `limit` - Items per page

**Response** (200 OK):
```json
{
  "success": true,
  "data": [
    {
      "id": "conv_123",
      "type": "DIRECT",
      "participants": [
        {
          "id": "user_456",
          "username": "janedoe",
          "avatarUrl": "https://..."
        }
      ],
      "lastMessage": {
        "id": "msg_789",
        "content": "Hey, how are you?",
        "createdAt": "2026-09-25T10:30:00Z"
      },
      "unreadCount": 3,
      "updatedAt": "2026-09-25T10:30:00Z"
    }
  ],
  "pagination": { ... }
}
```

---

### Create Conversation

**Endpoint**: `POST /conversations` 🔒

**Description**: Create a new direct conversation.

**Request Body**:
```json
{
  "participantId": "user_456"
}
```

**Response** (201 Created):
```json
{
  "success": true,
  "data": {
    "id": "conv_123",
    "type": "DIRECT",
    "participants": [
      {
        "id": "user_456",
        "username": "janedoe"
      }
    ],
    "createdAt": "2026-09-25T10:30:00Z"
  }
}
```

---

### Get Conversation Messages

**Endpoint**: `GET /conversations/:conversationId/messages` 🔒

**Description**: Get messages from a conversation.

**Query Parameters**:
- `cursor` - Cursor for pagination (messageId)
- `limit` - Items per page (default: 50)

**Response** (200 OK):
```json
{
  "success": true,
  "data": [
    {
      "id": "msg_789",
      "conversationId": "conv_123",
      "senderId": "user_456",
      "content": "Hey, how are you?",
      "type": "TEXT",
      "createdAt": "2026-09-25T10:30:00Z",
      "sender": {
        "username": "janedoe",
        "avatarUrl": "https://..."
      }
    }
  ],
  "pagination": {
    "nextCursor": "msg_788",
    "hasMore": true
  }
}
```

---

### Send Message

**Endpoint**: `POST /conversations/:conversationId/messages` 🔒

**Description**: Send a message in a conversation.

**Request Body**:
```json
{
  "content": "Hey, how are you?",
  "type": "TEXT"
}
```

**Message Types**:
- `TEXT` - Text message
- `IMAGE` - Image attachment
- `VIDEO` - Video attachment
- `AUDIO` - Audio message
- `FILE` - File attachment

**Response** (201 Created):
```json
{
  "success": true,
  "data": {
    "id": "msg_789",
    "conversationId": "conv_123",
    "senderId": "user_123",
    "content": "Hey, how are you?",
    "type": "TEXT",
    "createdAt": "2026-09-25T10:30:00Z"
  }
}
```

**Note**: Real-time delivery via WebSocket (see REALTIME_AND_LIVE.md)

---

### Send Message with Media

**Endpoint**: `POST /conversations/:conversationId/messages/media` 🔒

**Description**: Send a message with media attachment.

**Content-Type**: `multipart/form-data`

**Request Body**:
```
media: [file]
caption: "Check this out!"
```

**Response** (201 Created):
```json
{
  "success": true,
  "data": {
    "id": "msg_790",
    "type": "IMAGE",
    "content": "Check this out!",
    "mediaUrl": "https://res.cloudinary.com/.../image.jpg",
    "createdAt": "2026-09-25T10:32:00Z"
  }
}
```

---

### Mark Messages as Read

**Endpoint**: `POST /conversations/:conversationId/read` 🔒

**Description**: Mark all messages in conversation as read.

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Messages marked as read"
}
```

---

### Delete Message

**Endpoint**: `DELETE /messages/:messageId` 🔒

**Description**: Delete a message (sender only).

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Message deleted"
}
```

---

## Social Features

### Create Post

**Endpoint**: `POST /posts` 🔒

**Description**: Create a new social post.

**Request Body**:
```json
{
  "content": "Just watched an amazing tech video!",
  "groupId": "group_123",
  "visibility": "PUBLIC"
}
```

**Fields**:
- `content` - Required, 1-5000 characters
- `groupId` - Optional, post in specific group
- `visibility` - `PUBLIC`, `FOLLOWERS`, `PRIVATE`

**Response** (201 Created):
```json
{
  "success": true,
  "data": {
    "id": "post_123",
    "content": "Just watched an amazing tech video!",
    "visibility": "PUBLIC",
    "likeCount": 0,
    "commentCount": 0,
    "createdAt": "2026-09-25T10:30:00Z",
    "user": {
      "username": "johndoe",
      "avatarUrl": "https://..."
    }
  }
}
```

---

### Create Post with Media

**Endpoint**: `POST /posts/media` 🔒

**Description**: Create post with image/video attachments.

**Content-Type**: `multipart/form-data`

**Request Body**:
```
content: "Check out this view!"
media: [file1, file2, ...]
visibility: "PUBLIC"
```

**Response**: Same as Create Post with `mediaUrls` array

---

### Get Feed

**Endpoint**: `GET /posts/feed` 🔒

**Description**: Get personalized feed of posts from followed users and groups.

**Query Parameters**:
- `page` - Page number
- `limit` - Items per page

**Response** (200 OK):
```json
{
  "success": true,
  "data": [
    {
      "id": "post_123",
      "content": "Just watched an amazing tech video!",
      "mediaUrls": ["https://..."],
      "likeCount": 42,
      "commentCount": 8,
      "createdAt": "2026-09-25T10:30:00Z",
      "user": {
        "username": "johndoe",
        "avatarUrl": "https://..."
      }
    }
  ],
  "pagination": { ... }
}
```

---

### Like Post

**Endpoint**: `POST /posts/:postId/like` 🔒

**Description**: Like a post.

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Post liked"
}
```

---

### Comment on Post

**Endpoint**: `POST /posts/:postId/comments` 🔒

**Description**: Add a comment to a post.

**Request Body**:
```json
{
  "content": "Great post!"
}
```

**Response** (201 Created):
```json
{
  "success": true,
  "data": {
    "id": "comment_123",
    "postId": "post_123",
    "content": "Great post!",
    "createdAt": "2026-09-25T10:35:00Z",
    "user": {
      "username": "janedoe"
    }
  }
}
```

---

### Create Story

**Endpoint**: `POST /stories` 🔒

**Description**: Create a new story (24-hour expiry).

**Content-Type**: `multipart/form-data`

**Request Body**:
```
media: [image or video file]
caption: "Having a great day!"
```

**Response** (201 Created):
```json
{
  "success": true,
  "data": {
    "id": "story_123",
    "mediaUrl": "https://res.cloudinary.com/.../story.jpg",
    "caption": "Having a great day!",
    "expiresAt": "2026-09-26T10:30:00Z",
    "createdAt": "2026-09-25T10:30:00Z"
  }
}
```

---

### Get Stories

**Endpoint**: `GET /stories` 🔒

**Description**: Get stories from followed users.

**Response** (200 OK):
```json
{
  "success": true,
  "data": [
    {
      "user": {
        "id": "user_456",
        "username": "janedoe",
        "avatarUrl": "https://..."
      },
      "stories": [
        {
          "id": "story_123",
          "mediaUrl": "https://...",
          "caption": "Having a great day!",
          "createdAt": "2026-09-25T10:30:00Z",
          "expiresAt": "2026-09-26T10:30:00Z"
        }
      ],
      "unseenCount": 2
    }
  ]
}
```

---

### Create Reel

**Endpoint**: `POST /reels` 🔒

**Description**: Create a short-form video (reel).

**Content-Type**: `multipart/form-data`

**Request Body**:
```
video: [video file]
caption: "Quick tech tip!"
tags: ["tech", "tips"]
```

**Response** (201 Created):
```json
{
  "success": true,
  "data": {
    "id": "reel_123",
    "videoUrl": "https://res.cloudinary.com/.../reel.mp4",
    "caption": "Quick tech tip!",
    "viewCount": 0,
    "likeCount": 0,
    "createdAt": "2026-09-25T10:30:00Z"
  }
}
```

---

### Get Reels Feed

**Endpoint**: `GET /reels` 🔓

**Description**: Get feed of reels.

**Query Parameters**:
- `page` - Page number
- `limit` - Items per page

**Response** (200 OK):
```json
{
  "success": true,
  "data": [
    {
      "id": "reel_123",
      "videoUrl": "https://...",
      "thumbnailUrl": "https://...",
      "caption": "Quick tech tip!",
      "viewCount": 342,
      "likeCount": 87,
      "user": {
        "username": "johndoe",
        "avatarUrl": "https://..."
      }
    }
  ],
  "pagination": { ... }
}
```

---

## Ethiopian Calendar

### Create Calendar Note

**Endpoint**: `POST /calendar/notes` 🔒

**Description**: Create a note on the Ethiopian calendar.

**Request Body**:
```json
{
  "title": "መስቀል በዓል",
  "content": "የመስቀል በዓል ቀን",
  "date": "2026-01-27",
  "calendarType": "ETHIOPIAN"
}
```

**Fields**:
- `title` - Required
- `content` - Optional, additional details
- `date` - Required, ISO date format
- `calendarType` - `ETHIOPIAN` or `GREGORIAN`

**Response** (201 Created):
```json
{
  "success": true,
  "data": {
    "id": "note_123",
    "title": "መስቀል በዓል",
    "content": "የመስቀል በዓል ቀን",
    "date": "2026-01-27",
    "calendarType": "ETHIOPIAN",
    "createdAt": "2026-09-25T10:30:00Z"
  }
}
```

---

### Get Calendar Notes

**Endpoint**: `GET /calendar/notes` 🔒

**Description**: Get user's calendar notes.

**Query Parameters**:
- `startDate` - Filter from date (ISO format)
- `endDate` - Filter to date (ISO format)
- `calendarType` - `ETHIOPIAN` or `GREGORIAN`

**Response** (200 OK):
```json
{
  "success": true,
  "data": [
    {
      "id": "note_123",
      "title": "መስቀል በዓል",
      "content": "የመስቀል በዓል ቀን",
      "date": "2026-01-27",
      "calendarType": "ETHIOPIAN",
      "reminders": [
        {
          "id": "reminder_123",
          "time": "09:00:00",
          "enabled": true
        }
      ]
    }
  ]
}
```

---

### Create Reminder

**Endpoint**: `POST /calendar/notes/:noteId/reminders` 🔒

**Description**: Add a reminder to a calendar note.

**Request Body**:
```json
{
  "time": "09:00:00",
  "recurring": false
}
```

**Response** (201 Created):
```json
{
  "success": true,
  "data": {
    "id": "reminder_123",
    "noteId": "note_123",
    "time": "09:00:00",
    "recurring": false,
    "enabled": true,
    "createdAt": "2026-09-25T10:30:00Z"
  }
}
```

**Note**: Reminders work offline (triggered by local device)

---

### Delete Calendar Note

**Endpoint**: `DELETE /calendar/notes/:noteId` 🔒

**Description**: Delete a calendar note and its reminders.

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Calendar note deleted"
}
```

---

## Discovery & Search

### Search

**Endpoint**: `GET /search` 🔓

**Description**: Global search across videos, users, groups, and posts.

**Query Parameters**:
- `q` - Search query (required)
- `type` - Filter by type: `videos`, `users`, `groups`, `posts` (optional)
- `page` - Page number
- `limit` - Items per page

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "videos": [
      {
        "id": "video_123",
        "title": "Tech Tutorial",
        "thumbnailUrl": "https://..."
      }
    ],
    "users": [
      {
        "id": "user_456",
        "username": "janedoe",
        "avatarUrl": "https://..."
      }
    ],
    "groups": [
      {
        "id": "group_789",
        "name": "Tech Enthusiasts",
        "memberCount": 1523
      }
    ]
  },
  "pagination": { ... }
}
```

---

### Get Trending Videos

**Endpoint**: `GET /trending/videos` 🔓

**Description**: Get trending videos.

**Query Parameters**:
- `limit` - Number of results (default: 20, max: 50)

**Response** (200 OK):
```json
{
  "success": true,
  "data": [
    {
      "id": "video_123",
      "title": "Trending Video",
      "thumbnailUrl": "https://...",
      "viewCount": 15234,
      "trendingScore": 95.3
    }
  ]
}
```

---

### Get Explore Content

**Endpoint**: `GET /explore` 🔓

**Description**: Get curated content for discovery.

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "trending": [ ... ],
    "recommended": [ ... ],
    "categories": [
      {
        "name": "Technology",
        "videos": [ ... ]
      }
    ]
  }
}
```

---

## Notifications

### Get Notifications

**Endpoint**: `GET /notifications` 🔒

**Description**: Get user's notifications.

**Query Parameters**:
- `page` - Page number
- `limit` - Items per page
- `unreadOnly` - Boolean, filter unread notifications

**Response** (200 OK):
```json
{
  "success": true,
  "data": [
    {
      "id": "notif_123",
      "type": "VIDEO_LIKE",
      "title": "New like on your video",
      "body": "johndoe liked your video 'Tech Tutorial'",
      "read": false,
      "createdAt": "2026-09-25T10:30:00Z",
      "data": {
        "videoId": "video_123",
        "userId": "user_456"
      }
    }
  ],
  "pagination": { ... }
}
```

**Notification Types**:
- `VIDEO_LIKE`, `VIDEO_COMMENT` - Video interactions
- `POST_LIKE`, `POST_COMMENT` - Post interactions
- `FOLLOW` - New follower
- `MESSAGE` - New message
- `GROUP_INVITE` - Group invitation
- `LIVE_START` - Followed user went live
- `MENTION` - Mentioned in post/comment

---

### Mark Notification as Read

**Endpoint**: `PATCH /notifications/:notificationId/read` 🔒

**Description**: Mark a notification as read.

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Notification marked as read"
}
```

---

### Mark All as Read

**Endpoint**: `POST /notifications/mark-all-read` 🔒

**Description**: Mark all notifications as read.

**Response** (200 OK):
```json
{
  "success": true,
  "message": "All notifications marked as read"
}
```

---

### Register Device Token (FCM)

**Endpoint**: `POST /notifications/device-tokens` 🔒

**Description**: Register device token for push notifications.

**Request Body**:
```json
{
  "token": "fcm_device_token_here",
  "platform": "ANDROID"
}
```

**Fields**:
- `token` - FCM device token
- `platform` - `ANDROID`, `IOS`, or `WEB`

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Device token registered"
}
```

---

### Update Notification Preferences

**Endpoint**: `PATCH /notifications/preferences` 🔒

**Description**: Update notification preferences.

**Request Body**:
```json
{
  "videoLikes": true,
  "comments": true,
  "follows": true,
  "messages": true,
  "liveStreams": true,
  "groupActivity": false
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "videoLikes": true,
    "comments": true,
    "follows": true,
    "messages": true,
    "liveStreams": true,
    "groupActivity": false
  }
}
```

---

## Admin & Moderation

### Get Reports

**Endpoint**: `GET /admin/reports` 🔒

**Description**: Get content reports for moderation.

**Required Role**: `ADMIN` or `MODERATOR`

**Query Parameters**:
- `status` - Filter by status: `PENDING`, `REVIEWED`, `RESOLVED`
- `type` - Filter by type: `VIDEO`, `POST`, `USER`, `COMMENT`
- `page` - Page number
- `limit` - Items per page

**Response** (200 OK):
```json
{
  "success": true,
  "data": [
    {
      "id": "report_123",
      "type": "VIDEO",
      "reason": "INAPPROPRIATE_CONTENT",
      "description": "Contains offensive language",
      "status": "PENDING",
      "reporter": {
        "username": "reporter123"
      },
      "reportedContent": {
        "id": "video_123",
        "title": "Reported Video"
      },
      "createdAt": "2026-09-24T15:30:00Z"
    }
  ],
  "pagination": { ... }
}
```

---

### Take Moderation Action

**Endpoint**: `POST /admin/reports/:reportId/action` 🔒

**Description**: Take action on a report.

**Required Role**: `ADMIN` or `MODERATOR`

**Request Body**:
```json
{
  "action": "REMOVE_CONTENT",
  "notes": "Content violates community guidelines"
}
```

**Actions**:
- `DISMISS` - Dismiss report, no action needed
- `WARN_USER` - Send warning to user
- `REMOVE_CONTENT` - Remove reported content
- `SUSPEND_USER` - Suspend user account
- `BAN_USER` - Permanently ban user

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Moderation action taken",
  "data": {
    "action": "REMOVE_CONTENT",
    "takenBy": "admin_user_id",
    "takenAt": "2026-09-25T10:30:00Z"
  }
}
```

---

### Get User Activity Log

**Endpoint**: `GET /admin/users/:userId/activity` 🔒

**Description**: Get user activity log for investigation.

**Required Role**: `ADMIN` or `MODERATOR`

**Response** (200 OK):
```json
{
  "success": true,
  "data": [
    {
      "id": "log_123",
      "action": "VIDEO_UPLOAD",
      "details": {
        "videoId": "video_123",
        "title": "New Video"
      },
      "timestamp": "2026-09-25T10:30:00Z",
      "ipAddress": "192.168.1.1"
    }
  ]
}
```

---

### Ban User

**Endpoint**: `POST /admin/users/:userId/ban` 🔒

**Description**: Ban a user from the platform.

**Required Role**: `ADMIN`

**Request Body**:
```json
{
  "reason": "Repeated violations of community guidelines",
  "duration": "PERMANENT"
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "User banned successfully"
}
```

---

### Unban User

**Endpoint**: `POST /admin/users/:userId/unban` 🔒

**Description**: Remove ban from user.

**Required Role**: `ADMIN`

**Response** (200 OK):
```json
{
  "success": true,
  "message": "User unbanned successfully"
}
```

---

## Error Handling

### HTTP Status Codes

| Code | Meaning | Description |
|------|---------|-------------|
| `200` | OK | Request successful |
| `201` | Created | Resource created successfully |
| `400` | Bad Request | Invalid request data |
| `401` | Unauthorized | Missing or invalid authentication |
| `403` | Forbidden | Insufficient permissions |
| `404` | Not Found | Resource not found |
| `409` | Conflict | Resource conflict (e.g., duplicate username) |
| `422` | Unprocessable Entity | Validation error |
| `429` | Too Many Requests | Rate limit exceeded |
| `500` | Internal Server Error | Server error |
| `503` | Service Unavailable | Service temporarily unavailable |

### Error Response Format

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format",
        "value": "invalid-email"
      }
    ]
  },
  "timestamp": "2026-09-25T10:30:00Z"
}
```

### Common Error Codes

| Code | Description |
|------|-------------|
| `VALIDATION_ERROR` | Input validation failed |
| `AUTHENTICATION_REQUIRED` | Authentication token missing |
| `INVALID_TOKEN` | JWT token invalid or expired |
| `INSUFFICIENT_PERMISSIONS` | User lacks required permissions |
| `RESOURCE_NOT_FOUND` | Requested resource doesn't exist |
| `DUPLICATE_RESOURCE` | Resource already exists (e.g., username) |
| `RATE_LIMIT_EXCEEDED` | Too many requests |
| `ACCOUNT_LOCKED` | Account temporarily locked (brute force protection) |
| `FILE_TOO_LARGE` | Uploaded file exceeds size limit |
| `UNSUPPORTED_FILE_TYPE` | File type not allowed |
| `INTERNAL_SERVER_ERROR` | Unexpected server error |

---

## Rate Limiting

### Global Rate Limit

**Default**: 100 requests per 60 seconds per IP

**Headers**:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 87
X-RateLimit-Reset: 1632563400
```

### Endpoint-Specific Limits

| Endpoint | Limit | Window |
|----------|-------|--------|
| `POST /auth/register` | 5 requests | 60 seconds |
| `POST /auth/login` | 5 requests | 60 seconds |
| `POST /auth/refresh` | 5 requests | 60 seconds |
| `POST /videos` | 10 requests | 3600 seconds (1 hour) |
| `POST /live-streams` | 5 requests | 3600 seconds (1 hour) |

### Rate Limit Exceeded Response

```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests. Please try again later.",
    "retryAfter": 42
  },
  "timestamp": "2026-09-25T10:30:00Z"
}
```

**HTTP Status**: `429 Too Many Requests`

**Headers**:
```
Retry-After: 42
```

---

## Additional Resources

### Interactive API Documentation

**Swagger UI**: Available at `/api/docs` (when backend is running)

- Interactive API explorer
- Try API endpoints directly from browser
- Auto-generated from NestJS controllers and DTOs
- Includes request/response schemas and examples

### Related Documentation

- **ARCHITECTURE.md** - System architecture and design patterns
- **REALTIME_AND_LIVE.md** - WebSocket events and real-time features
- **DATABASE.md** - Database schema and relationships
- **SECURITY_AND_PRIVACY.md** - Security mechanisms and best practices
- **USER_GUIDE.md** - End-user feature documentation

### SDK/Client Libraries

**Flutter/Dart** (Mobile/Web):
- API client implementation in `mobile/lib/core/network/`
- Uses Dio HTTP client with interceptors
- Automatic token refresh
- Error handling and retry logic

---

**Document Version**: 1.0  
**API Version**: v1  
**Last Updated**: Based on implementation audit September 2026

**Note**: This documentation reflects the actual API implementation discovered during the code audit. For the most up-to-date API documentation, refer to the Swagger UI at `/api/docs` when the backend is running.
