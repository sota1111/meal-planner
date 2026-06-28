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
}
