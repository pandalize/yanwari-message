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
            }
        ];
        
        const friendshipResult = db.friendships.insertMany(friendships);
        logSuccess(`${friendshipResult.insertedIds.length}件の友達関係を投入しました`);
        
        // 4. メッセージデータの投入
        logInfo('メッセージデータを投入中...');
        const messages = [
            // Aliceが送信したメッセージ
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
            },
            // Bobが送信してAliceが受信したメッセージ
            {
                _id: ObjectId(),
                sender_id: bobId,
                recipient_email: "alice@yanwari-message.com",
                recipient_id: aliceId,
                original_text: "プロジェクトの締切について話し合う必要があります。",
                transformed_versions: {
                    gentle: {
                        text: "お疲れ様です。プロジェクトの進捗についてご相談があります。お時間のある時に、締切について少しお話しできればと思います。",
                        reasoning: "緊急感を和らげ、相手の都合を配慮した丁寧な表現にしました。"
                    },
                    constructive: {
                        text: "プロジェクトの締切について一緒に検討しませんか？現在の進捗状況を確認して、最適な計画を立てましょう。",
                        reasoning: "協力的で前向きなアプローチを強調した表現にしました。"
                    },
                    casual: {
                        text: "プロジェクトの締切の件、ちょっと相談したいことがあるんだ。時間ある時に話せる？",
                        reasoning: "親しみやすく気軽に相談できる雰囲気の表現にしました。"
                    }
                },
                selected_tone: "constructive",
                final_message: "プロジェクトの締切について一緒に検討しませんか？現在の進捗状況を確認して、最適な計画を立てましょう。",
                status: "delivered",
                scheduled_at: new Date("2025-01-18T10:00:00.000Z"),
                delivered_at: new Date("2025-01-18T10:00:00.000Z"),
                created_at: new Date("2025-01-18T09:15:00.000Z"),
                updated_at: new Date("2025-01-18T10:00:00.000Z"),
                read_at: new Date("2025-01-18T10:05:00.000Z")
            },
            // Charlieが送信してAliceが受信したメッセージ
            {
                _id: ObjectId(),
                sender_id: charlieId,
                recipient_email: "alice@yanwari-message.com",
                recipient_id: aliceId,
                original_text: "デザインのレビューお疲れ様でした。修正お願いします。",
                transformed_versions: {
                    gentle: {
                        text: "デザインのレビューをしていただき、ありがとうございました。いくつか調整したい箇所がございますので、お時間のある時に修正をお願いできればと思います。",
                        reasoning: "感謝の気持ちを伝え、相手への配慮を示した丁寧な表現にしました。"
                    },
                    constructive: {
                        text: "デザインレビューありがとうございました。フィードバックを反映させて、より良いものにしていきましょう。修正点をまとめてお送りします。",
                        reasoning: "建設的で協力的なトーンで、改善への意欲を示した表現にしました。"
                    },
                    casual: {
                        text: "デザインレビューお疲れ様！いくつか調整したい部分があるので、修正よろしくお願いします。",
                        reasoning: "親しみやすく簡潔で、負担を感じさせない表現にしました。"
                    }
                },
                selected_tone: "gentle",
                final_message: "デザインのレビューをしていただき、ありがとうございました。いくつか調整したい箇所がございますので、お時間のある時に修正をお願いできればと思います。",
                status: "delivered",
                scheduled_at: new Date("2025-01-18T14:00:00.000Z"),
                delivered_at: new Date("2025-01-18T14:00:00.000Z"),
                created_at: new Date("2025-01-18T13:30:00.000Z"),
                updated_at: new Date("2025-01-18T14:00:00.000Z"),
                read_at: new Date("2025-01-18T14:10:00.000Z")
            }
        ];
        
        const messageResult = db.messages.insertMany(messages);
        logSuccess(`${messageResult.insertedIds.length}件のメッセージを投入しました`);
        
        // 5. メッセージ評価データの投入
        logInfo('メッセージ評価データを投入中...');
        const messageIds = messageResult.insertedIds;
        const messageRatings = [
            // BobからのメッセージをAliceが評価
            {
                _id: ObjectId(),
                message_id: messageIds[1], // Bobからのメッセージ
                user_id: aliceId, // Aliceが評価
                rating: 5,
                comment: "とても建設的で協力的なアプローチでした。プレッシャーを感じることなく、一緒に解決策を考えられそうです。",
                helpful_aspects: ["tone", "collaborative_approach", "clarity"],
                created_at: new Date("2025-01-18T10:30:00.000Z"),
                updated_at: new Date("2025-01-18T10:30:00.000Z")
            },
            // CharlieからのメッセージをAliceが評価
            {
                _id: ObjectId(),
                message_id: messageIds[2], // Charlieからのメッセージ
                user_id: aliceId, // Aliceが評価
                rating: 4,
                comment: "丁寧で配慮のある言い回しでした。感謝の気持ちが伝わり、気持ちよく対応できます。",
                helpful_aspects: ["tone", "emotional_impact", "clarity"],
                created_at: new Date("2025-01-18T14:30:00.000Z"),
                updated_at: new Date("2025-01-18T14:30:00.000Z")
            },
            // Alice自身のメッセージをBobが評価（フィードバック用）
            {
                _id: ObjectId(),
                message_id: messageIds[0], // Aliceからのメッセージ
                user_id: bobId, // Bobが評価
                rating: 5,
                comment: "とても配慮のある優しい表現でした。プレッシャーを感じることなく、建設的に対応できました。",
                helpful_aspects: ["tone", "timing", "emotional_impact"],
                created_at: new Date("2025-01-18T08:30:00.000Z"),
                updated_at: new Date("2025-01-18T08:30:00.000Z")
            }
        ];
        
        const ratingResult = db.message_ratings.insertMany(messageRatings);
        logSuccess(`${ratingResult.insertedIds.length}件のメッセージ評価を投入しました`);
        
        // 7. データ検証
        logInfo('データ投入の検証中...');
        const userCount = db.users.countDocuments();
        const messageCount = db.messages.countDocuments();
        const friendshipCount = db.friendships.countDocuments();
        const ratingCount = db.message_ratings.countDocuments();
        
        logSuccess('=== データ投入完了 ===');
        logSuccess(`ユーザー: ${userCount}件`);
        logSuccess(`メッセージ: ${messageCount}件`);
        logSuccess(`友達関係: ${friendshipCount}件`);
        logSuccess(`メッセージ評価: ${ratingCount}件`);
        
        // 8. テスト用ログイン情報の表示
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