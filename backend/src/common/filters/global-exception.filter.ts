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
        const message =
          typeof resp['message'] === 'string'
            ? resp['message']
            : exception.message;
        const details = Array.isArray(resp['message'])
          ? (resp['message'] as string[])
          : undefined;
        return { statusCode: status, message, details };
      }

      return { statusCode: status, message: exception.message };
    }

    // Prisma — known request errors (e.g. unique constraint violation)
    if (exception instanceof Prisma.PrismaClientKnownRequestError) {
      return this.handlePrismaKnownError(exception);
    }

    // Prisma — validation errors (e.g. passing undefined/null where required)
    if (exception instanceof Prisma.PrismaClientValidationError) {
      this.logger.error(
        'PrismaClientValidationError — likely undefined id passed to query',
      );
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message:
          'Invalid query parameters — this is a server bug, please report it',
      };
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
      default:
        this.logger.error(
          `Unhandled Prisma error: ${error.code}`,
          error.message,
        );
        return {
          statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
          message: 'A database error occurred',
        };
    }
  }
}
