# Meal Planner（献立アプリ）プロトタイプ

家庭での「毎日の献立を考える」負担を軽減することを目的とした Flutter アプリのプロトタイプです。
冷蔵庫の在庫・スーパーの特売情報・家族の好みやアレルギーをもとに、AI（Google Gemini）が献立を自動提案します。

> **バージョン:** 1.0.0-prototype
> 献立・在庫・チラシ・ユーザー設定は端末ローカル（`shared_preferences`）に永続化され、アプリを再起動しても保持されます。
> サーバー連携・クラウド同期・アカウント機能はありません（データは端末内にのみ保存されます）。

## 主な機能

| 機能 | 概要 |
| -- | -- |
| 献立カレンダー | 月カレンダーで献立登録状況を一覧。登録日はドット表示。日付タップで主菜・副菜・汁物を表示し、料理タップで詳細（食材・手順）へスライド遷移。 |
| AI献立自動生成 | 期間と気分を選び、在庫・特売品・家族設定・アレルギー・好みを踏まえて Gemini が各日3品を生成。既存の登録分は上書きしません。 |
| 在庫（冷蔵庫）管理 | 食材名・数量（整数）・単位（個/g）を登録・編集・スワイプ削除。画像（冷蔵庫の写真・レシート・買い物メモ等）から Gemini が食材と数量を読み取り、在庫を自動登録。画像はカメラ撮影／フォトライブラリのどちらからでも取得可能。 |
| チラシ（特売品）管理 | 商品名・価格（任意）を登録・編集・スワイプ削除。 |
| ユーザー設定 | 家族人数（1〜10）、アレルギー、好みをトグルで設定。生成時に自動参照。 |
| 画面遷移・UI | 起動時スプラッシュ→フェード遷移、4タブ（献立／在庫／チラシ／設定）のボトムナビ、日本語UI。 |

## 技術スタック

- Flutter（iOS / Android。主対象はモバイル）
- 状態管理: Riverpod（`Notifier` / `NotifierProvider`）
- ローカル永続化: `shared_preferences`（JSON 直列化。献立・在庫・チラシ・設定を端末に保存）
- AI: Google Gemini `gemini-2.5-flash`（`google_generative_ai` パッケージ。献立生成に加え、画像からの在庫読み取りにも使用）
- 画像取得: `image_picker`（在庫画像をカメラ撮影またはフォトライブラリから取得）
- カレンダー: `table_calendar`
- 環境変数: `flutter_dotenv`

## セットアップ

このリポジトリにはアプリ本体（`lib/`・`pubspec.yaml`・テスト）に加えて `android/` を同梱しています。
**`ios/` プラットフォームフォルダは未同梱**のため、iOS で動かす場合は初回のみ生成してください
（Mac での iOS ビルド・配布の詳細は後述の「Mac で iPhone（iOS）向けにビルド・デプロイ」を参照）。

```bash
# 1. 未同梱のプラットフォームフォルダを生成（初回のみ。lib/ や pubspec.yaml は上書きされません）
#    iOS が必要なら ios/ を生成。すべて生成するなら `flutter create .`
flutter create --platforms=ios .

# 2. 依存関係を取得
flutter pub get

# 3. APIキーを設定（.env はコミットされません）
cp .env.example .env
#   .env を開いて GEMINI_API_KEY=... に実際のキーを設定
#   キーは https://aistudio.google.com/app/apikey で取得

# 4. 実行（iOSシミュレータ / Androidエミュレータ / 実機）
flutter run
```

## Mac で iPhone（iOS）向けにビルド・デプロイ

Mac 上でこのプロトタイプを iPhone（iOS）アプリとしてビルド・配布する手順です。
**iOS のビルドには macOS と Xcode が必須**で、Windows / Linux では実施できません。

### 1. 前提（Mac に用意するもの）

| 項目 | 用意方法 |
| -- | -- |
| macOS + Xcode | App Store から Xcode をインストール。初回に `sudo xcodebuild -license accept` を実行 |
| Xcode Command Line Tools | `xcode-select --install` |
| CocoaPods | `sudo gem install cocoapods`（または `brew install cocoapods`） |
| Flutter SDK | `flutter doctor` を実行し、**iOS toolchain と Xcode の項目が緑**になることを確認 |
| Apple Developer アカウント | 実機実行は無料の Apple ID でも可。TestFlight / App Store 配布には有料の Apple Developer Program 登録が必須 |

### 2. iOS プロジェクトの準備（初回のみ）

このリポジトリには `ios/` が同梱されていないため、最初に生成します。

```bash
# ios/ プラットフォームフォルダを生成（lib/ や pubspec.yaml は上書きされません）
flutter create --platforms=ios .

# APIキーを設定（未設定なら）
cp .env.example .env   # .env を開いて GEMINI_API_KEY=... を設定

# 依存関係を取得
flutter pub get
```

### 3. シミュレータで実行

```bash
open -a Simulator     # iOS シミュレータを起動
flutter devices       # 認識されたデバイスを確認
flutter run           # 起動中のシミュレータで実行（-d <device-id> で指定も可）
```

### 4. 実機（iPhone）で実行

1. iPhone を Mac に USB 接続し、デバイス側で「このコンピュータを信頼」を選択。
2. `open ios/Runner.xcworkspace` で Xcode を開く。
3. **Runner** ターゲット → **Signing & Capabilities** で、自分の Apple ID（Team）を選択し、
   **Bundle Identifier** を一意な値（例: `com.<yourname>.mealplanner`）に変更。
4. 初回はデバイス側で **設定 > 一般 > VPNとデバイス管理** から開発者プロファイルを信頼。
5. `flutter run -d <iphone-device-id>`（`flutter devices` で ID を確認）、または Xcode の ▶ Run で実行。

### 5. リリースビルド・配布（TestFlight / App Store）

```bash
# 署名済みの IPA を生成（build/ios/ipa/ に出力）
flutter build ipa
```

1. `flutter build ipa` で `build/ios/ipa/*.ipa` を生成（署名設定は手順4のものを使用）。
2. **Xcode の Organizer**（Window > Organizer）または **Transporter** アプリ、`xcrun altool` で
   App Store Connect へアップロード。
3. App Store Connect の **TestFlight** で内部テスターに配布して動作確認。
4. 審査を経て **App Store** で公開。
5. ※ TestFlight / App Store への配布には有料の **Apple Developer Program** 登録が必須です。

### よくあるハマりどころ

- **`pod install` 失敗 / CocoaPods 未導入** → `cd ios && pod install`（CocoaPods を再インストール）。
- **署名エラー（No signing certificate / provisioning）** → Bundle ID を一意にし、Team 設定を再確認。
- **`flutter doctor` の iOS 項目が赤** → Xcode 本体・Command Line Tools・CocoaPods のいずれかが未導入。
- AI献立生成を試す場合は `.env` の `GEMINI_API_KEY` を設定（未設定でも UI 操作は可能）。

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
