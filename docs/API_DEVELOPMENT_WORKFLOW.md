# API開発統一ワークフロー

## 概要

フロントエンドとバックエンドのAPI不一致問題を解決するため、OpenAPI/Swaggerベースの自動生成システムを導入しました。

## 🎯 解決する問題

- ❌ 「Unknown User」表示問題
- ❌ フロント・バックエンドの型定義不一致
- ❌ API仕様の非同期化
- ❌ 手動での型管理によるバグ

## 🔄 開発ワークフロー

### 1. 初期セットアップ

```bash
# 必要ツールのインストール
npm run swagger:install
```

### 2. API変更時の流れ

```bash
# 1. バックエンドのSwaggerアノテーション追加/更新
# 2. API仕様とフロント型定義を同期
npm run api:sync

# 3. 自動生成された型を確認
# - frontend/src/types/api/api.ts
# - backend/docs/swagger.json
```

### 3. 開発時のベストプラクティス

#### バックエンド開発者

```go
// ✅ 必ずSwaggerアノテーションを追加
// @Summary メッセージ一覧取得
// @Description 認証されたユーザーの送信済みメッセージを取得
// @Tags messages
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param page query int false "ページ番号" default(1)
// @Success 200 {object} MessageListResponse
// @Router /api/v1/messages [get]
func (h *MessageHandler) GetMessages(c *gin.Context) {
    // 実装...
}
```

#### フロントエンド開発者

```typescript
// ✅ 生成された型を使用
import { MessageWithRecipientInfo, MessageResponse } from '@/types/api/api'

// ❌ 手動型定義は禁止
// interface Message { ... }

// ✅ 自動生成型を使用
const message: MessageWithRecipientInfo = {
    recipientName: 'John Doe', // 型安全に保証される
    // ...
}
```

## 📁 ファイル構成

```
backend/
├── docs/
│   ├── swagger.json     # 自動生成されたAPI仕様
│   └── swagger.yaml
└── handlers/
    └── *.go            # Swaggerアノテーション付きハンドラー

frontend/
├── src/
│   ├── types/
│   │   └── api/
│   │       └── api.ts  # 自動生成されたTypeScript型
│   └── services/
│       └── generated/
│           └── apiClient.ts # 自動生成されたAPIクライアント
└── package.json

scripts/
└── swagger-generate.sh  # 自動生成スクリプト
```

## 🛠️ コマンド一覧

| コマンド | 用途 |
|---------|------|
| `npm run swagger:install` | 必要ツールのインストール |
| `npm run swagger:generate` | API仕様とフロント型生成 |
| `npm run api:sync` | API仕様同期（生成+メッセージ） |
| `cd frontend && npm run types:generate` | フロント型定義のみ生成 |

## 🔍 Unknown User問題の解決

### 問題の原因
```go
// ❌ 以前: recipientNameフィールドが存在しない
type Message struct {
    RecipientID primitive.ObjectID `json:"recipientId"`
    // recipientNameが無い
}
```

### 解決策
```go
// ✅ 解決: 統一レスポンス型を作成
type MessageWithRecipientInfo struct {
    Message
    RecipientName  string `json:"recipientName,omitempty"`
    RecipientEmail string `json:"recipientEmail,omitempty"`
}
```

## 🚀 導入効果

1. **型安全性**: コンパイル時エラーでAPI不一致を検出
2. **開発効率**: 手動型管理が不要
3. **品質向上**: Unknown User等の表示問題を根本解決
4. **保守性**: 単一の仕様書から自動生成

## 🔧 トラブルシューティング

### Swaggerが生成されない場合

```bash
# Go Swaggerツールの確認
which swag
go install github.com/swaggo/swag/cmd/swag@latest

# アノテーション確認
cd backend
swag init -g main.go -o docs/
```

### 型生成が失敗する場合

```bash
# ツールインストール確認  
cd frontend
npm install swagger-typescript-api

# 手動生成テスト
npx swagger-typescript-api -p ../backend/docs/swagger.json -o src/types/api --name api.ts --no-client
```

## 📋 チェックリスト

- [ ] 新しいAPIエンドポイントにSwaggerアノテーション追加済み
- [ ] `npm run api:sync`で型定義更新済み
- [ ] フロントエンドで生成型を使用済み
- [ ] 「Unknown User」等の表示問題が解決済み
- [ ] 型エラーがコンパイル時に検出されることを確認済み