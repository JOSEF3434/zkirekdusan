// src/modules/users/users.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { UsersRepository } from './users.repository.js';
import { UserResponseDto } from './dto/user-response.dto.js';

@Injectable()
export class UsersService {
  constructor(private readonly usersRepository: UsersRepository) {}

  async findById(id: string) {
    if (!id) throw new NotFoundException('User ID is required');
    const user = await this.usersRepository.findById(id);
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  async findByEmail(email: string) {
    return this.usersRepository.findByEmail(email);
  }

  async findByPhoneNumber(phoneNumber: string) {
    return this.usersRepository.findByPhoneNumber(phoneNumber);
  }

  async findByEmailOrPhone(identifier: string) {
    return this.usersRepository.findByEmailOrPhone(identifier);
  }

  async findByUsername(username: string) {
    return this.usersRepository.findByUsername(username);
  }

  async getRoleByName(name: string) {
    return this.usersRepository.getRoleByName(name);
  }

  async create(data: {
    email?: string;
    phoneNumber?: string;
    username: string;
    passwordHash: string;
    roleId: string;
  }) {
    return this.usersRepository.create(data);
  }

  async updateLastLogin(userId: string) {
    return this.usersRepository.updateLastLogin(userId);
  }

  async incrementFailedLogin(userId: string) {
    return this.usersRepository.incrementFailedLogin(userId);
  }

  async saveRefreshToken(userId: string, tokenHash: string, expiresAt: Date) {
    return this.usersRepository.saveRefreshToken(userId, tokenHash, expiresAt);
  }

  async findActiveRefreshToken(userId: string) {
    return this.usersRepository.findActiveRefreshToken(userId);
  }

  async revokeRefreshTokens(userId: string) {
    return this.usersRepository.revokeRefreshTokens(userId);
  }

  async createSession(data: { userId: string; expiresAt: Date }) {
    return this.usersRepository.createSession(data);
  }

  async revokeSessions(userId: string) {
    return this.usersRepository.revokeSessions(userId);
  }

  async getUserProfileDto(id: string): Promise<UserResponseDto> {
    const user = await this.findById(id);
    return {
      id: user.id,
      email: user.email,
      phoneNumber: user.phoneNumber,
      username: user.username,
      role: user.role.name,
      status: user.status,
      isEmailVerified: user.isEmailVerified,
      isPhoneVerified: user.isPhoneVerified,
      lastLoginAt: user.lastLoginAt,
      createdAt: user.createdAt,
    };
  }

  async findAll(page = 1, limit = 20, search?: string) {
    const skip = (page - 1) * limit;
    const { items, total } = await this.usersRepository.findAll({
      skip,
      take: limit,
      search,
    });

    const data: UserResponseDto[] = items.map((user) => ({
      id: user.id,
      email: user.email,
      phoneNumber: user.phoneNumber,
      username: user.username,
      role: user.role.name,
      status: user.status,
      isEmailVerified: user.isEmailVerified,
      isPhoneVerified: user.isPhoneVerified,
      lastLoginAt: user.lastLoginAt,
      createdAt: user.createdAt,
    }));

    return {
      data,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
        hasNext: page * limit < total,
        hasPrev: page > 1,
      },
    };
  }
}
