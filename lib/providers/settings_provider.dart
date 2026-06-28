import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_settings.dart';

/// ユーザー設定（家族人数・アレルギー・好み）をオンメモリで保持する Notifier。
class SettingsNotifier extends Notifier<UserSettings> {
  @override
  UserSettings build() => const UserSettings();

  void setFamilySize(int size) {
    final clamped = size.clamp(1, 10);
    state = state.copyWith(familySize: clamped);
  }

  void toggleAllergy(String allergy) {
    final next = [...state.allergies];
    if (next.contains(allergy)) {
      next.remove(allergy);
    } else {
      next.add(allergy);
    }
    state = state.copyWith(allergies: next);
  }

  void togglePreference(String preference) {
    final next = [...state.preferences];
    if (next.contains(preference)) {
      next.remove(preference);
    } else {
      next.add(preference);
    }
    state = state.copyWith(preferences: next);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, UserSettings>(SettingsNotifier.new);
