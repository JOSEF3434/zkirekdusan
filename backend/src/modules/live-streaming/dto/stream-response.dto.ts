import { LiveStreamStatus, LiveStreamVisibility, StreamProtocol } from '@prisma/client';

export class StreamResponseDto {
  id!: string;
  videoChannelId!: string;
  groupId!: string;
  createdById!: string;
  title!: string;
  description!: string | null;
  slug!: string;
  status!: LiveStreamStatus;
  visibility!: LiveStreamVisibility;
  protocol!: StreamProtocol;
  hlsUrl!: string | null;
  dashUrl!: string | null;
  webrtcUrl!: string | null;
  rtmpIngestUrl!: string | null;
  thumbnailUrl!: string | null;
  categories!: string[];
  tags!: string[];
  hashtags!: string[];
  scheduledAt!: Date | null;
  startedAt!: Date | null;
  endedAt!: Date | null;
  isRecordingEnabled!: boolean;
  isDvrEnabled!: boolean;
  isReplayEnabled!: boolean;
  isChatEnabled!: boolean;
  isChatSlowMode!: boolean;
  chatSlowModeSeconds!: number;
  isMembersOnlyChat!: boolean;
  isSubscribersOnlyChat!: boolean;
  peakViewerCount!: number;
  currentViewerCount!: number;
  totalViewerCount!: number;
  totalChatMessages!: number;
  totalReactions!: number;
  likesCount!: number;
  duration!: number | null;
  createdAt!: Date;
  updatedAt!: Date;

  // Optional relations
  createdBy?: { id: string; username: string; avatarUrl: string | null };
  group?: { id: string; name: string };
  videoChannel?: { id: string; name: string; avatarUrl: string | null };
}
