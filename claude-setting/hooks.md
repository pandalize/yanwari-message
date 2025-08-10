# Claude Code Hooks 設定ガイド

## 音声通知の設定

### macOS音声通知

1. **設定ファイルの編集**
   ```bash
   nano ~/.claude/settings.json
   ```

2. **音声通知設定の追加**
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

3. **利用可能な音声ファイル確認**
   ```bash
   ls /System/Library/Sounds/*.aiff
   ```

### ずんだもん音声通知（VOICEVOX連携）

1. **VOICEVOXの起動**
   ```bash
   # VOICEVOXを事前に起動しておく
   ```

2. **設定ファイルに追加**
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

## プッシュ通知の設定

### ntfyを使用したスマホ通知

1. **ntfyのインストール**
   ```bash
   # Homebrewの場合
   brew install ntfy
   ```

2. **設定ファイルに追加**
   ```json
   {
     "hooks": {
       "Notification": [{
         "matcher": "",
         "hooks": [{
           "type": "command",
           "command": "curl -d \"Claude Codeが承認を待っています\" ntfy.sh/your-topic-name"
         }]
       }],
       "Stop": [{
         "matcher": "",
         "hooks": [{
           "type": "command",
           "command": "curl -d \"Claude Codeのタスクが完了しました\" ntfy.sh/your-topic-name"
         }]
       }]
     }
   }
   ```

3. **スマホアプリのセットアップ**
   - iOS/Androidでntfyアプリをインストール
   - 同じトピック名（your-topic-name）を購読

### macOSデスクトップ通知

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

## 複合設定例（音声＋通知）

```json
{
  "hooks": {
    "Notification": [{
      "matcher": "",
      "hooks": [
        {
          "type": "command",
          "command": "afplay /System/Library/Sounds/Glass.aiff"
        },
        {
          "type": "command",
          "command": "osascript -e 'display notification \"Claude Codeが許可を求めています\" with title \"Claude Code\" subtitle \"確認待ち\"'"
        },
        {
          "type": "command",
          "command": "curl -d \"Claude Code: 承認待ち\" ntfy.sh/your-topic-name"
        }
      ]
    }],
    "Stop": [{
      "matcher": "",
      "hooks": [
        {
          "type": "command",
          "command": "afplay /System/Library/Sounds/Hero.aiff"
        },
        {
          "type": "command",
          "command": "osascript -e 'display notification \"タスクが完了しました\" with title \"Claude Code\" subtitle \"処理終了\"'"
        },
        {
          "type": "command",
          "command": "curl -d \"Claude Code: タスク完了\" ntfy.sh/your-topic-name"
        }
      ]
    }]
  }
}
```

## Hookイベントの種類

- **Notification**: 承認要求時に発動
- **Stop**: タスク完了時に発動
- **UserPromptSubmit**: ユーザープロンプト送信時
- **PreToolUse**: ツール使用前
- **PostToolUse**: ツール使用後
- **SubagentStop**: サブエージェント終了時

## 設定の反映

1. 設定ファイルを保存
2. Claude Codeセッションを再起動
3. 新しいセッションで設定が有効になる

## トラブルシューティング

- **音が鳴らない場合**
  - macOSのシステム音量を確認
  - ファイルパスが正しいか確認
  - `afplay`コマンドが使用可能か確認

- **通知が表示されない場合**
  - macOSの通知設定でターミナルの通知を許可
  - `osascript`の実行権限を確認

- **ntfy通知が届かない場合**
  - トピック名が一致しているか確認
  - インターネット接続を確認
  - スマホアプリで正しくトピックを購読しているか確認