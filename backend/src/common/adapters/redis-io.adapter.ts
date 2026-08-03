import { IoAdapter } from '@nestjs/platform-socket.io';
import { ServerOptions } from 'socket.io';
import { createAdapter } from '@socket.io/redis-adapter';
import { Redis } from 'ioredis';
import { INestApplication, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export class RedisIoAdapter extends IoAdapter {
  private adapterConstructor: ReturnType<typeof createAdapter> | undefined;
  private readonly logger = new Logger(RedisIoAdapter.name);
  public isReady = false;

  constructor(private readonly app: INestApplication) {
    super(app);
  }

  async connectToRedis(): Promise<void> {
    const configService = this.app.get(ConfigService);
    const redisUrl =
      configService.get<string>('REDIS_URL') || 'redis://localhost:6379';

    try {
      const pubClient = new Redis(redisUrl, {
        maxRetriesPerRequest: 0,
        lazyConnect: true,
        enableOfflineQueue: false,
        connectTimeout: 3000,
      });
      const subClient = pubClient.duplicate();

      // Actually attempt the connection
      await Promise.all([pubClient.connect(), subClient.connect()]);

      pubClient.on('error', (err) =>
        this.logger.warn(`Redis pub error: ${err.message}`),
      );
      subClient.on('error', (err) =>
        this.logger.warn(`Redis sub error: ${err.message}`),
      );

      this.adapterConstructor = createAdapter(pubClient, subClient);
      this.isReady = true;
      this.logger.log('✅ Socket.IO Redis adapter connected');
    } catch (err: any) {
      this.logger.warn(
        `⚠️  Redis unavailable (${err.message ?? err}). Socket.IO will use the default in-process adapter.`,
      );
      this.isReady = false;
    }
  }

  createIOServer(port: number, options?: ServerOptions): any {
    const server = super.createIOServer(port, options);
    if (this.adapterConstructor) {
      server.adapter(this.adapterConstructor);
    }
    return server;
  }
}
