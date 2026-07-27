// src/common/pipes/parse-uuid.pipe.ts
import {
  ArgumentMetadata,
  BadRequestException,
  Injectable,
  PipeTransform,
} from '@nestjs/common';

const UUID_REGEX =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * Validates that a route param/query is a valid UUID.
 * Throws BadRequestException instead of letting an invalid value
 * reach Prisma and cause a PrismaClientValidationError.
 */
@Injectable()
export class ParseUuidPipe implements PipeTransform<string, string> {
  transform(value: string, metadata: ArgumentMetadata): string {
    if (!value || !UUID_REGEX.test(value)) {
      throw new BadRequestException(
        `${metadata.data ?? 'Parameter'} must be a valid UUID`,
      );
    }
    return value;
  }
}
