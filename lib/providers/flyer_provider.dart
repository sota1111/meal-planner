import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/flyer_item.dart';

/// チラシ（特売品）をオンメモリで保持する Notifier。
class FlyerNotifier extends Notifier<List<FlyerItem>> {
  @override
  List<FlyerItem> build() => [];

  void add(FlyerItem item) => state = [...state, item];

  void update(FlyerItem item) =>
      state = [for (final i in state) if (i.id == item.id) item else i];

  void remove(String id) => state = state.where((i) => i.id != id).toList();
}

final flyerProvider =
    NotifierProvider<FlyerNotifier, List<FlyerItem>>(FlyerNotifier.new);
