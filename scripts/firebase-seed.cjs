#!/usr/bin/env node

/**
 * Firebase Emulator用ユーザーシードスクリプト
 * 
 * MongoDB のテストユーザーと同じユーザーを Firebase Emulator に自動作成
 */

const { initializeApp } = require('firebase/app');
const { getAuth, createUserWithEmailAndPassword, connectAuthEmulator } = require('firebase/auth');
const path = require('path');

// ローカル環境設定読み込み
require('dotenv').config({ path: path.join(__dirname, '../.env') });

// Firebase設定（エミュレータ用）
const firebaseConfig = {
    apiKey: "fake-api-key",
    authDomain: "yanwari-message.firebaseapp.com",
    projectId: "yanwari-message",
};

// テストユーザーデータ（MongoDBと同一）
const testUsers = [
    {
        email: 'alice@yanwari.com',
        password: 'password123',
        name: 'Alice テスター'
    },
    {
        email: 'bob@yanwari.com', 
        password: 'password123',
        name: 'Bob デモ'
    },
    {
        email: 'charlie@yanwari.com',
        password: 'password123', 
        name: 'Charlie サンプル'
    }
];

/**
 * Firebase Emulator にテストユーザーを作成
 */
async function seedFirebaseUsers() {
    console.log('🔥 Firebase Emulator ユーザーシード開始...\n');
    
    try {
        // Firebase初期化
        const app = initializeApp(firebaseConfig);
        const auth = getAuth(app);
        
        // エミュレータに接続（常に接続を試みる）
        try {
            connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
            console.log('✅ Firebase Emulator に接続しました (127.0.0.1:9099)\n');
        } catch (e) {
            // 既に接続済みの場合はエラーになるが、それは問題ない
            console.log('✅ Firebase Emulator 接続確認済み (127.0.0.1:9099)\n');
        }
        
        let successCount = 0;
        let skipCount = 0;
        
        // 各ユーザーを作成
        for (const user of testUsers) {
            try {
                console.log(`👤 ユーザー作成中: ${user.email}`);
                
                const userCredential = await createUserWithEmailAndPassword(
                    auth, 
                    user.email, 
                    user.password
                );
                
                console.log(`   ✅ 作成成功: ${userCredential.user.uid}`);
                successCount++;
                
            } catch (error) {
                if (error.code === 'auth/email-already-in-use') {
                    console.log(`   ⏭️  既存ユーザー: ${user.email}`);
                    skipCount++;
                } else {
                    console.error(`   ❌ 作成失敗: ${user.email}`, error.message);
                }
            }
        }
        
        console.log('\n📊 結果:');
        console.log(`   ✅ 新規作成: ${successCount}名`);
        console.log(`   ⏭️  既存スキップ: ${skipCount}名`);
        console.log(`   📝 合計: ${testUsers.length}名`);
        
        console.log('\n🎉 Firebase Emulator ユーザーシード完了！');
        console.log('\n📋 作成されたテストアカウント:');
        testUsers.forEach(user => {
            console.log(`   📧 ${user.email} / 🔒 ${user.password}`);
        });
        
        console.log('\n🌐 Firebase Emulator UI: http://127.0.0.1:4000/auth');
        
    } catch (error) {
        console.error('\n❌ Firebase Emulator シード中にエラーが発生しました:');
        console.error(error.message);
        
        if (error.message.includes('ECONNREFUSED')) {
            console.error('\n💡 解決方法:');
            console.error('   1. Firebase Emulator が起動していることを確認');
            console.error('   2. `npm run dev:local` でエミュレータを起動');
            console.error('   3. 再度このスクリプトを実行');
        }
        
        process.exit(1);
    }
}

// メイン実行
if (require.main === module) {
    seedFirebaseUsers();
}

module.exports = { seedFirebaseUsers };