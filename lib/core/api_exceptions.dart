// lib/core/api_exceptions.dart
import 'package:dio/dio.dart';

/// Базовый тип для всех ошибок API.
/// Виджеты ловят именно эти исключения, не зная о Dio.
sealed class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

/// Нет соединения, таймаут, сервер недоступен, CORS.
class NetworkException extends ApiException {
  const NetworkException([
    super.message = 'Сервер недоступен. Проверьте соединение.',
  ]);
}

/// 401 — не аутентифицирован или истёк токен.
class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Требуется вход в систему.']);
}

/// 403 — роль не позволяет операцию.
class ForbiddenException extends ApiException {
  const ForbiddenException([
    super.message = 'Недостаточно прав для этого действия.',
  ]);
}

/// 404.
class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Запись не найдена.']);
}

/// 409 — нарушено ограничение целостности.
class ConflictException extends ApiException {
  const ConflictException(super.message);
}

/// 422 — ошибки валидации по полям.
/// Ключ — имя поля в модели, значение — текст ошибки.
class ValidationException extends ApiException {
  final Map<String, String> errors;
  const ValidationException(super.message, this.errors);
}

/// 5xx.
class ServerException extends ApiException {
  const ServerException([
    super.message = 'Ошибка на сервере. Попробуйте позже.',
  ]);
}

/// Преобразование HTTP-кода и тела ответа в исключение.
ApiException mapHttpError(int status, dynamic body) {
  final message = (body is Map && body['message'] is String)
      ? body['message'] as String
      : null;

  return switch (status) {
    401 => UnauthorizedException(message ?? 'Требуется вход в систему.'),
    403 => ForbiddenException(
      message ?? 'Недостаточно прав для этого действия.',
    ),
    404 => NotFoundException(message ?? 'Запись не найдена.'),
    409 => ConflictException(message ?? 'Операция невозможна.'),
    422 => ValidationException(
      message ?? 'Ошибка валидации',
      (body is Map && body['errors'] is Map)
          ? (body['errors'] as Map).map((k, v) => MapEntry('$k', '$v'))
          : const {},
    ),
    _ => ServerException(message ?? 'Неизвестная ошибка (код $status).'),
  };
}

/// Преобразование DioException в исключение предметной области.
ApiException mapDioError(DioException e) {
  // Если интерсептор уже разобрал ошибку — не разбираем повторно.
  final existing = e.error;
  if (existing is ApiException) return existing;

  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => const NetworkException(
      'Сервер не ответил вовремя.',
    ),
    DioExceptionType.connectionError => const NetworkException(
      'Не удалось соединиться с сервером. '
      'Если сервер запущен, откройте консоль браузера '
      'и проверьте наличие ошибки CORS.',
    ),
    DioExceptionType.cancel => const NetworkException('Запрос отменён.'),
    _ => const ServerException(),
  };
}

/// Обёртка для запросов: любые DioException наружу не пропускаем.
Future<T> guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on DioException catch (e) {
    throw mapDioError(e);
  }
}
