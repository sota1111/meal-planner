import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/shopping_item.dart';
import '../../providers/shopping_list_provider.dart';

/// お買い物リスト画面（決定済み献立の食材のうち在庫に足りないものを出力する）。
class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  /// 画面内でのみ保持する消し込み状態（食材名で管理）。永続化はしない。
  final Set<String> _checked = <String>{};

  /// 買い物リストをテキスト化してクリップボードへコピーする。
  Future<void> _copyToClipboard(List<ShoppingItem> items) async {
    final buffer = StringBuffer('お買い物リスト');
    for (final item in items) {
      buffer.write('\n・${item.name}');
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('お買い物リストをコピーしました')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(shoppingListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('お買い物リスト'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all_outlined),
            tooltip: 'コピー',
            onPressed: items.isEmpty ? null : () => _copyToClipboard(items),
          ),
        ],
      ),
      body: items.isEmpty
          ? const _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final checked = _checked.contains(item.name);
                return CheckboxListTile(
                  value: checked,
                  onChanged: (value) {
                    setState(() {
                      if (value ?? false) {
                        _checked.add(item.name);
                      } else {
                        _checked.remove(item.name);
                      }
                    });
                  },
                  title: Text(
                    item.name,
                    style: checked
                        ? const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          )
                        : null,
                  ),
                  subtitle: item.recipes.isEmpty
                      ? null
                      : Text(
                          '使う料理: ${item.recipes.join('、')}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  controlAffinity: ListTileControlAffinity.leading,
                );
              },
            ),
    );
  }
}

/// 買うものが無い（献立未登録、または全て在庫あり）ときの表示。
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 56, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            '買うものはありません',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 4),
          Text(
            '献立の食材はすべて在庫にあります',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
