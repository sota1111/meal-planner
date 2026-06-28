/// 冷蔵庫の在庫食材を表すモデル。
enum FridgeUnit { piece, gram }

extension FridgeUnitX on FridgeUnit {
  String get label {
    switch (this) {
      case FridgeUnit.piece:
        return '個';
      case FridgeUnit.gram:
        return 'g';
    }
  }
}

class FridgeItem {
  final String id;
  final String name;
  final int quantity;
  final FridgeUnit unit;

  const FridgeItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
  });

  FridgeItem copyWith({
    String? name,
    int? quantity,
    FridgeUnit? unit,
  }) {
    return FridgeItem(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
    );
  }
}
