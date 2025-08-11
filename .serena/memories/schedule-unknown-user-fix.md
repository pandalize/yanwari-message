# 送信予定「Unknown User」表示問題の修正 (2025年8月10日)

## 問題の概要
- 送信スケジュール一覧画面でユーザーが「Unknown User」として表示される
- ユーザー Alice がログインして送信予定画面で受信者情報が不明と表示される

## 根本原因の特定
1. **ScheduleList.vue**: メッセージIDのみ表示、受信者情報なし
2. **backend GetSchedules**: 基本的なスケジュールデータのみ返却
3. **データ分離**: Schedule と Message と User が分離されたコレクション

## 修正内容

### バックエンド修正
1. **新しい型定義追加** (`models/schedule.go`):
   ```go
   type ScheduleWithDetails struct {
       Schedule
       RecipientName  string `bson:"recipientName" json:"recipientName"`
       RecipientEmail string `bson:"recipientEmail" json:"recipientEmail"`
       OriginalText   string `bson:"originalText" json:"originalText"`
       FinalText      string `bson:"finalText" json:"finalText"`
       SelectedTone   string `bson:"selectedTone" json:"selectedTone"`
   }
   ```

2. **MongoDB集約クエリ実装** (`GetSchedulesWithDetails`メソッド):
   - スケジュール → メッセージ → ユーザー の3つのコレクション結合
   - `$lookup` と `$unwind` を使用した効率的なデータ取得
   - 受信者名の生成ロジック: `recipient.name` または `email.split("@")[0]`

3. **ハンドラー修正** (`handlers/schedules.go`):
   - `GetSchedules` → `GetSchedulesWithDetails` に変更
   - 受信者詳細情報付きレスポンス返却

### フロントエンド修正  
1. **TypeScript型定義更新** (`services/scheduleService.ts`):
   ```typescript
   export interface Schedule {
     // 既存フィールド...
     recipientName?: string
     recipientEmail?: string
     originalText?: string
     finalText?: string
     selectedTone?: string
   }
   ```

2. **UI表示改善** (`ScheduleList.vue`):
   - 受信者情報セクション追加: 名前・メールアドレス表示
   - メッセージプレビューセクション追加: 本文・トーン表示  
   - 美しいカードレイアウト・アイコン・色分け追加

## 期待される結果
- 送信者名の適切な表示（name フィールドまたはメール前半部分）
- メッセージ本文・トーンの視認性向上
- 「Unknown User」表示の完全解消
- 送信スケジュールの詳細情報可視化

## 技術的ポイント
- MongoDB集約パイプライン活用による効率的なJOIN操作
- フォールバック戦略: name → email.split("@")[0] → "Unknown User"
- TypeScript型安全性保証と段階的な型拡張
- UIコンポーネントの責任分離とスタイリング改善