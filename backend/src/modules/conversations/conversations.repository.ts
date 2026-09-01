import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';

@Injectable()
export class ConversationsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findOrCreateDirect(userId1: string, userId2: string) {
    // Find existing direct conversation between these two users
    const existing = await this.prisma.conversation.findFirst({
      where: {
        type: 'DIRECT',
        AND: [
          { members: { some: { userId: userId1 } } },
          { members: { some: { userId: userId2 } } },
        ],
      },
      include: {
        members: {
          include: {
            user: {
              select: {
                id: true,
                username: true,
                profile: {
                  select: {
                    displayName: true,
                    avatar: {
                      select: {
                        url: true,
                      },
                    },
                  },
                },
              },
            },
          },
        },
        channel: {
          select: {
            name: true,
          },
        },
      },
    });

    if (existing) {
      return existing;
    }

    // Create new direct conversation
    return this.prisma.conversation.create({
      data: {
        type: 'DIRECT',
        members: {
          create: [{ userId: userId1 }, { userId: userId2 }],
        },
      },
      include: {
        members: {
          include: {
            user: {
              select: {
                id: true,
                username: true,
                profile: {
                  select: {
                    displayName: true,
                    avatar: {
                      select: {
                        url: true,
                      },
                    },
                  },
                },
              },
            },
          },
        },
        channel: {
          select: {
            name: true,
          },
        },
      },
    });
  }

  async findById(id: string) {
    return this.prisma.conversation.findUnique({
      where: { id },
      include: {
        members: {
          include: {
            user: {
              select: {
                id: true,
                username: true,
                profile: {
                  select: {
                    displayName: true,
                    avatar: {
                      select: {
                        url: true,
                      },
                    },
                  },
                },
              },
            },
          },
        },
        channel: {
          select: {
            name: true,
            isPrivate: true,
            groupId: true,
          },
        },
        group: {
          select: {
            id: true,
            name: true,
            avatarUrl: true,
          },
        },
        messages: {
          take: 1,
          orderBy: {
            createdAt: 'desc',
          },
          include: {
            sender: {
              select: {
                id: true,
                username: true,
                profile: {
                  select: {
                    displayName: true,
                  },
                },
              },
            },
          },
        },
      },
    });
  }

  async getUserConversations(userId: string) {
    return this.prisma.conversation.findMany({
      where: {
        members: {
          some: {
            userId,
          },
        },
      },
      include: {
        members: {
          include: {
            user: {
              select: {
                id: true,
                username: true,
                profile: {
                  select: {
                    displayName: true,
                    avatar: {
                      select: {
                        url: true,
                      },
                    },
                  },
                },
              },
            },
          },
        },
        channel: {
          select: {
            name: true,
          },
        },
        group: {
          select: {
            id: true,
            name: true,
            avatarUrl: true,
          },
        },
        messages: {
          take: 1,
          orderBy: {
            createdAt: 'desc',
          },
          include: {
            sender: {
              select: {
                id: true,
                username: true,
                profile: {
                  select: {
                    displayName: true,
                  },
                },
              },
            },
          },
        },
      },
      orderBy: {
        updatedAt: 'desc',
      },
    });
  }

  async updateLastMessage(conversationId: string, lastMessageId: string) {
    return this.prisma.conversation.update({
      where: {
        id: conversationId,
      },
      data: {
        lastMessageId,
        lastMessageAt: new Date(),
      },
    });
  }

  async updateMemberSetting(
    conversationId: string,
    userId: string,
    settings: {
      isMuted?: boolean;
      isPinned?: boolean;
    },
  ) {
    return this.prisma.conversationMember.updateMany({
      where: {
        conversationId,
        userId,
      },
      data: settings,
    });
  }

  async resetUnreadCount(conversationId: string, userId: string) {
    return this.prisma.conversationMember.updateMany({
      where: {
        conversationId,
        userId,
      },
      data: {
        unreadCount: 0,
      },
    });
  }

  async getAllUsersSortedNewest(excludeUserId?: string) {
    return this.prisma.user.findMany({
      where: {
        status: 'ACTIVE',
        ...(excludeUserId ? { id: { not: excludeUserId } } : {}),
      },
      include: {
        profile: {
          include: {
            avatar: {
              select: {
                url: true,
              },
            },
          },
        },
        presence: true,
      },
      orderBy: {
        createdAt: 'desc',
      },
      take: 100,
    });
  }

  async getAllPublicGroupsSortedNewest() {
    return this.prisma.group.findMany({
      where: {
        visibility: 'PUBLIC',
        status: 'ACTIVE',
        deletedAt: null,
      },
      include: {
        _count: {
          select: {
            members: {
              where: { removedAt: null },
            },
          },
        },
        conversations: {
          take: 1,
          orderBy: { createdAt: 'asc' },
          select: { id: true },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
      take: 100,
    });
  }

  async getUserPrivateGroups(userId: string) {
    return this.prisma.group.findMany({
      where: {
        visibility: 'PRIVATE',
        deletedAt: null,
        members: {
          some: {
            userId,
            removedAt: null,
          },
        },
      },
      include: {
        _count: {
          select: {
            members: {
              where: { removedAt: null },
            },
          },
        },
        conversations: {
          take: 1,
          orderBy: { createdAt: 'asc' },
          select: { id: true },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });
  }

  async findOrCreateGroupConversation(groupId: string, userId: string) {
    // Find existing conversation for this group
    let conv = await this.prisma.conversation.findFirst({
      where: {
        groupId,
      },
      include: {
        members: {
          include: {
            user: {
              select: {
                id: true,
                username: true,
                profile: {
                  select: {
                    displayName: true,
                    avatar: {
                      select: {
                        url: true,
                      },
                    },
                  },
                },
              },
            },
          },
        },
        channel: {
          select: {
            name: true,
            isPrivate: true,
            groupId: true,
          },
        },
        group: {
          select: {
            id: true,
            name: true,
            avatarUrl: true,
          },
        },
        messages: {
          take: 1,
          orderBy: {
            createdAt: 'desc',
          },
          include: {
            sender: {
              select: {
                id: true,
                username: true,
                profile: {
                  select: {
                    displayName: true,
                  },
                },
              },
            },
          },
        },
      },
    });

    if (!conv) {
      conv = await this.prisma.conversation.create({
        data: {
          type: 'GROUP_CHANNEL',
          groupId,
          members: {
            create: [{ userId }],
          },
        },
        include: {
          members: {
            include: {
              user: {
                select: {
                  id: true,
                  username: true,
                  profile: {
                    select: {
                      displayName: true,
                      avatar: {
                        select: {
                          url: true,
                        },
                      },
                    },
                  },
                },
              },
            },
          },
          channel: {
            select: {
              name: true,
              isPrivate: true,
              groupId: true,
            },
          },
          group: {
            select: {
              id: true,
              name: true,
              avatarUrl: true,
            },
          },
          messages: {
            take: 1,
            orderBy: {
              createdAt: 'desc',
            },
            include: {
              sender: {
                select: {
                  id: true,
                  username: true,
                  profile: {
                    select: {
                      displayName: true,
                    },
                  },
                },
              },
            },
          },
        },
      });
    } else {
      // Ensure user is in conversation members
      const isMember = conv.members.some((m) => m.userId === userId);
      if (!isMember) {
        await this.prisma.conversationMember.create({
          data: {
            conversationId: conv.id,
            userId,
          },
        });
        // Re-fetch with member included
        const updated = await this.findById(conv.id);
        if (updated) {
          conv = updated as any;
        }
      }
    }

    return conv;
  }
}

