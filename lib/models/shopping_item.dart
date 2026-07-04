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

/// 数量・分量の表記を取り除いて食材の基本名を得る。
/// 例: 「鶏もも肉 300g」→「鶏もも肉」、「醤油 大さじ2」→「醤油」、「塩 少々」→「塩」。
/// これにより数量違いの同じ食材（「鶏もも肉 300g」と「鶏もも肉 200g」）を1件にまとめられる。
String _stripQuantity(String value) {
  var s = value.trim();
  // 大さじ/小さじ/カップ + 数量
  s = s.replaceAll(RegExp(r'(大さじ|小さじ|カップ)\s*[\d０-９/／.．]*'), '');
  // 分量を表す語
  s = s.replaceAll(RegExp(r'(お好みで|お好み|適宜|適量|少々|ひとつまみ)'), '');
  // 末尾等の「数量(+単位)」表記（数量が先頭にある表記のみ対象）
  s = s.replaceAll(
    RegExp(
      r'[\d０-９]+([/／.．][\d０-９]+)?\s*'
      r'(kg|g|ml|mL|cc|l|L|個|本|枚|袋|パック|缶|片|かけ|束|株|玉|尾|杯|合|粒|房|人前|人分|切れ|切)?',
    ),
    '',
  );
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return s.isEmpty ? value.trim() : s;
}

/// 買い物リストから除外する「水・調味料」の名称（正規化前）。
const List<String> _rawSeasonings = <String>[
  // 水
  '水', 'お湯', '湯',
  // 塩・砂糖
  '塩', '食塩', 'あら塩', '粗塩',
  '砂糖', '上白糖', 'グラニュー糖', '三温糖', 'きび砂糖',
  // 醤油・味噌・酢
  '醤油', 'しょうゆ', '薄口醤油', '濃口醤油', 'うすくち醤油', 'こいくち醤油',
  '味噌', 'みそ',
  '酢', '米酢', '穀物酢', 'りんご酢',
  // みりん・酒
  'みりん', '味醂', '本みりん',
  '酒', '料理酒', '日本酒', '清酒',
  // 油
  '油', 'サラダ油', 'ごま油', 'ゴマ油', '胡麻油', 'オリーブオイル', 'オリーブ油', '米油',
  // こしょう
  'こしょう', 'コショウ', '胡椒', '黒こしょう', '黒胡椒', '白こしょう', 'ブラックペッパー',
  // だし・スープの素
  'だし', '出汁', 'だしの素', '顆粒だし', '和風だし', 'ほんだし',
  'コンソメ', 'ブイヨン', '中華だし', '鶏がらスープの素', '鶏ガラスープの素',
  'ウェイパー', '創味シャンタン',
  // ソース類・その他調味料
  'ケチャップ', 'トマトケチャップ', 'マヨネーズ',
  'ソース', 'ウスターソース', '中濃ソース', 'オイスターソース', 'とんかつソース',
  'めんつゆ', 'ぽん酢', 'ポン酢', '焼肉のたれ', '焼き肉のたれ',
  'はちみつ', '蜂蜜', 'ハチミツ',
];

/// 除外判定用に正規化した水・調味料名の集合。
final Set<String> _seasoningKeys = _rawSeasonings.map(_normalize).toSet();

/// 食材の基本名（正規化済み）が水・調味料に該当するか。
/// 誤って実食材（例: 「塩鮭」）を除外しないよう、完全一致で判定する。
bool _isSeasoningOrWater(String normalizedBaseName) =>
    _seasoningKeys.contains(normalizedBaseName);

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
/// - 全献立の食材を初出順に集約する。数量表記を除いた基本名で正規化し、
///   数量違いの同じ食材（例: 「鶏もも肉 300g」と「鶏もも肉 200g」）は1件にまとめる。
/// - 水・調味料（塩・砂糖・醤油・油など）は買い物リストから除外する。
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
      final raw = ingredient.trim();
      if (raw.isEmpty) continue;
      final base = _stripQuantity(raw); // 数量を除いた基本名
      final key = _normalize(base);
      if (key.isEmpty) continue;
      if (_isSeasoningOrWater(key)) continue; // 水・調味料は除外
      if (_isStocked(raw, stocked)) continue;
      if (!display.containsKey(key)) {
        order.add(key);
        display[key] = base; // 表示は数量を除いた基本名
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
