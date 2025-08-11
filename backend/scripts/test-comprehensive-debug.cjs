#!/usr/bin/env node

/**
 * 包括的デバッグ - Alice 問題の完全確認
 * WiFi接続時に実行してください
 */

const { MongoClient } = require('mongodb');
require('dotenv').config({ path: __dirname + '/../.env' });

async function comprehensiveDebug() {
    console.log('🔍 Alice 問題包括的デバッグ開始...\n');
    
    try {
        // 1. データベース接続確認
        console.log('🗄️ MongoDB Atlas 接続確認...');
        const client = new MongoClient(process.env.MONGODB_URI);
        await client.connect();
        const db = client.db('yanwari-message');
        console.log('✅ MongoDB Atlas 接続成功');
        
        // 2. Alice ユーザーの存在確認（複数フィールドで検索）
        console.log('\n👤 Alice ユーザー存在確認:');
        
        // メールアドレスで検索
        const aliceByEmail = await db.collection('users').findOne({ 
            email: 'alice@yanwari.com' 
        });
        console.log('  - メールアドレス検索:', aliceByEmail ? '✅ 発見' : '❌ 未発見');
        
        if (aliceByEmail) {
            console.log('    MongoDB ID:', aliceByEmail._id);
            console.log('    Email:', aliceByEmail.email);
            console.log('    Name:', aliceByEmail.name);
            console.log('    firebaseUid (camelCase):', aliceByEmail.firebaseUid);
            console.log('    firebase_uid (snake_case):', aliceByEmail.firebase_uid);
            console.log('');
        }
        
        // camelCase Firebase UID で検索
        const aliceByCamelCase = await db.collection('users').findOne({
            firebaseUid: 'test_firebase_uid_001'
        });
        console.log('  - camelCase UID検索:', aliceByCamelCase ? '✅ 発見' : '❌ 未発見');
        
        // snake_case Firebase UID で検索
        const aliceBySnakeCase = await db.collection('users').findOne({
            firebase_uid: 'test_firebase_uid_001'
        });
        console.log('  - snake_case UID検索:', aliceBySnakeCase ? '✅ 発見' : '❌ 未発見');
        
        // 3. フィールド名の実際の状況確認
        console.log('\n📊 データベースフィールド名確認:');
        const allUsers = await db.collection('users').find({}).toArray();
        if (allUsers.length > 0) {
            console.log('  サンプルユーザーフィールド:');
            const sampleUser = allUsers[0];
            console.log('    利用可能フィールド:', Object.keys(sampleUser));
            console.log('    firebaseUid:', sampleUser.firebaseUid);
            console.log('    firebase_uid:', sampleUser.firebase_uid);
        }
        
        // 4. Alice宛てメッセージ確認
        if (aliceByEmail) {
            console.log('\n📬 Alice宛てメッセージ確認:');
            const messages = await db.collection('messages').find({
                recipientId: aliceByEmail._id
            }).toArray();
            console.log(`  Alice宛てメッセージ: ${messages.length} 件`);
        }
        
        await client.close();
        
        // 5. Firebase認証テスト
        console.log('\n🔐 Firebase認証テスト:');
        const fetch = require('node-fetch');
        
        const loginResponse = await fetch('http://127.0.0.1:9099/www.googleapis.com/identitytoolkit/v3/relyingparty/verifyPassword?key=fake-api-key', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                email: 'alice@yanwari.com',
                password: 'testpassword123',
                returnSecureToken: true
            })
        });
        
        if (loginResponse.ok) {
            const authResult = await loginResponse.json();
            console.log('  Firebase UID:', authResult.localId);
            console.log('  ✅ Firebase認証成功');
            
            // 6. API認証テスト
            console.log('\n🔗 API認証テスト:');
            const apiResponse = await fetch('http://localhost:8080/api/v1/messages/inbox-with-ratings', {
                method: 'GET',
                headers: {
                    'Authorization': `Bearer ${authResult.idToken}`,
                    'Content-Type': 'application/json'
                }
            });
            
            if (apiResponse.ok) {
                const apiData = await apiResponse.json();
                console.log(`  API結果: ${apiData.data.messages.length} 件のメッセージ`);
                console.log('  総数:', apiData.data.pagination.total);
                console.log('  ✅ API呼び出し成功');
            } else {
                console.log('  ❌ API呼び出し失敗:', apiResponse.status);
                const errorText = await apiResponse.text();
                console.log('  エラー:', errorText);
            }
        } else {
            console.log('  ❌ Firebase認証失敗');
        }
        
    } catch (error) {
        console.error('❌ デバッグ中にエラー:', error.message);
        if (error.message.includes('ECONNREFUSED')) {
            console.log('\n💡 ヒント: テザリング接続の場合、WiFi接続でもう一度お試しください');
        }
    }
}

if (require.main === module) {
    comprehensiveDebug();
}