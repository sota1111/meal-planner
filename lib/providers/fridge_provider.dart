import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/fridge_item.dart';
import '../services/persistence.dart';

/// 在庫（冷蔵庫）食材を端末ローカルに永続化して保持する Notifier。
class FridgeNotifier extends Notifier<List<FridgeItem>> {
  @override
  List<FridgeItem> build() => _load();

  List<FridgeItem> _load() {
    final prefs = ref.read(sharedPreferencesProvider);
    final raw = prefs.getString(PersistenceKeys.fridge);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => FridgeItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // 破損データは無視して空から開始する。
      return [];
    }
  }

  void _save() {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString(
      PersistenceKeys.fridge,
      jsonEncode(state.map((i) => i.toJson()).toList()),
    );
  }

  void add(FridgeItem item) {
    state = [...state, item];
    _save();
  }

  void update(FridgeItem item) {
    state = [for (final i in state) if (i.id == item.id) item else i];
    _save();
  }

  void remove(String id) {
    state = state.where((i) => i.id != id).toList();
    _save();
  }
}

final fridgeProvider =
    NotifierProvider<FridgeNotifier, List<FridgeItem>>(FridgeNotifier.new);
