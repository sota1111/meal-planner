import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `SharedPreferences` のインスタンスを提供する Provider。
///
/// `main()` で `SharedPreferences.getInstance()` を await し、`ProviderScope` の
/// `overrides` でこの Provider を実インスタンスに差し替える。これにより各 Notifier は
/// `build()` 内から同期的に永続化ストアへアクセスでき、状態型を非同期化せずに済む。
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope',
  ),
);

/// 永続化に使う SharedPreferences のキー定義。
class PersistenceKeys {
  const PersistenceKeys._();

  static const String flyer = 'meal_planner.flyer';
  static const String fridge = 'meal_planner.fridge';
  static const String meals = 'meal_planner.meals';
  static const String settings = 'meal_planner.settings';
}
