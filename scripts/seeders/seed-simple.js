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
        
        // 4. メッセージデータの投入（多様なステータスと時間設定）
        logInfo('メッセージデータを投入中...');
        const now = new Date();
        const yesterday = new Date(now.getTime() - 24 * 60 * 60 * 1000);
        const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000);
        const nextWeek = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
        
        const messages = [
            // === 配信済みメッセージ（評価可能） ===
            // Alice → Bob: 配信済み（既読）
            {
                _id: ObjectId(),
                senderId: aliceId,
                recipientId: bobId,
                originalText: "明日の会議なんですが、資料の準備が遅れていませんか？",
                variations: {
                    gentle: "お疲れ様です。明日の会議の件でご連絡いたします。資料のご準備はいかがでしょうか？もしお時間が必要でしたら、お気軽にお声がけください。",
                    constructive: "明日の会議について確認です。資料の準備状況を教えていただけますか？必要でしたら、一緒に準備を進めることも可能です。",
                    casual: "明日の会議の資料、準備の進み具合はどんな感じ？何かサポートが必要だったら言ってね！"
                },
                selectedTone: "gentle",
                finalText: "お疲れ様です。明日の会議の件でご連絡いたします。資料のご準備はいかがでしょうか？もしお時間が必要でしたら、お気軽にお声がけください。",
                status: "read",
                scheduledAt: yesterday,
                sentAt: yesterday,
                deliveredAt: yesterday,
                readAt: new Date(yesterday.getTime() + 15 * 60 * 1000),
                createdAt: new Date(yesterday.getTime() - 60 * 60 * 1000),
                updatedAt: new Date(yesterday.getTime() + 15 * 60 * 1000)
            },
            
            // Bob → Alice: 配信済み（既読）
            {
                _id: ObjectId(),
                senderId: bobId,
                recipientId: aliceId,
                originalText: "プロジェクトの締切について話し合う必要があります。",
                variations: {
                    gentle: "お疲れ様です。プロジェクトの進捗についてご相談があります。お時間のある時に、締切について少しお話しできればと思います。",
                    constructive: "プロジェクトの締切について一緒に検討しませんか？現在の進捗状況を確認して、最適な計画を立てましょう。",
                    casual: "プロジェクトの締切の件、ちょっと相談したいことがあるんだ。時間ある時に話せる？"
                },
                selectedTone: "constructive",
                finalText: "プロジェクトの締切について一緒に検討しませんか？現在の進捗状況を確認して、最適な計画を立てましょう。",
                status: "read",
                scheduledAt: new Date(yesterday.getTime() + 2 * 60 * 60 * 1000),
                sentAt: new Date(yesterday.getTime() + 2 * 60 * 60 * 1000),
                deliveredAt: new Date(yesterday.getTime() + 2 * 60 * 60 * 1000 + 30 * 1000),
                readAt: new Date(yesterday.getTime() + 2 * 60 * 60 * 1000 + 5 * 60 * 1000),
                createdAt: new Date(yesterday.getTime() + 60 * 60 * 1000),
                updatedAt: new Date(yesterday.getTime() + 2 * 60 * 60 * 1000 + 5 * 60 * 1000)
            },
            
            // Charlie → Alice: 配信済み（既読）
            {
                _id: ObjectId(),
                senderId: charlieId,
                recipientId: aliceId,
                originalText: "デザインのレビューお疲れ様でした。修正お願いします。",
                variations: {
                    gentle: "デザインのレビューをしていただき、ありがとうございました。いくつか調整したい箇所がございますので、お時間のある時に修正をお願いできればと思います。",
                    constructive: "デザインレビューありがとうございました。フィードバックを反映させて、より良いものにしていきましょう。修正点をまとめてお送りします。",
                    casual: "デザインレビューお疲れ様！いくつか調整したい部分があるので、修正よろしくお願いします。"
                },
                selectedTone: "gentle",
                finalText: "デザインのレビューをしていただき、ありがとうございました。いくつか調整したい箇所がございますので、お時間のある時に修正をお願いできればと思います。",
                status: "read",
                scheduledAt: new Date(yesterday.getTime() + 6 * 60 * 60 * 1000),
                sentAt: new Date(yesterday.getTime() + 6 * 60 * 60 * 1000),
                deliveredAt: new Date(yesterday.getTime() + 6 * 60 * 60 * 1000 + 10 * 1000),
                readAt: new Date(yesterday.getTime() + 6 * 60 * 60 * 1000 + 10 * 60 * 1000),
                createdAt: new Date(yesterday.getTime() + 5 * 60 * 60 * 1000),
                updatedAt: new Date(yesterday.getTime() + 6 * 60 * 60 * 1000 + 10 * 60 * 1000)
            },
            
            // Alice → Charlie: 配信済み（未読）
            {
                _id: ObjectId(),
                senderId: aliceId,
                recipientId: charlieId,
                originalText: "企画書の内容、ちょっと厳しすぎるかもしれません。",
                variations: {
                    gentle: "企画書を拝見いたしました。いくつかご相談したい点がございます。お時間のある時にお話しできればと思います。",
                    constructive: "企画書についてフィードバックがあります。より実現可能なプランを一緒に検討してみませんか？",
                    casual: "企画書見たよ！ちょっと調整した方がよさそうな部分があるから、話し合おうか。"
                },
                selectedTone: "constructive",
                finalText: "企画書についてフィードバックがあります。より実現可能なプランを一緒に検討してみませんか？",
                status: "delivered",
                scheduledAt: new Date(now.getTime() - 2 * 60 * 60 * 1000),
                sentAt: new Date(now.getTime() - 2 * 60 * 60 * 1000),
                deliveredAt: new Date(now.getTime() - 2 * 60 * 60 * 1000 + 5 * 1000),
                createdAt: new Date(now.getTime() - 3 * 60 * 60 * 1000),
                updatedAt: new Date(now.getTime() - 2 * 60 * 60 * 1000)
            },
            
            // === 送信予定メッセージ ===
            // Bob → Charlie: 明日送信予定（友達でないため送信失敗想定）
            {
                _id: ObjectId(),
                senderId: bobId,
                recipientId: charlieId,
                originalText: "来週の研修の件で確認したいことがあります。",
                variations: {
                    gentle: "来週の研修についてご質問があります。お忙しい中申し訳ありませんが、確認させていただけますでしょうか。",
                    constructive: "来週の研修について一緒に準備を進めましょう。詳細を確認したい点がいくつかあります。",
                    casual: "来週の研修の件でちょっと聞きたいことがあるんだ。時間ある時に教えて！"
                },
                selectedTone: "gentle",
                finalText: "来週の研修についてご質問があります。お忙しい中申し訳ありませんが、確認させていただけますでしょうか。",
                status: "scheduled",
                scheduledAt: tomorrow,
                createdAt: now,
                updatedAt: now
            },
            
            // Alice → Bob: 来週送信予定
            {
                _id: ObjectId(),
                senderId: aliceId,
                recipientId: bobId,
                originalText: "月末の報告書、まだ手をつけられていないかもしれません。",
                variations: {
                    gentle: "月末の報告書についてご相談があります。進捗状況はいかがでしょうか。何かお手伝いできることがあればお声がけください。",
                    constructive: "月末の報告書の件で相談です。一緒に計画を立てて効率的に進めませんか？",
                    casual: "月末の報告書どう？何か手伝えることがあったら言ってね！"
                },
                selectedTone: "gentle",
                finalText: "月末の報告書についてご相談があります。進捗状況はいかがでしょうか。何かお手伝いできることがあればお声がけください。",
                status: "scheduled",
                scheduledAt: nextWeek,
                createdAt: new Date(now.getTime() - 30 * 60 * 1000),
                updatedAt: new Date(now.getTime() - 30 * 60 * 1000)
            },
            
            // === 送信済みメッセージ（相手からの返信待ち） ===
            // Charlie → Alice: 送信済み（未読）
            {
                _id: ObjectId(),
                senderId: charlieId,
                recipientId: aliceId,
                originalText: "新しいプロジェクトのアサインについて話があります。",
                variations: {
                    gentle: "新しいプロジェクトについてご相談があります。お時間のある時にお話しさせていただけますでしょうか。",
                    constructive: "新しいプロジェクトのアサインについて一緒に検討しませんか？詳細をお伝えしたいと思います。",
                    casual: "新しいプロジェクトの件で話があるんだ。都合の良い時に相談しよう！"
                },
                selectedTone: "constructive",
                finalText: "新しいプロジェクトのアサインについて一緒に検討しませんか？詳細をお伝えしたいと思います。",
                status: "sent",
                scheduledAt: new Date(now.getTime() - 30 * 60 * 1000),
                sentAt: new Date(now.getTime() - 30 * 60 * 1000),
                createdAt: new Date(now.getTime() - 60 * 60 * 1000),
                updatedAt: new Date(now.getTime() - 30 * 60 * 1000)
            },
            
            // Bob → Alice: 送信済み（配信待ち）
            {
                _id: ObjectId(),
                senderId: bobId,
                recipientId: aliceId,
                originalText: "昨日のミーティングのフォローアップをお願いします。",
                variations: {
                    gentle: "昨日のミーティングについて、いくつか確認事項がございます。お時間のある時にフォローアップをお願いできますでしょうか。",
                    constructive: "昨日のミーティングのフォローアップを一緒に進めませんか？アクションアイテムを整理しましょう。",
                    casual: "昨日のミーティングの件、フォローアップよろしく！何か質問があったら聞いて。"
                },
                selectedTone: "constructive",
                finalText: "昨日のミーティングのフォローアップを一緒に進めませんか？アクションアイテムを整理しましょう。",
                status: "sent",
                scheduledAt: new Date(now.getTime() - 15 * 60 * 1000),
                sentAt: new Date(now.getTime() - 15 * 60 * 1000),
                createdAt: new Date(now.getTime() - 45 * 60 * 1000),
                updatedAt: new Date(now.getTime() - 15 * 60 * 1000)
            }
        ];
        
        const messageResult = db.messages.insertMany(messages);
        logSuccess(`${messageResult.insertedIds.length}件のメッセージを投入しました`);
        
        // 5. メッセージ評価データの投入（配信済み・既読メッセージのみ評価可能）
        logInfo('メッセージ評価データを投入中...');
        const messageIds = messageResult.insertedIds;
        const messageRatings = [
            // Alice → Bobのメッセージ (messageIds[0]) をBobが評価
            {
                _id: ObjectId(),
                messageId: messageIds[0],
                userId: bobId,
                rating: 5,
                comment: "とても配慮のある優しい表現でした。プレッシャーを感じることなく、建設的に対応できました。",
                helpfulAspects: ["tone", "timing", "emotional_impact"],
                createdAt: new Date(yesterday.getTime() + 30 * 60 * 1000),
                updatedAt: new Date(yesterday.getTime() + 30 * 60 * 1000)
            },
            
            // Bob → Aliceのメッセージ (messageIds[1]) をAliceが評価
            {
                _id: ObjectId(),
                messageId: messageIds[1],
                userId: aliceId,
                rating: 4,
                comment: "建設的で協力的なアプローチが良かったです。一緒に解決策を考える姿勢が伝わってきました。",
                helpfulAspects: ["tone", "collaborative_approach", "clarity"],
                createdAt: new Date(yesterday.getTime() + 3 * 60 * 60 * 1000),
                updatedAt: new Date(yesterday.getTime() + 3 * 60 * 60 * 1000)
            },
            
            // Charlie → Aliceのメッセージ (messageIds[2]) をAliceが評価
            {
                _id: ObjectId(),
                messageId: messageIds[2],
                userId: aliceId,
                rating: 5,
                comment: "丁寧で配慮のある言い回しでした。感謝の気持ちが伝わり、気持ちよく対応できます。",
                helpfulAspects: ["tone", "emotional_impact", "clarity"],
                createdAt: new Date(yesterday.getTime() + 7 * 60 * 60 * 1000),
                updatedAt: new Date(yesterday.getTime() + 7 * 60 * 60 * 1000)
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