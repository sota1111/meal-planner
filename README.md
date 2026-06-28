# Meal Planner（献立アプリ）プロトタイプ

家庭での「毎日の献立を考える」負担を軽減することを目的とした Flutter アプリのプロトタイプです。
冷蔵庫の在庫・スーパーの特売情報・家族の好みやアレルギーをもとに、AI（Google Gemini）が献立を自動提案します。

> **バージョン:** 1.0.0-prototype
> オンメモリ動作のプロトタイプであり、データの永続化・サーバー連携・アカウント機能はありません。

## 主な機能

| 機能 | 概要 |
| -- | -- |
| 献立カレンダー | 月カレンダーで献立登録状況を一覧。登録日はドット表示。日付タップで主菜・副菜・汁物を表示し、料理タップで詳細（食材・手順）へスライド遷移。 |
| AI献立自動生成 | 期間と気分を選び、在庫・特売品・家族設定・アレルギー・好みを踏まえて Gemini が各日3品を生成。既存の登録分は上書きしません。 |
| 在庫（冷蔵庫）管理 | 食材名・数量（整数）・単位（個/g）を登録・編集・スワイプ削除。 |
| チラシ（特売品）管理 | 商品名・価格（任意）を登録・編集・スワイプ削除。 |
| ユーザー設定 | 家族人数（1〜10）、アレルギー、好みをトグルで設定。生成時に自動参照。 |
| 画面遷移・UI | 起動時スプラッシュ→フェード遷移、4タブ（献立／在庫／チラシ／設定）のボトムナビ、日本語UI。 |

## 技術スタック

- Flutter（iOS / Android。主対象はモバイル）
- 状態管理: Riverpod（`Notifier` / `NotifierProvider`）
- AI: Google Gemini `gemini-2.5-flash`（`google_generative_ai` パッケージ）
- カレンダー: `table_calendar`
- 環境変数: `flutter_dotenv`

## セットアップ

このリポジトリには `lib/`・`pubspec.yaml`・テストなどのアプリ本体のみが含まれます。
プラットフォーム固有フォルダ（`ios/` `android/` 等）は含まれていないため、初回のみ生成してください。

```bash
# 1. プラットフォームフォルダを生成（初回のみ。lib/ や pubspec.yaml は上書きされません）
flutter create .

# 2. 依存関係を取得
flutter pub get

# 3. APIキーを設定（.env はコミットされません）
cp .env.example .env
#   .env を開いて GEMINI_API_KEY=... に実際のキーを設定
#   キーは https://aistudio.google.com/app/apikey で取得

# 4. 実行（iOSシミュレータ / Androidエミュレータ / 実機）
flutter run
```

## 検証

```bash
flutter analyze   # 静的解析（lint）
flutter test      # ウィジェットテスト
```

> 注: このプロトタイプは Flutter SDK の無い環境で作成されたため、上記コマンドはまだ実行されていません。
> 最初のレビューで `flutter pub get && flutter analyze && flutter test` を実行して確認してください。

## 既知の制限（プロトタイプ）

- データ永続化なし（アプリ再起動でリセット）
- 認証・アカウント機能なし（単一ユーザー・単一デバイス前提）
- 朝・昼・夜の個別管理なし（1日1セット＝主菜・副菜・汁物）
- 在庫の自動減算なし
- 表示言語は日本語のみ（`Locale('ja')` 固定）
- AI献立生成にはインターネット接続と Gemini APIキーが必須
- Gemini API エラーは SnackBar 表示のみ（自動リトライ未実装）

## ディレクトリ構成

```
lib/
  main.dart                      アプリ起動・ローカライズ設定
  models/                        Meal / FridgeItem / FlyerItem / UserSettings
  providers/                     Riverpod Notifier（meals / fridge / flyer / settings）
  services/gemini_service.dart   Gemini 呼び出し・プロンプト生成・JSONパース
  utils/slide_route.dart         スライド遷移ルート
  features/
    splash/                      スプラッシュ画面
    home/                        ボトムナビ（4タブ）
    calendar/                    献立カレンダー・献立詳細
    generate/                    AI献立生成
    fridge/                      在庫管理
    flyer/                       チラシ管理
    settings/                    ユーザー設定
test/widget_test.dart            起動〜メイン画面遷移のスモークテスト
```
