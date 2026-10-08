// lib/screens/app_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../state/auth_notifier.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final loc = GoRouterState.of(context).uri.toString();
    final isReader = auth.user?.role == Role.reader;

    final idx = isReader
        ? (loc.startsWith('/my-orders') ? 1 : 0)
        : loc.startsWith('/clients')
        ? 1
        : loc.startsWith('/masters')
        ? 2
        : loc.startsWith('/services')
        ? 3
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Автосервис'),
        actions: [
          if (auth.user != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${auth.user!.fullName} (${auth.user!.role.label})',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Главная',
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/'),
          ),
          IconButton(
            tooltip: 'Выйти',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthNotifier>().logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: _buildBar(context, isReader, idx),
    );
  }

  Widget _buildBar(BuildContext context, bool isReader, int idx) {
    final destinations = <NavigationDestination>[
      const NavigationDestination(icon: Icon(Icons.build), label: 'Заказы'),
      if (isReader)
        const NavigationDestination(
          icon: Icon(Icons.assignment_ind),
          label: 'Мои заказы',
        )
      else ...[
        const NavigationDestination(icon: Icon(Icons.people), label: 'Клиенты'),
        const NavigationDestination(
          icon: Icon(Icons.handyman),
          label: 'Мастера',
        ),
        const NavigationDestination(
          icon: Icon(Icons.construction),
          label: 'Услуги',
        ),
      ],
    ];

    return NavigationBar(
      selectedIndex: idx.clamp(0, destinations.length - 1),
      onDestinationSelected: (i) {
        if (isReader) {
          if (i == 0) context.go('/orders');
          if (i == 1) context.go('/my-orders');
        } else {
          switch (i) {
            case 0:
              context.go('/orders');
              break;
            case 1:
              context.go('/clients');
              break;
            case 2:
              context.go('/masters');
              break;
            case 3:
              context.go('/services');
              break;
          }
        }
      },
      destinations: destinations,
    );
  }
}
