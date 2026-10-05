// lib/repositories/api_master_repository.dart
import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/master.dart';

class ApiMasterRepository {
  final Dio _dio;
  ApiMasterRepository(this._dio);

  /// Локальный кэш (пункт 15: справочники запрашиваются один раз).
  List<Master> _cache = const [];

  List<Master> get all => List.unmodifiable(_cache);

  /// Сервер по контракту учебного API отдаёт списки в обёртке:
  ///   { "items": [...], "page": 1, "size": 10, "total": N, "totalPages": M }
  /// Однако может вернуть и простой массив — поддерживаем обе формы.
  Future<List<Master>> getAll() => guard(() async {
    final response = await _dio.get('/masters');
    final data = response.data;

    final List<dynamic> rawList = data is List
        ? data
        : (data is Map && data['items'] is List)
        ? data['items'] as List
        : const <dynamic>[];

    final list = rawList
        .whereType<Map<String, dynamic>>()
        .map(Master.fromJson)
        .toList();

    _cache = list;
    return list;
  });

  Future<Master> create(Master m) => guard(() async {
    final response = await _dio.post(
      '/masters',
      data: {'fullName': m.fullName, 'specialization': m.specialization},
    );
    final created = Master.fromJson(response.data as Map<String, dynamic>);
    _cache = [..._cache, created];
    return created;
  });

  Future<Master> update(Master m) => guard(() async {
    final response = await _dio.put(
      '/masters/${m.id}',
      data: {'fullName': m.fullName, 'specialization': m.specialization},
    );
    final updated = Master.fromJson(response.data as Map<String, dynamic>);
    _cache = [
      for (final x in _cache)
        if (x.id == updated.id) updated else x,
    ];
    return updated;
  });

  Future<void> delete(int id) => guard(() async {
    await _dio.delete('/masters/$id');
    _cache = _cache.where((x) => x.id != id).toList();
  });

  /// Оставлено для совместимости с интерфейсом ПР3,
  /// но серверная операция отсутствует — намеренно бросаем.
  Future<void> replaceAll(List<Master> items) async {
    throw UnsupportedError(
      'replaceAll не поддерживается API. Используйте create/update/delete.',
    );
  }
}
