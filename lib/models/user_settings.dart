/// ユーザー設定（家族人数・アレルギー・好み）。
class UserSettings {
  final int familySize; // 1〜10
  final List<String> allergies;
  final List<String> preferences;

  const UserSettings({
    this.familySize = 2,
    this.allergies = const [],
    this.preferences = const [],
  });

  UserSettings copyWith({
    int? familySize,
    List<String>? allergies,
    List<String>? preferences,
  }) {
    return UserSettings(
      familySize: familySize ?? this.familySize,
      allergies: allergies ?? this.allergies,
      preferences: preferences ?? this.preferences,
    );
  }

  /// 永続化用の JSON へ変換する。
  Map<String, dynamic> toJson() => {
        'familySize': familySize,
        'allergies': allergies,
        'preferences': preferences,
      };

  /// 永続化された JSON から復元する。
  factory UserSettings.fromJson(Map<String, dynamic> json) {
    List<String> toStringList(dynamic value) => value is List
        ? value.map((e) => e.toString()).toList()
        : const [];
    final size = json['familySize'];
    return UserSettings(
      familySize: (size is int ? size : int.tryParse('$size') ?? 2).clamp(1, 10),
      allergies: toStringList(json['allergies']),
      preferences: toStringList(json['preferences']),
    );
  }

  /// 設定で選択可能なアレルギー候補。
  static const List<String> allergyOptions = [
    '卵',
    '乳',
    '小麦',
    'そば',
    '落花生',
    'えび',
    'かに',
    '大豆',
  ];

  /// 設定で選択可能な好み候補。
  static const List<String> preferenceOptions = [
    '和食好き',
    '洋食好き',
    '中華好き',
    'ヘルシー志向',
    'ボリューム重視',
    '時短重視',
  ];
}
