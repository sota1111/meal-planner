import 'dart:convert';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';

import '../models/flyer_item.dart';
import '../models/fridge_item.dart';
import '../models/meal.dart';
import '../models/user_settings.dart';

/// AI献立生成に失敗したことを表す例外。UI側で SnackBar 表示に使う（F-19）。
class GeminiException implements Exception {
  final String message;
  GeminiException(this.message);

  @override
  String toString() => message;
}

/// Google Gemini を用いて指定期間の献立を生成するサービス（F-10〜F-18）。
class GeminiService {
  final String apiKey;
  static const String _modelName = 'gemini-2.5-flash';

  GeminiService(this.apiKey);

  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  /// 期間・在庫・特売品・家族構成・アレルギー・好み・気分から献立を生成する。
  /// 戻り値は日付 → その日の献立（主菜・副菜・汁物）のマップ。
  Future<Map<DateTime, List<Meal>>> generateMeals({
    required DateTime start,
    required DateTime end,
    required List<FridgeItem> fridge,
    required List<FlyerItem> flyer,
    required UserSettings settings,
    required List<String> moods,
  }) async {
    if (apiKey.isEmpty) {
      throw GeminiException('Gemini APIキーが設定されていません。.env を確認してください。');
    }

    final prompt = _buildPrompt(
      start: start,
      end: end,
      fridge: fridge,
      flyer: flyer,
      settings: settings,
      moods: moods,
    );

    try {
      final model = GenerativeModel(
        model: _modelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
      );
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw GeminiException('AIから空の応答が返されました。');
      }
      return _parseResponse(text);
    } on GeminiException {
      rethrow;
    } catch (e) {
      throw GeminiException('献立の生成に失敗しました: $e');
    }
  }

  /// 画像から在庫食材を読み取り、登録可能な食材リストを返す（SOT-1512）。
  ///
  /// [imageBytes] は選択した画像のバイト列、[mimeType] は `image/jpeg` などの MIME タイプ。
  /// 冷蔵庫の写真・レシート・買い物メモなどから食材名・数量・単位を推定する。
  Future<List<FridgeItem>> extractFridgeItems({
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    if (apiKey.isEmpty) {
      throw GeminiException('Gemini APIキーが設定されていません。.env を確認してください。');
    }

    try {
      final model = GenerativeModel(
        model: _modelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
      );
      final response = await model.generateContent([
        Content.multi([
          TextPart(_fridgeExtractionPrompt),
          DataPart(mimeType, imageBytes),
        ]),
      ]);
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw GeminiException('AIから空の応答が返されました。');
      }
      return parseFridgeItems(text);
    } on GeminiException {
      rethrow;
    } catch (e) {
      throw GeminiException('画像からの在庫読み取りに失敗しました: $e');
    }
  }

  static const String _fridgeExtractionPrompt = '''
あなたは家庭の食材在庫を読み取るアシスタントです。
渡された画像（冷蔵庫の中身の写真、レシート、手書きの買い物メモなど）に写っている
食材とその数量を読み取り、在庫として登録できる形式で列挙してください。

# ルール
- 食材（食品）のみを対象とし、食品以外の物は無視すること。
- 数量が読み取れない場合は 1 とすること。
- 単位は個数で数えるものを "piece"、重さ（グラム）で表すものを "gram" とすること。判断できない場合は "piece"。
- 同じ食材が複数写っている場合は数量を合算して1件にまとめること。
- 食材が1つも読み取れない場合は items を空配列にすること。

# 出力形式（JSONのみ。前後に説明文やコードブロック記法を付けないこと）
{
  "items": [
    { "name": "食材名", "quantity": 正の整数, "unit": "piece" または "gram" }
  ]
}
''';

  /// 在庫抽出AIの応答（JSON文字列）を [FridgeItem] のリストへ変換する。
  ///
  /// UI から独立してテスト可能な純粋関数。名前が空の要素は除外し、数量が不正なら 1 に補正、
  /// 未知の単位は「個」にフォールバックする。各要素には一意な id を採番する。
  static List<FridgeItem> parseFridgeItems(String raw) {
    final cleaned = _stripCodeFence(raw);
    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      throw GeminiException('AI応答の解析に失敗しました。');
    }

    final items = decoded['items'];
    if (items is! List) {
      throw GeminiException('AI応答に在庫データが含まれていません。');
    }

    final baseId = DateTime.now().microsecondsSinceEpoch;
    final result = <FridgeItem>[];
    var seq = 0;
    for (final item in items) {
      if (item is! Map) continue;
      final name = (item['name'] ?? '').toString().trim();
      if (name.isEmpty) continue;
      final rawQty = item['quantity'];
      var quantity =
          rawQty is int ? rawQty : int.tryParse('$rawQty') ?? 1;
      if (quantity <= 0) quantity = 1;
      final unit = FridgeUnit.values.firstWhere(
        (u) => u.name == item['unit'],
        orElse: () => FridgeUnit.piece,
      );
      result.add(FridgeItem(
        id: '${baseId}_${seq++}',
        name: name,
        quantity: quantity,
        unit: unit,
      ));
    }
    return result;
  }

  String _buildPrompt({
    required DateTime start,
    required DateTime end,
    required List<FridgeItem> fridge,
    required List<FlyerItem> flyer,
    required UserSettings settings,
    required List<String> moods,
  }) {
    final dates = <String>[];
    for (var d = DateTime(start.year, start.month, start.day);
        !d.isAfter(end);
        d = d.add(const Duration(days: 1))) {
      dates.add(_dateFormat.format(d));
    }

    final fridgeText = fridge.isEmpty
        ? 'なし'
        : fridge.map((f) => '${f.name} ${f.quantity}${f.unit.label}').join('、');
    final flyerText = flyer.isEmpty
        ? 'なし'
        : flyer
            .map((f) => f.price == null ? f.name : '${f.name}(${f.price}円)')
            .join('、');
    final allergyText =
        settings.allergies.isEmpty ? 'なし' : settings.allergies.join('、');
    final preferenceText =
        settings.preferences.isEmpty ? 'なし' : settings.preferences.join('、');
    final moodText = moods.isEmpty ? '指定なし' : moods.join('、');

    return '''
あなたは日本の家庭料理に詳しい献立アドバイザーです。
以下の条件をもとに、対象期間の各日について献立を作成してください。

# 対象期間
${dates.join('、')}

# 条件
- 家族人数: ${settings.familySize}人
- 在庫食材: $fridgeText
- 特売品: $flyerText
- アレルギー食材: $allergyText
- 好み: $preferenceText
- 気分: $moodText

# 作成ルール
- 各日について「主菜」「副菜」「汁物」の3品を必ず提案すること。
- 各品には料理名・食材リスト・調理手順を含めること。
- アレルギー食材は一切使用しないこと。
- 在庫食材と特売品を優先的に使用すること。
- 調理時間は1品あたり30分以内を目安とし、日本の一般家庭で作れる料理にすること。

# 出力形式（JSONのみ。前後に説明文やコードブロック記法を付けないこと）
{
  "days": [
    {
      "date": "YYYY-MM-DD",
      "meals": [
        {
          "name": "料理名",
          "category": "主菜",
          "ingredients": ["食材1", "食材2"],
          "steps": ["手順1", "手順2"]
        }
      ]
    }
  ]
}
''';
  }

  /// マークダウンのコードブロック記法を除去して JSON をパースする。
  Map<DateTime, List<Meal>> _parseResponse(String raw) {
    final cleaned = _stripCodeFence(raw);
    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      throw GeminiException('AI応答の解析に失敗しました。');
    }

    final days = decoded['days'];
    if (days is! List) {
      throw GeminiException('AI応答に献立データが含まれていません。');
    }

    final result = <DateTime, List<Meal>>{};
    for (final day in days) {
      if (day is! Map) continue;
      final dateStr = day['date']?.toString();
      if (dateStr == null) continue;
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;

      final mealsJson = day['meals'];
      if (mealsJson is! List) continue;
      final meals = mealsJson
          .whereType<Map>()
          .map((m) => Meal.fromJson(Map<String, dynamic>.from(m)))
          .where((m) => m.name.isNotEmpty)
          .toList();
      if (meals.isNotEmpty) {
        result[DateTime(date.year, date.month, date.day)] = meals;
      }
    }

    if (result.isEmpty) {
      throw GeminiException('生成された献立が空でした。もう一度お試しください。');
    }
    return result;
  }

  static String _stripCodeFence(String text) {
    var t = text.trim();
    if (t.startsWith('```')) {
      // 先頭の ``` または ```json を除去
      final firstNewline = t.indexOf('\n');
      if (firstNewline != -1) {
        t = t.substring(firstNewline + 1);
      }
      if (t.endsWith('```')) {
        t = t.substring(0, t.length - 3);
      }
    }
    return t.trim();
  }
}
