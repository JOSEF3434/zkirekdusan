import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { StreamAnalyticsRepository } from './stream-analytics.repository.js';
import { LiveStreamingRepository } from '../live-streaming/live-streaming.repository.js';
import { AuthorizationService } from '../authorization/authorization.service.js';
import { GroupRole } from '../../common/constants/group-roles.js';

@Injectable()
export class StreamAnalyticsService {
  constructor(
    private readonly repository: StreamAnalyticsRepository,
    private readonly liveStreamingRepository: LiveStreamingRepository,
    private readonly authorizationService: AuthorizationService,
  ) {}

  async getAnalytics(userId: string, streamId: string) {
    const stream = await this.liveStreamingRepository.getStreamById(streamId);
    if (!stream) throw new NotFoundException('Stream not found');

    const hasPermission = await this.authorizationService.hasGroupRole(
      userId,
      stream.groupId,
      GroupRole.MODERATOR,
    );
    if (!hasPermission) throw new ForbiddenException('Not a moderator');

    const analytics = await this.repository.getAnalytics(streamId);
    if (!analytics) throw new NotFoundException('Analytics not available yet');

    return analytics;
  }
  
  // To be used internally by LiveGateway
  async trackViewerJoin(streamId: string, userId: string) {
      return this.repository.recordViewerJoin(streamId, userId);
  }

  async trackViewerLeave(viewerSessionId: string, durationSec: number) {
      return this.repository.recordViewerLeave(viewerSessionId, durationSec);
  }

  async updateCurrentViewers(streamId: string, current: number, peak: number) {
      return this.repository.updateViewerCount(streamId, current, peak);
  }

  async trackEngagement(streamId: string, type: 'chat' | 'reaction' | 'like') {
    const fieldMap = {
      chat: 'totalChatMessages',
      reaction: 'totalReactions',
      like: 'totalLikes',
    } as const;
    return this.repository.incrementEngagement(streamId, fieldMap[type]);
  }
}
