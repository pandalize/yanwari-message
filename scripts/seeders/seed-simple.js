// MongoDB 開発環境シーダースクリプト（簡単版）
// 使用方法: mongosh "mongodb://localhost:27017/yanwari-message" scripts/seeders/seed-simple.js

// データベース接続
const DB_NAME = 'yanwari-message';
db = db.getSiblingDB(DB_NAME);

// 色付きログ関数
function logInfo(message) {
    print(`🌱 [SEEDER] ${message}`);
}

function logSuccess(message) {
    print(`✅ [SEEDER] ${message}`);
}

function logError(message) {
    print(`❌ [SEEDER] ${message}`);
}

// サンプルデータを直接定義（正しいbcryptハッシュ使用）
const usersData = [
  {
    "name": "田中 あかり",
    "email": "alice@yanwari-message.com",
    "password_hash": "$2b$10$aU5wSSZqniz5Ltyd32Tk9uohg0FQowQqPldIwRC9njei6JI6HZzaq",
    "profile": {
      "bio": "デザイナーとして働いています。美しいデザインと心地よいコミュニケーションを大切にしています。",
      "avatar_url": "https://api.dicebear.com/7.x/avataaars/svg?seed=alice",
      "timezone": "Asia/Tokyo"
    },
    "created_at": "2025-01-15T09:00:00.000Z",
    "updated_at": "2025-01-18T10:00:00.000Z"
  },
  {
    "name": "佐藤 ひろし",
    "email": "bob@yanwari-message.com",
    "password_hash": "$2b$10$DIg5ZvV2225OhqwK0kTqleqT.UZlFn6R3MVk5b4fZBqVp0iFNLAxu",
    "profile": {
      "bio": "エンジニアとして新しい技術を学び続けています。チームワークを重視した開発が得意です。",
      "avatar_url": "https://api.dicebear.com/7.x/avataaars/svg?seed=bob",
      "timezone": "Asia/Tokyo"
    },
    "created_at": "2025-01-16T10:30:00.000Z",
    "updated_at": "2025-01-18T08:45:00.000Z"
  },
  {
    "name": "鈴木 みゆき",
    "email": "charlie@yanwari-message.com",
    "password_hash": "$2b$10$P5.ZtjozIfx/F3ubB6KfFuNCN6IEOyBsDbJHoHebWju/GBxKnfOdO",
    "profile": {
      "bio": "プロジェクトマネージャーとして、チームの調和と効率的な進行をサポートしています。",
      "avatar_url": "https://api.dicebear.com/7.x/avataaars/svg?seed=charlie",
      "timezone": "Asia/Tokyo"
    },
    "created_at": "2025-01-17T14:15:00.000Z",
    "updated_at": "2025-01-18T16:20:00.000Z"
  }
];

// メイン実行関数
function seedDevelopmentData() {
    logInfo('開発環境のサンプルデータ投入を開始します...');
    
    try {
        // 1. 既存データのクリア
        logInfo('既存データをクリアしています...');
        db.users.deleteMany({});
        db.messages.deleteMany({});
        db.friendships.deleteMany({});
        db.message_ratings.deleteMany({});
        db.user_settings.deleteMany({});
        logSuccess('既存データのクリアが完了しました');
        
        // 2. ユーザーデータの投入
        logInfo('ユーザーデータを投入中...');
        
        const userIdMap = {};
        const processedUsers = usersData.map(user => {
            const newId = ObjectId();
            userIdMap[user.email] = newId;
            
            return {
                ...user,
                _id: newId,
                created_at: new Date(user.created_at),
                updated_at: new Date(user.updated_at)
            };
        });
        
        const userResult = db.users.insertMany(processedUsers);
        logSuccess(`${userResult.insertedIds.length}件のユーザーを投入しました`);
        
        // 3. 友達関係データの投入
        logInfo('友達関係データを投入中...');
        const aliceId = userIdMap["alice@yanwari-message.com"];
        const bobId = userIdMap["bob@yanwari-message.com"];
        const charlieId = userIdMap["charlie@yanwari-message.com"];
        
        const friendships = [
            {
                _id: ObjectId(),
                user1_id: aliceId,
                user2_id: bobId,
                status: "accepted",
                created_at: new Date("2025-01-16T12:00:00.000Z"),
                updated_at: new Date("2025-01-16T12:00:00.000Z")
            },
            {
                _id: ObjectId(),
                user1_id: aliceId,
                user2_id: charlieId,
                status: "accepted",
                created_at: new Date("2025-01-17T15:30:00.000Z"),
                updated_at: new Date("2025-01-17T15:30:00.000Z")
            },
            {
                _id: ObjectId(),
                user1_id: bobId,
                user2_id: charlieId,
                status: "accepted",
                created_at: new Date("2025-01-17T16:45:00.000Z"),
                updated_at: new Date("2025-01-17T16:45:00.000Z")
            }
        ];
        
        const friendshipResult = db.friendships.insertMany(friendships);
        logSuccess(`${friendshipResult.insertedIds.length}件の友達関係を投入しました`);
        
        // 4. メッセージデータの投入
        logInfo('メッセージデータを投入中...');
        const messages = [
            {
                _id: ObjectId(),
                sender_id: aliceId,
                recipient_email: "bob@yanwari-message.com",
                recipient_id: bobId,
                original_text: "明日の会議なんですが、資料の準備が遅れていませんか？",
                transformed_versions: {
                    gentle: {
                        text: "お疲れ様です。明日の会議の件でご連絡いたします。資料のご準備はいかがでしょうか？もしお時間が必要でしたら、お気軽にお声がけください。",
                        reasoning: "直接的な指摘を避け、相手への配慮を示しながら確認する表現に変更しました。"
                    },
                    constructive: {
                        text: "明日の会議について確認です。資料の準備状況を教えていただけますか？必要でしたら、一緒に準備を進めることも可能です。",
                        reasoning: "問題解決志向で、協力的な姿勢を示す表現にしました。"
                    },
                    casual: {
                        text: "明日の会議の資料、準備の進み具合はどんな感じ？何かサポートが必要だったら言ってね！",
                        reasoning: "親しみやすく、プレッシャーを与えない軽やかな表現にしました。"
                    }
                },
                selected_tone: "gentle",
                final_message: "お疲れ様です。明日の会議の件でご連絡いたします。資料のご準備はいかがでしょうか？もしお時間が必要でしたら、お気軽にお声がけください。",
                status: "delivered",
                scheduled_at: new Date("2025-01-18T08:00:00.000Z"),
                delivered_at: new Date("2025-01-18T08:00:00.000Z"),
                created_at: new Date("2025-01-17T18:30:00.000Z"),
                updated_at: new Date("2025-01-18T08:00:00.000Z"),
                read_at: new Date("2025-01-18T08:15:00.000Z")
            }
        ];
        
        const messageResult = db.messages.insertMany(messages);
        logSuccess(`${messageResult.insertedIds.length}件のメッセージを投入しました`);
        
        // 5. データ検証
        logInfo('データ投入の検証中...');
        const userCount = db.users.countDocuments();
        const messageCount = db.messages.countDocuments();
        const friendshipCount = db.friendships.countDocuments();
        
        logSuccess('=== データ投入完了 ===');
        logSuccess(`ユーザー: ${userCount}件`);
        logSuccess(`メッセージ: ${messageCount}件`);
        logSuccess(`友達関係: ${friendshipCount}件`);
        
        // 6. テスト用ログイン情報の表示
        logInfo('=== テスト用ログイン情報 ===');
        logInfo('以下のアカウントでログインできます（パスワード: password123）:');
        logInfo('👩 田中 あかり - alice@yanwari-message.com');
        logInfo('👨 佐藤 ひろし - bob@yanwari-message.com');
        logInfo('👩 鈴木 みゆき - charlie@yanwari-message.com');
        
    } catch (error) {
        logError(`データ投入中にエラーが発生しました: ${error.message}`);
        logError(`スタックトレース: ${error.stack}`);
    }
}

// 実行
seedDevelopmentData();