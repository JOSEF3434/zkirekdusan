// src/common/filters/global-exception.filter.ts
import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';
import { Prisma } from '@prisma/client';

@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(GlobalExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    const { statusCode, message, details } = this.resolveError(exception);

    // Log only server errors (5xx) at error level
    if (statusCode >= 500) {
      this.logger.error(
        `[${request.method}] ${request.url} — ${statusCode}`,
        exception instanceof Error ? exception.stack : String(exception),
      );
    } else {
      this.logger.warn(
        `[${request.method}] ${request.url} — ${statusCode}: ${message}`,
      );
    }

    response.status(statusCode).json({
      success: false,
      error: message,
      statusCode,
      details,
      timestamp: new Date().toISOString(),
      path: request.url,
    });
  }

  private resolveError(exception: unknown): {
    statusCode: number;
    message: string;
    details?: string | string[];
  } {
    // NestJS HttpException (BadRequestException, UnauthorizedException, etc.)
    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const exceptionResponse = exception.getResponse();

      if (typeof exceptionResponse === 'object' && exceptionResponse !== null) {
        const resp = exceptionResponse as Record<string, unknown>;
        const details = Array.isArray(resp['message'])
          ? (resp['message'] as string[])
          : undefined;
        const message =
          typeof resp['message'] === 'string'
            ? resp['message']
            : details && details.length > 0
              ? details.join('; ')
              : exception.message;
        return { statusCode: status, message, details };
      }

      return { statusCode: status, message: exception.message };
    }

    // Prisma — known request errors (e.g. unique constraint violation)
    if (exception instanceof Prisma.PrismaClientKnownRequestError) {
      return this.handlePrismaKnownError(exception);
    }

    // Prisma — validation errors (e.g. invalid arguments, missing fields, schema mismatches)
    if (exception instanceof Prisma.PrismaClientValidationError) {
      return this.handlePrismaValidationError(exception);
    }

    // Prisma — initialization errors
    if (exception instanceof Prisma.PrismaClientInitializationError) {
      return {
        statusCode: HttpStatus.SERVICE_UNAVAILABLE,
        message: 'Database connection failed',
      };
    }

    // Unknown errors
    return {
      statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
      message: 'An unexpected internal error occurred',
    };
  }

  private handlePrismaValidationError(error: Prisma.PrismaClientValidationError): {
    statusCode: number;
    message: string;
    details?: string | string[];
  } {
    const rawMessage = error.message || '';
    this.logger.error(`PrismaClientValidationError: ${rawMessage}`, error.stack);

    // 1. Internal query/schema structure mismatch (e.g. unknown field in select statement)
    const selectFieldMatch = rawMessage.match(
      /Unknown field `([^`]+)` for select statement on model `([^`]+)`/,
    );
    if (selectFieldMatch) {
      const [, field, model] = selectFieldMatch;
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: 'Internal database query configuration error',
        details:
          process.env.NODE_ENV === 'development'
            ? `Unknown field '${field}' on model '${model}' in select statement`
            : undefined,
      };
    }

    // 2. Missing required argument / property
    const missingArgMatch = rawMessage.match(/Argument `([^`]+)` is missing/);
    if (missingArgMatch) {
      const [, arg] = missingArgMatch;
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: `Missing required field: ${arg}`,
        details: `Field '${arg}' is required`,
      };
    }

    // 3. Type mismatch (e.g. Provided String, expected Int)
    const typeMismatchMatch = rawMessage.match(
      /Provided (\w+), expected (\w+) at `([^`]+)`/,
    );
    if (typeMismatchMatch) {
      const [, provided, expected, path] = typeMismatchMatch;
      const fieldName = path.split('.').pop() || path;
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: `Invalid type for '${fieldName}': expected ${expected}, got ${provided}`,
        details: `Expected ${expected} for '${fieldName}'`,
      };
    }

    // 4. Unknown property / argument in payload
    const unknownArgMatch = rawMessage.match(/Unknown argument `([^`]+)`/);
    if (unknownArgMatch) {
      const [, arg] = unknownArgMatch;
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: `Unknown property: ${arg}`,
        details: `Property '${arg}' is not supported`,
      };
    }

    // 5. Invalid enum value
    const enumMatch = rawMessage.match(/Invalid value for argument `([^`]+)`/);
    if (enumMatch) {
      const [, arg] = enumMatch;
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: `Invalid value provided for '${arg}'`,
        details: `Value constraint failed for '${arg}'`,
      };
    }

    // 6. Generic client-safe validation error
    return {
      statusCode: HttpStatus.BAD_REQUEST,
      message: 'Invalid request data or database constraint failure',
      details: process.env.NODE_ENV === 'development' ? rawMessage : undefined,
    };
  }

  private handlePrismaKnownError(error: Prisma.PrismaClientKnownRequestError): {
    statusCode: number;
    message: string;
    details?: string | string[];
  } {
    switch (error.code) {
      case 'P2002': {
        // Unique constraint failed
        const fields = Array.isArray(error.meta?.['target'])
          ? (error.meta['target'] as string[]).join(', ')
          : 'field';
        return {
          statusCode: HttpStatus.CONFLICT,
          message: `A record with this ${fields} already exists`,
        };
      }
      case 'P2025':
        // Record not found
        return {
          statusCode: HttpStatus.NOT_FOUND,
          message: 'Record not found',
        };
      case 'P2003':
        // Foreign key constraint failed
        return {
          statusCode: HttpStatus.BAD_REQUEST,
          message: 'Related record does not exist',
        };
      case 'P2014':
        return {
          statusCode: HttpStatus.BAD_REQUEST,
          message:
            'The change you are trying to make would violate a required relation',
        };
      case 'P2021':
        return {
          statusCode: HttpStatus.BAD_REQUEST,
          message: 'Table does not exist in the database',
        };
      case 'P2022':
        return {
          statusCode: HttpStatus.BAD_REQUEST,
          message: 'Column does not exist in the database',
        };
      default:
        this.logger.error(
          `Unhandled Prisma error code: ${error.code}, message: ${error.message}, meta: ${JSON.stringify(error.meta)}`,
        );
        return {
          statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
          message: 'A database error occurred',
          details:
            process.env.NODE_ENV === 'development' ? error.message : undefined,
        };
    }
  }
}
