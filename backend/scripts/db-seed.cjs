#!/usr/bin/env node

/**
 * MongoDB サンプルデータ投入スクリプト
 * 
 * データセット:
 * - auth-only: 認証用最小データ（ユーザー2-3名）
 * - messages: メッセージ・友達関係・評価データ含む
 * - full: 全機能のテストデータ（大量データ含む）
 */

const { MongoClient, ObjectId } = require('mongodb');
const path = require('path');
const fs = require('fs');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

// 本番環境での実行を防止
if (process.env.NODE_ENV === 'production') {
    console.error('❌ エラー: 本番環境ではサンプルデータ投入は実行できません');
    process.exit(1);
}

// MongoDB接続URI
const MONGODB_URI = process.env.MONGODB_URI;
if (!MONGODB_URI) {
    console.error('❌ エラー: MONGODB_URI環境変数が設定されていません');
    process.exit(1);
}

// コマンドライン引数の解析
const args = process.argv.slice(2);
const dataset = args.find(arg => arg.startsWith('--dataset='))?.split('=')[1] || 'full';

/**
 * サンプルデータを投入
 */
async function seedDatabase() {
    let client;
    
    try {
        console.log(`🌱 サンプルデータ投入開始 (データセット: ${dataset})\n`);
        
        // MongoDB接続
        console.log('📡 MongoDB Atlas に接続中...');
        client = new MongoClient(MONGODB_URI);
        await client.connect();
        
        const db = client.db();
        console.log('✅ MongoDB Atlas 接続成功\n');
        
        // データセット別の投入
        switch (dataset) {
            case 'auth-only':
                await seedAuthOnly(db);
                break;
            case 'messages':
                await seedAuthOnly(db);
                await seedMessages(db);
                break;
            case 'full':
                await seedAuthOnly(db);
                await seedMessages(db);
                await seedFullData(db);
                break;
            default:
                throw new Error(`未知のデータセット: ${dataset}`);
        }
        
        console.log('\n✨ サンプルデータ投入完了！');
        
    } catch (error) {
        console.error('\n❌ サンプルデータ投入中にエラーが発生しました:');
        console.error(error.message);
        process.exit(1);
    } finally {
        if (client) {
            await client.close();
            console.log('🔌 データベース接続を閉じました');
        }
    }
}

/**
 * 認証用最小データを投入
 */
async function seedAuthOnly(db) {
    console.log('👥 認証用ユーザーデータを投入中...');
    
    const users = [
        {
            _id: new ObjectId(),
            email: 'alice@yanwari.com',
            name: 'Alice テスター',
            firebase_uid: 'test_firebase_uid_001',
            timezone: 'Asia/Tokyo',
            createdAt: new Date('2025-01-01T00:00:00Z'),
            updatedAt: new Date('2025-01-01T00:00:00Z')
        },
        {
            _id: new ObjectId(),
            email: 'bob@yanwari.com',
            name: 'Bob デモ',
            firebase_uid: 'test_firebase_uid_002',
            timezone: 'Asia/Tokyo',
            createdAt: new Date('2025-01-01T00:00:00Z'),
            updatedAt: new Date('2025-01-01T00:00:00Z')
        },
        {
            _id: new ObjectId(),
            email: 'charlie@yanwari.com',
            name: 'Charlie サンプル',
            firebase_uid: 'test_firebase_uid_003',
            timezone: 'Asia/Tokyo',
            createdAt: new Date('2025-01-01T00:00:00Z'),
            updatedAt: new Date('2025-01-01T00:00:00Z')
        }
    ];
    
    // ユーザーを保存（グローバルに利用するため）
    global.testUsers = users;
    
    const result = await db.collection('users').insertMany(users);
    console.log(`  ✓ ${result.insertedCount}人のユーザーを作成`);
    
    return users;
}

/**
 * メッセージ関連データを投入
 */
async function seedMessages(db) {
    console.log('🤝 友達関係データを投入中...');
    
    const users = global.testUsers;
    const [alice, bob, charlie] = users;
    
    // 友達関係（Alice - Bob, Alice - Charlie）
    const friendships = [
        {
            user1_id: alice._id < bob._id ? alice._id : bob._id,
            user2_id: alice._id < bob._id ? bob._id : alice._id,
            created_at: new Date('2025-01-01T00:00:00Z')
        },
        {
            user1_id: alice._id < charlie._id ? alice._id : charlie._id,
            user2_id: alice._id < charlie._id ? charlie._id : alice._id,
            created_at: new Date('2025-01-01T02:00:00Z')
        }
    ];
    
    await db.collection('friendships').insertMany(friendships);
    console.log(`  ✓ ${friendships.length}件の友達関係を作成`);
    
    console.log('💬 メッセージデータを投入中...');
    
    const messages = [
        // Alice → Bob のメッセージ
        {
            _id: new ObjectId(),
            senderId: alice._id,
            recipientId: bob._id,
            originalText: '今日は疲れたよ！！！',
            variations: {
                gentle: '本日はとても疲労を感じました。少し休息を取りたいと思います。',
                constructive: '今日は大変でしたが、明日に向けて休息を取らせていただければと思います。',
                casual: '今日めっちゃ疲れた！ちょっと休ませて〜'
            },
            selectedTone: 'gentle',
            finalText: '本日はとても疲労を感じました。少し休息を取りたいと思います。',
            status: 'delivered',
            createdAt: new Date('2025-01-01T09:00:00Z'),
            updatedAt: new Date('2025-01-01T09:00:00Z'),
            sentAt: new Date('2025-01-01T09:00:00Z'),
            readAt: new Date('2025-01-01T10:30:00Z')
        },
        
        // Bob → Alice のメッセージ（会議延期）
        {
            _id: new ObjectId(),
            senderId: bob._id,
            recipientId: alice._id,
            originalText: '明日の会議、準備できてないから延期してほしい',
            variations: {
                gentle: '明日の会議についてですが、もう少しお時間をいただけると助かります😊',
                constructive: '明日の会議の準備に追加時間が必要です。延期をご検討いただけますでしょうか？',
                casual: '明日の会議なんですが、準備が間に合わないので延期できますか？'
            },
            selectedTone: 'constructive',
            finalText: '明日の会議の準備に追加時間が必要です。延期をご検討いただけますでしょうか？',
            status: 'delivered',
            createdAt: new Date('2025-01-01T14:00:00Z'),
            updatedAt: new Date('2025-01-01T14:00:00Z'),
            sentAt: new Date('2025-01-01T14:00:00Z')
        },
        
        // Charlie → Alice のメッセージ（お疲れ様）
        {
            _id: new ObjectId(),
            senderId: charlie._id,
            recipientId: alice._id,
            originalText: 'プロジェクト完了お疲れさま！すごく頑張ったね',
            variations: {
                gentle: 'プロジェクト完了、本当にお疲れさまでした。Alice さんの努力に心から感謝しています😊',
                constructive: 'プロジェクト完了おめでとうございます。Alice さんのリーダーシップのおかげで成功しました。',
                casual: 'プロジェクト完了お疲れさま！Alice のがんばりのおかげだよ〜！'
            },
            selectedTone: 'gentle',
            finalText: 'プロジェクト完了、本当にお疲れさまでした。Alice さんの努力に心から感謝しています😊',
            status: 'delivered',
            createdAt: new Date('2025-01-02T10:00:00Z'),
            updatedAt: new Date('2025-01-02T10:00:00Z'),
            sentAt: new Date('2025-01-02T10:00:00Z')
        },
        
        // Bob → Alice のメッセージ（遅刻の謝罪）
        {
            _id: new ObjectId(),
            senderId: bob._id,
            recipientId: alice._id,
            originalText: '電車遅延で会議に遅れます。20分くらい遅れる予定',
            variations: {
                gentle: '申し訳ございません。電車の遅延により会議に約20分遅れてしまいます。',
                constructive: '電車遅延のため、会議開始時間に20分程度遅れる見込みです。先に進めていただけますでしょうか。',
                casual: '電車遅延で20分くらい遅れちゃいます。先に始めててください！'
            },
            selectedTone: 'gentle',
            finalText: '申し訳ございません。電車の遅延により会議に約20分遅れてしまいます。',
            status: 'delivered',
            createdAt: new Date('2025-01-02T08:30:00Z'),
            updatedAt: new Date('2025-01-02T08:30:00Z'),
            sentAt: new Date('2025-01-02T08:30:00Z'),
            readAt: new Date('2025-01-02T08:32:00Z')
        },
        
        // Alice → Charlie のメッセージ（お礼）
        {
            _id: new ObjectId(),
            senderId: alice._id,
            recipientId: charlie._id,
            originalText: 'いつも助けてくれてありがとう！',
            variations: {
                gentle: 'いつも親身にサポートしてくださり、本当にありがとうございます。',
                constructive: 'プロジェクトでのサポートに感謝しています。Charlie さんの協力のおかげです。',
                casual: 'いつも助けてくれてありがとう！Charlie がいてくれて本当に助かってる〜'
            },
            selectedTone: 'gentle',
            finalText: 'いつも親身にサポートしてくださり、本当にありがとうございます。',
            status: 'sent',
            createdAt: new Date('2025-01-02T15:00:00Z'),
            updatedAt: new Date('2025-01-02T15:00:00Z'),
            sentAt: new Date('2025-01-02T15:00:00Z')
        },
        
        // Bob → Alice のメッセージ（ランチ誘い）
        {
            _id: new ObjectId(),
            senderId: bob._id,
            recipientId: alice._id,
            originalText: '今度みんなでランチでもしない？新しい店見つけたんだ',
            variations: {
                gentle: 'お時間のあるときに、皆さんでお食事でもいかがでしょうか。素敵なお店を発見いたしました。',
                constructive: 'チームでランチミーティングはいかがでしょうか。新しいレストランでリラックスした環境で話し合えそうです。',
                casual: 'みんなでランチしない？いい感じの新しいお店見つけたよ〜！'
            },
            selectedTone: 'casual',
            finalText: 'みんなでランチしない？いい感じの新しいお店見つけたよ〜！',
            status: 'delivered',
            createdAt: new Date('2025-01-03T11:30:00Z'),
            updatedAt: new Date('2025-01-03T11:30:00Z'),
            sentAt: new Date('2025-01-03T11:30:00Z')
        },
        
        // Charlie → Alice のメッセージ（質問）
        {
            _id: new ObjectId(),
            senderId: charlie._id,
            recipientId: alice._id,
            originalText: '来週の資料作成の件で相談があります',
            variations: {
                gentle: '来週の資料作成についてお聞きしたいことがございます。お時間のあるときに相談させていただけますでしょうか。',
                constructive: '来週の資料作成について確認したい点があります。効率的に進めるため、お時間をいただけますか。',
                casual: '来週の資料作成のことで相談があるんだけど、時間ある？'
            },
            selectedTone: 'constructive',
            finalText: '来週の資料作成について確認したい点があります。効率的に進めるため、お時間をいただけますか。',
            status: 'delivered',
            createdAt: new Date('2025-01-03T16:45:00Z'),
            updatedAt: new Date('2025-01-03T16:45:00Z'),
            sentAt: new Date('2025-01-03T16:45:00Z')
        },
        
        // Bob → Alice のメッセージ（体調不良）
        {
            _id: new ObjectId(),
            senderId: bob._id,
            recipientId: alice._id,
            originalText: '風邪ひいたから明日休むかも',
            variations: {
                gentle: '体調を崩してしまい、明日はお休みをいただく可能性があります。ご迷惑をおかけして申し訳ありません。',
                constructive: '体調不良のため、明日の出社が困難な状況です。業務への影響を最小限に抑えるよう調整いたします。',
                casual: '風邪ひいちゃったから、明日お休みもらうかも。ごめん！'
            },
            selectedTone: 'gentle',
            finalText: '体調を崩してしまい、明日はお休みをいただく可能性があります。ご迷惑をおかけして申し訳ありません。',
            status: 'delivered',
            createdAt: new Date('2025-01-04T18:00:00Z'),
            updatedAt: new Date('2025-01-04T18:00:00Z'),
            sentAt: new Date('2025-01-04T18:00:00Z'),
            readAt: new Date('2025-01-04T18:15:00Z')
        }
    ];
    
    // メッセージIDを保存（評価用）
    global.testMessages = messages;
    
    await db.collection('messages').insertMany(messages);
    console.log(`  ✓ ${messages.length}件のメッセージを作成`);
    
    // メッセージ評価
    console.log('⭐ メッセージ評価データを投入中...');
    
    const ratings = [
        // Bob が Alice のメッセージを評価
        {
            messageId: messages[0]._id,
            recipientId: bob._id, 
            rating: 4,
            createdAt: new Date('2025-01-01T10:35:00Z'),
            updatedAt: new Date('2025-01-01T10:35:00Z')
        },
        
        // Alice が Bob の会議延期メッセージを評価
        {
            messageId: messages[1]._id,
            recipientId: alice._id,
            rating: 5,
            createdAt: new Date('2025-01-01T15:00:00Z'),
            updatedAt: new Date('2025-01-01T15:00:00Z')
        },
        
        // Alice が Charlie のお疲れ様メッセージを評価
        {
            messageId: messages[2]._id,
            recipientId: alice._id,
            rating: 5,
            createdAt: new Date('2025-01-02T11:00:00Z'),
            updatedAt: new Date('2025-01-02T11:00:00Z')
        },
        
        // Alice が Bob のランチ誘いメッセージを評価
        {
            messageId: messages[5]._id,
            recipientId: alice._id,
            rating: 3,
            createdAt: new Date('2025-01-03T12:00:00Z'),
            updatedAt: new Date('2025-01-03T12:00:00Z')
        },
        
        // Alice が Bob の体調不良メッセージを評価
        {
            messageId: messages[7]._id,
            recipientId: alice._id,
            rating: 4,
            createdAt: new Date('2025-01-04T18:30:00Z'),
            updatedAt: new Date('2025-01-04T18:30:00Z')
        }
    ];
    
    await db.collection('message_ratings').insertMany(ratings);
    console.log(`  ✓ ${ratings.length}件の評価を作成`);
}

/**
 * 全機能テストデータを投入
 */
async function seedFullData(db) {
    console.log('📅 スケジュールデータを投入中...');
    
    const users = global.testUsers;
    const [alice, bob] = users;
    
    const schedules = [
        {
            userId: alice._id,
            messageText: 'テスト用スケジュールメッセージです',
            recipientEmail: 'bob@yanwari.com',
            scheduledAt: new Date(Date.now() + 24 * 60 * 60 * 1000), // 明日
            createdAt: new Date(),
            status: 'pending'
        }
    ];
    
    await db.collection('schedules').insertMany(schedules);
    console.log(`  ✓ ${schedules.length}件のスケジュールを作成`);
    
    console.log('🛠️ ユーザー設定データを投入中...');
    
    const userSettings = [
        {
            userId: alice._id,
            notifications: {
                email: true,
                browser: true,
                sendComplete: true
            },
            messageSettings: {
                defaultTone: 'gentle',
                autoSendDelay: 300
            },
            createdAt: new Date(),
            updatedAt: new Date()
        }
    ];
    
    await db.collection('user_settings').insertMany(userSettings);
    console.log(`  ✓ ${userSettings.length}件のユーザー設定を作成`);
}

// メイン実行
if (require.main === module) {
    seedDatabase();
}

module.exports = { seedDatabase };