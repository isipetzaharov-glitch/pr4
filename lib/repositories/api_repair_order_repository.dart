// lib/repositories/api_repair_order_repository.dart
import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/order_query.dart';
import '../models/page_result.dart';
import '../models/repair_order.dart';
import 'order_repository.dart';

class ApiRepairOrderRepository implements OrderRepository {
  final Dio _dio;
  ApiRepairOrderRepository(this._dio);

  /// Пункт 13: токен отмены последнего поискового запроса.
  CancelToken? _searchToken;

  @override
  Future<PageResult<RepairOrder>> find(OrderQuery q) => guard(() async {
    // Отменяем предыдущий запрос поиска, если он ещё не завершился.
    _searchToken?.cancel('superseded by newer query');
    _searchToken = CancelToken();

    final response = await _dio.get(
      '/orders',
      cancelToken: _searchToken,
      queryParameters: {
        if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
        if (q.serviceId != null) 'serviceId': q.serviceId,
        if (q.masterId != null) 'masterId': q.masterId,
        if (q.yearFrom != null) 'yearFrom': q.yearFrom,
        if (q.yearTo != null) 'yearTo': q.yearTo,
        'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
        'page': q.page,
        'size': q.size,
        if (q.includeDeleted) 'includeDeleted': true,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return PageResult(
      items: (data['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map(RepairOrder.fromJson)
          .toList(),
      page: (data['page'] as num?)?.toInt() ?? 1,
      size: (data['size'] as num?)?.toInt() ?? q.size,
      total: (data['total'] as num?)?.toInt() ?? 0,
    );
  });

  /// Возвращает null, если заказ не найден (404).
  /// Интерсептор превращает 404 в NotFoundException — перехватываем его здесь.
  @override
  Future<RepairOrder?> findById(int id) async {
    try {
      return await guard(() async {
        final response = await _dio.get('/orders/$id');
        return RepairOrder.fromJson(response.data as Map<String, dynamic>);
      });
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<RepairOrder> create(RepairOrder o) => guard(() async {
    final response = await _dio.post(
      '/orders',
      data: {
        'title': o.title,
        'vin': o.vin,
        'year': o.year,
        'clientId': o.clientId,
        'masterId': o.masterId,
        'serviceIds': o.serviceIds,
        'cost': o.cost,
        'status': o.status,
      },
    );
    return RepairOrder.fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<RepairOrder> update(RepairOrder o) => guard(() async {
    final response = await _dio.put(
      '/orders/${o.id}',
      data: {
        'title': o.title,
        'vin': o.vin,
        'year': o.year,
        'clientId': o.clientId,
        'masterId': o.masterId,
        'serviceIds': o.serviceIds,
        'cost': o.cost,
        'status': o.status,
      },
    );
    return RepairOrder.fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<void> softDelete(int id) => guard(() => _dio.delete('/orders/$id'));

  @override
  Future<void> hardDelete(int id) =>
      guard(() => _dio.delete('/orders/$id', queryParameters: {'hard': true}));

  @override
  Future<void> restore(int id) => guard(() => _dio.post('/orders/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
    final response = await _dio.post('/orders/bulk-delete', data: {'ids': ids});
    return (response.data as Map<String, dynamic>)['deleted'] as int? ?? 0;
  });
}
