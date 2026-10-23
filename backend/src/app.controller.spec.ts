/// <reference types="jest" />
import { Test, TestingModule } from '@nestjs/testing';
import { AppService } from './app.service.js';
import { AppController } from './app.controller.js';

import { PrismaService } from './prisma/prisma.service.js';

describe('AppController', () => {
  let appController: AppController;

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [AppController],
      providers: [
        AppService,
        {
          provide: PrismaService,
          useValue: {
            user: {
              findFirst: jest.fn(),
              findUnique: jest.fn(),
            },
          },
        },
      ],
    }).compile();

    appController = app.get<AppController>(AppController);
  });

  describe('root', () => {
    it('should return health status', () => {
      expect(appController.getHello()).toEqual({
        status: 'ok',
        message: 'Backend is running',
      });
    });
  });
});
