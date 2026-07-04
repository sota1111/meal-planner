import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_settings.dart';
import '../services/persistence.dart';

/// ユーザー設定（家族人数・アレルギー・好み）を端末ローカルに永続化して保持する Notifier。
class SettingsNotifier extends Notifier<UserSettings> {
  @override
  UserSettings build() => _load();

  UserSettings _load() {
    final prefs = ref.read(sharedPreferencesProvider);
    final raw = prefs.getString(PersistenceKeys.settings);
    if (raw == null || raw.isEmpty) return const UserSettings();
    try {
      return UserSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // 破損データは無視して既定設定から開始する。
      return const UserSettings();
    }
  }

  void _save() {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString(PersistenceKeys.settings, jsonEncode(state.toJson()));
  }

  void setFamilySize(int size) {
    final clamped = size.clamp(1, 10);
    state = state.copyWith(familySize: clamped);
    _save();
  }

  void toggleAllergy(String allergy) {
    final next = [...state.allergies];
    if (next.contains(allergy)) {
      next.remove(allergy);
    } else {
      next.add(allergy);
    }
    state = state.copyWith(allergies: next);
    _save();
  }

  void togglePreference(String preference) {
    final next = [...state.preferences];
    if (next.contains(preference)) {
      next.remove(preference);
    } else {
      next.add(preference);
    }
    state = state.copyWith(preferences: next);
    _save();
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, UserSettings>(SettingsNotifier.new);
