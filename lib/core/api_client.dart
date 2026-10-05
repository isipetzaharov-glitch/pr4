// lib/core/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exceptions.dart';
import 'config.dart';

/// Собирает Dio с базовыми настройками, интерсептором логирования
/// и повтором запросов при сетевом сбое.
Dio buildDio({String? Function()? tokenProvider}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      // 4xx пропускаем в onResponse — разберём сами.
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenProvider?.call();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (kDebugMode) {
          debugPrint('[API →] ${options.method} ${options.uri}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        final status = response.statusCode ?? 0;
        if (kDebugMode) {
          debugPrint('[API ←] $status ${response.requestOptions.uri}');
        }
        if (status >= 400) {
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true,
          );
        }
        return handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          debugPrint('[API ✗] ${error.requestOptions.uri} — ${error.type}');
        }
        return handler.next(error);
      },
    ),
  );

  // Пункт 14: повтор только для GET при сетевом сбое.
  dio.interceptors.add(RetryInterceptor(dio));

  return dio;
}

/// Повтор операций чтения при сетевых сбоях.
///
/// Создание/изменение/удаление НЕ повторяется: нельзя гарантировать
/// идемпотентность на сервере без специальных заголовков.
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxAttempts;

  RetryInterceptor(this.dio, {this.maxAttempts = 3});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final isRead = err.requestOptions.method == 'GET';
    final isNetwork =
        err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout;

    final attempt = (err.requestOptions.extra['retryAttempt'] as int?) ?? 0;

    if (!isRead || !isNetwork || attempt >= maxAttempts) {
      return handler.next(err);
    }

    // Нарастающая пауза: 300, 600, 1200 мс.
    final delay = Duration(milliseconds: 300 * (1 << attempt));
    await Future.delayed(delay);

    final opts = err.requestOptions;
    opts.extra['retryAttempt'] = attempt + 1;

    try {
      final response = await dio.fetch(opts);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }
}
