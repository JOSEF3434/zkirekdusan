// test/core/network/auth_endpoint_regression_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_client.dart';

class TestErrorHandler extends Fake implements ErrorInterceptorHandler {
  DioException? forwardedError;

  @override
  void next(DioException err) {
    forwardedError = err;
  }
}

void main() {
  group('PrefixFallbackInterceptor & Auth Endpoint Contract Tests', () {
    late Dio dio;
    late PrefixFallbackInterceptor interceptor;

    setUp(() {
      PrefixFallbackInterceptor.resetRootMountedPrefixes();
      dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'));
      interceptor = PrefixFallbackInterceptor(dio);
      dio.interceptors.add(interceptor);
    });

    test('Canonical auth endpoints never have /api stripped on request', () {
      final reqOptions = RequestOptions(
        path: '/auth/login',
        baseUrl: 'http://localhost:3000/api',
      );

      final handler = RequestInterceptorHandler();
      interceptor.onRequest(reqOptions, handler);

      expect(reqOptions.baseUrl, equals('http://localhost:3000/api'));
    });

    test(
      '404 on /api/auth/login is passed directly to next handler without retrying',
      () async {
        final reqOptions = RequestOptions(
          path: '/auth/login',
          baseUrl: 'http://localhost:3000/api',
        );

        final dioError = DioException(
          requestOptions: reqOptions,
          response: Response(
            requestOptions: reqOptions,
            statusCode: 404,
            data: 'Cannot POST /api/auth/login',
          ),
        );

        final handler = TestErrorHandler();
        interceptor.onError(dioError, handler);

        // Verify that the error was forwarded directly to handler.next without setting retry flag
        expect(handler.forwardedError, equals(dioError));
        expect(reqOptions.extra['prefix_fallback_retried'], isNot(true));
      },
    );

    test(
      'Auth routes: /auth/register, /auth/refresh, /auth/login-config are all recognized as canonical',
      () {
        final paths = [
          '/auth/login',
          'auth/login',
          '/auth/register',
          'auth/register',
          '/auth/refresh',
          '/api/auth/login',
          'api/auth/refresh',
          '/auth/login-config',
        ];

        for (final p in paths) {
          final options = RequestOptions(
            path: p,
            baseUrl: 'http://localhost:3000/api',
          );
          interceptor.onRequest(options, RequestInterceptorHandler());
          expect(
            options.baseUrl,
            equals('http://localhost:3000/api'),
            reason: 'Route $p must preserve /api baseUrl',
          );
        }
      },
    );
  });
}
