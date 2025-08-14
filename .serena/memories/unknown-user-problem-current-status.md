# Unknown User問題の現状分析

## ✅ 解決済み（基盤構築完了）

### 1. API自動生成・同期システム
- **バックエンド**: `GetSentMessagesResponse`構造体追加済み
- **Swagger**: `GetSentMessages`ハンドラーで具体的型定義使用
- **TypeScript型定義**: `ModelsMessageWithRecipientInfo`に`recipientName`フィールド含有を確認
- **生成スクリプト**: `swagger-generate.sh`の`swagger-typescript-api`コマンド修正済み

### 2. 送信済みメッセージ表示（HistoryView.vue）
- **場所**: `frontend/src/views/HistoryView.vue`の`loadSentMessages`関数
- **状態**: 新しいAPI型定義（`ModelsMessageWithRecipientInfo`）を使用するよう更新済み
- **API**: `/messages/sent`エンドポイント
- **期待**: バックエンドから`recipientName`が正しく返却されれば表示される

## ❌ 未解決（要対応）

### 1. スケジュール一覧表示
- **場所**: `frontend/src/components/schedule/ScheduleList.vue:64`
```vue
<p class="recipient-name">🎯 送信先: {{ schedule.recipientName || 'Unknown User' }}</p>
```
- **問題**: スケジュール情報にrecipientNameフィールドがない
- **必要な対応**: スケジュールAPIでrecipientName返却の実装

### 2. 受信ボックス表示（Inbox）
- **場所**: `frontend/src/components/inbox/InboxList.vue:252`
```typescript
senderName: msg.senderName || 'Unknown User',
```
- **問題**: 受信メッセージでsenderNameフィールドがない
- **必要な対応**: 受信メッセージAPIでsenderName返却の実装

### 3. 固定履歴表示（FixedHistoryView）
- **場所**: `frontend/src/views/FixedHistoryView.vue:137`
```typescript
let recipientName = 'Unknown User'
```
- **問題**: 手動でrecipientName取得ロジックを実装している
- **必要な対応**: 自動生成API型定義の活用

### 4. 履歴詳細表示（HistoryView内の複数箇所）
- **場所**: `frontend/src/views/HistoryView.vue`の3箇所
  - Line 362: `let recipientName = 'Unknown User'`
  - Line 413: `let recipientName = 'Unknown User'`  
  - Line 499: `let recipientName = 'Unknown User'`
- **問題**: 手動でユーザー情報取得している
- **必要な対応**: 自動生成API型定義の活用

### 5. メッセージサービスのユーザー情報取得
- **場所**: `frontend/src/services/messageService.ts`の複数箇所
- **問題**: ユーザー情報取得失敗時のフォールバック
- **状態**: これは適切なエラーハンドリングなので維持

## 📋 対応が必要なAPI

### 1. スケジュール関連API
- **エンドポイント**: `/schedules/` 
- **必要な修正**: レスポンスにrecipientNameを含める
- **対応方法**: `ScheduleWithRecipientInfo`構造体の作成とSwagger注釈更新

### 2. 受信メッセージAPI
- **エンドポイント**: `/messages/received`
- **必要な修正**: レスポンスにsenderNameを含める  
- **対応方法**: `MessageWithSenderInfo`構造体の作成とSwagger注釈更新

### 3. 個別メッセージ取得API
- **エンドポイント**: `/messages/{id}`
- **必要な修正**: recipientName/senderNameを含める
- **対応方法**: 既存のMessageWithRecipientInfo活用

## 🎯 優先順位

### 高優先度
1. **スケジュール一覧**: ユーザーが最も頻繁に見る画面
2. **受信ボックス**: メッセージの送信者が分からないのは致命的

### 中優先度  
3. **履歴詳細**: 詳細画面での表示改善
4. **固定履歴**: 使用頻度は比較的低い

## 📊 解決率
- **解決済み**: 1/9箇所（約11%）
- **未解決**: 8/9箇所（約89%）
- **基盤構築**: 完了（今後の修正を効率化）