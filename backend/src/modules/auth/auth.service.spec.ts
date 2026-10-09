// src/modules/auth/auth.service.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { AuthService } from './auth.service.js';
import { UsersService } from '../users/users.service.js';
import { PasswordService } from '../../common/service/password.service.js';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { AuthPolicyService } from '../auth-policy/auth-policy.service.js';
import { UnauthorizedException } from '@nestjs/common';
import { LoginDto } from './dto/login.dto.js';

describe('AuthService', () => {
  let service: AuthService;
  let mockUsersService: any;
  let mockPasswordService: any;
  let mockJwtService: any;
  let mockConfigService: any;
  let mockAuthPolicyService: any;

  const makeLoginDto = (data: Partial<LoginDto>): LoginDto =>
    Object.assign(new LoginDto(), data);

  const mockUser1 = {
    id: 'user-1',
    email: 'user1@example.com',
    phoneNumber: '+12025550001',
    username: 'userone',
    passwordHash: 'hashed_pw_1',
    status: 'ACTIVE',
    role: { name: 'USER' },
    lockedUntil: null,
  };

  const mockUser2 = {
    id: 'user-2',
    email: 'user2@example.com',
    phoneNumber: '+12025550002',
    username: 'usertwo',
    passwordHash: 'hashed_pw_2',
    status: 'ACTIVE',
    role: { name: 'USER' },
    lockedUntil: null,
  };

  beforeEach(async () => {
    mockUsersService = {
      findByEmail: jest.fn(),
      findByPhoneNumber: jest.fn(),
      findByUsername: jest.fn(),
      incrementFailedLogin: jest.fn(),
      updateLastLogin: jest.fn(),
      revokeRefreshTokens: jest.fn(),
      saveRefreshToken: jest.fn(),
      createSession: jest.fn(),
    };

    mockPasswordService = {
      compare: jest.fn(),
      hash: jest.fn().mockResolvedValue('new_hash'),
    };

    mockJwtService = {
      signAsync: jest.fn().mockResolvedValue('jwt_token'),
    };

    mockConfigService = {
      getOrThrow: jest.fn().mockReturnValue('test_secret'),
      get: jest.fn().mockReturnValue('15m'),
    };

    mockAuthPolicyService = {
      getActivePolicy: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: UsersService, useValue: mockUsersService },
        { provide: PasswordService, useValue: mockPasswordService },
        { provide: JwtService, useValue: mockJwtService },
        { provide: ConfigService, useValue: mockConfigService },
        { provide: AuthPolicyService, useValue: mockAuthPolicyService },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('Policy: SINGLE_IDENTIFIER', () => {
    beforeEach(() => {
      mockAuthPolicyService.getActivePolicy.mockResolvedValue({
        activePolicy: 'SINGLE_IDENTIFIER',
        allowEmail: true,
        allowPhone: true,
        allowUsername: true,
        dualCombination: null,
      });
    });

    it('should successfully authenticate with valid email and password', async () => {
      mockUsersService.findByEmail.mockResolvedValue(mockUser1);
      mockPasswordService.compare.mockResolvedValue(true);

      const res = await service.login(
        makeLoginDto({
          email: 'user1@example.com',
          password: 'ValidPassword123!',
        }),
      );

      expect(res.user.id).toBe('user-1');
      expect(res.accessToken).toBe('jwt_token');
      expect(mockUsersService.updateLastLogin).toHaveBeenCalledWith('user-1');
    });

    it('should reject login if identifier is disallowed by policy', async () => {
      mockAuthPolicyService.getActivePolicy.mockResolvedValue({
        activePolicy: 'SINGLE_IDENTIFIER',
        allowEmail: true,
        allowPhone: false, // phone disabled!
        allowUsername: true,
      });

      await expect(
        service.login(
          makeLoginDto({
            phoneNumber: '+12025550001',
            password: 'ValidPassword123!',
          }),
        ),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should reject login when multiple supplied identifiers resolve to different accounts', async () => {
      mockUsersService.findByEmail.mockResolvedValue(mockUser1);
      mockUsersService.findByPhoneNumber.mockResolvedValue(mockUser2); // Different user!

      await expect(
        service.login(
          makeLoginDto({
            email: 'user1@example.com',
            phoneNumber: '+12025550002',
            password: 'ValidPassword123!',
          }),
        ),
      ).rejects.toThrow(UnauthorizedException);
    });
  });

  describe('Policy: DUAL_IDENTIFIER', () => {
    beforeEach(() => {
      mockAuthPolicyService.getActivePolicy.mockResolvedValue({
        activePolicy: 'DUAL_IDENTIFIER',
        allowEmail: true,
        allowPhone: true,
        allowUsername: true,
        dualCombination: 'EMAIL_PHONE',
      });
    });

    it('should authenticate when both email and phone belong to the same account', async () => {
      mockUsersService.findByEmail.mockResolvedValue(mockUser1);
      mockUsersService.findByPhoneNumber.mockResolvedValue(mockUser1);
      mockPasswordService.compare.mockResolvedValue(true);

      const res = await service.login(
        makeLoginDto({
          email: 'user1@example.com',
          phoneNumber: '+12025550001',
          password: 'ValidPassword123!',
        }),
      );

      expect(res.user.id).toBe('user-1');
    });

    it('should reject when one identifier belongs to user1 and second identifier belongs to user2', async () => {
      mockUsersService.findByEmail.mockResolvedValue(mockUser1);
      mockUsersService.findByPhoneNumber.mockResolvedValue(mockUser2);

      await expect(
        service.login(
          makeLoginDto({
            email: 'user1@example.com',
            phoneNumber: '+12025550002',
            password: 'ValidPassword123!',
          }),
        ),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should reject when a required identifier is missing', async () => {
      mockUsersService.findByEmail.mockResolvedValue(mockUser1);

      await expect(
        service.login(
          makeLoginDto({
            email: 'user1@example.com',
            // phoneNumber omitted
            password: 'ValidPassword123!',
          }),
        ),
      ).rejects.toThrow(UnauthorizedException);
    });
  });

  describe('Policy: ALL_IDENTIFIERS', () => {
    beforeEach(() => {
      mockAuthPolicyService.getActivePolicy.mockResolvedValue({
        activePolicy: 'ALL_IDENTIFIERS',
        allowEmail: true,
        allowPhone: true,
        allowUsername: true,
        dualCombination: null,
      });
    });

    it('should authenticate when all three identifiers belong to the same account', async () => {
      mockUsersService.findByEmail.mockResolvedValue(mockUser1);
      mockUsersService.findByPhoneNumber.mockResolvedValue(mockUser1);
      mockUsersService.findByUsername.mockResolvedValue(mockUser1);
      mockPasswordService.compare.mockResolvedValue(true);

      const res = await service.login(
        makeLoginDto({
          email: 'user1@example.com',
          phoneNumber: '+12025550001',
          username: 'userone',
          password: 'ValidPassword123!',
        }),
      );

      expect(res.user.id).toBe('user-1');
    });

    it('should reject if any one identifier references another account', async () => {
      mockUsersService.findByEmail.mockResolvedValue(mockUser1);
      mockUsersService.findByPhoneNumber.mockResolvedValue(mockUser1);
      mockUsersService.findByUsername.mockResolvedValue(mockUser2); // Mismatched!

      await expect(
        service.login(
          makeLoginDto({
            email: 'user1@example.com',
            phoneNumber: '+12025550001',
            username: 'usertwo',
            password: 'ValidPassword123!',
          }),
        ),
      ).rejects.toThrow(UnauthorizedException);
    });
  });

  describe('Password & Brute Force Lockout Handling', () => {
    it('should increment failed login count and throw UnauthorizedException on wrong password', async () => {
      mockAuthPolicyService.getActivePolicy.mockResolvedValue({
        activePolicy: 'SINGLE_IDENTIFIER',
        allowEmail: true,
        allowPhone: true,
        allowUsername: true,
      });
      mockUsersService.findByEmail.mockResolvedValue(mockUser1);
      mockPasswordService.compare.mockResolvedValue(false); // Wrong password!

      await expect(
        service.login(
          makeLoginDto({
            email: 'user1@example.com',
            password: 'WrongPassword!',
          }),
        ),
      ).rejects.toThrow(UnauthorizedException);

      expect(mockUsersService.incrementFailedLogin).toHaveBeenCalledWith('user-1');
    });
  });
});
