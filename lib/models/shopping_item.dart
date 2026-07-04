import 'fridge_item.dart';
import 'meal.dart';

/// お買い物リストの1項目（買うべき食材名と、その食材を使う料理名の一覧）。
class ShoppingItem {
  final String name;
  final List<String> recipes;

  const ShoppingItem({required this.name, this.recipes = const []});
}

/// マッチング用に食材名を正規化する（前後空白除去・小文字化・空白類の除去）。
String _normalize(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');

/// 在庫に「足りている」と判定できる正規化済み在庫名の集合を作る。
/// 在庫数が0以下の食材は在庫なしとして扱う。
Set<String> _stockedNames(Iterable<FridgeItem> fridge) {
  final result = <String>{};
  for (final item in fridge) {
    if (item.quantity <= 0) continue;
    final normalized = _normalize(item.name);
    if (normalized.isEmpty) continue;
    result.add(normalized);
  }
  return result;
}

/// 食材が在庫でカバーされているか判定する。
/// 在庫名が食材名に含まれる、または食材名が在庫名に含まれる場合は在庫ありとみなす
/// （例: 在庫「鶏もも肉」で献立食材「鶏もも肉 300g」をカバー）。
bool _isStocked(String ingredient, Set<String> stocked) {
  final normalized = _normalize(ingredient);
  if (normalized.isEmpty) return true; // 空文字はリストに載せない
  for (final name in stocked) {
    if (normalized.contains(name) || name.contains(normalized)) return true;
  }
  return false;
}

/// 決定済みの献立から、在庫に足りない食材だけを抽出したお買い物リストを算出する。
///
/// - 全献立の食材を初出順に集約し、正規化して重複を除外する。
/// - 在庫（数量>0）でカバーされない食材のみを対象にする。
/// - 各食材について、それを使う料理名を `recipes` にまとめる。
List<ShoppingItem> computeShoppingList({
  required Iterable<Meal> meals,
  required Iterable<FridgeItem> fridge,
}) {
  final stocked = _stockedNames(fridge);

  // 正規化キー -> 表示名 / 料理名一覧 を初出順で保持する。
  final order = <String>[];
  final display = <String, String>{};
  final recipes = <String, List<String>>{};

  for (final meal in meals) {
    for (final ingredient in meal.ingredients) {
      final name = ingredient.trim();
      if (name.isEmpty) continue;
      if (_isStocked(name, stocked)) continue;
      final key = _normalize(name);
      if (key.isEmpty) continue;
      if (!display.containsKey(key)) {
        order.add(key);
        display[key] = name;
        recipes[key] = <String>[];
      }
      final mealName = meal.name.trim();
      if (mealName.isNotEmpty && !recipes[key]!.contains(mealName)) {
        recipes[key]!.add(mealName);
      }
    }
  }

  return [
    for (final key in order)
      ShoppingItem(name: display[key]!, recipes: recipes[key]!),
  ];
}
