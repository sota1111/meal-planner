import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/fridge_item.dart';
import '../../providers/fridge_provider.dart';
import '../../services/gemini_service.dart';

/// 在庫（冷蔵庫）管理画面（F-20〜F-23）。
/// 画像から在庫を自動入力する機能を持つ（SOT-1512）。
class FridgeScreen extends ConsumerStatefulWidget {
  const FridgeScreen({super.key});

  @override
  ConsumerState<FridgeScreen> createState() => _FridgeScreenState();
}

class _FridgeScreenState extends ConsumerState<FridgeScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(fridgeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('在庫（冷蔵庫）'),
        actions: [
          IconButton(
            tooltip: '画像から在庫を自動入力',
            icon: const Icon(Icons.add_a_photo_outlined),
            onPressed: _loading ? null : () => _showAddOptions(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fridgeFab',
        onPressed: _loading ? null : () => _showAddOptions(context),
        child: const Icon(Icons.add),
      ),
      body: Stack(
        children: [
          items.isEmpty
              ? const Center(
                  child:
                      Text('在庫が登録されていません', style: TextStyle(color: Colors.grey)),
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
                        onTap: () => _showForm(context, existing: item),
                      ),
                    );
                  },
                ),
          if (_loading)
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      '画像から在庫を読み取っています…',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 指定した取得元（フォトライブラリ／カメラ）の画像を選び、AIで在庫を
  /// 読み取って一覧へ追加登録する。
  Future<void> _pickAndExtract(ImageSource source) async {
    final XFile? file;
    try {
      file = await _picker.pickImage(source: source);
    } catch (_) {
      _showSnackBar(source == ImageSource.camera
          ? 'カメラの起動に失敗しました'
          : '画像の選択に失敗しました');
      return;
    }
    if (file == null) return; // ユーザーがキャンセルした

    setState(() => _loading = true);
    try {
      final bytes = await file.readAsBytes();
      final apiKey = dotenv.maybeGet('GEMINI_API_KEY') ?? '';
      final service = GeminiService(apiKey);
      final items = await service.extractFridgeItems(
        imageBytes: bytes,
        mimeType: _mimeTypeFor(file.name),
      );
      if (items.isEmpty) {
        _showSnackBar('画像から在庫を読み取れませんでした');
        return;
      }
      final notifier = ref.read(fridgeProvider.notifier);
      for (final item in items) {
        notifier.add(item);
      }
      _showSnackBar('${items.length}件の在庫を登録しました');
    } on GeminiException catch (e) {
      _showSnackBar(e.message);
    } catch (e) {
      _showSnackBar('予期しないエラーが発生しました: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// ファイル名の拡張子から MIME タイプを推定する（判別不能時は JPEG 扱い）。
  String _mimeTypeFor(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// 「＋」ボタンから、手入力と画像からの追加を並べて選べるようにする（SOT-1512）。
  /// 画像からの在庫追加を分かりやすくするための導線。
  void _showAddOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                '在庫を追加',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('手入力で追加'),
              subtitle: const Text('食材名と数量を入力して登録します'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _showForm(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('カメラで撮影して追加'),
              subtitle: const Text('その場で撮影するとAIが在庫を読み取って登録します'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickAndExtract(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('写真から選んで追加'),
              subtitle: const Text('写真を選ぶとAIが在庫を読み取って登録します'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickAndExtract(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showForm(BuildContext context, {FridgeItem? existing}) {
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
