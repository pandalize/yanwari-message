# データベース初期化・データ投入・起動の最新手順

## 🚀 完全セットアップ（推奨）

### 1. 初回セットアップ
```bash
# 1. リポジトリクローン
git clone <repository-url>
cd yanwari-message

# 2. 環境変数設定
cp .env.example .env
# .env ファイルを編集してANTHROPIC_API_KEYを設定

# 3. 全サービス起動（初回は自動ビルド）
npm run dev
```

### 2. データベースセットアップ
```bash
# データベース初期化 + サンプルデータ投入（8件のメッセージ + 評価）
docker exec -i yanwari-mongodb mongosh "mongodb://localhost:27017/yanwari-message" < scripts/seeders/seed-simple.js

# または従来方式
npm run db:seed
```

### 3. 開発環境確認
```bash
# サービス状況確認
docker-compose ps

# ログ確認
npm run logs

# API動作確認
curl http://localhost:8080/health
```

## 🎯 最新のシーダー内容（2025年8月版）

### 投入されるデータ
- **ユーザー**: 3件 (Alice, Bob, Charlie)
- **メッセージ**: 8件（多様なステータス）
- **友達関係**: 2件 (Alice↔Bob, Alice↔Charlie)
- **評価データ**: 3件

### メッセージの種類
1. **既読（評価可能）**: 3件 - Alice受信、評価済み
2. **送信済み（未読）**: 2件 - 返信待ち状態
3. **送信予定**: 2件 - 明日・来週配信
4. **配信済み（未読）**: 1件 - Alice → Charlie

### テストアカウント（パスワード: password123）
- 👩 田中 あかり - `alice@yanwari-message.com`
- 👨 佐藤 ひろし - `bob@yanwari-message.com`  
- 👩 鈴木 みゆき - `charlie@yanwari-message.com`

## 🧪 APIテスト例

### 認証テスト
```bash
# ログイン
TOKEN=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"alice@yanwari-message.com","password":"password123"}' \
  | jq -r '.data.access_token')

# 評価付き受信トレイ
curl -X GET "http://localhost:8080/api/v1/messages/inbox-with-ratings" \
  -H "Authorization: Bearer $TOKEN" \
  | jq .
```

## 🔧 データベース管理コマンド

```bash
# MongoDB管理UI起動
npm run db:admin
# → http://localhost:8081 でアクセス（admin/admin123）

# データベースリセット + 再投入
npm run db:reset

# 全データクリア
npm run db:clean

# データベース状況確認
npm run db:status
```

## 🎮 統合テスト環境

### JWT認証テストページ
```bash
# システム起動後にアクセス
http://localhost/test/jwt-auth-test.html

# ワンクリックログイン・API動作確認・デバッグが可能
```

## 📝 重要な変更点

### 2025年8月版の改善
- ✅ データベーススキーマ: snake_case → camelCase 統一
- ✅ variations構造: 複雑ネスト → シンプル文字列
- ✅ 時間設定: 昨日・今日・明日・来週のリアルなタイムライン
- ✅ 評価システム: 3段階評価 + 詳細コメント
- ✅ 友達関係: Alice中心の2方向関係（Bob↮Charlie なし）

### データ整合性確保
- MongoDB indexes更新済み
- JWT認証システム完全統合
- API /api/v1/messages/inbox-with-ratings 動作確認済み