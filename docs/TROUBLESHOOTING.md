# トラブルシューティング

## 友達申請で500エラーが発生する場合

### 症状
- 友達申請送信時に500エラー（Internal Server Error）が発生
- バックエンドログに以下のエラーが表示される：
  ```
  E11000 duplicate key error collection: yanwari-message.friend_requests 
  index: sender_id_1_recipient_id_1 dup key: { sender_id: null, recipient_id: null }
  ```

### 原因
- データベースに古いスキーマのMongoDBインデックスが残存している
- 古いスキーマ: `sender_id`, `recipient_id`
- 新しいスキーマ: `from_user_id`, `to_user_id`
- インデックスの競合によりMongoDB挿入処理が失敗

### 解決手順

#### 1. 問題の確認
```bash
# インデックス一覧を確認
docker-compose exec mongodb mongosh yanwari-message --eval 'db.friend_requests.getIndexes()'
```

#### 2. 古いインデックスの削除
```bash
docker-compose exec mongodb mongosh yanwari-message --eval '
print("古いインデックスを削除中...");
db.friend_requests.dropIndex("sender_id_1_recipient_id_1");
db.friend_requests.dropIndex("recipient_id_1_status_1");
print("✅ 古いインデックス削除完了");
'
```

#### 3. 修正後の確認
```bash
# 正しいインデックスのみが残っていることを確認
docker-compose exec mongodb mongosh yanwari-message --eval '
print("現在のインデックス一覧:");
db.friend_requests.getIndexes().forEach(idx => print(JSON.stringify(idx)));
'
```

期待される結果:
```json
{"v":2,"key":{"_id":1},"name":"_id_"}
{"v":2,"key":{"from_user_id":1,"to_user_id":1},"name":"from_user_id_1_to_user_id_1","unique":true}
{"v":2,"key":{"status":1},"name":"status_1"}
{"v":2,"key":{"to_user_id":1},"name":"to_user_id_1"}
```

#### 4. 動作テスト
```bash
# 友達申請APIの動作確認
BOB_TOKEN=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"bob@yanwari-message.com","password":"password123"}' \
  | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['access_token'])")

curl -X POST http://localhost:8080/api/v1/friend-requests/send \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $BOB_TOKEN" \
  -d '{"to_email":"charlie@yanwari-message.com","message":"友達になりませんか？"}'
```

成功時の応答例:
```json
{
  "data": {
    "id": "...",
    "from_user_id": "...",
    "to_user_id": "...",
    "status": "pending",
    "message": "友達になりませんか？",
    "created_at": "2025-08-25T12:12:41.002Z",
    "updated_at": "2025-08-25T12:12:41.002Z"
  },
  "message": "友達申請を送信しました"
}
```

### 予防策

#### 開発環境のリセット時
```bash
# データベース完全リセット（推奨）
npm run db:reset
```

#### 本番環境への注意
- 本番環境では、データベースマイグレーションスクリプトを使用
- インデックス削除前に必ずデータのバックアップを取得
- ダウンタイムが発生する可能性があることを考慮

### 関連ファイル
- バックエンドモデル: `backend/models/friend_request.go`
- データベースシーダー: `scripts/seeders/seed-simple.js`

### 修正履歴
- 2025-08-25: 古いインデックス問題の解決手順を文書化