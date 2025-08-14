# 🏠 ローカル開発環境ガイド

このガイドでは、やんわり伝言サービスのローカル開発環境構築から日常の開発フローまでを解説します。

## 📋 目次

1. [前提条件](#-前提条件)
2. [初回セットアップ](#-初回セットアップ)
3. [日常の開発フロー](#-日常の開発フロー)
4. [データ管理](#-データ管理)
5. [トラブルシューティング](#-トラブルシューティング)
6. [コマンドリファレンス](#-コマンドリファレンス)

## 📌 前提条件

以下のツールがインストールされていることを確認してください：

```bash
# バージョン確認
docker --version          # Docker Desktop
node --version            # Node.js 18+
go version               # Go 1.23+
firebase --version       # Firebase CLI

# macOSでのインストール例
brew install docker node go
npm install -g firebase-tools
```

## 🚀 初回セットアップ

### 1. リポジトリのクローン

```bash
git clone https://github.com/your-org/yanwari-message.git
cd yanwari-message
```

### 2. 依存関係のインストール

```bash
npm run install:all
```

### 3. 開発環境の起動とデータセットアップ

```bash
# ターミナル1: 開発環境起動
npm run dev:local

# ターミナル2: データセットアップ（起動完了後）
npm run setup:local
```

✅ **これで完了！** 以下のサービスが利用可能になります：

| サービス | URL | 説明 |
|---------|-----|------|
| Frontend | http://localhost:5173 | Vue.js アプリケーション |
| Backend API | http://localhost:8080 | Go APIサーバー |
| Swagger UI | http://localhost:8080/docs | API仕様書 |
| MongoDB管理 | http://localhost:8081 | Mongo Express |
| Firebase Auth | http://localhost:4000/auth | 認証エミュレータ |

## 👤 テストアカウント

ローカル環境には以下のテストアカウントが用意されています：

| 名前 | Email | パスワード |
|------|-------|-----------|
| Alice テスター | alice@yanwari.com | password123 |
| Bob デモ | bob@yanwari.com | password123 |
| Charlie サンプル | charlie@yanwari.com | password123 |

## 🔄 日常の開発フロー

### 開発開始

```bash
# 開発環境起動（データは永続化されているため、これだけでOK）
npm run dev:local
```

### 開発終了

```bash
# Ctrl+C でサーバー停止（MongoDBは起動したまま）
```

## 📊 データ管理

### データリセット＆再セットアップ

新しい状態でテストしたい場合：

```bash
# データベースリセット
npm run mongodb:reset

# データ再セットアップ
npm run setup:local
```

### 個別データ管理

```bash
# MongoDBのみリセット
npm run mongodb:seed

# Firebase Emulatorのみリセット
npm run firebase:seed

# UID同期のみ実行
npm run sync:users
```

## 🐛 トラブルシューティング

### ポート競合エラー

```bash
# 使用中のポートを確認
lsof -i :8080  # Backend
lsof -i :5173  # Frontend
lsof -i :27017 # MongoDB

# プロセスを終了
kill -9 <PID>
```

### Docker関連の問題

```bash
# Docker Desktopが起動していない場合
open -a "Docker Desktop"

# MongoDBコンテナの状態確認
docker ps
npm run mongodb:status

# MongoDBコンテナ再起動
npm run mongodb:stop
npm run mongodb:start
```

### Firebase Emulator接続エラー

```bash
# Firebase Emulatorの再起動
firebase emulators:stop
npm run dev:local  # 再起動
```

### ログインできない場合

```bash
# データ同期を再実行
npm run setup:local
```

## 📚 コマンドリファレンス

### 環境起動

| コマンド | 説明 |
|---------|------|
| `npm run dev:local` | ローカル開発環境起動 |
| `npm run dev:cloud` | クラウド環境起動（MongoDB Atlas使用） |

### データセットアップ

| コマンド | 説明 |
|---------|------|
| `npm run setup:local` | 全データ一括セットアップ（推奨） |
| `npm run mongodb:seed` | MongoDBテストデータ投入 |
| `npm run firebase:seed` | Firebase Emulatorユーザー作成 |
| `npm run sync:users` | Firebase UIDとMongoDB同期 |

### MongoDB管理

| コマンド | 説明 |
|---------|------|
| `npm run mongodb:start` | MongoDB起動 |
| `npm run mongodb:stop` | MongoDB停止 |
| `npm run mongodb:status` | 状態確認 |
| `npm run mongodb:reset` | データリセット |

### その他

| コマンド | 説明 |
|---------|------|
| `npm run api:sync` | API型定義同期 |
| `npm run test` | テスト実行 |
| `npm run lint` | コード品質チェック |
| `npm run build` | プロダクションビルド |

## 🔄 環境の使い分け

| 用途 | コマンド | MongoDB | Firebase | 推奨シーン |
|------|----------|---------|----------|------------|
| **高速開発** | `dev:local` | ローカル | Emulator | 機能開発・デバッグ |
| **統合テスト** | `dev:cloud` | Atlas | Emulator | チーム開発・本番近似 |

## 💡 Tips

### MongoDB Compassでの接続

より詳細なデータベース操作が必要な場合：

```
mongodb://admin:password123@localhost:27017/yanwari-message?authSource=admin
```

### ログ確認

```bash
# Backend ログ
[🟢BACKEND] のプレフィックスで表示

# Frontend ログ
[🌐FRONTEND] のプレフィックスで表示

# Firebase Emulator ログ
[🔥FIREBASE] のプレフィックスで表示
```

### パフォーマンス

- MongoDB は常時起動推奨（リソース消費が少ない）
- 開発終了時は `Ctrl+C` でアプリケーションサーバーのみ停止
- MongoDBコンテナは必要に応じて手動停止

---

問題が発生した場合は、[GitHub Issues](https://github.com/your-org/yanwari-message/issues) で報告してください。