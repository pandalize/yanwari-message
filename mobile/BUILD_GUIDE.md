# やんわり伝言 Flutter モバイルアプリ - ビルドガイド

このドキュメントでは、やんわり伝言Flutterモバイルアプリの実機テスト用ビルド方法を説明します。

## 📋 前提条件

### 必要なツール
- **Flutter SDK 3.24.5+**: `/Users/fujinoyuki/development/flutter/bin/flutter`
- **Dart SDK 3.5.4+**: Flutter SDKに含まれています
- **Xcode**: iOS開発用（macOSのみ）
- **Android Studio**: Android開発用（オプション）
- **Firebase CLI**: Firebase設定用

### 環境変数設定
```bash
# Flutter SDKのパスを追加
export PATH="$PATH:/Users/fujinoyuki/development/flutter/bin"

# FlutterFire CLIのパスを追加（必要に応じて）
export PATH="$PATH:$HOME/.pub-cache/bin"
```

## 🔧 初期セットアップ

### 1. 依存関係のインストール
```bash
cd mobile
flutter pub get
```

### 2. Firebase設定確認
現在のFirebase設定（`lib/main.dart`）:
```dart
await Firebase.initializeApp(
  options: const FirebaseOptions(
    apiKey: "AIzaSyDMN2wUjE6NicanP0KP8ybnPgJZloMNOoI",
    authDomain: "yanwari-message.firebaseapp.com", 
    projectId: "yanwari-message",
    storageBucket: "yanwari-message.appspot.com",
    messagingSenderId: "24525991821",
    appId: "1:24525991821:android:abc123def456789",
    iosBundleId: "com.example.yanwariMessageMobile",
  ),
);
```

### 3. バックエンドサーバー起動確認
```bash
# バックエンドサーバーが起動していることを確認
curl http://localhost:8080/health
```

## 📱 iOS ビルド

### iOS シミュレーター用

#### 1. iOS deployment target確認
`ios/Podfile` で iOS 13.0+ が設定されていることを確認:
```ruby
platform :ios, '13.0'
```

#### 2. シミュレーター用ビルド
```bash
# クリーンビルド（推奨）
flutter clean
flutter pub get

# シミュレーター用ビルド
flutter build ios --simulator
```

#### 3. シミュレーターでの実行
```bash
# 利用可能なシミュレーターを確認
flutter emulators
xcrun simctl list devices

# シミュレーター起動（iPhone 16 Pro例）
xcrun simctl boot 9882B16C-E00F-402C-9526-5604CAD4063C

# アプリ起動
flutter run -d 9882B16C-E00F-402C-9526-5604CAD4063C
```

### iOS 実機用（Apple Developer Account必要）

#### 1. 実機用ビルド
```bash
flutter build ios --release
```

#### 2. Xcodeでの署名設定
1. `ios/Runner.xcworkspace`をXcodeで開く
2. Team設定でApple Developer Accountを選択
3. Bundle Identifierを固有のものに変更
4. Archive & Distribute

## 🤖 Android ビルド

### Android APK用

#### 1. Android SDK設定（必要な場合）
```bash
# Android SDKの場所を確認
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools
```

#### 2. デバッグAPKビルド
```bash
flutter build apk --debug
```

#### 3. リリースAPKビルド
```bash
flutter build apk --release
```

生成されたAPK: `build/app/outputs/flutter-apk/app-release.apk`

## 🌐 Web ビラウザ版

### 開発用サーバー起動
```bash
flutter run -d chrome --web-port 3000
```

アクセス: http://localhost:3000

## 🚀 ビルド成功例

### 現在のビルド状況（2025年8月2日）

#### ✅ 成功したビルド
1. **iOS シミュレーター**: 
   - ビルド時間: 51.9秒
   - 出力: `build/ios/iphonesimulator/Runner.app`
   - iPhone 16 Pro シミュレーターで動作確認済み

2. **Web ブラウザ**: 
   - Chrome で正常起動
   - DevTools: http://127.0.0.1:9102

#### ⚠️ 制限事項
1. **Android APK**: Android SDK未設定のためビルド不可
2. **iOS 実機**: Apple Developer Account設定が必要

## 🧪 テスト手順

### 1. 認証テスト
1. アプリ起動後、「新規登録」をタップ
2. メールアドレス・パスワードを入力
3. Firebase認証でユーザー作成
4. ログイン画面でサインイン

### 2. メッセージ作成フロー
1. ホーム画面で「メッセージ作成」をタップ
2. 受信者メールアドレスを入力
3. メッセージテキストを入力（例：「明日の会議を延期したい」）
4. 「変換」ボタンでAIトーン変換

### 3. トーン選択
1. 3つのトーン（優しめ・建設的・カジュアル）から選択
2. 各トーンの変換結果を確認
3. 最適なトーンを選択

### 4. スケジュール設定
1. AI提案の時間候補を確認
2. 「今すぐ送信」または時間指定
3. カスタム時間設定（日時ピッカー）
4. 送信スケジュール登録

### 5. API連携確認
- バックエンドサーバー（http://localhost:8080）との通信
- Firebase認証トークンの自動付与
- エラーハンドリング・再試行機能

## 🔧 トラブルシューティング

### よくある問題と解決法

#### iOS ビルドエラー
```
Error: The plugin "firebase_auth" requires a higher minimum iOS deployment version
```
**解決法**: `ios/Podfile` で `platform :ios, '13.0'` を設定

#### Flutter コマンドが見つからない
```
command not found: flutter
```
**解決法**: PATHにFlutter SDKを追加
```bash
export PATH="$PATH:/Users/fujinoyuki/development/flutter/bin"
```

#### Android SDK not found
```
No Android SDK found. Try setting the ANDROID_HOME environment variable.
```
**解決法**: Android Studioをインストールし、ANDROID_HOME環境変数を設定

#### Firebase接続エラー
```
Firebase configuration error
```
**解決法**: 
1. Firebase Console でプロジェクト設定を確認
2. `lib/main.dart` の FirebaseOptions を実際の値に更新
3. バックエンドサーバーが起動していることを確認

#### シミュレーター権限エラー
```
Could not register as server for FlutterDartVMServicePublisher, permission denied
```
**解決法**: 
- macOS システム設定 > プライバシー > ローカルネットワーク でアプリの権限を許可
- または、Web版（Chrome）でテスト実行

## 📁 ビルド出力ファイル

### iOS
- **シミュレーター**: `build/ios/iphonesimulator/Runner.app`
- **実機**: `build/ios/iphoneos/Runner.app`

### Android  
- **デバッグAPK**: `build/app/outputs/flutter-apk/app-debug.apk`
- **リリースAPK**: `build/app/outputs/flutter-apk/app-release.apk`

### Web
- **ビルド**: `build/web/`
- **開発サーバー**: http://localhost:3000

## 📞 サポート

問題が発生した場合:
1. `flutter doctor` でFlutter環境を診断
2. `flutter clean && flutter pub get` でクリーンビルド
3. バックエンドサーバーの起動状況を確認
4. Firebase Console でプロジェクト設定を確認

---

**最終更新**: 2025年8月2日  
**Flutter版**: 3.24.5  
**対応プラットフォーム**: iOS（シミュレーター・実機）、Android（APK）、Web（Chrome）