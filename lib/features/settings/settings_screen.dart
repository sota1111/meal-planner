import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_settings.dart';
import '../../providers/settings_provider.dart';

/// ユーザー設定画面（F-40〜F-43）。
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('家族人数', style: theme.textTheme.titleMedium),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: settings.familySize.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '${settings.familySize}人',
                  onChanged: (v) => notifier.setFamilySize(v.round()),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '${settings.familySize}人',
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('アレルギー食材', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final allergy in UserSettings.allergyOptions)
                FilterChip(
                  label: Text(allergy),
                  selected: settings.allergies.contains(allergy),
                  onSelected: (_) => notifier.toggleAllergy(allergy),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text('好み', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final preference in UserSettings.preferenceOptions)
                FilterChip(
                  label: Text(preference),
                  selected: settings.preferences.contains(preference),
                  onSelected: (_) => notifier.togglePreference(preference),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'ここで登録した設定は、AI献立生成時に自動的に参照されます。',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
