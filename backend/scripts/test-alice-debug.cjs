#!/usr/bin/env node

/**
 * Alice 専用デバッグエンドポイント テスト
 */

async function testAliceDebug() {
    console.log('🔍 Alice デバッグエンドポイント テスト開始...\n');
    
    try {
        const fetch = require('node-fetch');
        
        // Firebase Emulator でログイン
        console.log('🔐 Firebase Emulator でログイン中...');
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
        const idToken = authResult.idToken;
        console.log('✅ Firebase ログイン成功');
        
        // デバッグAPI呼び出し
        console.log('\n📡 デバッグAPI呼び出しテスト...');
        const debugResponse = await fetch('http://localhost:8080/api/v1/messages/inbox-with-ratings', {
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${idToken}`,
                'Content-Type': 'application/json'
            }
        });
        
        console.log(`🔍 デバッグAPI レスポンス ステータス: ${debugResponse.status}`);
        
        if (debugResponse.ok) {
            const debugData = await debugResponse.json();
            console.log('✅ デバッグAPI 呼び出し成功');
            
            if (debugData.debug) {
                console.log('\n🔍 認証デバッグ情報:');
                console.log('  - 認証ユーザー:', debugData.debug.authUser);
                console.log('  - 認証ユーザーID:', debugData.debug.authUserID);
                console.log('  - 認証ユーザー名:', debugData.debug.authUserName);
                console.log('  - Firebase UID:', debugData.debug.firebaseUID);
                
                // 期待値と比較
                console.log('\n📊 期待値との比較:');
                console.log('  - Alice ObjectID 期待値: 689966590c9e92e85fee9ebe');
                console.log('  - API 取得 ObjectID:     ', debugData.debug.authUserID);
                console.log('  - 一致:', debugData.debug.authUserID === '689966590c9e92e85fee9ebe' ? '✅' : '❌');
                
                // メッセージクエリ結果も表示
                console.log('\n📬 メッセージクエリ結果:');
                console.log('  - クエリ結果:', debugData.debug.queryResult);
                console.log('  - 総件数:', debugData.debug.totalCount);
            } else {
                console.log('❌ デバッグ情報が見つかりません');
                console.log('レスポンス:', JSON.stringify(debugData, null, 2));
            }
        } else {
            const errorText = await debugResponse.text();
            console.error(`❌ デバッグAPI 呼び出し失敗: ${debugResponse.status}`);
            console.error('エラー詳細:', errorText);
        }
        
    } catch (error) {
        console.error('❌ テスト中にエラーが発生:', error.message);
    }
}

if (require.main === module) {
    testAliceDebug();
}