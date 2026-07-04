import 'package:flutter_test/flutter_test.dart';
import 'package:meal_planner/models/fridge_item.dart';
import 'package:meal_planner/services/gemini_service.dart';

/// 画像からの在庫抽出（SOT-1512）で、AI応答JSONを FridgeItem へ変換する
/// パーサ `GeminiService.parseFridgeItems` の単体テスト。
void main() {
  test('正常なJSONから在庫食材を抽出する（単位も解釈）', () {
    const raw = '''
{
  "items": [
    { "name": "玉ねぎ", "quantity": 3, "unit": "piece" },
    { "name": "豚肉", "quantity": 200, "unit": "gram" }
  ]
}''';
    final items = GeminiService.parseFridgeItems(raw);
    expect(items, hasLength(2));
    expect(items[0].name, '玉ねぎ');
    expect(items[0].quantity, 3);
    expect(items[0].unit, FridgeUnit.piece);
    expect(items[1].name, '豚肉');
    expect(items[1].quantity, 200);
    expect(items[1].unit, FridgeUnit.gram);
    // id は一意に採番される。
    expect(items[0].id, isNot(items[1].id));
  });

  test('コードフェンス付き・不正な数量・未知の単位を補正する', () {
    const raw = '''
```json
{
  "items": [
    { "name": "にんじん", "quantity": 0, "unit": "kome" },
    { "name": "  ", "quantity": 5, "unit": "piece" },
    { "name": "牛乳", "unit": "piece" }
  ]
}
```''';
    final items = GeminiService.parseFridgeItems(raw);
    // 名前が空の要素は除外され、2件のみ残る。
    expect(items, hasLength(2));
    // 数量0は1に補正、未知の単位は個(piece)へフォールバック。
    expect(items[0].name, 'にんじん');
    expect(items[0].quantity, 1);
    expect(items[0].unit, FridgeUnit.piece);
    // quantity 欠落時は1にフォールバック。
    expect(items[1].name, '牛乳');
    expect(items[1].quantity, 1);
  });

  test('空のitemsは空リストを返す', () {
    const raw = '{ "items": [] }';
    expect(GeminiService.parseFridgeItems(raw), isEmpty);
  });

  test('解析不能なJSONは GeminiException を投げる', () {
    expect(
      () => GeminiService.parseFridgeItems('これはJSONではありません'),
      throwsA(isA<GeminiException>()),
    );
  });

  test('items フィールドが無い場合は GeminiException を投げる', () {
    expect(
      () => GeminiService.parseFridgeItems('{ "foo": 1 }'),
      throwsA(isA<GeminiException>()),
    );
  });
}
