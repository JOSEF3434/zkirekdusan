import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';

@Injectable()
export class StreamHighlightsService {
  constructor(private readonly prisma: PrismaService) {}

  async createHighlight(
    userId: string,
    streamId: string,
    data: {
      title: string;
      description?: string;
      startTimeSec: number;
      endTimeSec: number;
    },
  ) {
    const stream = await this.prisma.liveStream.findUnique({
      where: { id: streamId },
      include: { videoChannel: true },
    });

    if (!stream || stream.deletedAt)
      throw new NotFoundException('Stream not found');

    // Simple permission check (assuming only creator can highlight for now)
    if (stream.createdById !== userId) {
      throw new ForbiddenException(
        'Only the stream creator can create highlights',
      );
    }

    const highlight = await this.prisma.streamHighlight.create({
      data: {
        liveStreamId: streamId,
        createdById: userId,
        title: data.title,
        description: data.description,
        startTimeSec: data.startTimeSec,
        endTimeSec: data.endTimeSec,
        isPublic: true,
      },
    });

    // In a real system, we'd enqueue a job to FFmpeg cut the recording based on these timestamps
    // and upload it as a standalone Video entity or just keep it as a highlight snippet.

    return highlight;
  }

  async getHighlights(streamId: string) {
    return this.prisma.streamHighlight.findMany({
      where: { liveStreamId: streamId, isPublic: true },
      orderBy: { startTimeSec: 'asc' },
    });
  }

  async deleteHighlight(userId: string, highlightId: string) {
    const highlight = await this.prisma.streamHighlight.findUnique({
      where: { id: highlightId },
    });
    if (!highlight) throw new NotFoundException('Highlight not found');

    if (highlight.createdById !== userId) {
      throw new ForbiddenException('You do not own this highlight');
    }

    await this.prisma.streamHighlight.delete({ where: { id: highlightId } });
  }
}
