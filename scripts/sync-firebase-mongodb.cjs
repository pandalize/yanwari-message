#!/usr/bin/env node

/**
 * Firebase Emulator と MongoDB のユーザー情報を同期するスクリプト
 * 
 * Firebase Emulator で作成されたユーザーの UID を MongoDB に反映
 */

const { MongoClient } = require('mongodb');
const path = require('path');

// ローカル環境設定読み込み
require('dotenv').config({ path: path.join(__dirname, '../backend/.env.local') });

// Firebase Emulator で作成されたユーザー情報
const firebaseUsers = [
    {
        email: 'alice@yanwari.com',
        firebaseUid: 'hz2QyzxqXex0fIjcgyzwNBZWStJb',
        name: 'Alice テスター'
    },
    {
        email: 'bob@yanwari.com',
        firebaseUid: 'bzdW6Dg7ja4vL7pOc3LEzG7lFayU',
        name: 'Bob デモ'
    },
    {
        email: 'charlie@yanwari.com',
        firebaseUid: 'xsKDz3tEZpBfJ2tgucEdUXdWLNLD',
        name: 'Charlie サンプル'
    }
];

async function syncUsers() {
    let client;
    
    try {
        console.log('🔄 Firebase-MongoDB ユーザー同期開始...\n');
        
        // MongoDB接続
        const MONGODB_URI = process.env.MONGODB_URI;
        if (!MONGODB_URI) {
            throw new Error('MONGODB_URI環境変数が設定されていません');
        }
        
        client = new MongoClient(MONGODB_URI);
        await client.connect();
        
        const db = client.db();
        const usersCollection = db.collection('users');
        
        console.log('📡 ローカルMongoDB に接続しました\n');
        
        // 各ユーザーのFirebase UIDを更新
        for (const user of firebaseUsers) {
            console.log(`👤 更新中: ${user.email}`);
            
            const result = await usersCollection.updateOne(
                { email: user.email },
                { 
                    $set: { 
                        firebaseUid: user.firebaseUid,
                        updatedAt: new Date()
                    }
                }
            );
            
            if (result.matchedCount > 0) {
                console.log(`   ✅ Firebase UID更新完了: ${user.firebaseUid}`);
            } else {
                // ユーザーが存在しない場合は作成
                console.log(`   ⚠️  ユーザーが存在しないため、新規作成中...`);
                await usersCollection.insertOne({
                    email: user.email,
                    name: user.name,
                    firebaseUid: user.firebaseUid,
                    timezone: 'Asia/Tokyo',
                    createdAt: new Date(),
                    updatedAt: new Date()
                });
                console.log(`   ✅ 新規ユーザー作成完了`);
            }
        }
        
        console.log('\n✨ Firebase-MongoDB ユーザー同期完了！');
        console.log('\n📋 同期されたユーザー:');
        firebaseUsers.forEach(user => {
            console.log(`   📧 ${user.email} → UID: ${user.firebaseUid}`);
        });
        
    } catch (error) {
        console.error('\n❌ 同期中にエラーが発生しました:');
        console.error(error.message);
        process.exit(1);
    } finally {
        if (client) {
            await client.close();
            console.log('\n🔌 データベース接続を閉じました');
        }
    }
}

// メイン実行
if (require.main === module) {
    syncUsers();
}

module.exports = { syncUsers };