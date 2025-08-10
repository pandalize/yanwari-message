# 🎭 AIトーン変換チューニング・テストガイド

このガイドは、**プログラマーでないチューニング担当者**がAIトーン変換の調整とテストを安全に行うためのマニュアルです。

## 📋 前提条件

- やんわり伝言サーバーが起動していること (`http://localhost:8080`)
- テスト用のユーザーアカウントでログインできること
- 基本的なcurlコマンドの実行環境があること

## 🚀 チューニング作業フロー

### 1. 現在の設定をテストして基準を確認

#### 1.1 ログインしてJWTトークンを取得
```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test-user@example.com","password":"testpassword123"}'
```

**レスポンス例:**
```json
{
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {...}
  }
}
```

#### 1.2 取得したトークンを環境変数に設定
```bash
export JWT_TOKEN="[上記で取得したaccess_token]"
```

#### 1.3 テスト用メッセージを作成
```bash
curl -X POST http://localhost:8080/api/v1/messages/draft \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d '{"originalText":"チューニングテスト用のメッセージです","recipientEmail":"hnn-a@gmail.com"}'
```

**成功レスポンス例:**
```json
{
  "data": {
    "id": "6857ece40a161ae7dd9fea79",
    "originalText": "チューニングテスト用のメッセージです"
  }
}
```

メッセージIDをメモしてください: `6857ece40a161ae7dd9fea79`

#### 1.4 現在の設定でトーン変換を実行（基準値として記録）
```bash
curl -X POST http://localhost:8080/api/v1/transform/tones \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d '{"messageId":"[上記のメッセージID]","originalText":"チューニングテスト用のメッセージです"}'
```

**出力結果をテキストファイルに保存:**
```bash
curl -X POST http://localhost:8080/api/v1/transform/tones \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d '{"messageId":"[メッセージID]","originalText":"チューニングテスト用のメッセージです"}' \
  > before_tuning.json
```

### 2. 設定ファイルを調整

#### 2.1 設定ファイルを開く
```bash
# 設定ファイルの場所
backend/config/tone_prompts.yaml
```

#### 2.2 調整例：優しめトーンをより丁寧に
```yaml
tones:
  gentle:
    characteristics:
      - "極めて丁寧な敬語を使用"  # 変更前: "丁寧語・敬語を使用"
      - "絵文字を多めに使用（😊🙏💦🌸✨など）"  # 絵文字追加
      - "深い感謝や謝罪の気持ちを表現"  # 変更前: "感謝や謝罪の気持ちを表現"
```

#### 2.3 調整例：カジュアルトーンの関西弁を調整
```yaml
  casual:
    characteristics:
      - "フレンドリーで親近感のある表現"
      - "軽い関西弁や話し言葉（「〜やで」「〜やん」など）"  # 具体例追加
      - "親しみやすい絵文字を使用（😊👋🎉など）"
```

### 3. 設定をリアルタイム反映（サーバー再起動不要）

```bash
curl -X POST http://localhost:8080/api/v1/transform/reload-config \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN"
```

**成功レスポンス:**
```json
{
  "message": "設定を再読み込みしました",
  "available_tones": {
    "casual": "🎯 カジュアルトーン",
    "constructive": "🏗️ 建設的トーン", 
    "gentle": "💝 優しめトーン"
  }
}
```

### 4. 調整後の効果をテスト

#### 4.1 同じメッセージで再度トーン変換を実行
```bash
curl -X POST http://localhost:8080/api/v1/transform/tones \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d '{"messageId":"[同じメッセージID]","originalText":"チューニングテスト用のメッセージです"}' \
  > after_tuning.json
```

#### 4.2 Before/After比較
```bash
# 調整前の結果
cat before_tuning.json

# 調整後の結果  
cat after_tuning.json
```

## 📊 効果測定方法

### A. 文体の変化確認
- **敬語レベル**: より丁寧/カジュアルになったか
- **絵文字使用**: 種類・数が期待通りか
- **文章構造**: 長さ・詳しさが適切か

### B. 実際のテストケース例

#### テストケース1: 会議延期の依頼
```bash
{"originalText":"明日の会議、準備が間に合わないので延期してもらえませんか？"}
```

#### テストケース2: お礼のメッセージ
```bash
{"originalText":"昨日はありがとうございました。とても勉強になりました。"}
```

#### テストケース3: 謝罪のメッセージ  
```bash
{"originalText":"返事が遅くなってすみません。"}
```

## 🔧 よくある調整パターン

### パターン1: より丁寧にしたい
```yaml
characteristics:
  - "極めて丁寧な敬語を使用"
  - "深い敬意と感謝を表現"
  - "クッション言葉を豊富に使用"
```

### パターン2: 絵文字を調整したい
```yaml
characteristics:
  - "絵文字を控えめに使用（😊🙏のみ）"  # 少なく
  - "絵文字を豊富に使用（😊🙏💦🌸✨🎉など）"  # 多く
```

### パターン3: ビジネス向けに調整
```yaml
characteristics:
  - "ビジネス敬語を使用"
  - "具体的な提案を含める"
  - "期限やスケジュールを明示"
```

## ⚠️ 安全な調整のための注意事項

### 1. バックアップを取る
```bash
# 調整前に必ずバックアップ
cp backend/config/tone_prompts.yaml backend/config/tone_prompts.yaml.backup
```

### 2. 段階的に調整する
- 一度に大きく変更せず、少しずつ調整
- 1つの特徴だけ変更して効果を確認

### 3. テンプレート構文を壊さない
- `{{.Characteristics}}` と `{{.OriginalText}}` は必須
- YAML構文（インデント）を正確に

### 4. 設定エラー時の対処
```bash
# エラーが出た場合はバックアップから復旧
cp backend/config/tone_prompts.yaml.backup backend/config/tone_prompts.yaml

# 設定を再読み込み
curl -X POST http://localhost:8080/api/v1/transform/reload-config \
  -H "Authorization: Bearer $JWT_TOKEN"
```

## 📝 チューニング記録テンプレート

```
## チューニング記録 [日付]

### 調整内容
- 対象トーン: gentle/constructive/casual
- 変更した特徴: [具体的な変更内容]
- 目的: [なぜこの調整をしたか]

### テスト結果
- テストメッセージ: "[使用したテストメッセージ]"
- 調整前の出力: "[前の結果]"
- 調整後の出力: "[新しい結果]"

### 評価
- 期待通りの変化: Yes/No
- 改善点: [さらに調整が必要な点]
- 次回調整予定: [次に試したい調整]
```

## 🚨 トラブルシューティング

### Q: トーン変換が動かない
A: JWTトークンの有効期限を確認。15分で期限切れするため、再ログインが必要。

### Q: 設定変更が反映されない
A: `/api/v1/transform/reload-config` を実行したか確認。

### Q: エラー「プロンプト生成エラー」が出る
A: YAML構文エラーの可能性。バックアップから復旧してやり直し。

### Q: 期待通りの結果にならない
A: 特徴の記述を具体的に。「丁寧に」→「恐縮ですがという表現を多用」など。

---

**チューニング担当者の皆様へ**  
このガイドに従って安全にAIトーン変換を調整できます。不明な点があれば開発チームまでお気軽にお問い合わせください。