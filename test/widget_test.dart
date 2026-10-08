// test/widget_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/auth_api.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/repositories/api_client_repository.dart';
import 'package:flutter_application_1/repositories/api_master_repository.dart';
import 'package:flutter_application_1/repositories/api_repair_order_repository.dart';
import 'package:flutter_application_1/repositories/api_service_type_repository.dart';
import 'package:flutter_application_1/repositories/client_repository.dart';
import 'package:flutter_application_1/repositories/order_repository.dart';
import 'package:flutter_application_1/state/auth_notifier.dart';
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
    // Заглушка SharedPreferences для тестовой среды.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Dio без сети: любой запрос отвечает пустым списком.
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

    // AuthNotifier в состоянии «не авторизован»:
    // в prefs нет токенов, restore() ничего не сделает.
    final authApi = AuthApi(dio);
    final auth = AuthNotifier(prefs, authApi);
    await auth.restore();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SharedPreferences>.value(value: prefs),
          Provider<Dio>.value(value: dio),
          Provider<AuthApi>.value(value: authApi),
          ChangeNotifierProvider<AuthNotifier>.value(value: auth),

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

    // Даём асинхронным загрузкам завершиться.
    await tester.pump(const Duration(milliseconds: 500));

    // Так как пользователь не авторизован, router направит на /login.
    // На экране входа в AppBar — заголовок «Вход» и кнопка «Автосервис».
    // Проверяем, что экран логина отрисовался.
    expect(find.text('Вход'), findsOneWidget);
    expect(find.text('Автосервис'), findsAtLeastNWidgets(1));
  });
}
