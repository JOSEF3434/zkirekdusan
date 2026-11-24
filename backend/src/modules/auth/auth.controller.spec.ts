// src/modules/auth/auth.controller.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { AuthService } from './auth.service.js';
import { AuthController } from './auth.controller.js';
import { PasswordRecoveryService } from './services/password-recovery.service.js';

describe('AuthController', () => {
  let controller: AuthController;
  let mockPasswordRecoveryService: any;

  beforeEach(async () => {
    mockPasswordRecoveryService = {
      requestRecovery: jest.fn().mockResolvedValue({
        success: true,
        message: 'Recovery instructions sent.',
        method: 'EMAIL',
        resendCooldownSeconds: 60,
      }),
      verifyChallenge: jest.fn().mockResolvedValue({
        valid: true,
        message: 'Code verified successfully.',
        resetToken: 'mock-token',
        method: 'PHONE',
      }),
      validateEmailToken: jest.fn().mockResolvedValue({
        valid: true,
        message: 'Recovery link is valid.',
      }),
      resendRecovery: jest.fn().mockResolvedValue({
        success: true,
        message: 'Code resent.',
        method: 'PHONE',
        resendCooldownSeconds: 60,
      }),
      resetPassword: jest.fn().mockResolvedValue({
        success: true,
        message: 'Password reset successfully.',
      }),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [AuthController],
      providers: [
        { provide: AuthService, useValue: {} },
        { provide: PasswordRecoveryService, useValue: mockPasswordRecoveryService },
      ],
    }).compile();

    controller = module.get<AuthController>(AuthController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  it('should call forgotPassword successfully', async () => {
    const req = { headers: {}, ip: '127.0.0.1' } as any;
    const res = await controller.forgotPassword({ identifier: 'test@example.com' }, req);
    expect(res.success).toBe(true);
    expect(mockPasswordRecoveryService.requestRecovery).toHaveBeenCalled();
  });

  it('should verify recovery code successfully', async () => {
    const res = await controller.verifyRecoveryCode({
      method: 'PHONE' as any,
      destination: '+251911223344',
      code: '123456',
    });
    expect(res.valid).toBe(true);
    expect(mockPasswordRecoveryService.verifyChallenge).toHaveBeenCalled();
  });
});
