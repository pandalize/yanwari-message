# Claude Code Hooks 面白い実装例

## GitHub OSS プロジェクト

### 1. Claude Code Hooks Mastery
**作者:** disler  
**リンク:** https://github.com/disler/claude-code-hooks-mastery

**特徴:**
- 全6種類のhookイベント（UserPromptSubmit, PreToolUse, PostToolUse, Notification, Stop, SubagentStop）の活用例
- プロンプト検証機能
- インテリジェントTTSシステム
- セキュリティ強化機能
- パーソナライズ体験
- 自動ログ機能
- チャット記録自動抽出

### 2. Claude Code Hooks Multi-Agent Observability
**作者:** disler  
**リンク:** https://github.com/disler/claude-code-hooks-multi-agent-observability

**特徴:**
- リアルタイム監視・可視化システム
- 複数エージェントの同時監視
- セッション追跡機能
- イベントフィルタリング
- ライブ更新機能

### 3. Awesome Claude Code
**作者:** hesreallyhim  
**リンク:** https://github.com/hesreallyhim/awesome-claude-code

**特徴:**
- Claude Codeのコマンド、ファイル、ワークフローのキュレーションリスト
- hooks実験的リソース集
- エージェントライフサイクル制御例

### 4. gh-asset Tool
**作者:** YuitoSato  
**リンク:** https://github.com/YuitoSato/gh-asset

**特徴:**
- GitHub Issues・PR内の画像にClaude Codeからアクセス可能
- プライベートリポジトリにも対応
- Claude Codeが完全自動実装

### 5. Claude Code Hooks SDK (PHP)
**作者:** beyondcode

**特徴:**
- Laravel風PHP SDK
- 構造化JSON応答生成
- 表現力豊かなチェイン可能API

### 6. TDD Guard
**作者:** Nizar Selander

**特徴:**
- リアルタイムファイル操作監視
- TDD原則違反の変更をブロック
- hooks駆動システム

## 日本のQiita/Zenn面白実装

### 1. ずんだもん音声通知
**記事:** https://zenn.dev/nikechan/articles/ac9cdfbeb412f5  
**作者:** ニケちゃん

**特徴:**
- VOICEVOXとの連携
- ずんだもんが「クロードコードが呼んでいます」と音声通知
- Notification hookで承認依頼時に発動

**実装例:**
```json
{
  "hooks": {
    "Notification": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "bash -c 'read -r j; txt=\"クロードコードが呼んでいます。\"; f=$(mktemp /tmp/vv_XXXXXX.wav); curl -s -X POST \"http://127.0.0.1:50021/audio_query?speaker=1\" --get --data-urlencode text=\"${txt}\" | curl -s -X POST -H \"Content-Type: application/json\" -d @- \"http://127.0.0.1:50021/synthesis?speaker=1\" -o \"$f\"; afplay \"$f\"; rm \"$f\"'"
      }]
    }]
  }
}
```

### 2. スマホ通知システム
**記事:** https://zenn.dev/keit0728/articles/bfb68f669755a7  
**作者:** keit0728

**特徴:**
- ntfyを使用したプッシュ通知
- 承認依頼時とタスク完了時にスマホへ通知
- リモート作業時の見逃し防止

### 3. 作業完了通知まとめ
**記事:** https://zenn.dev/karaage0703/articles/1cb99d9fca145f  
**作者:** karaage0703

**特徴:**
- macOS通知センター活用
- 音声合成（say command）
- デスクトップ通知とサウンドの組み合わせ

### 4. Hooks完了通知設定
**記事:** https://zenn.dev/the_exile/articles/claude-code-hooks  
**作者:** the_exile

**特徴:**
- 基本的なhooks設定方法
- 設定ファイルの管理方法
- プロジェクト固有設定

## 設定ファイル例

### 基本的なmacOS通知
```json
{
  "hooks": {
    "Notification": [{
      "matcher": "",
      "hooks": [{
        "type": "command", 
        "command": "osascript -e 'display notification \"Claude Codeが許可を求めています\" with title \"Claude Code\" subtitle \"確認待ち\" sound name \"Glass\"'"
      }]
    }],
    "Stop": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "osascript -e 'display notification \"タスクが完了しました\" with title \"Claude Code\" subtitle \"処理終了\" sound name \"Hero\"'"
      }]
    }]
  }
}
```

### 音声通知
```json
{
  "hooks": {
    "Stop": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "afplay /System/Library/Sounds/Glass.aiff"
      }]
    }]
  }
}
```

## 実際の設定手順

### グローバル音声通知設定

1. **設定ファイルの場所確認**
   ```bash
   ls -la ~/.claude/
   ```

2. **現在の設定内容確認**
   ```bash
   cat ~/.claude/settings.json
   ```

3. **音声通知設定の追加**
   `~/.claude/settings.json`に以下の設定を追加：
   ```json
   {
     "hooks": {
       "Notification": [{
         "matcher": "",
         "hooks": [{
           "type": "command",
           "command": "afplay /System/Library/Sounds/Glass.aiff"
         }]
       }],
       "Stop": [{
         "matcher": "",
         "hooks": [{
           "type": "command",
           "command": "afplay /System/Library/Sounds/Hero.aiff"
         }]
       }]
     }
   }
   ```

4. **音声ファイルの確認**
   ```bash
   ls /System/Library/Sounds/ | grep -E "(Glass|Hero).aiff"
   ```

5. **設定反映**
   Claude Codeセッションを再起動して設定を反映

### 音声通知の動作

- **Notification hook**: 承認要求時にGlass.aiffが再生
- **Stop hook**: タスク完了時にHero.aiffが再生
- **グローバル設定**: 全セッション・全プロジェクトで有効

### 2025-07-20 セッション

現在の設定は`~/.claude/settings.json`にあります。このファイルを編集すればPC全体のClaude Code設定が変更されます。現在は音声通知とntfy通知が設定されています。

他に設定できる項目：
- 他のhookイベント（PreToolUse、PostToolUse、UserPromptSubmit、SubagentStop）
- プロジェクト固有の設定は`~/.claude/projects/`内
- IDE統合設定は`~/.claude/ide/`内

**ユーザー:** ここまでをclaude.mdに追記
