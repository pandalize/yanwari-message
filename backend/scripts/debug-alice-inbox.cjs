const { MongoClient, ObjectId } = require('mongodb');
require('dotenv').config({ path: __dirname + '/../.env' });

async function debugAliceInbox() {
    console.log('🔍 Alice 受信トレイデバッグ開始...\n');
    
    const client = new MongoClient(process.env.MONGODB_URI);
    
    try {
        await client.connect();
        const db = client.db('yanwari-message');
        
        // 1. Alice ユーザー情報確認
        console.log('👤 Alice ユーザー情報確認:');
        const alice = await db.collection('users').findOne({ email: 'alice@yanwari.com' });
        if (alice) {
            console.log('  ID:', alice._id);
            console.log('  Email:', alice.email);
            console.log('  Firebase UID:', alice.firebaseUid);
            console.log('  Name:', alice.name);
        } else {
            console.log('❌ Alice ユーザーが見つかりません');
            return;
        }
        
        // 2. Alice 宛てのメッセージ検索
        console.log('\n📬 Alice 宛てメッセージ確認:');
        const messages = await db.collection('messages')
            .find({ recipientId: alice._id })
            .toArray();
        
        console.log(`  Alice 宛てメッセージ数: ${messages.length} 件`);
        messages.forEach((msg, index) => {
            console.log(`  [${index + 1}] ID: ${msg._id}`);
            console.log(`      送信者ID: ${msg.senderId}`);
            console.log(`      本文: "${msg.originalText.substring(0, 30)}..."`);
            console.log(`      ステータス: ${msg.status}`);
            console.log(`      作成日時: ${msg.createdAt}`);
        });
        
        // 3. 受信トレイ API のクエリを模擬実行
        console.log('\n🔍 受信トレイAPIクエリ模擬実行:');
        const pipeline = [
            // Alice宛てのメッセージを検索
            { $match: { recipientId: alice._id } },
            // 送信者情報を取得
            {
                $lookup: {
                    from: 'users',
                    localField: 'senderId',
                    foreignField: '_id',
                    as: 'sender'
                }
            },
            { $unwind: '$sender' },
            // 評価情報を取得
            {
                $lookup: {
                    from: 'message_ratings',
                    let: { messageId: '$_id', recipientId: '$recipientId' },
                    pipeline: [
                        {
                            $match: {
                                $expr: {
                                    $and: [
                                        { $eq: ['$messageId', '$$messageId'] },
                                        { $eq: ['$recipientId', '$$recipientId'] }
                                    ]
                                }
                            }
                        }
                    ],
                    as: 'rating'
                }
            },
            // プロジェクション
            {
                $project: {
                    _id: 1,
                    senderId: 1,
                    recipientId: 1,
                    originalText: 1,
                    finalText: 1,
                    status: 1,
                    createdAt: 1,
                    readAt: 1,
                    senderName: '$sender.name',
                    senderEmail: '$sender.email',
                    rating: { $arrayElemAt: ['$rating.rating', 0] }
                }
            },
            { $sort: { createdAt: -1 } }
        ];
        
        const inboxMessages = await db.collection('messages')
            .aggregate(pipeline)
            .toArray();
        
        console.log(`  受信トレイクエリ結果: ${inboxMessages.length} 件`);
        inboxMessages.forEach((msg, index) => {
            console.log(`  [${index + 1}] 送信者: ${msg.senderName} (${msg.senderEmail})`);
            console.log(`      本文: "${msg.originalText.substring(0, 30)}..."`);
            console.log(`      評価: ${msg.rating || '未評価'}`);
            console.log(`      ステータス: ${msg.status}`);
        });
        
        // 4. Firebase UID でのユーザー検索確認
        console.log('\n🔐 Firebase UID での検索確認:');
        const firebaseUser = await db.collection('users').findOne({ 
            firebaseUid: 'test_firebase_uid_001' 
        });
        if (firebaseUser) {
            console.log('  ✅ Firebase UID での検索成功');
            console.log('  ID:', firebaseUser._id);
            console.log('  Email:', firebaseUser.email);
        } else {
            console.log('  ❌ Firebase UID での検索失敗');
        }
        
    } catch (error) {
        console.error('❌ エラー:', error.message);
    } finally {
        await client.close();
    }
}

debugAliceInbox();