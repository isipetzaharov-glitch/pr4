// lib/repositories/api_client_repository.dart
import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/client.dart';
import '../models/page_result.dart';
import 'client_repository.dart';

class ApiClientRepository implements ClientRepository {
  final Dio _dio;
  ApiClientRepository(this._dio);

  CancelToken? _searchToken;

  @override
  Future<PageResult<Client>> find({
    String search = '',
    String sortField = 'lastName',
    bool sortAscending = true,
    int page = 1,
    int size = 10,
    bool includeDeleted = false,
  }) => guard(() async {
    _searchToken?.cancel('superseded');
    _searchToken = CancelToken();

    final response = await _dio.get(
      '/clients',
      cancelToken: _searchToken,
      queryParameters: {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        'sort': '$sortField,${sortAscending ? 'asc' : 'desc'}',
        'page': page,
        'size': size,
        if (includeDeleted) 'includeDeleted': true,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return PageResult(
      items: (data['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map(Client.fromJson)
          .toList(),
      page: (data['page'] as num?)?.toInt() ?? 1,
      size: (data['size'] as num?)?.toInt() ?? size,
      total: (data['total'] as num?)?.toInt() ?? 0,
    );
  });

  /// Возвращает null, если клиент не найден (404).
  @override
  Future<Client?> findById(int id) async {
    try {
      return await guard(() async {
        final response = await _dio.get('/clients/$id');
        return Client.fromJson(response.data as Map<String, dynamic>);
      });
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<Client> create(Client c) => guard(() async {
    final response = await _dio.post('/clients', data: c.toJson());
    return Client.fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<Client> update(Client c) => guard(() async {
    final response = await _dio.put('/clients/${c.id}', data: c.toJson());
    return Client.fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<void> softDelete(int id) => guard(() => _dio.delete('/clients/$id'));

  @override
  Future<void> restore(int id) =>
      guard(() => _dio.post('/clients/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
    final response = await _dio.post(
      '/clients/bulk-delete',
      data: {'ids': ids},
    );
    return (response.data as Map<String, dynamic>)['deleted'] as int? ?? 0;
  });

  /// Пункт 9-подобная уникальность: сервер отвечает 200 + {exists: bool},
  /// либо 409 на этапе сохранения. Здесь — предварительная проверка.
  @override
  Future<bool> emailExists(String email, {int? exceptId}) => guard(() async {
    final response = await _dio.get(
      '/clients/email-exists',
      queryParameters: {
        'email': email,
        // ignore: use_null_aware_elements
        if (exceptId != null) 'exceptId': exceptId,
      },
    );
    return (response.data as Map<String, dynamic>)['exists'] as bool? ?? false;
  });
}
