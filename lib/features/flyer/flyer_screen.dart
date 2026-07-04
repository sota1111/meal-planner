import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/flyer_item.dart';
import '../../providers/flyer_provider.dart';
import '../../services/gemini_service.dart';

/// チラシ（特売品）管理画面（F-30〜F-33）。
/// 画像からチラシ情報を自動入力する機能を持つ（SOT-1515）。
class FlyerScreen extends ConsumerStatefulWidget {
  const FlyerScreen({super.key});

  @override
  ConsumerState<FlyerScreen> createState() => _FlyerScreenState();
}

class _FlyerScreenState extends ConsumerState<FlyerScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(flyerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('チラシ（特売品）'),
        actions: [
          IconButton(
            tooltip: '画像からチラシを自動入力',
            icon: const Icon(Icons.add_a_photo_outlined),
            onPressed:
                _loading ? null : () => _pickAndExtract(ImageSource.gallery),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'flyerFab',
        onPressed: _loading ? null : () => _showAddOptions(context),
        child: const Icon(Icons.add),
      ),
      body: Stack(
        children: [
          items.isEmpty
              ? const Center(
                  child: Text('特売品が登録されていません',
                      style: TextStyle(color: Colors.grey)),
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
                        trailing: Text(
                            item.price == null ? '価格未設定' : '${item.price}円'),
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
                      '画像からチラシを読み取っています…',
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

  /// 画像を取得し、AIでチラシ特売品を読み取って一覧へ追加登録する（SOT-1515）。
  /// [source] にフォトライブラリ（gallery）かカメラ撮影（camera）を指定する。
  Future<void> _pickAndExtract(ImageSource source) async {
    final XFile? file;
    try {
      file = await _picker.pickImage(source: source);
    } catch (_) {
      _showSnackBar(source == ImageSource.camera
          ? '写真の撮影に失敗しました'
          : '画像の選択に失敗しました');
      return;
    }
    if (file == null) return; // ユーザーがキャンセルした

    setState(() => _loading = true);
    try {
      final bytes = await file.readAsBytes();
      final apiKey = dotenv.maybeGet('GEMINI_API_KEY') ?? '';
      final service = GeminiService(apiKey);
      final items = await service.extractFlyerItems(
        imageBytes: bytes,
        mimeType: _mimeTypeFor(file.name),
      );
      if (items.isEmpty) {
        _showSnackBar('画像からチラシ情報を読み取れませんでした');
        return;
      }
      final notifier = ref.read(flyerProvider.notifier);
      for (final item in items) {
        notifier.add(item);
      }
      _showSnackBar('${items.length}件の特売品を登録しました');
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

  /// 「＋」ボタンから、手入力と画像からの追加を並べて選べるようにする（SOT-1515）。
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
                '特売品を追加',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('手入力で追加'),
              subtitle: const Text('商品名と価格を入力して登録します'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _showForm(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('写真から追加'),
              subtitle: const Text('フォトライブラリの写真からAIが特売品を読み取ります'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickAndExtract(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('カメラで撮影して追加'),
              subtitle: const Text('その場で撮影したチラシからAIが特売品を読み取ります'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickAndExtract(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showForm(BuildContext context, {FlyerItem? existing}) {
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
