# Real-Time & Live Streaming Documentation

**Zikire Kdusan (StreamHub) - WebSocket & Live Streaming Architecture**

This document provides comprehensive documentation for real-time communication features, including Socket.IO WebSocket implementation, live streaming architecture, and real-time messaging.

---

## Table of Contents

1. [Overview](#overview)
2. [Technology Stack](#technology-stack)
3. [WebSocket Architecture](#websocket-architecture)
4. [Socket.IO Gateways](#socketio-gateways)
5. [Authentication & Authorization](#authentication--authorization)
6. [Live Streaming Flow](#live-streaming-flow)
7. [Real-Time Messaging](#real-time-messaging)
8. [Live Chat System](#live-chat-system)
9. [Presence System](#presence-system)
10. [Event Reference](#event-reference)
11. [Client Implementation](#client-implementation)
12. [Error Handling](#error-handling)
13. [Horizontal Scaling](#horizontal-scaling)
14. [Performance Optimization](#performance-optimization)
15. [Monitoring & Debugging](#monitoring--debugging)

---

## Overview

Zikire Kdusan uses **Socket.IO** for real-time bidirectional communication between clients and servers. Real-time features include:

- 🔴 **Live Streaming** - RTMP ingest, HLS playback, real-time viewer tracking
- 💬 **Live Chat** - Real-time chat during live streams
- 🎉 **Floating Reactions** - Animated emoji reactions on streams
- 📨 **Instant Messaging** - Direct and group messages with read receipts
- 🔔 **Push Notifications** - Real-time notification delivery
- 👤 **Presence** - Online/offline status tracking
- 📊 **Live Analytics** - Real-time viewer counts and engagement metrics

---

## Technology Stack

### Backend

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **WebSocket Library** | Socket.IO | 4.8.x | Real-time communication |
| **NestJS Integration** | @nestjs/platform-socket.io | 11.1.x | NestJS WebSocket support |
| **WebSocket Adapters** | @nestjs/websockets | 11.1.x | Gateway decorators |
| **Redis Adapter** | @socket.io/redis-adapter | 8.3.x | Multi-server scaling |
| **Redis Client** | ioredis | 5.11.x | Redis connection |
| **Live Streaming** | Cloudinary Live | Latest | RTMP/HLS streaming |

### Frontend

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **WebSocket Client** | socket_io_client | 2.0.x | Socket.IO client for Flutter |
| **RTMP Streaming** | apivideo_live_stream | 1.2.x | Mobile RTMP broadcasting |
| **Video Player** | video_player | 2.9.x | HLS playback |
| **Camera** | camera | 0.11.x | Camera access for streaming |

---

## WebSocket Architecture

### Connection Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                          CLIENT                                  │
│  (Flutter Mobile/Web)                                            │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ 1. WSS Connection Request
                         │    (with JWT in auth handshake)
                         │
┌────────────────────────▼────────────────────────────────────────┐
│                    SOCKET.IO GATEWAY                             │
│  (NestJS Backend - WebSocket Server)                             │
├──────────────────────────────────────────────────────────────────┤
│  2. Verify JWT Token                                             │
│  3. Extract user information                                     │
│  4. Attach user to socket.data                                   │
│  5. Establish WebSocket connection                               │
│  6. Emit 'connected' event to client                             │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ 7. Client emits events
                         │    (send_message, join_stream, etc.)
                         │
┌────────────────────────▼────────────────────────────────────────┐
│                  EVENT HANDLERS                                  │
│  (Process events, validate, update DB)                           │
├──────────────────────────────────────────────────────────────────┤
│  8. Validate user permissions                                    │
│  9. Process event (save to DB, business logic)                   │
│  10. Emit response/broadcast to other clients                    │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ 11. Redis Pub/Sub (for multi-server)
                         │
┌────────────────────────▼────────────────────────────────────────┐
│                       REDIS                                      │
│  (Pub/Sub for broadcasting across servers)                       │
├──────────────────────────────────────────────────────────────────┤
│  - Enables horizontal scaling                                    │
│  - Messages broadcast to all server instances                    │
│  - Clients on different servers receive events                   │
└──────────────────────────────────────────────────────────────────┘
```

### Connection Establishment

**Client-Side (Flutter)**:
```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

IO.Socket socket = IO.io('https://api.example.com', <String, dynamic>{
  'transports': ['websocket'],
  'autoConnect': false,
  'auth': {
    'token': accessToken,  // JWT access token
  },
});

socket.connect();

socket.on('connect', (_) {
  print('Connected to WebSocket server');
  print('Socket ID: ${socket.id}');
});

socket.on('disconnect', (_) {
  print('Disconnected from server');
});
```

**Server-Side (NestJS)**:
```typescript
@WebSocketGateway({
  cors: { origin: '*' },
  transports: ['websocket', 'polling'],
  namespace: '/live',
})
export class LiveGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  async handleConnection(client: Socket) {
    try {
      // Extract and verify JWT from handshake
      const token = client.handshake.auth.token;
      const payload = await this.jwtService.verify(token);
      
      // Attach user info to socket
      client.data.userId = payload.sub;
      client.data.username = payload.username;
      
      console.log(`User ${payload.username} connected (${client.id})`);
      
      // Emit welcome event
      client.emit('connected', {
        socketId: client.id,
        userId: payload.sub,
      });
    } catch (error) {
      console.error('Connection auth failed:', error);
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    console.log(`User disconnected (${client.id})`);
  }
}
```

---

## Socket.IO Gateways

### Gateway Overview

The system has **two main gateways**:

1. **LiveGateway** (`/live` namespace) - Live streaming features
2. **MessagingGateway** (`/messaging` namespace) - Real-time messaging

### LiveGateway

**Purpose**: Handle live streaming real-time features

**Namespace**: `/live`

**Events**:
- `join_stream` - Join a live stream room
- `leave_stream` - Leave a live stream room
- `send_chat_message` - Send message in live chat
- `send_reaction` - Send floating emoji reaction
- `viewer_joined` - Broadcast when viewer joins
- `viewer_left` - Broadcast when viewer leaves
- `viewer_count` - Broadcast updated viewer count
- `chat_message` - Broadcast chat message
- `floating_reaction` - Broadcast emoji reaction
- `stream_ended` - Notify stream ended

**Implementation**:
```typescript
@WebSocketGateway({
  namespace: '/live',
  cors: { origin: '*' },
  transports: ['websocket', 'polling'],
})
export class LiveGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  constructor(
    private readonly jwtService: JwtService,
    private readonly liveStreamingService: LiveStreamingService,
    private readonly streamChatService: StreamChatService,
  ) {}

  // Connection handling
  async handleConnection(client: Socket) {
    // Authenticate (see Authentication section)
  }

  handleDisconnect(client: Socket) {
    // Handle disconnection
    // Remove from all rooms
    // Update viewer counts
  }

  // Event: Join stream
  @SubscribeMessage('join_stream')
  async handleJoinStream(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { streamId: string },
  ) {
    const { streamId } = data;
    const userId = client.data.userId;

    // Join Socket.IO room
    client.join(`stream:${streamId}`);

    // Track viewer in database
    await this.liveStreamingService.addViewer(streamId, userId);

    // Get updated viewer count
    const viewerCount = await this.liveStreamingService.getViewerCount(streamId);

    // Broadcast viewer joined
    this.server.to(`stream:${streamId}`).emit('viewer_joined', {
      userId,
      username: client.data.username,
    });

    // Broadcast updated count
    this.server.to(`stream:${streamId}`).emit('viewer_count', {
      count: viewerCount,
    });

    // Send acknowledgment to joiner
    return { success: true, viewerCount };
  }

  // Event: Send chat message
  @SubscribeMessage('send_chat_message')
  async handleChatMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { streamId: string; message: string },
  ) {
    const { streamId, message } = data;
    const userId = client.data.userId;

    // Validate message
    if (!message || message.trim().length === 0) {
      return { error: 'Message cannot be empty' };
    }

    // Check if user is in stream room
    if (!client.rooms.has(`stream:${streamId}`)) {
      return { error: 'You must join the stream first' };
    }

    // Save message to database
    const chatMessage = await this.streamChatService.create({
      liveStreamId: streamId,
      userId,
      message: message.trim(),
    });

    // Broadcast message to all viewers
    this.server.to(`stream:${streamId}`).emit('chat_message', {
      id: chatMessage.id,
      userId,
      username: client.data.username,
      message: chatMessage.message,
      timestamp: chatMessage.createdAt,
    });

    return { success: true };
  }

  // Event: Send floating reaction
  @SubscribeMessage('send_reaction')
  async handleReaction(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { streamId: string; emoji: string },
  ) {
    const { streamId, emoji } = data;
    const userId = client.data.userId;

    // Validate emoji
    const validEmojis = ['❤️', '👍', '😂', '😮', '😢', '🔥', '🎉'];
    if (!validEmojis.includes(emoji)) {
      return { error: 'Invalid emoji' };
    }

    // Save reaction to database
    await this.liveStreamingService.addReaction(streamId, userId, emoji);

    // Broadcast reaction to all viewers
    this.server.to(`stream:${streamId}`).emit('floating_reaction', {
      userId,
      username: client.data.username,
      emoji,
      timestamp: new Date(),
    });

    return { success: true };
  }
}
```

---

### MessagingGateway

**Purpose**: Handle real-time messaging features

**Namespace**: `/messaging`

**Events**:
- `send_message` - Send message in conversation
- `typing_start` - User started typing
- `typing_stop` - User stopped typing
- `mark_read` - Mark messages as read
- `message_received` - Broadcast new message
- `message_read` - Broadcast read receipt
- `user_typing` - Broadcast typing indicator

**Implementation**:
```typescript
@WebSocketGateway({
  namespace: '/messaging',
  cors: { origin: '*' },
  transports: ['websocket', 'polling'],
})
export class MessagingGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  async handleConnection(client: Socket) {
    // Authenticate client
    const token = client.handshake.auth.token;
    const payload = await this.jwtService.verify(token);
    
    client.data.userId = payload.sub;
    
    // Join user's personal room for targeted messages
    client.join(`user:${payload.sub}`);
  }

  @SubscribeMessage('send_message')
  async handleSendMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string; content: string },
  ) {
    const { conversationId, content } = data;
    const senderId = client.data.userId;

    // Save message to database
    const message = await this.messagesService.create({
      conversationId,
      senderId,
      content,
    });

    // Get conversation participants
    const participants = await this.conversationsService.getParticipants(conversationId);

    // Broadcast to all participants
    participants.forEach(participant => {
      if (participant.userId !== senderId) {
        this.server.to(`user:${participant.userId}`).emit('message_received', {
          conversationId,
          message: {
            id: message.id,
            senderId,
            content: message.content,
            createdAt: message.createdAt,
          },
        });
      }
    });

    return { success: true, messageId: message.id };
  }

  @SubscribeMessage('typing_start')
  handleTypingStart(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    const { conversationId } = data;
    const userId = client.data.userId;

    // Broadcast to conversation except sender
    client.to(`conversation:${conversationId}`).emit('user_typing', {
      conversationId,
      userId,
      isTyping: true,
    });
  }
}
```

---

## Authentication & Authorization

### Handshake Authentication

**Client sends JWT** in connection auth:
```dart
IO.Socket socket = IO.io('https://api.example.com/live', {
  'auth': {
    'token': accessToken,  // JWT token
  },
});
```

**Server verifies JWT**:
```typescript
async handleConnection(client: Socket) {
  try {
    // Extract token from handshake
    const token = client.handshake.auth.token;
    
    if (!token) {
      throw new UnauthorizedException('No token provided');
    }
    
    // Verify JWT
    const payload = await this.jwtService.verify(token);
    
    // Attach user to socket
    client.data.userId = payload.sub;
    client.data.username = payload.username;
    client.data.role = payload.role;
    
    console.log(`Authenticated: ${payload.username}`);
  } catch (error) {
    console.error('Auth failed:', error.message);
    client.emit('error', { message: 'Authentication failed' });
    client.disconnect();
  }
}
```

### Event-Level Authorization

**Check permissions before processing events**:
```typescript
@SubscribeMessage('moderate_chat')
async handleModerateChat(
  @ConnectedSocket() client: Socket,
  @MessageBody() data: { streamId: string; messageId: string; action: string },
) {
  const userId = client.data.userId;
  
  // Check if user has moderation permission
  const stream = await this.liveStreamingService.findOne(data.streamId);
  const canModerate = await this.authorizationService.canModerate(userId, stream);
  
  if (!canModerate) {
    return { error: 'Insufficient permissions' };
  }
  
  // Process moderation action
  // ...
}
```

---

## Live Streaming Flow

### Complete Live Streaming Lifecycle

```
┌─────────────────────────────────────────────────────────────────┐
│                    1. CREATE STREAM                              │
├─────────────────────────────────────────────────────────────────┤
│  Client → POST /live-streams                                     │
│  Backend → Create LiveStream record                              │
│  Backend → Cloudinary.createLiveStream()                         │
│  Response → { rtmpUrl, streamKey, hlsUrl }                       │
└─────────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                  2. START RTMP STREAMING                         │
├─────────────────────────────────────────────────────────────────┤
│  Broadcaster → RTMP stream to rtmpUrl + streamKey                │
│  Cloudinary → Receives RTMP stream                               │
│  Cloudinary → Transcodes to HLS in real-time                     │
│  Cloudinary → Webhook → Backend (stream started)                 │
│  Backend → Update status to LIVE                                 │
│  Backend → Wait 2 minutes for notification delay                 │
│  Backend → Send "went live" notifications                        │
└─────────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                  3. VIEWERS JOIN STREAM                          │
├─────────────────────────────────────────────────────────────────┤
│  Viewer → Connect to WebSocket (/live namespace)                 │
│  Viewer → Emit 'join_stream' { streamId }                        │
│  Backend → Add viewer to room: stream:${streamId}                │
│  Backend → Track viewer in database                              │
│  Backend → Broadcast 'viewer_joined' to room                     │
│  Backend → Broadcast 'viewer_count' update                       │
│  Viewer → Fetch HLS URL and start playback                       │
└─────────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│              4. REAL-TIME INTERACTION                            │
├─────────────────────────────────────────────────────────────────┤
│  CHAT:                                                           │
│    Viewer → Emit 'send_chat_message' { streamId, message }      │
│    Backend → Save to StreamChat table                            │
│    Backend → Broadcast 'chat_message' to all viewers             │
│                                                                  │
│  REACTIONS:                                                      │
│    Viewer → Emit 'send_reaction' { streamId, emoji }            │
│    Backend → Save to StreamReaction table                        │
│    Backend → Broadcast 'floating_reaction' to all viewers        │
│                                                                  │
│  VIEWER TRACKING:                                                │
│    Backend → Track join/leave times                              │
│    Backend → Calculate watch duration                            │
│    Backend → Update viewer count continuously                    │
└─────────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│              5. STREAM INTERRUPTION (Optional)                   │
├─────────────────────────────────────────────────────────────────┤
│  Broadcaster → Network drops, RTMP disconnects                   │
│  Cloudinary → Detects stream interruption                        │
│  Backend → Update status to INTERRUPTED                          │
│  Backend → Start 30-second grace period timer                    │
│  Backend → Broadcast 'stream_interrupted' to viewers             │
│                                                                  │
│  CASE A: Reconnection within 30s                                │
│    Broadcaster → Reconnects RTMP                                 │
│    Backend → Update status back to LIVE                          │
│    Backend → Broadcast 'stream_resumed'                          │
│                                                                  │
│  CASE B: No reconnection after 30s                              │
│    Backend → End stream automatically                            │
│    Backend → Proceed to stream end flow                          │
└─────────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    6. END STREAM                                 │
├─────────────────────────────────────────────────────────────────┤
│  Broadcaster → POST /live-streams/:id/end                        │
│  Backend → Update status to ENDED                                │
│  Backend → Set endedAt timestamp                                 │
│  Backend → Broadcast 'stream_ended' to all viewers               │
│  Backend → Disconnect all viewers from room                      │
│  Cloudinary → Stop RTMP ingest                                   │
│  Cloudinary → Process recording → VOD                            │
│  Backend → Save StreamRecording with VOD URL                     │
└─────────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                  7. POST-STREAM ANALYTICS                        │
├─────────────────────────────────────────────────────────────────┤
│  Backend → Calculate total viewers                               │
│  Backend → Calculate peak viewer count                           │
│  Backend → Calculate total watch time                            │
│  Backend → Save to StreamAnalytics table                         │
│  Backend → VOD available for replay                              │
└─────────────────────────────────────────────────────────────────┘
```

### 2-Minute Notification Delay

**Purpose**: Prevent notification spam from test streams

**Implementation**:
```typescript
async handleStreamStarted(streamId: string) {
  // Stream just went live
  await this.updateStreamStatus(streamId, 'LIVE');
  
  // Wait 2 minutes before sending notifications
  setTimeout(async () => {
    const stream = await this.findOne(streamId);
    
    // Check if stream is still live
    if (stream.status === 'LIVE') {
      // Send notifications to followers
      await this.notificationsService.sendLiveNotifications(streamId);
      
      // Mark as notified
      await this.prisma.liveStream.update({
        where: { id: streamId },
        data: { notifiedLiveAt: new Date() },
      });
    }
  }, 2 * 60 * 1000); // 2 minutes
}
```

### 30-Second Interruption Grace Period

**Purpose**: Allow brief network interruptions without ending stream

**Implementation**:
```typescript
async handleStreamInterrupted(streamId: string) {
  // Update status to interrupted
  await this.updateStreamStatus(streamId, 'INTERRUPTED');
  
  // Notify viewers
  this.liveGateway.server
    .to(`stream:${streamId}`)
    .emit('stream_interrupted', {
      message: 'Stream temporarily interrupted. Reconnecting...',
    });
  
  // Start 30-second grace period
  setTimeout(async () => {
    const stream = await this.findOne(streamId);
    
    // If still interrupted after 30 seconds, end stream
    if (stream.status === 'INTERRUPTED') {
      await this.endStream(streamId);
    }
  }, 30 * 1000); // 30 seconds
}

async handleStreamResumed(streamId: string) {
  // Update status back to live
  await this.updateStreamStatus(streamId, 'LIVE');
  
  // Notify viewers
  this.liveGateway.server
    .to(`stream:${streamId}`)
    .emit('stream_resumed', {
      message: 'Stream resumed',
    });
}
```

---

## Real-Time Messaging

### Message Delivery Flow

```
┌──────────────┐                                    ┌──────────────┐
│   Sender     │                                    │  Recipient   │
│  (Device A)  │                                    │  (Device B)  │
└──────┬───────┘                                    └──────▲───────┘
       │                                                   │
       │ 1. Emit 'send_message'                           │
       │    { conversationId, content }                   │
       │                                                   │
       ▼                                                   │
┌──────────────────────────────────────────────────────────────────┐
│                    MESSAGING GATEWAY                              │
│                  (WebSocket Server)                               │
├──────────────────────────────────────────────────────────────────┤
│  2. Authenticate sender                                           │
│  3. Validate message content                                      │
│  4. Check conversation permissions                                │
└──────┬──────────────────────────────────────────────────────────┘
       │
       │ 5. Save to database
       ▼
┌──────────────────────────────────────────────────────────────────┐
│                      DATABASE                                     │
│  INSERT INTO messages (conversationId, senderId, content, ...)   │
└──────┬──────────────────────────────────────────────────────────┘
       │
       │ 6. Get conversation participants
       ▼
┌──────────────────────────────────────────────────────────────────┐
│               BROADCAST TO PARTICIPANTS                           │
├──────────────────────────────────────────────────────────────────┤
│  For each participant (except sender):                            │
│    server.to(`user:${participantId}`).emit('message_received')   │
└──────┬──────────────────────────────────────────────────────────┘
       │
       │ 7. Emit 'message_received'
       │
       └──────────────────────────────────────────►  Recipient receives
                                                     message in real-time
```

### Offline Message Handling

**If recipient is offline**:
1. Message saved to database
2. Recipient won't receive WebSocket event (not connected)
3. When recipient comes online:
   - Opens app → triggers sync
   - Fetches unread messages via REST API
   - Background sync runs every 15 minutes

**Push Notification**:
- If recipient offline, queue push notification
- Firebase Cloud Messaging delivers notification
- Notification triggers app to sync messages

---

## Live Chat System

### Chat Message Structure

```typescript
interface ChatMessage {
  id: string;
  streamId: string;
  userId: string;
  username: string;
  message: string;
  timestamp: Date;
  isDeleted: boolean;
}
```

### Chat Features

**1. Send Message**:
```dart
// Client
socket.emit('send_chat_message', {
  'streamId': currentStreamId,
  'message': messageText,
});
```

**2. Receive Messages**:
```dart
// Client
socket.on('chat_message', (data) {
  ChatMessage message = ChatMessage.fromJson(data);
  addMessageToChat(message);
});
```

**3. Message Moderation**:
```typescript
// Server
@SubscribeMessage('delete_chat_message')
async handleDeleteMessage(
  @ConnectedSocket() client: Socket,
  @MessageBody() data: { streamId: string; messageId: string },
) {
  const userId = client.data.userId;
  
  // Check if user is streamer or moderator
  const canDelete = await this.canModerateChat(userId, data.streamId);
  
  if (!canDelete) {
    return { error: 'Insufficient permissions' };
  }
  
  // Soft delete message
  await this.streamChatService.delete(data.messageId);
  
  // Broadcast deletion
  this.server.to(`stream:${data.streamId}`).emit('message_deleted', {
    messageId: data.messageId,
  });
  
  return { success: true };
}
```

**4. Chat Rate Limiting**:
```typescript
// Prevent spam - limit messages per user
const rateLimits = new Map<string, number[]>();

@SubscribeMessage('send_chat_message')
async handleChatMessage(
  @ConnectedSocket() client: Socket,
  @MessageBody() data: { streamId: string; message: string },
) {
  const userId = client.data.userId;
  const now = Date.now();
  
  // Get user's recent message timestamps
  const timestamps = rateLimits.get(userId) || [];
  const recentMessages = timestamps.filter(t => now - t < 10000); // Last 10 seconds
  
  // Limit: 5 messages per 10 seconds
  if (recentMessages.length >= 5) {
    return { error: 'Slow down! You are sending messages too quickly.' };
  }
  
  // Add timestamp
  recentMessages.push(now);
  rateLimits.set(userId, recentMessages);
  
  // Process message...
}
```

---

## Presence System

### Online/Offline Status

**Track user presence**:
```typescript
@WebSocketGateway({ namespace: '/presence' })
export class PresenceGateway implements OnGatewayConnection, OnGatewayDisconnect {
  private onlineUsers = new Map<string, string>(); // userId -> socketId
  
  async handleConnection(client: Socket) {
    const userId = client.data.userId;
    
    // Mark user as online
    this.onlineUsers.set(userId, client.id);
    
    // Update presence in database
    await this.presenceService.updateStatus(userId, 'ONLINE');
    
    // Broadcast to friends
    const friends = await this.getOnlineFriends(userId);
    friends.forEach(friendId => {
      this.server.to(`user:${friendId}`).emit('friend_online', {
        userId,
        status: 'ONLINE',
      });
    });
  }
  
  handleDisconnect(client: Socket) {
    const userId = client.data.userId;
    
    // Mark user as offline
    this.onlineUsers.delete(userId);
    
    // Update presence
    await this.presenceService.updateStatus(userId, 'OFFLINE');
    
    // Broadcast to friends
    const friends = await this.getOnlineFriends(userId);
    friends.forEach(friendId => {
      this.server.to(`user:${friendId}`).emit('friend_offline', {
        userId,
        status: 'OFFLINE',
      });
    });
  }
}
```

**Client subscribes to presence**:
```dart
socket.on('friend_online', (data) {
  updateUserStatus(data['userId'], 'online');
});

socket.on('friend_offline', (data) {
  updateUserStatus(data['userId'], 'offline');
});
```

---

## Event Reference

### LiveGateway Events

#### Client → Server (Emit)

| Event | Payload | Description |
|-------|---------|-------------|
| `join_stream` | `{ streamId: string }` | Join a live stream room |
| `leave_stream` | `{ streamId: string }` | Leave a live stream room |
| `send_chat_message` | `{ streamId: string, message: string }` | Send chat message |
| `send_reaction` | `{ streamId: string, emoji: string }` | Send floating reaction |
| `like_stream` | `{ streamId: string }` | Like the stream |

#### Server → Client (Listen)

| Event | Payload | Description |
|-------|---------|-------------|
| `connected` | `{ socketId: string, userId: string }` | Connection established |
| `viewer_joined` | `{ userId: string, username: string }` | Someone joined stream |
| `viewer_left` | `{ userId: string }` | Someone left stream |
| `viewer_count` | `{ count: number }` | Updated viewer count |
| `chat_message` | `{ id, userId, username, message, timestamp }` | New chat message |
| `floating_reaction` | `{ userId, username, emoji, timestamp }` | New emoji reaction |
| `stream_ended` | `{ streamId: string }` | Stream has ended |
| `stream_interrupted` | `{ message: string }` | Stream temporarily interrupted |
| `stream_resumed` | `{ message: string }` | Stream resumed |

### MessagingGateway Events

#### Client → Server (Emit)

| Event | Payload | Description |
|-------|---------|-------------|
| `send_message` | `{ conversationId, content }` | Send a message |
| `typing_start` | `{ conversationId }` | Started typing |
| `typing_stop` | `{ conversationId }` | Stopped typing |
| `mark_read` | `{ conversationId, messageId }` | Mark message as read |

#### Server → Client (Listen)

| Event | Payload | Description |
|-------|---------|-------------|
| `message_received` | `{ conversationId, message }` | New message received |
| `message_read` | `{ conversationId, messageId, userId }` | Message was read |
| `user_typing` | `{ conversationId, userId, isTyping }` | User typing indicator |

---

## Client Implementation

### Flutter Socket.IO Setup

**Complete implementation**:
```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket? socket;
  final String serverUrl = 'https://api.example.com';
  
  Future<void> connect(String accessToken) async {
    socket = IO.io('$serverUrl/live', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {
        'token': accessToken,
      },
    });
    
    // Connection events
    socket!.on('connect', (_) {
      print('Connected to WebSocket server');
    });
    
    socket!.on('disconnect', (_) {
      print('Disconnected from server');
    });
    
    socket!.on('error', (error) {
      print('Socket error: $error');
    });
    
    // Connect
    socket!.connect();
  }
  
  void disconnect() {
    socket?.disconnect();
    socket?.dispose();
  }
  
  // Join live stream
  void joinStream(String streamId) {
    socket?.emit('join_stream', {'streamId': streamId});
  }
  
  // Send chat message
  void sendChatMessage(String streamId, String message) {
    socket?.emit('send_chat_message', {
      'streamId': streamId,
      'message': message,
    });
  }
  
  // Listen for chat messages
  void onChatMessage(Function(dynamic) callback) {
    socket?.on('chat_message', callback);
  }
  
  // Send reaction
  void sendReaction(String streamId, String emoji) {
    socket?.emit('send_reaction', {
      'streamId': streamId,
      'emoji': emoji,
    });
  }
  
  // Listen for reactions
  void onFloatingReaction(Function(dynamic) callback) {
    socket?.on('floating_reaction', callback);
  }
  
  // Listen for viewer count
  void onViewerCount(Function(dynamic) callback) {
    socket?.on('viewer_count', callback);
  }
}
```

### Usage in Flutter

```dart
class LiveStreamScreen extends StatefulWidget {
  @override
  _LiveStreamScreenState createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  final SocketService socketService = SocketService();
  final List<ChatMessage> messages = [];
  int viewerCount = 0;
  
  @override
  void initState() {
    super.initState();
    initializeSocket();
  }
  
  Future<void> initializeSocket() async {
    final accessToken = await getAccessToken();
    await socketService.connect(accessToken);
    
    // Join stream
    socketService.joinStream(widget.streamId);
    
    // Listen for chat messages
    socketService.onChatMessage((data) {
      setState(() {
        messages.add(ChatMessage.fromJson(data));
      });
    });
    
    // Listen for viewer count
    socketService.onViewerCount((data) {
      setState(() {
        viewerCount = data['count'];
      });
    });
    
    // Listen for reactions
    socketService.onFloatingReaction((data) {
      showFloatingEmoji(data['emoji']);
    });
  }
  
  void sendMessage(String text) {
    socketService.sendChatMessage(widget.streamId, text);
  }
  
  void sendReaction(String emoji) {
    socketService.sendReaction(widget.streamId, emoji);
  }
  
  @override
  void dispose() {
    socketService.disconnect();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Video player
          VideoPlayer(hlsUrl: widget.hlsUrl),
          
          // Viewer count
          Text('$viewerCount viewers'),
          
          // Chat messages
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ChatMessageWidget(message: messages[index]);
              },
            ),
          ),
          
          // Message input
          ChatInput(onSend: sendMessage),
          
          // Reaction buttons
          ReactionBar(onReaction: sendReaction),
        ],
      ),
    );
  }
}
```

---

## Error Handling

### Connection Errors

```dart
socket.on('connect_error', (error) {
  print('Connection error: $error');
  // Retry connection or show error to user
});

socket.on('error', (error) {
  print('Socket error: $error');
  // Handle specific error
});
```

### Reconnection Strategy

```dart
IO.Socket socket = IO.io(serverUrl, <String, dynamic>{
  'transports': ['websocket'],
  'reconnection': true,
  'reconnectionAttempts': 5,
  'reconnectionDelay': 1000,
  'reconnectionDelayMax': 5000,
  'auth': {
    'token': accessToken,
  },
});

socket.on('reconnect', (attemptNumber) {
  print('Reconnected after $attemptNumber attempts');
  // Re-join rooms
  rejoinActiveRooms();
});

socket.on('reconnect_failed', (_) {
  print('Failed to reconnect after maximum attempts');
  // Show user they're offline
});
```

---

## Horizontal Scaling

### Redis Adapter

**Purpose**: Enable WebSocket communication across multiple server instances

**Setup**:
```typescript
import { createAdapter } from '@socket.io/redis-adapter';
import { createClient } from 'redis';

// Create Redis clients
const pubClient = createClient({ url: 'redis://localhost:6379' });
const subClient = pubClient.duplicate();

// Connect clients
await Promise.all([pubClient.connect(), subClient.connect()]);

// Attach adapter to Socket.IO server
io.adapter(createAdapter(pubClient, subClient));
```

**How it works**:
1. Server A receives WebSocket event from Client 1
2. Server A processes event and emits to room
3. Redis adapter publishes event to Redis
4. Server B (and all other servers) receive from Redis
5. Server B emits to its connected clients in that room
6. Client 2 (connected to Server B) receives the event

**Result**: Clients on different servers can communicate seamlessly

---

## Performance Optimization

### Room Management

**Use rooms for targeted broadcasting**:
```typescript
// Join room
client.join(`stream:${streamId}`);

// Broadcast to room (efficient)
this.server.to(`stream:${streamId}`).emit('event', data);

// Don't broadcast to all sockets (inefficient)
this.server.emit('event', data); // ❌ Sends to everyone
```

### Event Throttling

**Limit high-frequency events**:
```typescript
// Throttle viewer count updates (once per second)
let lastViewerCountUpdate = 0;

if (Date.now() - lastViewerCountUpdate > 1000) {
  this.server.to(`stream:${streamId}`).emit('viewer_count', { count });
  lastViewerCountUpdate = Date.now();
}
```

### Cleanup

**Remove listeners when done**:
```dart
@override
void dispose() {
  socket.off('chat_message');
  socket.off('viewer_count');
  socket.disconnect();
  super.dispose();
}
```

---

## Monitoring & Debugging

### Server-Side Logging

```typescript
@WebSocketGateway()
export class LiveGateway {
  private readonly logger = new Logger(LiveGateway.name);
  
  handleConnection(client: Socket) {
    this.logger.log(`Client connected: ${client.id}`);
  }
  
  @SubscribeMessage('join_stream')
  async handleJoinStream(client: Socket, data: any) {
    this.logger.log(`User ${client.data.userId} joining stream ${data.streamId}`);
    // ...
  }
}
```

### Client-Side Debugging

```dart
socket.onAny((event, data) {
  print('Socket event: $event');
  print('Data: $data');
});
```

### Metrics to Monitor

- **Active connections**: Number of connected sockets
- **Room sizes**: Number of clients in each room
- **Event frequency**: Events per second
- **Latency**: Time from emit to receive
- **Error rate**: Failed events / total events

---

## Conclusion

Zikire Kdusan's real-time architecture provides:

- ✅ **Low-latency communication** via WebSocket (Socket.IO)
- ✅ **Scalable design** with Redis adapter for multi-server deployment
- ✅ **Secure connections** with JWT authentication
- ✅ **Rich live streaming** with RTMP ingest and HLS playback
- ✅ **Interactive features** (chat, reactions, presence)
- ✅ **Robust error handling** and reconnection logic
- ✅ **Performance optimized** with rooms and event throttling

**Key Features**:
- Live streaming with 30-second interruption grace period
- 2-minute notification delay for test streams
- Real-time chat with moderation
- Floating emoji reactions
- Presence tracking
- Multi-server support via Redis

---

**Document Version**: 1.0  
**Last Updated**: Based on implementation audit September 2026  
**Related Documentation**: ARCHITECTURE.md, API.md, DATABASE.md

For implementation details, see:
- `backend/src/modules/live-gateway/live.gateway.ts`
- `backend/src/modules/messaging-gateway/messaging.gateway.ts`
- `mobile/lib/core/services/socket_service.dart`
