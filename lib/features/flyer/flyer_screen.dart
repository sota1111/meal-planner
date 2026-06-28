import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/flyer_item.dart';
import '../../providers/flyer_provider.dart';

/// チラシ（特売品）管理画面（F-30〜F-33）。
class FlyerScreen extends ConsumerWidget {
  const FlyerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(flyerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('チラシ（特売品）')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, ref),
        child: const Icon(Icons.add),
      ),
      body: items.isEmpty
          ? const Center(
              child: Text('特売品が登録されていません', style: TextStyle(color: Colors.grey)),
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
                      ref.read(flyerProvider.notifier).remove(item.id),
                  child: ListTile(
                    leading: const Icon(Icons.local_offer),
                    title: Text(item.name),
                    trailing: Text(item.price == null ? '価格未設定' : '${item.price}円'),
                    onTap: () => _showForm(context, ref, existing: item),
                  ),
                );
              },
            ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref, {FlyerItem? existing}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FlyerFormSheet(ref: ref, existing: existing),
    );
  }
}

class _FlyerFormSheet extends StatefulWidget {
  final WidgetRef ref;
  final FlyerItem? existing;

  const _FlyerFormSheet({required this.ref, this.existing});

  @override
  State<_FlyerFormSheet> createState() => _FlyerFormSheetState();
}

class _FlyerFormSheetState extends State<_FlyerFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _priceController =
        TextEditingController(text: e?.price?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final notifier = widget.ref.read(flyerProvider.notifier);
    final priceText = _priceController.text.trim();
    final price = priceText.isEmpty ? null : int.tryParse(priceText);
    final existing = widget.existing;
    if (existing == null) {
      notifier.add(FlyerItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        price: price,
      ));
    } else {
      notifier.update(FlyerItem(
        id: existing.id,
        name: _nameController.text.trim(),
        price: price,
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
              widget.existing == null ? '特売品を追加' : '特売品を編集',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '商品名'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '商品名を入力してください' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: '価格（任意）',
                suffixText: '円',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('保存')),
          ],
        ),
      ),
    );
  }
}
