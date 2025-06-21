# セットアップガイド

## 環境変数設定

### 1. 環境変数ファイルの作成

```bash
cp .env.example .env
```

### 2. 必要な値を設定

`.env` ファイルを編集して以下の値を設定してください：

```env
# MongoDB Atlas接続情報（必須）
MONGODB_URI=mongodb+srv://your-username:your-password@your-cluster.mongodb.net/
MONGODB_DATABASE=yanwari-message

# JWT秘密鍵（必須、本番では32文字以上の強力なキー）
JWT_SECRET_KEY=your-super-secret-jwt-key-minimum-32-characters

# その他（オプション）
PORT=8080
GIN_MODE=debug
ALLOWED_ORIGINS=http://localhost:5173,http://localhost:3000
LOG_LEVEL=debug
```

## サーバー起動

```bash
go run main.go
```

または

```bash
go build -o main . && ./main
```

## 動作確認

### 1. ヘルスチェック

```bash
curl http://localhost:8080/health
```

**期待される応答:**
```json
{
  "status": "ok",
  "message": "Health check completed",
  "timestamp": "2024-XX-XXTXX:XX:XXZ",
  "port": "8080",
  "components": {
    "server": {
      "status": "ok",
      "uptime": "1m30s"
    },
    "database": {
      "status": "ok",
      "type": "MongoDB Atlas"
    }
  }
}
```

### 2. API ステータス

```bash
curl http://localhost:8080/api/status
```

### 3. 認証エンドポイントテスト

詳細は `API_TEST_COMMANDS.md` を参照してください。

## グレースフルシャットダウン

サーバーを停止する際は `Ctrl+C` を押してください。
サーバーは以下の手順で安全に停止します：

1. 新しいリクエストの受付を停止
2. 現在処理中のリクエストの完了を待機（最大30秒）
3. データベース接続のクリーンアップ
4. アプリケーション終了

## トラブルシューティング

### データベース接続エラー

1. `MONGODB_URI` が正しく設定されているか確認
2. MongoDB Atlas のネットワークアクセス設定を確認
3. ユーザー名・パスワードが正しいか確認

### CORS エラー

1. `ALLOWED_ORIGINS` 環境変数を確認
2. フロントエンドのポート番号が一致しているか確認

### 認証エラー

1. `JWT_SECRET_KEY` が設定されているか確認
2. キーが十分に長く複雑であるか確認（32文字以上推奨）