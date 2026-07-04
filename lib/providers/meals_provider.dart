import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/meal.dart';
import '../services/persistence.dart';

/// 時刻情報を落として日付（年月日）に正規化する。
DateTime normalizeDate(DateTime date) => DateTime(date.year, date.month, date.day);

/// 正規化済みの日付を永続化キー（yyyy-MM-dd）へ変換する。
String _dateKey(DateTime date) {
  final d = normalizeDate(date);
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

/// 日付ごとの献立（主菜・副菜・汁物）を端末ローカルに永続化して保持する Notifier。
class MealsNotifier extends Notifier<Map<DateTime, List<Meal>>> {
  @override
  Map<DateTime, List<Meal>> build() => _load();

  Map<DateTime, List<Meal>> _load() {
    final prefs = ref.read(sharedPreferencesProvider);
    final raw = prefs.getString(PersistenceKeys.meals);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final result = <DateTime, List<Meal>>{};
      decoded.forEach((key, value) {
        final date = normalizeDate(DateTime.parse(key));
        final meals = (value as List<dynamic>)
            .map((e) => Meal.fromJson(e as Map<String, dynamic>))
            .toList();
        result[date] = meals;
      });
      return result;
    } catch (_) {
      // 破損データは無視して空から開始する。
      return {};
    }
  }

  void _save() {
    final prefs = ref.read(sharedPreferencesProvider);
    final map = <String, dynamic>{
      for (final entry in state.entries)
        _dateKey(entry.key): entry.value.map((m) => m.toJson()).toList(),
    };
    prefs.setString(PersistenceKeys.meals, jsonEncode(map));
  }

  /// 指定日の献立を返す（未登録なら空リスト）。
  List<Meal> mealsOn(DateTime date) => state[normalizeDate(date)] ?? const [];

  /// 指定日の献立を設定（上書き）する。
  void setMealsForDay(DateTime date, List<Meal> meals) {
    state = {...state, normalizeDate(date): meals};
    _save();
  }

  /// AI生成結果を既存データへマージする。既存の登録日は上書きしない（F-15）。
  void mergeDays(Map<DateTime, List<Meal>> generated) {
    final next = {...state};
    generated.forEach((date, meals) {
      final key = normalizeDate(date);
      final existing = next[key];
      if (existing == null || existing.isEmpty) {
        next[key] = meals;
      }
    });
    state = next;
    _save();
  }
}

final mealsProvider =
    NotifierProvider<MealsNotifier, Map<DateTime, List<Meal>>>(MealsNotifier.new);
