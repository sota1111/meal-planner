import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_planner/models/flyer_item.dart';
import 'package:meal_planner/models/fridge_item.dart';
import 'package:meal_planner/models/meal.dart';
import 'package:meal_planner/providers/flyer_provider.dart';
import 'package:meal_planner/providers/fridge_provider.dart';
import 'package:meal_planner/providers/meals_provider.dart';
import 'package:meal_planner/providers/settings_provider.dart';
import 'package:meal_planner/services/persistence.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 同一の SharedPreferences を共有する新しい ProviderContainer を作る。
/// アプリの再起動（Notifier の再構築）を模擬し、`build()` が永続化ストアから
/// 読み込むことを検証するために使う。
ProviderContainer _containerWith(SharedPreferences prefs) {
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('チラシは再起動後も永続化される', () async {
    final prefs = await SharedPreferences.getInstance();
    final c1 = _containerWith(prefs);
    c1.read(flyerProvider.notifier).add(
          const FlyerItem(id: 'f1', name: '牛乳', price: 198),
        );

    // 再起動を模擬（同じ prefs で新しいコンテナ）。
    final c2 = _containerWith(prefs);
    final loaded = c2.read(flyerProvider);
    expect(loaded, hasLength(1));
    expect(loaded.first.id, 'f1');
    expect(loaded.first.name, '牛乳');
    expect(loaded.first.price, 198);
  });

  test('在庫は再起動後も永続化される（単位を含む）', () async {
    final prefs = await SharedPreferences.getInstance();
    final c1 = _containerWith(prefs);
    c1.read(fridgeProvider.notifier).add(
          const FridgeItem(
            id: 'i1',
            name: '玉ねぎ',
            quantity: 3,
            unit: FridgeUnit.piece,
          ),
        );

    final c2 = _containerWith(prefs);
    final loaded = c2.read(fridgeProvider);
    expect(loaded, hasLength(1));
    expect(loaded.first.name, '玉ねぎ');
    expect(loaded.first.quantity, 3);
    expect(loaded.first.unit, FridgeUnit.piece);
  });

  test('献立は日付キーごとに再起動後も永続化される', () async {
    final prefs = await SharedPreferences.getInstance();
    final date = DateTime(2026, 7, 4);
    final c1 = _containerWith(prefs);
    c1.read(mealsProvider.notifier).setMealsForDay(date, const [
      Meal(
        name: '肉じゃが',
        category: MealCategory.mainDish,
        ingredients: ['じゃがいも', '牛肉'],
        steps: ['切る', '煮る'],
      ),
    ]);

    final c2 = _containerWith(prefs);
    final meals = c2.read(mealsProvider.notifier).mealsOn(date);
    expect(meals, hasLength(1));
    expect(meals.first.name, '肉じゃが');
    expect(meals.first.category, MealCategory.mainDish);
    expect(meals.first.ingredients, ['じゃがいも', '牛肉']);
    expect(meals.first.steps, ['切る', '煮る']);
  });

  test('設定は再起動後も永続化される', () async {
    final prefs = await SharedPreferences.getInstance();
    final c1 = _containerWith(prefs);
    c1.read(settingsProvider.notifier)
      ..setFamilySize(4)
      ..toggleAllergy('卵')
      ..togglePreference('和食好き');

    final c2 = _containerWith(prefs);
    final settings = c2.read(settingsProvider);
    expect(settings.familySize, 4);
    expect(settings.allergies, contains('卵'));
    expect(settings.preferences, contains('和食好き'));
  });

  test('削除も永続化される', () async {
    final prefs = await SharedPreferences.getInstance();
    final c1 = _containerWith(prefs);
    final notifier = c1.read(flyerProvider.notifier)
      ..add(const FlyerItem(id: 'f1', name: '牛乳'))
      ..add(const FlyerItem(id: 'f2', name: '卵'));
    notifier.remove('f1');

    final c2 = _containerWith(prefs);
    final loaded = c2.read(flyerProvider);
    expect(loaded, hasLength(1));
    expect(loaded.first.id, 'f2');
  });
}
