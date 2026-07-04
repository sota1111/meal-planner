import 'package:flutter_test/flutter_test.dart';
import 'package:meal_planner/models/fridge_item.dart';
import 'package:meal_planner/models/meal.dart';
import 'package:meal_planner/models/shopping_item.dart';

FridgeItem _fridge(String name, {int quantity = 1}) => FridgeItem(
      id: name,
      name: name,
      quantity: quantity,
      unit: FridgeUnit.piece,
    );

Meal _meal(String name, List<String> ingredients) =>
    Meal(name: name, category: MealCategory.mainDish, ingredients: ingredients);

/// 決定済み献立と在庫から買い物リストを算出する純粋関数 `computeShoppingList` の単体テスト。
void main() {
  test('在庫に無い食材だけを抽出する', () {
    final list = computeShoppingList(
      meals: [
        _meal('カレー', ['玉ねぎ', 'にんじん', 'じゃがいも']),
      ],
      fridge: [_fridge('玉ねぎ')],
    );
    expect(list.map((e) => e.name), ['にんじん', 'じゃがいも']);
  });

  test('重複食材は初出順で1件に集約し、使う料理をまとめる', () {
    final list = computeShoppingList(
      meals: [
        _meal('カレー', ['にんじん']),
        _meal('サラダ', ['にんじん', 'レタス']),
      ],
      fridge: const [],
    );
    expect(list, hasLength(2));
    expect(list[0].name, 'にんじん');
    expect(list[0].recipes, ['カレー', 'サラダ']);
    expect(list[1].name, 'レタス');
    expect(list[1].recipes, ['サラダ']);
  });

  test('在庫名が食材名に含まれる場合は在庫ありとみなす（数量付き表記）', () {
    final list = computeShoppingList(
      meals: [
        _meal('唐揚げ', ['鶏もも肉 300g', '片栗粉']),
      ],
      fridge: [_fridge('鶏もも肉')],
    );
    expect(list.map((e) => e.name), ['片栗粉']);
  });

  test('数量0以下の在庫は在庫なしとして扱う', () {
    final list = computeShoppingList(
      meals: [
        _meal('味噌汁', ['豆腐']),
      ],
      fridge: [_fridge('豆腐', quantity: 0)],
    );
    expect(list.map((e) => e.name), ['豆腐']);
  });

  test('空白のみ・空文字の食材は無視する', () {
    final list = computeShoppingList(
      meals: [
        _meal('何か', ['', '   ', 'ピーマン']),
      ],
      fridge: const [],
    );
    expect(list.map((e) => e.name), ['ピーマン']);
  });

  test('全食材が在庫にあるとき空リストを返す', () {
    final list = computeShoppingList(
      meals: [
        _meal('目玉焼き', ['卵']),
      ],
      fridge: [_fridge('卵')],
    );
    expect(list, isEmpty);
  });

  test('水・調味料はリストから除外する', () {
    final list = computeShoppingList(
      meals: [
        _meal('煮物', [
          '水 200ml',
          '塩 少々',
          '砂糖 大さじ2',
          '醤油 大さじ1',
          'ごま油',
          'にんじん',
        ]),
      ],
      fridge: const [],
    );
    // 水・調味料は除外され、実食材のにんじんだけが残る。
    expect(list.map((e) => e.name), ['にんじん']);
  });

  test('調味料名を含むが実食材のもの（塩鮭など）は除外しない', () {
    final list = computeShoppingList(
      meals: [
        _meal('焼き魚', ['塩鮭 2切れ', '大根おろし']),
      ],
      fridge: const [],
    );
    expect(list.map((e) => e.name), ['塩鮭', '大根おろし']);
  });

  test('数量違いの同じ食材は1件にまとめる', () {
    final list = computeShoppingList(
      meals: [
        _meal('唐揚げ', ['鶏もも肉 300g']),
        _meal('親子丼', ['鶏もも肉 200g']),
      ],
      fridge: const [],
    );
    expect(list, hasLength(1));
    expect(list[0].name, '鶏もも肉');
    expect(list[0].recipes, ['唐揚げ', '親子丼']);
  });
}
