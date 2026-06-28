import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/fridge_item.dart';
import '../../providers/fridge_provider.dart';

/// 在庫（冷蔵庫）管理画面（F-20〜F-23）。
class FridgeScreen extends ConsumerWidget {
  const FridgeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(fridgeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('在庫（冷蔵庫）')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fridgeFab',
        onPressed: () => _showForm(context, ref),
        child: const Icon(Icons.add),
      ),
      body: items.isEmpty
          ? const Center(
              child: Text('在庫が登録されていません', style: TextStyle(color: Colors.grey)),
            )
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Dismissible(
                  key: ValueKey(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) =>
                      ref.read(fridgeProvider.notifier).remove(item.id),
                  child: ListTile(
                    leading: const Icon(Icons.kitchen),
                    title: Text(item.name),
                    trailing: Text('${item.quantity}${item.unit.label}'),
                    onTap: () => _showForm(context, ref, existing: item),
                  ),
                );
              },
            ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref, {FridgeItem? existing}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FridgeFormSheet(ref: ref, existing: existing),
    );
  }
}

class _FridgeFormSheet extends StatefulWidget {
  final WidgetRef ref;
  final FridgeItem? existing;

  const _FridgeFormSheet({required this.ref, this.existing});

  @override
  State<_FridgeFormSheet> createState() => _FridgeFormSheetState();
}

class _FridgeFormSheetState extends State<_FridgeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late FridgeUnit _unit;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _quantityController =
        TextEditingController(text: e == null ? '' : e.quantity.toString());
    _unit = e?.unit ?? FridgeUnit.piece;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final notifier = widget.ref.read(fridgeProvider.notifier);
    final quantity = int.parse(_quantityController.text);
    final existing = widget.existing;
    if (existing == null) {
      notifier.add(FridgeItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        quantity: quantity,
        unit: _unit,
      ));
    } else {
      notifier.update(existing.copyWith(
        name: _nameController.text.trim(),
        quantity: quantity,
        unit: _unit,
      ));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? '在庫を追加' : '在庫を編集',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '食材名'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '食材名を入力してください' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(labelText: '数量'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.isEmpty) return '数量を入力してください';
                      final n = int.tryParse(v);
                      if (n == null || n <= 0) return '1以上の整数を入力してください';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<FridgeUnit>(
                  value: _unit,
                  items: FridgeUnit.values
                      .map((u) => DropdownMenuItem(
                            value: u,
                            child: Text(u.label),
                          ))
                      .toList(),
                  onChanged: (u) => setState(() => _unit = u ?? _unit),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('保存')),
          ],
        ),
      ),
    );
  }
}
