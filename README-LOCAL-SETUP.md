# 🏠 ローカル開発環境セットアップガイド

このガイドでは、ローカルMongoDB + Firebase Emulatorを使用した高速開発環境の構築方法を説明します。

## 🎯 ローカル開発環境の利点

- ⚡ **高速**: ネットワーク遅延なし
- 💰 **無料**: クラウドの課金なし  
- 🔒 **安全**: データ破壊の心配なし
- 🐛 **デバッグ容易**: ローカルでのトラブルシューティング

## 📋 前提条件

以下がインストールされていることを確認してください：

```bash
# 必須ツール
docker --version          # Docker Desktop
node --version            # Node.js 18+
go version               # Go 1.23+
firebase --version       # Firebase CLI

# インストール例（macOS）
brew install docker node go
npm install -g firebase-tools
```

## 🚀 クイックスタート

```bash
# 1. プロジェクトクローン（既に完了している場合はスキップ）
git clone https://github.com/your-org/yanwari-message.git
cd yanwari-message

# 2. 依存関係インストール
npm run install:all

# 3. ローカル開発環境起動（第1ターミナル）
npm run dev:local

# 4. 初回のみ：データセットアップ（第2ターミナル）
npm run setup:local
```

**これだけで完了！** 🎉

以下のサービスが自動的に起動します：
- MongoDB (Docker) - http://localhost:8081
- Firebase Emulator - http://localhost:4000/auth
- Backend API - http://localhost:8080
- Frontend - http://localhost:5173

## 📂 ローカル環境の構成

### Docker Compose構成

```yaml
# docker-compose.yml
services:
  mongodb:
    image: mongo:7
    ports: ["27017:27017"]
    
  mongo-express:
    image: mongo-express:latest
    ports: ["8081:8081"]
```

### 環境変数

```bash
# backend/.env.local
MONGODB_URI=mongodb://admin:password123@localhost:27017/yanwari-message?authSource=admin
FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099
```

## 🔧 MongoDB管理コマンド

```bash
# MongoDB管理
npm run mongodb:start    # MongoDB起動
npm run mongodb:stop     # MongoDB停止
npm run mongodb:status   # 状態確認
npm run mongodb:reset    # データリセット
npm run mongodb:seed     # テストデータ投入

# Firebase連携
npm run firebase:seed    # Firebase Emulatorにユーザー作成
npm run sync:users       # Firebase UIDとMongoDB同期

# 統合セットアップ（推奨）
npm run setup:local      # 全データ一括セットアップ
```

## 📊 テストデータの投入

```bash
# テストデータ投入
npm run mongodb:seed

# または詳細オプション付き
node backend/scripts/db-seed.cjs --local --dataset=full
```

投入されるテストデータ：
- **ユーザー**: Alice、Bob、Charlie（パスワード: password123）
- **メッセージ**: 各種ステータスのテスト用メッセージ
- **友達関係**: ユーザー間の友達関係
- **スケジュール**: 送信予定メッセージ

## 🌐 アクセスURL一覧

| サービス | URL | 説明 |
|---------|-----|------|
| Frontend | http://localhost:5173 | Vue.js アプリケーション |
| Backend API | http://localhost:8080 | Go API サーバー |
| Mongo Express | http://localhost:8081 | MongoDB管理画面 |
| Firebase Auth | http://localhost:4000/auth | Firebase認証エミュレータ |
| Swagger UI | http://localhost:8080/docs | API仕様書 |

## 🔄 開発ワークフロー

### 1. 日常の開発開始

```bash
npm run dev:local
```

### 2. データベース操作

```bash
# データリセット（新機能テスト時）
npm run mongodb:reset
npm run mongodb:seed

# 状態確認
npm run mongodb:status
```

### 3. API変更時

```bash
# API仕様同期
npm run api:sync

# テスト実行
npm run test
```

### 4. 開発終了

`Ctrl+C` でサーバー群停止、MongoDBは残り続けます。

## 🆚 環境の使い分け

| 用途 | コマンド | MongoDB | Firebase | 推奨シーン |
|------|----------|---------|----------|------------|
| **高速開発** | `dev:local` | ローカル | Emulator | 機能開発・デバッグ |
| **統合テスト** | `dev:cloud` | Atlas | Emulator | チーム開発・本番近似 |
| **従来方式** | `dev` | Atlas | Emulator | 既存の開発フロー |

## 🐛 トラブルシューティング

### MongoDB接続エラー

```bash
# Docker状態確認
docker ps

# MongoDB再起動
npm run mongodb:stop
npm run mongodb:start
```

### ポート競合

```bash
# ポート使用状況確認
lsof -i :27017  # MongoDB
lsof -i :8080   # Backend
lsof -i :5173   # Frontend

# プロセス終了
kill -9 <PID>
```

### Firebase Emulator接続失敗

```bash
# Firebase CLIログイン確認
firebase login

# プロジェクト確認
firebase projects:list
firebase use yanwari-message
```

## 📈 パフォーマンス比較

| 項目 | ローカル | クラウド |
|------|----------|----------|
| DB接続速度 | ~1ms | ~50-100ms |
| データ読み書き | ~5ms | ~100-200ms |
| 初期起動 | ~10秒 | ~30秒 |
| 月額コスト | 無料 | 数百円〜 |

## 🔒 セキュリティ注意事項

- ローカル環境の認証情報は開発用です
- 本番データはローカルに保存しないでください
- `.env.local`は`.gitignore`に含まれています

---

この環境で快適な開発をお楽しみください！ 🚀