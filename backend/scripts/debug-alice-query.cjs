#!/usr/bin/env node

/**
 * Alice 受信メッセージクエリデバッグ
 * GetReceivedMessages関数と同じクエリを直接実行してテスト
 */

const { MongoClient, ObjectId } = require('mongodb');
require('dotenv').config({ path: __dirname + '/../.env' });

async function debugAliceQuery() {
    console.log('🔍 Alice 受信メッセージクエリデバッグ開始...\n');
    
    const client = new MongoClient(process.env.MONGODB_URI);
    
    try {
        await client.connect();
        const db = client.db('yanwari-message');
        
        // 1. Alice の ObjectID を取得
        const alice = await db.collection('users').findOne({ 
            email: 'alice@yanwari.com' 
        });
        
        if (!alice) {
            console.log('❌ Alice ユーザーが見つかりません');
            return;
        }
        
        console.log('👤 Alice 情報:');
        console.log('  - MongoDB ID:', alice._id);
        console.log('  - Firebase UID:', alice.firebaseUid);
        console.log('  - Email:', alice.email);
        console.log('  - Name:', alice.name);
        
        // 2. すべてのメッセージを確認
        console.log('\n📨 全メッセージ確認:');
        const allMessages = await db.collection('messages').find({}).toArray();
        console.log(`  総メッセージ数: ${allMessages.length} 件`);
        
        console.log('\n  メッセージ詳細:');
        allMessages.forEach((msg, index) => {
            console.log(`  [${index + 1}] ID: ${msg._id}`);
            console.log(`      送信者ID: ${msg.senderId}`);
            console.log(`      受信者ID: ${msg.recipientId}`);
            console.log(`      Alice宛て?: ${msg.recipientId?.toString() === alice._id.toString() ? '✅' : '❌'}`);
            console.log(`      本文: "${msg.originalText?.substring(0, 30)}..."`);
            console.log(`      ステータス: ${msg.status}`);
            console.log(`      送信日: ${msg.sentAt}`);
            console.log('');
        });
        
        // 3. Alice宛てメッセージの直接検索
        console.log('🎯 Alice宛てメッセージ直接検索:');
        const aliceMessages = await db.collection('messages').find({
            recipientId: alice._id
        }).toArray();
        console.log(`  Alice宛てメッセージ数: ${aliceMessages.length} 件`);
        
        // 4. GetReceivedMessages と同じクエリを実行
        console.log('\n🔍 GetReceivedMessages関数と同じクエリ実行:');
        const filter = {
            recipientId: alice._id,
            status: { $in: ['sent', 'delivered', 'read'] }
        };
        
        console.log('  使用フィルター:', JSON.stringify(filter, null, 2));
        
        const receivedMessages = await db.collection('messages').find(filter).toArray();
        console.log(`  取得メッセージ数: ${receivedMessages.length} 件`);
        
        if (receivedMessages.length > 0) {
            console.log('\n  📋 取得されたメッセージ:');
            receivedMessages.forEach((msg, index) => {
                console.log(`  [${index + 1}] 本文: "${msg.originalText.substring(0, 30)}..."`);
                console.log(`      ステータス: ${msg.status}`);
                console.log(`      送信日: ${msg.sentAt}`);
            });
        } else {
            console.log('\n  ❌ クエリで取得されたメッセージはありません');
            
            // 5. 詳細な原因分析
            console.log('\n🔍 詳細な原因分析:');
            
            // recipientId が Alice に一致するかチェック
            const recipientMatches = await db.collection('messages').find({
                recipientId: alice._id
            }).toArray();
            console.log(`  recipientId 一致: ${recipientMatches.length} 件`);
            
            // ステータスで絞り込み
            const statusMatches = await db.collection('messages').find({
                status: { $in: ['sent', 'delivered', 'read'] }
            }).toArray();
            console.log(`  ステータス 一致: ${statusMatches.length} 件`);
            
            // 各ステータスごとの確認
            for (const status of ['draft', 'pending', 'scheduled', 'sent', 'delivered', 'read']) {
                const count = await db.collection('messages').countDocuments({
                    recipientId: alice._id,
                    status: status
                });
                console.log(`  Alice宛て + ${status}: ${count} 件`);
            }
        }
        
    } catch (error) {
        console.error('❌ デバッグ中にエラー:', error.message);
    } finally {
        await client.close();
    }
}

if (require.main === module) {
    debugAliceQuery();
}