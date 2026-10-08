// lib/screens/my_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../models/order_query.dart';
import '../models/repair_order.dart';
import '../repositories/order_repository.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  List<RepairOrder> _orders = [];
  bool _loading = true;
  String? _error;

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
    final repo = context.read<OrderRepository>();
    try {
      final page = await repo.find(const OrderQuery(size: 100));
      if (!mounted) return;
      setState(() {
        _orders = page.items;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заказы'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _orders.isEmpty
          ? const Center(child: Text('Заказов пока нет'))
          : ListView.separated(
              itemCount: _orders.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final o = _orders[i];
                return ListTile(
                  title: Text(o.title),
                  subtitle: Text('VIN: ${o.vin} • ${o.status}'),
                  trailing: Text('${o.cost.toStringAsFixed(0)} ₽'),
                );
              },
            ),
    );
  }
}
