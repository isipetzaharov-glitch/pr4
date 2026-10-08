// lib/main.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api_client.dart';
import 'core/auth_api.dart';
import 'repositories/api_client_repository.dart';
import 'repositories/api_master_repository.dart';
import 'repositories/api_repair_order_repository.dart';
import 'repositories/api_service_type_repository.dart';
import 'repositories/client_repository.dart';
import 'repositories/order_repository.dart';
import 'router.dart';
import 'state/auth_notifier.dart';
import 'state/client_list_notifier.dart';
import 'state/dictionaries_notifier.dart';
import 'state/order_list_notifier.dart';
import 'widgets/inactivity_watcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();

  late AuthNotifier auth;
  late AuthApi authApi;

  final dio = buildDio(
    tokenProvider: () => auth.accessToken,
    refreshHandler: () async {
      try {
        await auth.refreshTokens();
        return true;
      } catch (_) {
        await auth.logout();
        return false;
      }
    },
  );

  authApi = AuthApi(dio);
  auth = AuthNotifier(prefs, authApi);
  await auth.restore();

  runApp(
    MultiProvider(
      providers: [
        Provider<SharedPreferences>.value(value: prefs),
        Provider<Dio>.value(value: dio),
        Provider<AuthApi>.value(value: authApi),
        ChangeNotifierProvider<AuthNotifier>.value(value: auth),

        ProxyProvider<Dio, OrderRepository>(
          update: (_, d, _) => ApiRepairOrderRepository(d),
        ),
        ProxyProvider<Dio, ClientRepository>(
          update: (_, d, _) => ApiClientRepository(d),
        ),
        ProxyProvider<Dio, ApiMasterRepository>(
          update: (_, d, _) => ApiMasterRepository(d),
        ),
        ProxyProvider<Dio, ApiServiceTypeRepository>(
          update: (_, d, _) => ApiServiceTypeRepository(d),
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
}

class AutoServiceApp extends StatelessWidget {
  const AutoServiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final router = buildRouter(auth);

    return MaterialApp.router(
      title: 'Автосервис',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      routerConfig: router,
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        if (!auth.isAuthenticated) return content;

        return InactivityWatcher(
          timeout: const Duration(minutes: 3),
          warningBefore: const Duration(seconds: 30),
          onWarning: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Сессия завершится через 30 секунд без активности',
                ),
                duration: Duration(seconds: 5),
              ),
            );
          },
          onTimeout: () async {
            // Только выход. Роутер сам редиректит на /login,
            // потому что auth.isAuthenticated станет false
            // и сработает refreshListenable.
            await auth.logout();
          },
          child: content,
        );
      },
    );
  }
}
