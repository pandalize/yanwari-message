# 開発環境セットアップガイド

## 🎯 概要

やんわり伝言サービスの開発環境セットアップと日常的な開発ワークフローのガイドです。

## 📋 必要な環境

### 基本ツール
- **Node.js**: v18.0.0以上
- **npm**: v9.0.0以上  
- **Go**: 1.23以上
- **Firebase CLI**: 最新版

### 開発ツール（推奨）
- **VSCode**: プロジェクト設定済み
- **Git**: バージョン管理

## 🚀 初回セットアップ

### 1. リポジトリクローン
```bash
git clone <repository-url>
cd yanwari-message
```

### 2. 環境構築
```bash
# 全体セットアップ（推奨）
npm run setup

# 個別セットアップの場合
npm run install:all    # 依存関係インストール
npm run setup:env      # 環境変数ファイル作成
npm run tools:install  # 開発ツールインストール
```

### 3. Firebase設定
```bash
# Firebase CLI インストール（未インストールの場合）
npm install -g firebase-tools

# Firebaseログイン
firebase login

# プロジェクト設定確認
firebase projects:list
```

## 🔥 開発サーバー起動

### 方法1: インタラクティブモード（推奨）
```bash
npm run dev
```
メニューが表示され、起動モードを選択できます。

### 方法2: 直接指定
```bash
# Firebase付き起動（フル機能）
npm run dev:firebase

# ローカルのみ起動（APIテストのみ）
npm run dev:local

# 環境リセット後起動
npm run reset
```

### 起動後のURL
- **フロントエンド**: http://localhost:5173
- **バックエンド**: http://localhost:8080
- **Swagger UI**: http://localhost:8080/swagger/index.html
- **Firebase Emulator**: http://localhost:4000

## 📊 データベース・テストデータ

### データベース管理
```bash
# データベースリセット
npm run db:reset

# サンプルデータ投入
npm run db:seed           # フルデータセット
npm run db:seed:basic     # 認証のみ
npm run db:seed:messages  # メッセージデータのみ
```

### Firebase テストユーザー
```bash
# テストユーザー作成
npm run firebase:users

# Firebase環境セットアップ（DB + ユーザー）
npm run firebase:setup
```

### 完全リセット
```bash
# 環境完全リセット
npm run reset

# クイックリセット（データのみ）
npm run reset:quick
```

## 🔍 開発ツール

### 状況確認
```bash
# 開発環境状況確認
npm run dev:status

# プロセス停止
npm run dev:stop
```

### コード品質
```bash
# テスト実行
npm run test

# リント実行
npm run lint

# コード整形
npm run format

# ビルド確認
npm run build
```

### API設計・型生成
```bash
# API仕様生成 + フロントエンド型生成
npm run api:sync

# API仕様のみ生成
npm run api:generate
```

## 🛠️ 開発ワークフロー

### 日常の開発フロー

1. **環境起動**
   ```bash
   npm run dev  # メニューから選択
   ```

2. **機能開発**
   - バックエンドAPI開発時: Swaggerアノテーション追加必須
   - フロントエンド開発時: 生成された型を使用

3. **API変更時**
   ```bash
   npm run api:sync  # 型定義同期
   ```

4. **品質チェック**
   ```bash
   npm run lint && npm run test
   ```

### ブランチ切り替え時
```bash
npm run reset  # 環境リセット
npm run dev    # 再起動
```

### 新機能開発時
```bash
# データをリセットしてクリーンな状態で開発
npm run reset
npm run dev:firebase
```

## 🎨 VSCode設定

プロジェクトには以下が設定済み：

- **タスク**: `Ctrl+Shift+P` → "Tasks: Run Task"
  - API仕様同期
  - Swagger生成
- **デバッグ設定**: Go・Vue.js対応
- **推奨拡張機能**: 自動提案あり

## 🔧 トラブルシューティング

### ポート競合エラー
```bash
# ポート確認
npm run dev:status

# プロセス停止
npm run dev:stop

# 完全リセット
npm run reset
```

### 依存関係エラー
```bash
# 依存関係再インストール
npm run clean
npm run install:all
```

### Firebase接続エラー
```bash
# Firebase再ログイン
firebase logout
firebase login

# エミュレーター確認
firebase emulators:start --only auth
```

### 型定義エラー
```bash
# 型定義再生成
npm run api:sync

# TypeScriptリセット
cd frontend && npm run type-check
```

### MongoDB接続エラー
- `.env`ファイルのMONGO_URIを確認
- MongoDB Atlas接続状況を確認

## 📱 モバイル開発

Flutterアプリも含まれています：

```bash
# モバイル開発ディレクトリ
cd mobile

# 依存関係インストール
flutter pub get

# iOS起動
flutter run -d ios

# Android起動  
flutter run -d android
```

## 📋 チェックリスト

開発開始前：
- [ ] Node.js・Go・Firebase CLIがインストール済み
- [ ] `npm run setup`で環境構築完了
- [ ] `npm run dev:status`で全サービス起動確認
- [ ] http://localhost:5173 でフロントエンドアクセス可能
- [ ] http://localhost:8080/swagger/index.html でAPI仕様確認可能

新機能開発時：
- [ ] 適切なブランチ作成済み（feature/xxx）
- [ ] `npm run reset`で環境リセット済み
- [ ] バックエンドAPIにSwaggerアノテーション追加
- [ ] `npm run api:sync`で型定義同期済み
- [ ] `npm run lint && npm run test`でチェック通過

## 🆘 サポート

問題が解決しない場合：
1. このドキュメントの関連セクション確認
2. `npm run dev:status`で環境状態確認
3. プロジェクトのissuesで既知の問題を確認
4. チームメンバーに相談

---

**次のステップ**: [API開発ワークフロー](./API_DEVELOPMENT_WORKFLOW.md)も併せてご確認ください。