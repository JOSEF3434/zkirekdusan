// src/modules/video-channels/dto/update-video-channel.dto.ts
import { PartialType } from '@nestjs/swagger';
import { CreateVideoChannelDto } from './create-video-channel.dto.js';

export class UpdateVideoChannelDto extends PartialType(CreateVideoChannelDto) {}
