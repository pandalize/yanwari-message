# やんわり伝言アプリ - テスト・動作確認ワークフロー

## 🔄 完全な再現性テスト手順

### 1. 開発環境の完全停止・再起動

#### 停止
```bash
npm run dev:stop
```

#### 状況確認
```bash
npm run dev:status
```

#### 再起動
```bash
npm run dev
```

### 2. データベース完全リセット・再投入
```bash
# 新しいターミナルで実行
npm run db:reset && npm run db:seed
```

### 3. Firebase Emulator ユーザー作成
```bash
npm run test:firebase-integration
```

### 4. ブラウザ動作確認
1. ブラウザで `http://localhost:5173` にアクセス
2. ログイン: `alice@yanwari.com` / `testpassword123`
3. 受信トレイで以下をテスト：
   - ✅ メッセージ表示（Bob デモからのメッセージ）
   - ✅ メッセージクリックで既読処理
   - ✅ 星評価機能（1-5段階）
   - ✅ ツリーマップ表示

### 5. データベース内容確認
```bash
node -e "
const { MongoClient } = require('mongodb');
require('dotenv').config({ path: './backend/.env' });
async function check() {
    const client = new MongoClient(process.env.MONGODB_URI);
    try {
        await client.connect();
        const db = client.db();
        const messages = await db.collection('messages').find({}).toArray();
        const ratings = await db.collection('message_ratings').find({}).toArray();
        const users = await db.collection('users').find({}).toArray();
        console.log('👥 ユーザー数:', users.length);
        console.log('📬 メッセージ数:', messages.length);
        console.log('⭐ 評価数:', ratings.length);
        console.log('');
        messages.forEach(msg => {
            console.log('Message:', msg.finalText?.substring(0, 30) + '...', 'Status:', msg.status);
        });
    } finally { await client.close(); }
}
check().catch(console.error);"
```

## 🧪 個別テストコマンド

### データベーステスト
```bash
# データベースリセットのみ
npm run db:reset

# サンプルデータ投入のみ
npm run db:seed

# 認証用最小データのみ
npm run db:seed:auth-only

# メッセージ付きデータ
npm run db:seed:messages

# 全機能テストデータ
npm run db:seed:full
```

### Firebase Emulator テスト
```bash
# Firebase ユーザー作成・確認
npm run test:firebase-integration

# Firebase Emulator UI
# ブラウザで http://127.0.0.1:4000/ にアクセス
```

### 個別サービス起動
```bash
# バックエンドのみ
npm run dev:backend

# フロントエンドのみ  
npm run dev:frontend

# Firebase Emulator のみ
firebase emulators:start --only auth
```

## 🔍 トラブルシューティング

### ポートが使用中の場合
```bash
# ポート確認
lsof -i:5173 -i:8080 -i:9099

# 強制終了
kill -9 $(lsof -ti:5173)
kill -9 $(lsof -ti:8080) 
kill -9 $(lsof -ti:9099)
```

### MongoDB 接続エラー
```bash
# 環境変数確認
cat backend/.env | grep MONGODB_URI

# 接続テスト
node -e "
const { MongoClient } = require('mongodb');
require('dotenv').config({ path: './backend/.env' });
const client = new MongoClient(process.env.MONGODB_URI);
client.connect().then(() => {
  console.log('✅ MongoDB 接続成功');
  client.close();
}).catch(err => console.error('❌ MongoDB 接続失敗:', err));"
```

### Firebase Emulator エラー
```bash
# Firebase CLI バージョン確認
firebase --version

# Firebase プロジェクト確認
firebase projects:list

# Firebase Emulator 再起動
firebase emulators:start --only auth
```

## 📝 期待される結果

### 正常な起動状態
- **Frontend**: http://localhost:5173 でアクセス可能
- **Backend**: http://localhost:8080/health でヘルスチェック成功
- **Firebase Emulator**: http://127.0.0.1:4000/ でUI表示

### テストデータ内容
- **ユーザー**: Alice, Bob, Charlie (3人)
- **メッセージ**: Bob→Alice (1件, status: 'delivered')
- **友達関係**: Alice-Bob, Alice-Charlie (2件)
- **評価**: Bob のメッセージに4つ星評価 (1件)

### 動作確認項目
- [x] ログイン成功
- [x] メッセージ受信トレイ表示
- [x] メッセージ詳細表示・既読処理
- [x] 星評価機能（1-5段階）
- [x] ツリーマップ可視化表示
- [x] 送信者名正常表示（「Bob デモ」）
- [x] トークン自動リフレッシュ機能