// lib/repositories/api_service_type_repository.dart
import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/service_type.dart';

class ApiServiceTypeRepository {
  final Dio _dio;
  ApiServiceTypeRepository(this._dio);

  /// Кэш (пункт 15).
  List<ServiceType> _cache = const [];

  List<ServiceType> get all => List.unmodifiable(_cache);

  /// Сервер отдаёт список в обёртке страницы:
  ///   { "items": [...], "page": 1, "size": 10, "total": N, "totalPages": M }
  /// Поддерживаем и простой массив на случай другого сервера.
  Future<List<ServiceType>> getAll() => guard(() async {
    final response = await _dio.get('/service-types');
    final data = response.data;

    final List<dynamic> rawList = data is List
        ? data
        : (data is Map && data['items'] is List)
        ? data['items'] as List
        : const <dynamic>[];

    final list = rawList
        .whereType<Map<String, dynamic>>()
        .map(ServiceType.fromJson)
        .toList();

    _cache = list;
    return list;
  });

  /// Возвращает null, если услуга не найдена (404).
  Future<ServiceType?> findById(int id) async {
    try {
      return await guard(() async {
        final response = await _dio.get('/service-types/$id');
        return ServiceType.fromJson(response.data as Map<String, dynamic>);
      });
    } on NotFoundException {
      return null;
    }
  }

  Future<ServiceType> create(ServiceType s) => guard(() async {
    final response = await _dio.post('/service-types', data: {'name': s.name});
    final created = ServiceType.fromJson(response.data as Map<String, dynamic>);
    _cache = [..._cache, created];
    return created;
  });

  Future<ServiceType> update(ServiceType s) => guard(() async {
    final response = await _dio.put(
      '/service-types/${s.id}',
      data: {'name': s.name},
    );
    final updated = ServiceType.fromJson(response.data as Map<String, dynamic>);
    _cache = [
      for (final x in _cache)
        if (x.id == updated.id) updated else x,
    ];
    return updated;
  });

  Future<void> delete(int id) => guard(() async {
    await _dio.delete('/service-types/$id');
    _cache = _cache.where((x) => x.id != id).toList();
  });
}
