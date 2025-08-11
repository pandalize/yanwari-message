#!/usr/bin/env node

/**
 * MongoDB データベース完全リセットスクリプト
 * 
 * 機能:
 * - 全コレクションの削除
 * - インデックスの再作成
 * - サンプルデータの投入
 */

const { MongoClient } = require('mongodb');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

// 本番環境での実行を防止
if (process.env.NODE_ENV === 'production') {
    console.error('❌ エラー: 本番環境ではテストデータ初期化は実行できません');
    process.exit(1);
}

// MongoDB接続URI
const MONGODB_URI = process.env.MONGODB_URI;
if (!MONGODB_URI) {
    console.error('❌ エラー: MONGODB_URI環境変数が設定されていません');
    process.exit(1);
}

// 削除対象コレクション
const COLLECTIONS_TO_RESET = [
    'users',
    'messages',
    'friendships',
    'friend_requests',
    'message_ratings',
    'schedules',
    'user_settings'
];

/**
 * MongoDBデータベースを完全リセット
 */
async function resetDatabase() {
    let client;
    
    try {
        console.log('🔥 MongoDB データベースリセット開始...\n');
        
        // MongoDB接続
        console.log('📡 MongoDB Atlas に接続中...');
        client = new MongoClient(MONGODB_URI);
        await client.connect();
        
        const db = client.db();
        console.log('✅ MongoDB Atlas 接続成功\n');
        
        // 既存コレクションの確認
        const existingCollections = await db.listCollections().toArray();
        const existingNames = existingCollections.map(c => c.name);
        
        console.log('📋 既存コレクション:', existingNames.length > 0 ? existingNames : '(なし)');
        
        // コレクションの削除
        for (const collectionName of COLLECTIONS_TO_RESET) {
            if (existingNames.includes(collectionName)) {
                console.log(`🗑️  削除中: ${collectionName}`);
                await db.collection(collectionName).drop();
            } else {
                console.log(`⚠️  スキップ: ${collectionName} (存在しません)`);
            }
        }
        
        console.log('\n🔄 インデックス作成中...');
        
        // 基本インデックスの作成
        await createIndexes(db);
        
        console.log('✅ インデックス作成完了');
        
        console.log('\n✨ データベースリセット完了！');
        console.log('💡 サンプルデータを投入するには: npm run db:seed');
        
    } catch (error) {
        console.error('\n❌ データベースリセット中にエラーが発生しました:');
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
 * 基本インデックスを作成
 */
async function createIndexes(db) {
    // users コレクション
    await db.collection('users').createIndex({ email: 1 }, { unique: true });
    await db.collection('users').createIndex({ firebase_uid: 1 }, { unique: true, sparse: true });
    console.log('  ✓ users インデックス');
    
    // messages コレクション  
    await db.collection('messages').createIndex({ sender_id: 1 });
    await db.collection('messages').createIndex({ recipient_id: 1 });
    await db.collection('messages').createIndex({ created_at: -1 });
    console.log('  ✓ messages インデックス');
    
    // friendships コレクション
    await db.collection('friendships').createIndex({ user1_id: 1, user2_id: 1 }, { unique: true });
    await db.collection('friendships').createIndex({ user1_id: 1 });
    await db.collection('friendships').createIndex({ user2_id: 1 });
    console.log('  ✓ friendships インデックス');
    
    // friend_requests コレクション
    await db.collection('friend_requests').createIndex({ from_user_id: 1, to_user_id: 1 });
    await db.collection('friend_requests').createIndex({ to_user_id: 1, status: 1 });
    console.log('  ✓ friend_requests インデックス');
    
    // message_ratings コレクション
    await db.collection('message_ratings').createIndex({ messageId: 1, recipientId: 1 }, { unique: true });
    console.log('  ✓ message_ratings インデックス');
    
    // schedules コレクション
    await db.collection('schedules').createIndex({ user_id: 1 });
    await db.collection('schedules').createIndex({ scheduled_at: 1 });
    console.log('  ✓ schedules インデックス');
}

// メイン実行
if (require.main === module) {
    resetDatabase();
}

module.exports = { resetDatabase };