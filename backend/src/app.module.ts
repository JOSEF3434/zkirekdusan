import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { AppService } from './app.service';
import { AppController } from './app.controller';
import { PrismaModule } from 'prisma/prisma.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    //PrismaModule, // This is a Module, so it stays here.
  ],
  controllers: [
    AppController, // Controllers go here.
  ],
  providers: [
    AppService, // Services/Providers go here.
  ],
})

export class AppModule {}
