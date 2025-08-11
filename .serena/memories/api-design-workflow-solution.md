# API設計統一ワークフロー・システム解決策

## 問題の背景
- フロントエンドとバックエンドのAPI不一致により「Unknown User」表示問題が発生
- recipientNameフィールドがバックエンドのMessageモデルに存在しないため
- 手動での型定義管理によるバグの頻発
- API仕様の非同期化による開発効率低下

## 解決策の概要
OpenAPI/Swaggerベースの自動生成システムを構築し、単一の設計書から自動的にフロントエンドの型定義を生成する統一ワークフローを実装。

## 実装したファイル・機能

### 1. 自動生成スクリプト
- `scripts/swagger-generate.sh` - Swagger仕様書からフロントエンド型定義を自動生成

### 2. package.jsonコマンド拡張
- `swagger:generate` - API仕様とフロント型生成
- `swagger:install` - 必要ツールのインストール  
- `api:sync` - API仕様同期（生成+完了通知）

### 3. バックエンド型定義の改善
- `backend/models/message.go`に以下を追加:
  - `MessageResponse` - APIレスポンス統一型
  - `MessageWithRecipientInfo` - 受信者情報付きメッセージ型（recipientName問題解決）
- Swaggerアノテーションの改善（handlers/messages.goのCreateDraftメソッド）

### 4. フロントエンド設定
- `frontend/package.json`に`types:generate`コマンド追加
- 自動生成される型定義: `frontend/src/types/api/api.ts`

### 5. 開発環境統合
- `.vscode/tasks.json` - VSCodeタスク統合
- `docs/API_DEVELOPMENT_WORKFLOW.md` - 詳細な開発ワークフローガイド

## 使用方法

### 初回セットアップ
```bash
npm run swagger:install
```

### API変更時のワークフロー
```bash
# 1. バックエンドでSwaggerアノテーション追加/更新
# 2. 仕様書と型定義を同期
npm run api:sync
# 3. フロントエンドで生成された型を使用
```

### フロントエンドでの型使用例
```typescript
import { MessageWithRecipientInfo, MessageResponse } from '@/types/api/api'

const message: MessageWithRecipientInfo = {
    recipientName: 'John Doe', // 型安全に保証
    // ...
}
```

## 効果
1. **型安全性**: コンパイル時エラーでAPI不一致を検出
2. **開発効率**: 手動型管理が不要、ワンコマンド同期
3. **品質向上**: Unknown User等の表示問題を根本解決
4. **保守性**: 単一の仕様書から自動生成

## 技術スタック
- OpenAPI/Swagger（API仕様書）
- swag（Go Swagger生成ツール）
- swagger-typescript-api（TypeScript型生成）
- 既存のGin + Vue.js + TypeScript環境

## ファイル構成
```
backend/docs/swagger.json          # 自動生成API仕様書
frontend/src/types/api/api.ts      # 自動生成TypeScript型
scripts/swagger-generate.sh       # 自動生成スクリプト
docs/API_DEVELOPMENT_WORKFLOW.md  # 開発ワークフローガイド
.vscode/tasks.json                # VSCode統合
```