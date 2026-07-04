import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/flyer_item.dart';
import '../services/persistence.dart';

/// チラシ（特売品）を端末ローカルに永続化して保持する Notifier。
class FlyerNotifier extends Notifier<List<FlyerItem>> {
  @override
  List<FlyerItem> build() => _load();

  List<FlyerItem> _load() {
    final prefs = ref.read(sharedPreferencesProvider);
    final raw = prefs.getString(PersistenceKeys.flyer);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => FlyerItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // 破損データは無視して空から開始する。
      return [];
    }
  }

  void _save() {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString(
      PersistenceKeys.flyer,
      jsonEncode(state.map((i) => i.toJson()).toList()),
    );
  }

  void add(FlyerItem item) {
    state = [...state, item];
    _save();
  }

  void update(FlyerItem item) {
    state = [for (final i in state) if (i.id == item.id) item else i];
    _save();
  }

  void remove(String id) {
    state = state.where((i) => i.id != id).toList();
    _save();
  }
}

final flyerProvider =
    NotifierProvider<FlyerNotifier, List<FlyerItem>>(FlyerNotifier.new);
