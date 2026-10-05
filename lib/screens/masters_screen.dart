// lib/screens/masters_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../models/master.dart';
import '../models/order_query.dart';
import '../repositories/api_master_repository.dart';
import '../repositories/order_repository.dart';
import 'master_form_screen.dart';

class MastersScreen extends StatefulWidget {
  const MastersScreen({super.key});

  @override
  State<MastersScreen> createState() => _MastersScreenState();
}

class _MastersScreenState extends State<MastersScreen> {
  List<Master> _masters = [];
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

    final repo = context.read<ApiMasterRepository>();
    try {
      final list = await repo.getAll();
      if (!mounted) return;
      setState(() {
        _masters = list;
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

  Future<void> _tryDelete(Master m) async {
    final ordersRepo = context.read<OrderRepository>();
    final masterRepo = context.read<ApiMasterRepository>();

    // Пункт 13 (ПР3): считаем связанные заказы.
    final page = await ordersRepo.find(
      const OrderQuery(size: 1000, includeDeleted: true),
    );
    final linked = page.items.where((o) => o.masterId == m.id).length;

    if (!mounted) return;

    if (linked > 0) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Удаление невозможно'),
          content: Text(
            'На мастера «${m.fullName}» ссылаются $linked заказ(ов). '
            'Сначала удалите или переназначьте их.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Понятно'),
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить мастера?'),
        content: Text('Мастер «${m.fullName}» будет удалён.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    if (!mounted) return;

    try {
      await masterRepo.delete(m.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Мастер удалён')));
      await _load();
    } on ConflictException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мастера'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MasterFormScreen()),
              );
              if (!mounted) return;
              await _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 8),
                  Text(_error!),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _load,
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            )
          : _masters.isEmpty
          ? const Center(child: Text('Список мастеров пуст'))
          : ListView.separated(
              itemCount: _masters.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final m = _masters[i];
                return ListTile(
                  title: Text(m.fullName),
                  subtitle: Text(m.specialization),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MasterFormScreen(id: m.id),
                            ),
                          );
                          if (!mounted) return;
                          await _load();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _tryDelete(m),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
