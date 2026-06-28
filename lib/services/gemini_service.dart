import 'dart:convert';

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

  String _stripCodeFence(String text) {
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
