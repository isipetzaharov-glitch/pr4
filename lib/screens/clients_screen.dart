// lib/screens/clients_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/client.dart';
import '../state/client_list_notifier.dart';
import '../state/order_list_notifier.dart' show LoadStatus;
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ClientListNotifier>().load();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context.read<ClientListNotifier>().setSearch(v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final n = context.watch<ClientListNotifier>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _filtersRow(context, n),
            const SizedBox(height: 8),
            if (n.hasSelection) _selectionBar(context, n),
            Expanded(child: _body(context, n)),
            if (n.status == LoadStatus.success && n.result.items.isNotEmpty)
              PaginationBar(
                page: n.result.page,
                totalPages: n.result.totalPages,
                total: n.result.total,
                size: n.result.size,
                onPageChanged: n.setPage,
                onSizeChanged: n.setSize,
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Новый клиент',
        onPressed: () => context.go('/clients/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _filtersRow(BuildContext context, ClientListNotifier n) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 260,
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Поиск: фамилия или страна',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        FilterChip(
          label: const Text('Показать удалённых'),
          selected: n.includeDeleted,
          onSelected: (v) => n.setIncludeDeleted(v),
        ),
      ],
    );
  }

  Widget _selectionBar(BuildContext context, ClientListNotifier n) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Row(
        children: [
          Text('Выбрано: ${n.selected.length}'),
          const Spacer(),
          TextButton(
            onPressed: () {
              for (final id in n.selected.toList()) {
                n.toggleSelection(id);
              }
            },
            child: const Text('Снять выделение'),
          ),
          FilledButton(
            onPressed: () async {
              final ok = await _confirm(context, 'Удалить выбранных клиентов?');
              if (ok == true) await n.deleteSelected();
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, ClientListNotifier n) {
    if (n.status == LoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (n.status == LoadStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            Text(n.error ?? 'Ошибка'),
            const SizedBox(height: 8),
            FilledButton(onPressed: n.load, child: const Text('Повторить')),
          ],
        ),
      );
    }
    if (n.result.items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Клиенты не найдены'),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 600) return _cardsList(context, n);
        return _table(context, n);
      },
    );
  }

  Widget _table(BuildContext context, ClientListNotifier n) {
    return EntityTable<Client>(
      items: n.result.items,
      idOf: (c) => c.id,
      selected: n.selected,
      onToggleSelect: n.toggleSelection,
      sortField: n.sortField,
      sortAscending: n.sortAscending,
      onSort: n.setSort,
      columns: [
        TableColumnSpec(
          label: 'Фамилия',
          sortField: 'lastName',
          build: (c) => Text(c.lastName),
        ),
        TableColumnSpec(label: 'Имя', build: (c) => Text(c.firstName)),
        TableColumnSpec(label: 'Email', build: (c) => Text(c.email)),
        TableColumnSpec(label: 'Телефон', build: (c) => Text(c.phone)),
        TableColumnSpec(
          label: 'Страна',
          sortField: 'country',
          build: (c) => Text(c.country),
        ),
        TableColumnSpec(
          label: 'Карта',
          build: (c) => Text(c.card?.number ?? '—'),
        ),
      ],
      actions: (c) => [
        IconButton(
          tooltip: 'Открыть',
          icon: const Icon(Icons.visibility),
          onPressed: () => context.go('/clients/${c.id}'),
        ),
        IconButton(
          tooltip: 'Редактировать',
          icon: const Icon(Icons.edit),
          onPressed: () => context.go('/clients/${c.id}/edit'),
        ),
        IconButton(
          tooltip: 'Удалить',
          icon: const Icon(Icons.delete),
          onPressed: () async {
            final ok = await _confirm(
              context,
              'Удалить клиента «${c.fullName}»?',
            );
            if (ok == true) await n.softDeleteOne(c.id);
          },
        ),
      ],
    );
  }

  Widget _cardsList(BuildContext context, ClientListNotifier n) {
    return ListView.separated(
      itemCount: n.result.items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final cl = n.result.items[i];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: Checkbox(
              value: n.selected.contains(cl.id),
              onChanged: (_) => n.toggleSelection(cl.id),
            ),
            title: Text(cl.fullName),
            subtitle: Text('${cl.phone}\n${cl.country}'),
            isThreeLine: true,
            onTap: () => context.go('/clients/${cl.id}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Редактировать',
                  icon: const Icon(Icons.edit),
                  onPressed: () => context.go('/clients/${cl.id}/edit'),
                ),
                IconButton(
                  tooltip: 'Удалить',
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final ok = await _confirm(context, 'Удалить клиента?');
                    if (ok == true) await n.softDeleteOne(cl.id);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Диалог подтверждения с использованием dialogContext —
  /// надёжно закрывает именно маршрут диалога.
  Future<bool?> _confirm(BuildContext context, String text) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Да'),
          ),
        ],
      ),
    );
  }
}
