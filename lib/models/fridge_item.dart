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

  /// 永続化用の JSON へ変換する。単位は列挙名で保存する。
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'unit': unit.name,
      };

  /// 永続化された JSON から復元する（不明な単位は個にフォールバック）。
  factory FridgeItem.fromJson(Map<String, dynamic> json) => FridgeItem(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        quantity: json['quantity'] is int
            ? json['quantity'] as int
            : int.tryParse('${json['quantity']}') ?? 0,
        unit: FridgeUnit.values.firstWhere(
          (u) => u.name == json['unit'],
          orElse: () => FridgeUnit.piece,
        ),
      );
}
