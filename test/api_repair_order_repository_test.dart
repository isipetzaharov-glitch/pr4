// test/api_repair_order_repository_test.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exceptions.dart';
import 'package:flutter_application_1/models/order_query.dart';
import 'package:flutter_application_1/models/repair_order.dart';
import 'package:flutter_application_1/repositories/api_repair_order_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dio без сети: подменяем HttpClientAdapter на фиктивный.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);
  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => handler(options);

  @override
  void close({bool force = false}) {}
}

/// Собираем боевой Dio (с интерсептором), но:
/// - убираем RetryInterceptor, иначе тест «сетевой сбой»
///   зациклится на бесконечных повторных попытках;
/// - подменяем транспорт на фиктивный.
Dio _dioWith(Future<ResponseBody> Function(RequestOptions) handler) {
  final dio = buildDio();
  dio.interceptors.removeWhere((i) => i is RetryInterceptor);
  dio.httpClientAdapter = _FakeAdapter(handler);
  return dio;
}

ResponseBody _json(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

RepairOrder _sample() => const RepairOrder(
  id: 0,
  title: 'Тестовый заказ',
  vin: 'VIN0000000000099',
  year: 2020,
  clientId: 1,
  masterId: 1,
  serviceIds: [1],
  cost: 1000,
  status: 'new',
);

void main() {
  group('ApiRepairOrderRepository', () {
    test('find возвращает страницу с items/page/size/total', () async {
      final dio = _dioWith(
        (_) async => _json(200, {
          'items': [
            {
              'id': 1,
              'title': 'Замена масла',
              'vin': 'VIN0000000000001',
              'year': 2018,
              'clientId': 1,
              'masterId': 1,
              'serviceIds': [1],
              'cost': 4500,
              'status': 'done',
            },
          ],
          'page': 1,
          'size': 10,
          'total': 1,
        }),
      );
      final repo = ApiRepairOrderRepository(dio);

      final page = await repo.find(const OrderQuery());

      expect(page.items, hasLength(1));
      expect(page.items.first.title, 'Замена масла');
      expect(page.total, 1);
    });

    test('create с 422 → ValidationException с разбором полей', () async {
      final dio = _dioWith(
        (_) async => _json(422, {
          'message': 'Ошибка валидации',
          'errors': {'vin': 'VIN уже используется'},
        }),
      );
      final repo = ApiRepairOrderRepository(dio);

      expect(() => repo.create(_sample()), throwsA(isA<ValidationException>()));
    });

    test('create с 409 → ConflictException', () async {
      final dio = _dioWith(
        (_) async => _json(409, {'message': 'VIN уже используется'}),
      );
      final repo = ApiRepairOrderRepository(dio);

      expect(() => repo.create(_sample()), throwsA(isA<ConflictException>()));
    });

    test(
      'findById с 404 → null (репозиторий сам обрабатывает NotFound)',
      () async {
        final dio = _dioWith(
          (_) async => _json(404, {'message': 'Не найдено'}),
        );
        final repo = ApiRepairOrderRepository(dio);

        final order = await repo.findById(999);

        expect(order, isNull);
      },
    );

    test('сетевой сбой → NetworkException', () async {
      final dio = _dioWith((_) async {
        throw DioException(
          requestOptions: RequestOptions(path: '/orders'),
          type: DioExceptionType.connectionError,
        );
      });
      final repo = ApiRepairOrderRepository(dio);

      expect(
        () => repo.find(const OrderQuery()),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
