#!/usr/bin/env node

/**
 * Alice 認証詳細デバッグ
 * Firebase認証のFirebase UIDを確認し、MongoDBでの検索を詳細に調べる
 */

const { MongoClient } = require('mongodb');
require('dotenv').config({ path: __dirname + '/../.env' });

async function debugAliceAuth() {
    console.log('🔍 Alice 認証詳細デバッグ開始...\n');
    
    try {
        const fetch = require('node-fetch');
        
        // 1. Firebase Emulator でログイン
        console.log('🔐 Firebase Emulator でログイン...');
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
        
        if (!loginResponse.ok) {
            console.error('❌ Firebase ログイン失敗:', loginResponse.status);
            return;
        }
        
        const authResult = await loginResponse.json();
        console.log('✅ Firebase ログイン成功');
        console.log('📋 認証結果:');
        console.log('  - localId (Firebase UID):', authResult.localId);
        console.log('  - email:', authResult.email);
        console.log('  - emailVerified:', authResult.emailVerified);
        
        // 2. MongoDB で直接検索
        console.log('\n🗄️ MongoDB で直接検索...');
        const client = new MongoClient(process.env.MONGODB_URI);
        await client.connect();
        const db = client.db('yanwari-message');
        
        // Firebase UID で検索
        const userByUID = await db.collection('users').findOne({
            firebaseUid: authResult.localId
        });
        
        console.log('📊 Firebase UID での検索結果:');
        if (userByUID) {
            console.log('  ✅ ユーザー発見:');
            console.log('    - MongoDB ID:', userByUID._id);
            console.log('    - Email:', userByUID.email);
            console.log('    - Firebase UID:', userByUID.firebaseUid);
            console.log('    - Name:', userByUID.name);
        } else {
            console.log('  ❌ Firebase UID でユーザーが見つかりません');
        }
        
        // メールアドレスでも検索
        const userByEmail = await db.collection('users').findOne({
            email: 'alice@yanwari.com'
        });
        
        console.log('\n📊 メールアドレスでの検索結果:');
        if (userByEmail) {
            console.log('  ✅ ユーザー発見:');
            console.log('    - MongoDB ID:', userByEmail._id);
            console.log('    - Email:', userByEmail.email);
            console.log('    - Firebase UID:', userByEmail.firebaseUid);
            console.log('    - Name:', userByEmail.name);
        } else {
            console.log('  ❌ メールアドレスでユーザーが見つかりません');
        }
        
        // 差異を確認
        if (userByUID && userByEmail) {
            if (userByUID._id.toString() === userByEmail._id.toString()) {
                console.log('\n✅ Firebase UID 検索とメール検索で同じユーザーが見つかりました');
            } else {
                console.log('\n❌ Firebase UID 検索とメール検索で異なるユーザーが見つかりました');
            }
        } else if (!userByUID && userByEmail) {
            console.log('\n🚨 重要: メールアドレスではユーザーが見つかるが、Firebase UIDでは見つからない');
            console.log('   期待Firebase UID:', authResult.localId);
            console.log('   実際Firebase UID:', userByEmail.firebaseUid);
            console.log('   → Firebase UID 不一致が原因です');
        }
        
        await client.close();
        
    } catch (error) {
        console.error('❌ デバッグ中にエラー:', error.message);
    }
}

if (require.main === module) {
    debugAliceAuth();
}