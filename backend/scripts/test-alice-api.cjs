#!/usr/bin/env node

/**
 * Alice 受信トレイ API テスト
 * Firebase Emulator を使用して Alice でログインし、受信トレイ API をテスト
 */

async function testAliceAPI() {
    console.log('🧪 Alice API テスト開始...\n');
    
    try {
        const fetch = require('node-fetch');
        
        // Firebase Emulator に直接ログイン
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
            const errorText = await loginResponse.text();
            console.error('エラー詳細:', errorText);
            return;
        }
        
        const authResult = await loginResponse.json();
        const idToken = authResult.idToken;
        console.log('✅ Firebase ログイン成功');
        
        // バックエンドAPI呼び出し
        console.log('\n📡 受信トレイAPI呼び出しテスト...');
        const apiResponse = await fetch('http://localhost:8080/api/v1/messages/inbox-with-ratings', {
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${idToken}`,
                'Content-Type': 'application/json'
            }
        });
        
        console.log(`🔍 API レスポンス ステータス: ${apiResponse.status}`);
        
        if (apiResponse.ok) {
            const data = await apiResponse.json();
            console.log('✅ API 呼び出し成功');
            console.log('📊 API レスポンス構造:');
            console.log('  - success:', data.success);
            console.log('  - data 存在:', !!data.data);
            console.log('  - messages 存在:', !!data.data?.messages);
            console.log(`📬 受信メッセージ数: ${data.data?.messages?.length || 0} 件`);
            
            // デバッグ情報を表示
            if (data.debug) {
                console.log('\n🔍 デバッグ情報:');
                console.log('  - 認証ユーザー:', data.debug.authUser);
                console.log('  - 認証ユーザーID:', data.debug.authUserID);
                console.log('  - クエリ結果:', data.debug.queryResult);
                console.log('  - 総件数:', data.debug.totalCount);
            }
            
            if (data.data?.messages?.length > 0) {
                console.log('\n📋 受信メッセージ一覧:');
                data.data.messages.forEach((msg, index) => {
                    console.log(`  [${index + 1}] 送信者: ${msg.senderName || 'Unknown'} (${msg.senderEmail || 'N/A'})`);
                    console.log(`      本文: "${(msg.originalText || '').substring(0, 30)}..."`);
                    console.log(`      変換後: "${(msg.finalText || '').substring(0, 30)}..."`);
                    console.log(`      評価: ${msg.rating || '未評価'}`);
                    console.log(`      ステータス: ${msg.status}`);
                    console.log(`      既読: ${msg.readAt ? '既読' : '未読'}`);
                    console.log('');
                });
            } else {
                console.log('❌ 受信メッセージが空です - データベースに存在するが API で取得できない');
            }
        } else {
            const errorText = await apiResponse.text();
            console.error(`❌ API 呼び出し失敗: ${apiResponse.status}`);
            console.error('エラー詳細:', errorText);
        }
        
    } catch (error) {
        console.error('❌ テスト中にエラーが発生:', error.message);
        console.error('Stack trace:', error.stack);
    }
}

if (require.main === module) {
    testAliceAPI();
}