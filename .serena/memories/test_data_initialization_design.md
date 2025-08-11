# テストデータ初期化システム設計

## 課題
現在、テスト実行時に適切なデータが入っていないケースがある：
- 空のデータベース状態
- 不整合なテストデータ
- 各テストでのデータ準備の手間
- 開発者間でのテスト環境の差異

## 目標
- 毎回データベースを初期化して適切なデータが入っている状態に簡単にできるシステム
- 一貫したテストデータセット
- 簡単なコマンドでの実行

## 設計方針

### 1. データベース初期化システム
```bash
# 完全リセット + サンプルデータ投入
npm run db:reset

# サンプルデータのみ投入（データベースはクリアしない）
npm run db:seed

# 特定のデータセットのみ
npm run db:seed --dataset=auth-only
npm run db:seed --dataset=messages
npm run db:seed --dataset=full
```

### 2. 階層化されたデータセット
- **auth-only**: 認証用最小データ（ユーザー2-3名）
- **messages**: メッセージ・友達関係・評価データ含む
- **full**: 全機能のテストデータ（大量データ含む）

### 3. ファイル構造
```
backend/
├── scripts/
│   ├── db-reset.js         # データベース完全リセット
│   ├── db-seed.js          # サンプルデータ投入
│   └── test-data/
│       ├── users.json      # テストユーザーデータ
│       ├── messages.json   # サンプルメッセージデータ
│       ├── friendships.json # 友達関係データ
│       └── ratings.json    # 評価データ
```

### 4. 実装機能

#### A. データベースリセット機能
- MongoDB全コレクションのクリア
- インデックスの再作成
- 接続確認・エラーハンドリング

#### B. サンプルデータ投入機能
- JSON形式のテストデータ読み込み
- 関連性のあるデータの整合性確保
- 段階的データ投入（users → friendships → messages → ratings）

#### C. 環境別設定
```javascript
// 本番環境では絶対に実行されない安全機構
if (process.env.NODE_ENV === 'production') {
  console.error('ERROR: テストデータ初期化は本番環境では実行できません');
  process.exit(1);
}
```

### 5. テストデータ内容

#### users.json
```json
[
  {
    "_id": "test_user_001",
    "email": "alice@yanwari.com",
    "name": "Alice テスター",
    "firebase_uid": "test_firebase_uid_001"
  },
  {
    "_id": "test_user_002", 
    "email": "bob@yanwari.com",
    "name": "Bob デモ",
    "firebase_uid": "test_firebase_uid_002"
  }
]
```

#### friendships.json
```json
[
  {
    "user1_id": "test_user_001",
    "user2_id": "test_user_002",
    "created_at": "2025-01-01T00:00:00Z"
  }
]
```

#### messages.json
```json
[
  {
    "sender_id": "test_user_001",
    "recipient_id": "test_user_002", 
    "original_text": "今日は疲れたよ！！！",
    "variations": {
      "gentle": "本日はとても疲労を感じました。少し休息を取りたいと思います。",
      "constructive": "今日は大変でしたが、明日に向けて休息を取らせていただければと思います。",
      "casual": "今日めっちゃ疲れた！ちょっと休ませて〜"
    },
    "selected_tone": "gentle",
    "final_text": "本日はとても疲労を感じました。少し休息を取りたいと思います。",
    "status": "sent",
    "sent_at": "2025-01-01T09:00:00Z"
  }
]
```

#### ratings.json
```json
[
  {
    "message_id": "message_001",
    "rating": 4,
    "created_at": "2025-01-01T10:00:00Z"
  }
]
```

### 6. 統合テストサポート

#### テスト前自動実行
```javascript
// tests/setup.js
beforeAll(async () => {
  await require('../scripts/db-reset');
  await require('../scripts/db-seed');
});
```

#### APIテストとの連携
```bash
# API_TEST_COMMANDS.mdの更新
# テストデータ初期化後のテストコマンド提供
npm run db:reset && ./test_message.sh
```

### 7. 開発ワークフロー統合

#### yanwari-startスクリプト統合
```bash
# 開発環境起動時の選択肢
./yanwari-start --fresh-db    # データベース初期化付き起動
./yanwari-start --seed-only   # サンプルデータ投入のみ
```

### 8. ログ・モニタリング
- データ投入処理の詳細ログ
- 投入データ数の確認
- エラー時の詳細情報
- 処理時間の計測

### 9. セキュリティ考慮
- 本番環境での実行防止
- テスト用Firebase UIDの使用
- 実際のユーザーデータとの分離
- テスト用メールアドレスの使用

### 10. 将来拡張

#### データバリエーション
- 大量データテスト用セット
- パフォーマンステスト用データ
- エラーケーステスト用データ

#### 自動化
- CI/CD環境でのテストデータ自動セットアップ
- テスト実行後のクリーンアップ
- 並行テスト用の分離されたデータベース

## 実装順序

1. **Phase 1**: 基本的なdb-reset.js, db-seed.js実装
2. **Phase 2**: JSONテストデータファイル作成
3. **Phase 3**: package.jsonスクリプト統合
4. **Phase 4**: yanwari-startスクリプト統合
5. **Phase 5**: APIテストとの統合