import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/flyer_provider.dart';
import '../../providers/fridge_provider.dart';
import '../../providers/meals_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/gemini_service.dart';

/// AI献立自動生成画面（F-10〜F-19）。
class GenerateScreen extends ConsumerStatefulWidget {
  const GenerateScreen({super.key});

  @override
  ConsumerState<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends ConsumerState<GenerateScreen> {
  static const List<String> _moodOptions = [
    'こってり',
    'あっさり',
    '健康的',
    '体調回復',
    'バランス良く',
  ];

  DateTimeRange? _range;
  final Set<String> _selectedMoods = {};
  bool _loading = false;

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _range,
      locale: const Locale('ja'),
    );
    if (picked != null) {
      setState(() => _range = picked);
    }
  }

  Future<void> _generate() async {
    final range = _range;
    if (range == null) {
      _showSnackBar('期間を選択してください');
      return;
    }

    setState(() => _loading = true);
    try {
      final apiKey = dotenv.maybeGet('GEMINI_API_KEY') ?? '';
      final service = GeminiService(apiKey);
      final result = await service.generateMeals(
        start: range.start,
        end: range.end,
        fridge: ref.read(fridgeProvider),
        flyer: ref.read(flyerProvider),
        settings: ref.read(settingsProvider),
        moods: _selectedMoods.toList(),
      );
      ref.read(mealsProvider.notifier).mergeDays(result);
      if (!mounted) return;
      _showSnackBar('${result.length}日分の献立を生成しました');
      Navigator.of(context).pop();
    } on GeminiException catch (e) {
      if (!mounted) return;
      _showSnackBar(e.message);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('予期しないエラーが発生しました: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/M/d', 'ja_JP');
    final rangeLabel = _range == null
        ? '期間が未選択です'
        : '${dateFormat.format(_range!.start)} 〜 ${dateFormat.format(_range!.end)}';

    return Scaffold(
      appBar: AppBar(title: const Text('AI献立を生成')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('期間', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _loading ? null : _pickRange,
                icon: const Icon(Icons.date_range),
                label: Text(rangeLabel),
              ),
              const SizedBox(height: 24),
              Text('気分', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final mood in _moodOptions)
                    FilterChip(
                      label: Text(mood),
                      selected: _selectedMoods.contains(mood),
                      onSelected: _loading
                          ? null
                          : (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedMoods.add(mood);
                                } else {
                                  _selectedMoods.remove(mood);
                                }
                              });
                            },
                    ),
                ],
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _loading ? null : _generate,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('献立を生成する'),
              ),
              const SizedBox(height: 12),
              const Text(
                '在庫・特売品・家族設定・アレルギー・好みを踏まえて、各日「主菜・副菜・汁物」を提案します。',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          if (_loading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'AIが献立を考えています...',
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
}
