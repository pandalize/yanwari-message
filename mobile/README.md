# やんわり伝言 モバイルアプリ

Flutter製のやんわり伝言モバイルアプリです。思いやりのあるコミュニケーションをサポートするために、AIを活用してメッセージを最適なトーンに変換し、適切なタイミングで送信することができます。

## 📱 機能概要

### 🔐 認証システム
- **Firebase認証**: メールアドレス・パスワードでのユーザー登録・ログイン
- **自動ログイン**: アプリ再起動時の認証状態維持
- **セキュア**: Firebase ID Tokenを使用したバックエンド連携

### ✍️ メッセージ作成
- **直感的なUI**: シンプルで使いやすいメッセージ作成画面
- **受信者選択**: メールアドレスでの受信者指定
- **リアルタイム文字数**: 入力文字数の表示・制限

### 🎭 AIトーン変換
- **3種類のトーン**: 
  - 💝 **優しめ**: 丁寧で思いやりのある表現
  - 🏗️ **建設的**: 問題解決に焦点を当てた表現  
  - 🎯 **カジュアル**: フレンドリーで親しみやすい表現
- **並行処理**: 3つのトーンを同時に生成
- **視覚的選択**: カードベースのUI で比較・選択

### ⏰ スマートスケジューリング
- **AI時間提案**: メッセージ内容を分析して最適な送信タイミングを提案
- **即座送信**: 今すぐメッセージを送信
- **カスタム時間**: 日時ピッカーで任意の時間を設定
- **タイムゾーン対応**: Asia/Tokyo タイムゾーンでの時間管理

## 🏗️ 技術スタック

### フロントエンド
- **Flutter 3.24.5**: クロスプラットフォーム UI フレームワーク
- **Dart 3.5.4**: プログラミング言語
- **Provider**: 状態管理
- **Material 3**: Google の最新デザインシステム

### 認証・バックエンド連携
- **Firebase Authentication**: ユーザー認証
- **Dio**: HTTP クライアント
- **Auto Token Refresh**: 認証トークンの自動更新

### UI/UX
- **レスポンシブデザイン**: 様々な画面サイズに対応
- **やんわり伝言ブランディング**: 優しい緑色（#81C784）を基調
- **直感的ナビゲーション**: カードベースのホーム画面

## 🚀 はじめ方

### 前提条件
- Flutter SDK 3.24.5+
- Dart SDK 3.5.4+
- iOS: Xcode + iOS 13.0+
- Android: Android Studio + API Level 21+

### セットアップ
```bash
# リポジトリのクローン
git clone <repository-url>
cd mobile

# 依存関係のインストール
flutter pub get

# iOS/Android デバイス確認
flutter devices

# アプリ起動（デバイスを選択）
flutter run
```

詳細なビルド手順は [BUILD_GUIDE.md](./BUILD_GUIDE.md) を参照してください。

## 📂 プロジェクト構造

```
mobile/
├── lib/
│   ├── main.dart                    # アプリエントリーポイント
│   ├── models/                      # データモデル
│   │   ├── message.dart
│   │   └── user.dart
│   ├── screens/                     # UI画面
│   │   ├── auth_wrapper.dart        # 認証ラッパー
│   │   ├── login_screen.dart        # ログイン画面
│   │   ├── register_screen.dart     # 新規登録画面
│   │   ├── home_screen.dart         # ホーム画面
│   │   ├── message_compose_screen.dart  # メッセージ作成
│   │   ├── tone_selection_screen.dart   # トーン選択
│   │   └── schedule_selection_screen.dart # スケジュール選択
│   └── services/                    # サービス層
│       ├── auth_service.dart        # Firebase認証サービス
│       └── api_service.dart         # バックエンドAPI連携
├── ios/                            # iOS固有設定
├── android/                        # Android固有設定
├── BUILD_GUIDE.md                  # ビルドガイド
└── README.md                       # このファイル
```

## 🎯 使用方法

### 1. ユーザー登録・ログイン
1. アプリ起動
2. 「新規登録」または「ログイン」を選択
3. メールアドレス・パスワードを入力
4. Firebase認証でアカウント作成/ログイン

### 2. やんわり伝言の送信
1. ホーム画面で「メッセージ作成」をタップ
2. 受信者のメールアドレスを入力
3. 送信したいメッセージを入力
4. 「変換」ボタンで AI トーン変換
5. 3つのトーンから最適なものを選択
6. AI提案または任意の時間でスケジュール設定
7. 送信予定に登録完了

### 3. AI時間提案の例
- **緊急度の高いメッセージ**: 「今すぐ」「1時間後」を提案
- **謝罪メッセージ**: 「今すぐ」「明朝9時」を提案  
- **雑談メッセージ**: 「夕方18時」「明日のお昼」を提案

## 🔧 開発情報

### バックエンド連携
- **API Base URL**: `http://localhost:8080/api/v1`
- **認証方式**: Firebase ID Token（Bearer Token）
- **自動リトライ**: 401エラー時の自動トークン更新

### Firebase設定
- **プロジェクトID**: `yanwari-message`
- **認証プロバイダー**: Email/Password
- **セキュリティルール**: 認証済みユーザーのみアクセス可能

### 対応プラットフォーム
- ✅ **iOS**: iPhone/iPad（iOS 13.0+）
- ✅ **Android**: スマートフォン/タブレット（API Level 21+）  
- ✅ **Web**: Chrome、Safari、Firefox
- ✅ **macOS**: Mac Designed for iPad
- ✅ **Windows**: デスクトップアプリ（実験的）
- ✅ **Linux**: デスクトップアプリ（実験的）

## 📊 実装状況

### ✅ 完了済み機能
- [x] Firebase認証システム
- [x] メッセージ作成UI
- [x] AIトーン変換（3種類）
- [x] スケジュール設定
- [x] AI時間提案
- [x] バックエンドAPI連携
- [x] レスポンシブデザイン
- [x] エラーハンドリング

### 🚧 今後の拡張予定
- [ ] 受信トレイ機能
- [ ] 送信履歴確認
- [ ] 友達管理システム  
- [ ] プッシュ通知
- [ ] ダークモード対応
- [ ] 多言語対応

## 🐛 トラブルシューティング

### よくある問題

#### ビルドエラー
```bash
# 依存関係の問題
flutter clean
flutter pub get

# iOS の minimum deployment target
ios/Podfile で platform :ios, '13.0' を確認
```

#### 認証エラー
- Firebase Console でプロジェクト設定を確認
- バックエンドサーバーが起動していることを確認
- ネットワーク接続を確認

#### API連携エラー  
- バックエンドサーバー: http://localhost:8080/health で確認
- CORS設定: バックエンドで mobile origins が許可されているか確認

## 🤝 貢献

### 開発への参加
1. このリポジトリをフォーク
2. 新しいブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add amazing feature'`)
4. ブランチにプッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストを作成

### コードスタイル
- **Flutter/Dart**: 公式スタイルガイドに準拠
- **コメント**: 日本語でのコメント推奨
- **命名規則**: キャメルケース（変数・関数）、PascalCase（クラス）

## 📄 ライセンス

このプロジェクトは MIT ライセンスの下で公開されています。

## 👥 開発チーム

- **プロジェクトリード**: fujinoyuki
- **Flutter開発**: Claude Code Assistant
- **バックエンド**: Go + Firebase + MongoDB Atlas
- **デザイン**: Material 3 + やんわり伝言ブランディング

---

**最終更新**: 2025年8月2日  
**バージョン**: 1.0.0  
**対応Flutter**: 3.24.5+
