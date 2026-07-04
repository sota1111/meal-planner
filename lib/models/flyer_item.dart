/// チラシ（特売品）を表すモデル。価格は任意。
class FlyerItem {
  final String id;
  final String name;
  final int? price;

  const FlyerItem({
    required this.id,
    required this.name,
    this.price,
  });

  FlyerItem copyWith({
    String? name,
    int? price,
    bool clearPrice = false,
  }) {
    return FlyerItem(
      id: id,
      name: name ?? this.name,
      price: clearPrice ? null : (price ?? this.price),
    );
  }

  /// 永続化用の JSON へ変換する。
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
      };

  /// 永続化された JSON から復元する。
  factory FlyerItem.fromJson(Map<String, dynamic> json) => FlyerItem(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        price: json['price'] is int ? json['price'] as int : null,
      );
}
