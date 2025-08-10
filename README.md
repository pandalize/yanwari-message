# やんわり伝言サービス

AI を使って気まずい用件を優しく伝えるサービスです。

## 🚀 実装済み機能

### コア機能
- ✅ **Firebase認証** - セキュアな認証システム
- ✅ **メッセージ作成・編集** - リアルタイム下書き保存
- ✅ **AIトーン変換** - 3種類の並行変換（優しめ・建設的・カジュアル）
- ✅ **スケジュール送信** - AI時間提案・配信予約
- ✅ **友達申請システム** - 申請・承諾・管理
- ✅ **メッセージ評価** - 5段階評価・ツリーマップ可視化
- ✅ **設定機能** - プロフィール・通知・パスワード管理

### プラットフォーム
- ✅ **Webアプリ** - Vue 3 + TypeScript
- ✅ **iOSアプリ** - Flutter（受信トレイ実装済み）
- 🔄 **Androidアプリ** - Flutter（開発中）

## 🛠 技術スタック

- **バックエンド**: Go 1.23+ + Gin + Firebase認証 + MongoDB Atlas
- **フロントエンド**: Vue 3 + TypeScript + Vite + Pinia
- **モバイル**: Flutter (iOS/Android)
- **AI連携**: Anthropic Claude API
- **データベース**: MongoDB Atlas

## 📦 セットアップ

### 必要な環境
- Go 1.23.0+
- Node.js 18.0+
- Flutter (モバイル開発の場合)
- MongoDB Atlas アカウント
- Firebase プロジェクト
- Anthropic API キー

### クイックスタート

```bash
# 1. 依存関係のインストール
npm run install:all

# 2. 環境変数の設定
npm run setup:env
# backend/.env を編集して実際の値を設定

# 3. 開発サーバー起動
npm run dev
# または統合スクリプト
./yanwari-start
```

### 各プラットフォーム個別起動

```bash
# Webのみ
npm run dev:frontend  # http://localhost:5173
npm run dev:backend   # http://localhost:8080

# モバイル（iOS）
cd mobile && flutter run
```

## 📱 アプリフロー

1. **ユーザー登録・ログイン**（Firebase認証）
2. **友達申請・承諾**
3. **メッセージ作成**
4. **AIトーン変換**（3種類から選択）
5. **AI時間提案**（メッセージ分析で最適タイミング提案）
6. **配信時間決定・送信**
7. **受信・評価**

## 🧪 テスト・品質管理

```bash
# 全てのテスト
npm run test

# リント・フォーマット
npm run lint
npm run format

# APIテスト
./test_message.sh
```

## 📚 詳細ドキュメント

- **開発者ガイド**: `CLAUDE.md`
- **API仕様**: `docs/API_REFERENCE.md`
- **APIテスト**: `API_TEST_COMMANDS.md`
- **モバイル開発**: `mobile/README.md`

## 🤝 開発参加

現在のブランチ:
- **メイン**: `main`
- **開発**: `develop`
- **現在**: `fix/message-rating-system`

機能開発は `feature/*` ブランチで行い、`develop` を経由して `main` にマージします。