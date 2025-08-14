# CLAUDE.md

このファイルは、Claude Code (claude.ai/code) がこのリポジトリで作業する際のガイダンスを提供します。

## プロジェクト概要

やんわり伝言サービス - AIを使って気まずい用件を優しく伝えるサービス

### 基本フロー
1. ユーザーがメッセージ入力
2. AI が3つのトーン（優しめ、建設的、カジュアル）に変換
3. 最適なトーンを選択
4. AI がメッセージを分析して最適な送信時間を提案
5. 配信時間を決定して送信予約
6. 受信者に指定時間に配信

## 技術スタック

- **バックエンド**: Go 1.23+ + Gin + Firebase認証 + MongoDB Atlas
- **フロントエンド**: Vue 3 + TypeScript + Vite + Pinia
- **モバイル**: Flutter (iOS/Android)
- **AI**: Anthropic Claude API

## 開発コマンド

### 🚀 基本コマンド
```bash
# 初回セットアップ
npm run install:all      # 依存関係インストール
npm run setup:local      # ローカル環境のデータセットアップ

# 開発サーバー起動
npm run dev:local        # ローカル環境（MongoDB + Firebase Emulator）
npm run dev:cloud        # クラウド環境（MongoDB Atlas + Firebase Emulator）

# 環境管理
npm run status           # 状況確認  
npm run stop            # サーバー停止
```

### 🔧 開発ツール
```bash
# API・テスト
npm run api:sync         # API型定義同期
npm run test            # テスト実行
npm run lint            # コード品質チェック
npm run build           # プロダクションビルド

# データ管理（ローカル開発用）
npm run setup:local      # 全データ一括セットアップ（推奨）
npm run mongodb:seed     # MongoDBテストデータ投入
npm run firebase:seed    # Firebase Emulatorユーザー作成
npm run sync:users       # Firebase UIDとMongoDB同期
```

### 📍 開発環境アクセスURL

- **Frontend**: http://localhost:5173
- **Backend API**: http://localhost:8080  
- **Swagger UI**: http://localhost:8080/docs
- **MongoDB管理**: http://localhost:8081
- **Firebase Auth**: http://localhost:4000/auth

### 📚 詳細ドキュメント

- [ローカル開発環境ガイド](docs/LOCAL_DEVELOPMENT_GUIDE.md)
- [APIリファレンス](docs/API_REFERENCE.md)
- [テストワークフロー](docs/TESTING_WORKFLOW.md)

## ブランチ戦略

### メインブランチ
- **main** - 本番環境（プロダクション）
- **develop** - 統合開発ブランチ（Web・Mobile共通）

### 機能開発ブランチ
- **feature/web-[機能名]** - Web版専用機能（Vue.js）
- **feature/mobile-[機能名]** - モバイル版専用機能（Flutter）
- **feature/shared-[機能名]** - 共通機能（バックエンドAPI・DB・認証等）

### 開発フロー
```bash
# 機能開発例
git checkout develop
git pull origin develop
git checkout -b feature/web-new-ui        # Web版機能
git checkout -b feature/mobile-new-screen # Mobile版機能  
git checkout -b feature/shared-new-api    # 共通機能

# 開発完了後
git push origin feature/xxx
# PR作成: feature/xxx → develop
# develop → main（リリース時）
```

## 運用ルール

1. **日本語コメント必須**
2. **Firebase認証**: 全APIで認証必須
3. **品質チェック**: 実装後は `npm run lint` と `npm run test` を実行
4. **⚠️ 開発サーバー起動の重要ルール**:
   - **Claude Code は自動で開発サーバーを起動してはいけません**
   - 開発サーバー起動(`npm run dev`、`npm run dev:local`等)は必ずユーザーが手動で実行する
   - Claude と ユーザーが同時に起動するとポート競合やプロセス重複が発生する
   - Claude Code は起動方法の説明やデバッグのみ行い、実際の起動コマンド実行は避ける

## 完了済み機能

- ✅ Firebase認証システム
- ✅ メッセージ作成・AIトーン変換  
- ✅ スケジュール・時間提案機能
- ✅ 友達申請システム
- ✅ メッセージ評価システム
- ✅ Flutter iOSアプリ

## ブランチ構成

### 統一ブランチ構成
- **develop** - 統合開発ブランチ（Web・Mobile・API全て）

### 利点
- 単一コードベースでの開発
- 機能の一貫性確保
- 開発・レビュー効率の最大化