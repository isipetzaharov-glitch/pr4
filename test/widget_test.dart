// test/widget_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/repositories/api_client_repository.dart';
import 'package:flutter_application_1/repositories/api_master_repository.dart';
import 'package:flutter_application_1/repositories/api_repair_order_repository.dart';
import 'package:flutter_application_1/repositories/api_service_type_repository.dart';
import 'package:flutter_application_1/repositories/client_repository.dart';
import 'package:flutter_application_1/repositories/order_repository.dart';
import 'package:flutter_application_1/state/client_list_notifier.dart';
import 'package:flutter_application_1/state/dictionaries_notifier.dart';
import 'package:flutter_application_1/state/order_list_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Приложение Автосервис открывается без ошибок', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferences.getInstance();

    // Dio без сети. Список заказов отдаём пустой, чтобы приложение
    // открылось на пустом состоянии, не стучась наружу.
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {'items': [], 'page': 1, 'size': 10, 'total': 0},
            ),
          );
        },
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<Dio>.value(value: dio),
          Provider<OrderRepository>(
            create: (_) => ApiRepairOrderRepository(dio),
          ),
          Provider<ClientRepository>(create: (_) => ApiClientRepository(dio)),
          Provider<ApiMasterRepository>(
            create: (_) => ApiMasterRepository(dio),
          ),
          Provider<ApiServiceTypeRepository>(
            create: (_) => ApiServiceTypeRepository(dio),
          ),
          ChangeNotifierProvider(
            create: (ctx) => OrderListNotifier(ctx.read<OrderRepository>()),
          ),
          ChangeNotifierProvider(
            create: (ctx) => ClientListNotifier(ctx.read<ClientRepository>()),
          ),
          ChangeNotifierProvider(
            create: (ctx) => DictionariesNotifier(
              ctx.read<ClientRepository>(),
              ctx.read<ApiMasterRepository>(),
              ctx.read<ApiServiceTypeRepository>(),
            ),
          ),
        ],
        child: const AutoServiceApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Автосервис'), findsOneWidget);
  });
}
