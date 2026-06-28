import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/fridge_item.dart';

/// 在庫（冷蔵庫）食材をオンメモリで保持する Notifier。
class FridgeNotifier extends Notifier<List<FridgeItem>> {
  @override
  List<FridgeItem> build() => [];

  void add(FridgeItem item) => state = [...state, item];

  void update(FridgeItem item) =>
      state = [for (final i in state) if (i.id == item.id) item else i];

  void remove(String id) => state = state.where((i) => i.id != id).toList();
}

final fridgeProvider =
    NotifierProvider<FridgeNotifier, List<FridgeItem>>(FridgeNotifier.new);
