import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/meal.dart';

/// 時刻情報を落として日付（年月日）に正規化する。
DateTime normalizeDate(DateTime date) => DateTime(date.year, date.month, date.day);

/// 日付ごとの献立（主菜・副菜・汁物）をオンメモリで保持する Notifier。
class MealsNotifier extends Notifier<Map<DateTime, List<Meal>>> {
  @override
  Map<DateTime, List<Meal>> build() => {};

  /// 指定日の献立を返す（未登録なら空リスト）。
  List<Meal> mealsOn(DateTime date) => state[normalizeDate(date)] ?? const [];

  /// 指定日の献立を設定（上書き）する。
  void setMealsForDay(DateTime date, List<Meal> meals) {
    state = {...state, normalizeDate(date): meals};
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
  }
}

final mealsProvider =
    NotifierProvider<MealsNotifier, Map<DateTime, List<Meal>>>(MealsNotifier.new);
