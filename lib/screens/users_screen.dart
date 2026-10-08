// lib/screens/users_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../state/auth_notifier.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  bool _loading = true;
  String? _error;
  List<AppUser> _users = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    // auth.user — синхронный геттер, await не нужен.
    final auth = context.read<AuthNotifier>();
    final me = auth.user;

    if (!mounted) return;
    setState(() {
      _users = me == null ? const <AppUser>[] : <AppUser>[me];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользователи'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _users.isEmpty
          ? const Center(child: Text('Список пользователей пуст'))
          : ListView.separated(
              itemCount: _users.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final u = _users[i];
                return ListTile(
                  title: Text(u.fullName),
                  subtitle: Text('${u.username} • ${u.role.label}'),
                  leading: const Icon(Icons.person),
                );
              },
            ),
    );
  }
}
