#!/usr/bin/env node

/**
 * Firebase Emulator + MongoDB 統合テストスクリプト
 * 
 * 機能:
 * - Firebase Emulatorでテストユーザー作成
 * - MongoDB内ユーザーとのFirebase UID連携テスト
 * - 認証フローの動作確認
 */

const admin = require('firebase-admin');
const { MongoClient, ObjectId } = require('mongodb');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

// Firebase Emulator設定
const FIREBASE_AUTH_EMULATOR_HOST = 'localhost:9099';
process.env.FIREBASE_AUTH_EMULATOR_HOST = FIREBASE_AUTH_EMULATOR_HOST;

// MongoDB接続URI
const MONGODB_URI = process.env.MONGODB_URI;
if (!MONGODB_URI) {
    console.error('❌ エラー: MONGODB_URI環境変数が設定されていません');
    process.exit(1);
}

// テストユーザーデータ
const TEST_USERS = [
    {
        uid: 'test_firebase_uid_001',
        email: 'alice@yanwari.com',
        password: 'testpassword123',
        displayName: 'Alice テスター'
    },
    {
        uid: 'test_firebase_uid_002',
        email: 'bob@yanwari.com',
        password: 'testpassword123',
        displayName: 'Bob デモ'
    },
    {
        uid: 'test_firebase_uid_003',
        email: 'charlie@yanwari.com',
        password: 'testpassword123',
        displayName: 'Charlie サンプル'
    }
];

/**
 * Firebase Emulator + MongoDB 統合テスト
 */
async function testFirebaseIntegration() {
    let mongoClient;
    
    try {
        console.log('🔥 Firebase Emulator + MongoDB 統合テスト開始\n');
        
        // Firebase Admin SDK初期化（Emulator用）
        console.log('🚀 Firebase Admin SDK 初期化中...');
        
        if (admin.apps.length === 0) {
            admin.initializeApp({
                projectId: 'yanwari-message'
            });
        }
        
        const auth = admin.auth();
        console.log('✅ Firebase Admin SDK 初期化完了');
        
        // MongoDB接続
        console.log('📡 MongoDB Atlas 接続中...');
        mongoClient = new MongoClient(MONGODB_URI);
        await mongoClient.connect();
        const db = mongoClient.db();
        console.log('✅ MongoDB Atlas 接続完了\n');
        
        // Firebase Emulatorのユーザーをクリア（既存ユーザー削除）
        console.log('🧹 Firebase Emulator ユーザークリア中...');
        try {
            const listResult = await auth.listUsers();
            for (const user of listResult.users) {
                await auth.deleteUser(user.uid);
            }
            console.log(`  ✓ ${listResult.users.length}人のユーザーを削除`);
        } catch (error) {
            console.log('  ℹ️ Emulator内にユーザーが存在しません（初回実行）');
        }
        
        // テストユーザーをFirebase Emulatorに作成
        console.log('👥 Firebase Emulator テストユーザー作成中...');
        
        const firebaseUsers = [];
        for (const testUser of TEST_USERS) {
            try {
                // 既存ユーザーを削除してから作成（重複を防ぐ）
                try {
                    await auth.deleteUser(testUser.uid);
                } catch (deleteErr) {
                    // ユーザーが存在しない場合は無視
                }
                
                const userRecord = await auth.createUser({
                    uid: testUser.uid,
                    email: testUser.email,
                    password: testUser.password,
                    displayName: testUser.displayName,
                    emailVerified: true
                });
                
                firebaseUsers.push(userRecord);
                console.log(`  ✓ ${userRecord.email} (${userRecord.uid})`);
            } catch (error) {
                console.log(`  ❌ ${testUser.email} 作成失敗: ${error.message}`);
            }
        }
        
        // MongoDB内ユーザーとFirebase UIDの連携確認
        console.log('\n🔗 Firebase UID - MongoDB ユーザー連携確認...');
        
        const users = await db.collection('users').find({}).toArray();
        const linkedUsers = [];
        
        for (const user of users) {
            if (user.firebaseUid) {
                try {
                    const firebaseUser = await auth.getUser(user.firebaseUid);
                    console.log(`  ✅ ${user.email} → Firebase UID: ${user.firebaseUid}`);
                    linkedUsers.push({
                        mongodb: user,
                        firebase: firebaseUser
                    });
                } catch (error) {
                    console.log(`  ❌ ${user.email} → Firebase UID: ${user.firebaseUid} (未作成)`);
                }
            } else {
                console.log(`  ⚠️  ${user.email} → Firebase UID: (未設定)`);
            }
        }
        
        // カスタムトークン生成テスト
        console.log('\\n🔐 Firebase カスタムトークン生成テスト...');
        
        for (const linkedUser of linkedUsers) {
            try {
                const customToken = await auth.createCustomToken(linkedUser.firebase.uid, {
                    mongoDbUserId: linkedUser.mongodb._id.toString(),
                    email: linkedUser.mongodb.email
                });
                
                console.log(`  ✅ ${linkedUser.mongodb.email} → カスタムトークン生成成功`);
                console.log(`    Token: ${customToken.substring(0, 50)}...`);
            } catch (error) {
                console.log(`  ❌ ${linkedUser.mongodb.email} → トークン生成失敗: ${error.message}`);
            }
        }
        
        // Firebase Emulator UI情報
        console.log('\\n📊 テスト結果サマリー:');
        console.log(`  🔥 Firebase Emulator: http://127.0.0.1:4000/auth`);
        console.log(`  📱 Firebase ユーザー: ${firebaseUsers.length}人作成`);
        console.log(`  🗃️  MongoDB ユーザー: ${users.length}人存在`);
        console.log(`  🔗 連携済みユーザー: ${linkedUsers.length}人`);
        
        console.log('\\n✨ Firebase Emulator + MongoDB 統合テスト完了！');
        console.log('💡 Emulator UI: http://127.0.0.1:4000/');
        
    } catch (error) {
        console.error('\\n❌ 統合テスト中にエラーが発生しました:');
        console.error(error.message);
        process.exit(1);
    } finally {
        if (mongoClient) {
            await mongoClient.close();
            console.log('🔌 データベース接続を閉じました');
        }
    }
}

// メイン実行
if (require.main === module) {
    testFirebaseIntegration();
}

module.exports = { testFirebaseIntegration };