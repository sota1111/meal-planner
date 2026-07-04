import 'package:flutter_test/flutter_test.dart';
import 'package:meal_planner/services/gemini_service.dart';

/// 画像からのチラシ抽出（SOT-1515）で、AI応答JSONを FlyerItem へ変換する
/// パーサ `GeminiService.parseFlyerItems` の単体テスト。
void main() {
  test('正常なJSONからチラシ特売品を抽出する（価格も解釈）', () {
    const raw = '''
{
  "items": [
    { "name": "豚こま肉", "price": 298 },
    { "name": "キャベツ", "price": null }
  ]
}''';
    final items = GeminiService.parseFlyerItems(raw);
    expect(items, hasLength(2));
    expect(items[0].name, '豚こま肉');
    expect(items[0].price, 298);
    expect(items[1].name, 'キャベツ');
    expect(items[1].price, isNull);
    // id は一意に採番される。
    expect(items[0].id, isNot(items[1].id));
  });

  test('コードフェンス付き・不正な価格・空名を補正する', () {
    const raw = '''
```json
{
  "items": [
    { "name": "牛乳", "price": 0 },
    { "name": "  ", "price": 100 },
    { "name": "卵", "price": "170" }
  ]
}
```''';
    final items = GeminiService.parseFlyerItems(raw);
    // 名前が空の要素は除外され、2件のみ残る。
    expect(items, hasLength(2));
    // 価格0以下は価格未設定(null)へフォールバック。
    expect(items[0].name, '牛乳');
    expect(items[0].price, isNull);
    // 文字列の数値は整数へパースされる。
    expect(items[1].name, '卵');
    expect(items[1].price, 170);
  });

  test('空のitemsは空リストを返す', () {
    const raw = '{ "items": [] }';
    expect(GeminiService.parseFlyerItems(raw), isEmpty);
  });

  test('解析不能なJSONは GeminiException を投げる', () {
    expect(
      () => GeminiService.parseFlyerItems('これはJSONではありません'),
      throwsA(isA<GeminiException>()),
    );
  });

  test('items フィールドが無い場合は GeminiException を投げる', () {
    expect(
      () => GeminiService.parseFlyerItems('{ "foo": 1 }'),
      throwsA(isA<GeminiException>()),
    );
  });
}
