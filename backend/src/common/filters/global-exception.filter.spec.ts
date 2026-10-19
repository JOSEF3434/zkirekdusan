import { HttpStatus, BadRequestException, ArgumentsHost } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { GlobalExceptionFilter } from './global-exception.filter.js';

describe('GlobalExceptionFilter', () => {
  let filter: GlobalExceptionFilter;
  let mockResponse: any;
  let mockRequest: any;
  let mockArgumentsHost: ArgumentsHost;

  beforeEach(() => {
    filter = new GlobalExceptionFilter();
    mockResponse = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    };
    mockRequest = {
      method: 'POST',
      url: '/api/books/admin',
    };
    mockArgumentsHost = {
      switchToHttp: jest.fn().mockReturnValue({
        getResponse: () => mockResponse,
        getRequest: () => mockRequest,
      }),
    } as any;
  });

  describe('PrismaClientValidationError handling', () => {
    it('catches unknown field in select statement (e.g. fileSize on File) as 500 internal database query error', () => {
      const prismaError = new Prisma.PrismaClientValidationError(
        'Invalid `prisma.book.create()` invocation:\nUnknown field `fileSize` for select statement on model `File`. Available options are marked with ?:',
        { clientVersion: '7.8.0' },
      );

      filter.catch(prismaError, mockArgumentsHost);

      expect(mockResponse.status).toHaveBeenCalledWith(HttpStatus.INTERNAL_SERVER_ERROR);
      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
          error: 'Internal database query configuration error',
          path: '/api/books/admin',
        }),
      );
    });

    it('catches missing argument as 400 Bad Request with client-safe message', () => {
      const prismaError = new Prisma.PrismaClientValidationError(
        'Invalid `prisma.book.create()` invocation:\nArgument `title` is missing.',
        { clientVersion: '7.8.0' },
      );

      filter.catch(prismaError, mockArgumentsHost);

      expect(mockResponse.status).toHaveBeenCalledWith(HttpStatus.BAD_REQUEST);
      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          statusCode: HttpStatus.BAD_REQUEST,
          error: 'Missing required field: title',
        }),
      );
    });

    it('catches type mismatch as 400 Bad Request with actionable details', () => {
      const prismaError = new Prisma.PrismaClientValidationError(
        'Provided String, expected Int at `Book.create.data.publishedYear`',
        { clientVersion: '7.8.0' },
      );

      filter.catch(prismaError, mockArgumentsHost);

      expect(mockResponse.status).toHaveBeenCalledWith(HttpStatus.BAD_REQUEST);
      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          statusCode: HttpStatus.BAD_REQUEST,
          error: "Invalid type for 'publishedYear': expected Int, got String",
        }),
      );
    });
  });

  describe('HttpException validation handling', () => {
    it('formats array of validation errors from ValidationPipe into readable message and details', () => {
      const exception = new BadRequestException({
        statusCode: 400,
        message: [
          'title must be longer than 1 character',
          'publishedYear must not be greater than 2100',
        ],
        error: 'Bad Request',
      });

      filter.catch(exception, mockArgumentsHost);

      expect(mockResponse.status).toHaveBeenCalledWith(HttpStatus.BAD_REQUEST);
      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          statusCode: HttpStatus.BAD_REQUEST,
          error: 'title must be longer than 1 character; publishedYear must not be greater than 2100',
          details: [
            'title must be longer than 1 character',
            'publishedYear must not be greater than 2100',
          ],
        }),
      );
    });

    it('handles single string message in BadRequestException', () => {
      const exception = new BadRequestException('Category not found');

      filter.catch(exception, mockArgumentsHost);

      expect(mockResponse.status).toHaveBeenCalledWith(HttpStatus.BAD_REQUEST);
      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          statusCode: HttpStatus.BAD_REQUEST,
          error: 'Category not found',
        }),
      );
    });
  });
});
