// MongoDB 開発環境シーダースクリプト
// 使用方法: mongosh "mongodb://localhost:27017/yanwari-message" scripts/seeders/seed-development.js

// データベース接続
const DB_NAME = 'yanwari-message';
db = db.getSiblingDB(DB_NAME);

// 色付きログ関数
function logInfo(message) {
    print(`🌱 [SEEDER] ${message}`);
}

function logSuccess(message) {
    print(`✅ [SEEDER] ${message}`);
}

function logError(message) {
    print(`❌ [SEEDER] ${message}`);
}

function logWarning(message) {
    print(`⚠️  [SEEDER] ${message}`);
}

// ファイル読み込み関数（実際の環境では適切なパスに調整）
function loadJsonData(filename) {
    try {
        // Docker環境では /tmp/sample-data/ にコピーされる
        const fs = require('fs');
        const content = fs.readFileSync(`/tmp/sample-data/${filename}`, 'utf8');
        return JSON.parse(content);
    } catch (error) {
        logError(`Failed to load ${filename}: ${error.message}`);
        return [];
    }
}

// ObjectId変換関数
function convertToObjectIds(data, idFields = ['_id', 'user_id', 'sender_id', 'recipient_id', 'user1_id', 'user2_id', 'message_id']) {
    return data.map(item => {
        const convertedItem = { ...item };
        
        idFields.forEach(field => {
            if (convertedItem[field] && typeof convertedItem[field] === 'string') {
                convertedItem[field] = ObjectId();
                convertedItem[`${field}_original`] = item[field]; // 元のIDも保持
            }
        });
        
        // 日付文字列をDateオブジェクトに変換
        Object.keys(convertedItem).forEach(key => {
            if (key.includes('_at') && typeof convertedItem[key] === 'string') {
                convertedItem[key] = new Date(convertedItem[key]);
            }
        });
        
        return convertedItem;
    });
}

// ID参照解決関数
function resolveReferences(data, referenceMap) {
    return data.map(item => {
        const resolvedItem = { ...item };
        
        Object.keys(referenceMap).forEach(originalId => {
            Object.keys(resolvedItem).forEach(key => {
                if (resolvedItem[key] === originalId) {
                    resolvedItem[key] = referenceMap[originalId];
                }
            });
        });
        
        return resolvedItem;
    });
}

// メイン実行関数
function seedDevelopmentData() {
    logInfo('開発環境のサンプルデータ投入を開始します...');
    
    try {
        // 1. 既存データのクリア
        logInfo('既存データをクリアしています...');
        db.users.deleteMany({});
        db.messages.deleteMany({});
        db.friendships.deleteMany({});
        db.message_ratings.deleteMany({});
        db.user_settings.deleteMany({});
        logSuccess('既存データのクリアが完了しました');
        
        // 2. ユーザーデータの投入
        logInfo('ユーザーデータを投入中...');
        const usersData = loadJsonData('users.json');
        if (usersData.length === 0) {
            logError('ユーザーデータの読み込みに失敗しました');
            return;
        }
        
        const userIdMap = {};
        const processedUsers = usersData.map(user => {
            const newId = ObjectId();
            userIdMap[user._id] = newId;
            
            return {
                ...user,
                _id: newId,
                created_at: new Date(user.created_at),
                updated_at: new Date(user.updated_at)
            };
        });
        
        const userResult = db.users.insertMany(processedUsers);
        logSuccess(`${userResult.insertedIds.length}件のユーザーを投入しました`);
        
        // 3. 友達関係データの投入
        logInfo('友達関係データを投入中...');
        const friendshipsData = loadJsonData('friendships.json');
        const processedFriendships = friendshipsData.map(friendship => ({
            ...friendship,
            _id: ObjectId(),
            user1_id: userIdMap[friendship.user1_id],
            user2_id: userIdMap[friendship.user2_id],
            created_at: new Date(friendship.created_at),
            updated_at: new Date(friendship.updated_at)
        }));
        
        if (processedFriendships.length > 0) {
            const friendshipResult = db.friendships.insertMany(processedFriendships);
            logSuccess(`${friendshipResult.insertedIds.length}件の友達関係を投入しました`);
        }
        
        // 4. メッセージデータの投入
        logInfo('メッセージデータを投入中...');
        const messagesData = loadJsonData('messages.json');
        const messageIdMap = {};
        const processedMessages = messagesData.map(message => {
            const newId = ObjectId();
            messageIdMap[message._id] = newId;
            
            const processedMessage = {
                ...message,
                _id: newId,
                sender_id: userIdMap[message.sender_id],
                recipient_id: userIdMap[message.recipient_id],
                created_at: new Date(message.created_at),
                updated_at: new Date(message.updated_at)
            };
            
            // オプションの日付フィールドを処理
            if (message.scheduled_at) {
                processedMessage.scheduled_at = new Date(message.scheduled_at);
            }
            if (message.delivered_at) {
                processedMessage.delivered_at = new Date(message.delivered_at);
            }
            if (message.read_at) {
                processedMessage.read_at = new Date(message.read_at);
            }
            
            return processedMessage;
        });
        
        if (processedMessages.length > 0) {
            const messageResult = db.messages.insertMany(processedMessages);
            logSuccess(`${messageResult.insertedIds.length}件のメッセージを投入しました`);
        }
        
        // 5. メッセージ評価データの投入
        logInfo('メッセージ評価データを投入中...');
        const ratingsData = loadJsonData('message_ratings.json');
        const processedRatings = ratingsData.map(rating => ({
            ...rating,
            _id: ObjectId(),
            message_id: messageIdMap[rating.message_id],
            user_id: userIdMap[rating.user_id],
            created_at: new Date(rating.created_at),
            updated_at: new Date(rating.updated_at)
        }));
        
        if (processedRatings.length > 0) {
            const ratingResult = db.message_ratings.insertMany(processedRatings);
            logSuccess(`${ratingResult.insertedIds.length}件のメッセージ評価を投入しました`);
        }
        
        // 6. ユーザー設定データの投入
        logInfo('ユーザー設定データを投入中...');
        const settingsData = loadJsonData('user_settings.json');
        const processedSettings = settingsData.map(setting => ({
            ...setting,
            _id: ObjectId(),
            user_id: userIdMap[setting.user_id],
            created_at: new Date(setting.created_at),
            updated_at: new Date(setting.updated_at)
        }));
        
        if (processedSettings.length > 0) {
            const settingsResult = db.user_settings.insertMany(processedSettings);
            logSuccess(`${settingsResult.insertedIds.length}件のユーザー設定を投入しました`);
        }
        
        // 7. データ検証
        logInfo('データ投入の検証中...');
        const userCount = db.users.countDocuments();
        const messageCount = db.messages.countDocuments();
        const friendshipCount = db.friendships.countDocuments();
        const ratingCount = db.message_ratings.countDocuments();
        const settingsCount = db.user_settings.countDocuments();
        
        logSuccess('=== データ投入完了 ===');
        logSuccess(`ユーザー: ${userCount}件`);
        logSuccess(`メッセージ: ${messageCount}件`);
        logSuccess(`友達関係: ${friendshipCount}件`);
        logSuccess(`メッセージ評価: ${ratingCount}件`);
        logSuccess(`ユーザー設定: ${settingsCount}件`);
        
        // 8. テスト用ログイン情報の表示
        logInfo('=== テスト用ログイン情報 ===');
        logInfo('以下のアカウントでログインできます（パスワード: password123）:');
        logInfo('👩 田中 あかり - alice@yanwari-message.com');
        logInfo('👨 佐藤 ひろし - bob@yanwari-message.com');
        logInfo('👩 鈴木 みゆき - charlie@yanwari-message.com');
        
    } catch (error) {
        logError(`データ投入中にエラーが発生しました: ${error.message}`);
        logError(`スタックトレース: ${error.stack}`);
    }
}

// 実行
seedDevelopmentData();