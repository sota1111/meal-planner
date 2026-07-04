import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/shopping_item.dart';
import 'fridge_provider.dart';
import 'meals_provider.dart';

/// 決定済みの全献立と在庫から、買うべき（在庫に足りない）食材のリストを導出する。
final shoppingListProvider = Provider<List<ShoppingItem>>((ref) {
  final mealsByDate = ref.watch(mealsProvider);
  final fridge = ref.watch(fridgeProvider);
  final meals = mealsByDate.values.expand((list) => list);
  return computeShoppingList(meals: meals, fridge: fridge);
});
