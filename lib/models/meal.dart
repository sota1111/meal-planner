/// 献立の1品を表すモデル（料理名・カテゴリ・食材・調理手順）。
enum MealCategory { mainDish, sideDish, soup }

extension MealCategoryX on MealCategory {
  /// 画面表示・AIプロンプト用の日本語ラベル。
  String get label {
    switch (this) {
      case MealCategory.mainDish:
        return '主菜';
      case MealCategory.sideDish:
        return '副菜';
      case MealCategory.soup:
        return '汁物';
    }
  }

  /// 日本語ラベルから列挙値へ変換（不明な場合は主菜にフォールバック）。
  static MealCategory fromLabel(String? value) {
    switch (value) {
      case '主菜':
        return MealCategory.mainDish;
      case '副菜':
        return MealCategory.sideDish;
      case '汁物':
        return MealCategory.soup;
      default:
        return MealCategory.mainDish;
    }
  }
}

class Meal {
  final String name;
  final MealCategory category;
  final List<String> ingredients;
  final List<String> steps;

  const Meal({
    required this.name,
    required this.category,
    this.ingredients = const [],
    this.steps = const [],
  });

  /// AIレスポンス（JSON）の1品から生成する。
  factory Meal.fromJson(Map<String, dynamic> json) {
    List<String> toStringList(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return const [];
    }

    return Meal(
      name: (json['name'] ?? '').toString(),
      category: MealCategoryX.fromLabel(json['category']?.toString()),
      ingredients: toStringList(json['ingredients']),
      steps: toStringList(json['steps']),
    );
  }

  /// 永続化用の JSON へ変換する（カテゴリは日本語ラベルで保存し `fromJson` と対称）。
  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category.label,
        'ingredients': ingredients,
        'steps': steps,
      };
}
