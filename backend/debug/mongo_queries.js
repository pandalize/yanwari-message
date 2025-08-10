// MongoDB クエリスクリプト
// mongo shell または MongoDB Compass で実行可能

// 使用方法:
// mongo "mongodb+srv://your-connection-string/yanwari-message" mongo_queries.js

print("🔍 やんわり伝言メッセージコレクション調査");
print("=" * 60);

// 1. 基本統計情報
print("\n📊 基本統計情報:");
print("総メッセージ数: " + db.messages.countDocuments({}));

// 2. ステータス別件数
print("\n📋 ステータス別メッセージ数:");
const statusCounts = db.messages.aggregate([
    { $group: { _id: "$status", count: { $sum: 1 } } },
    { $sort: { "_id": 1 } }
]);
statusCounts.forEach(function(doc) {
    print("  " + doc._id + ": " + doc.count + "件");
});

// 3. scheduled状態のメッセージ詳細
print("\n🕒 scheduled状態のメッセージ:");
print("-" * 50);
const scheduledMessages = db.messages.find({ status: "scheduled" });
let scheduledCount = 0;
const now = new Date();

scheduledMessages.forEach(function(msg) {
    scheduledCount++;
    print("メッセージ #" + scheduledCount + ":");
    print("  ID: " + msg._id);
    print("  ステータス: " + msg.status);
    
    if (msg.scheduledAt) {
        const scheduledTime = new Date(msg.scheduledAt);
        print("  配信予定時刻: " + scheduledTime.toISOString());
        print("  JST: " + scheduledTime.toLocaleString('ja-JP', { timeZone: 'Asia/Tokyo' }));
        
        if (scheduledTime < now) {
            const diffMs = now - scheduledTime;
            const diffMinutes = Math.floor(diffMs / (1000 * 60));
            print("  ⚠️  配信予定時刻が過去 (" + diffMinutes + "分前)");
        } else {
            const diffMs = scheduledTime - now;
            const diffMinutes = Math.floor(diffMs / (1000 * 60));
            print("  ⏰ 配信まで残り " + diffMinutes + "分");
        }
    } else {
        print("  ⚠️  scheduledAtがnull");
    }
    
    print("  作成日時: " + new Date(msg.createdAt).toISOString());
    print("  元テキスト: " + (msg.originalText ? msg.originalText.substring(0, 50) + "..." : "なし"));
    print("");
});

if (scheduledCount === 0) {
    print("  ✅ scheduled状態のメッセージはありません");
}

// 4. 配信対象メッセージのシミュレーション（DeliverScheduledMessages関数と同じ条件）
print("\n🔍 DeliverScheduledMessages関数の実行シミュレーション:");
print("-" * 50);
print("検索条件: { status: 'scheduled', scheduledAt: { $lte: ISODate('" + now.toISOString() + "') } }");

const deliveryTargets = db.messages.find({
    status: "scheduled",
    scheduledAt: { $lte: now }
});

let deliveryCount = 0;
deliveryTargets.forEach(function(msg) {
    deliveryCount++;
    print("配信対象メッセージ #" + deliveryCount + ":");
    print("  ID: " + msg._id);
    print("  配信予定時刻: " + new Date(msg.scheduledAt).toISOString());
    print("  作成日時: " + new Date(msg.createdAt).toISOString());
    print("");
});

print("📋 DeliverScheduledMessages関数の結果: " + deliveryCount + "件のメッセージが配信対象");

// 5. 過去の配信予定時刻を持つ未送信メッセージ
print("\n⏰ 過去の配信予定時刻を持つ未送信メッセージ:");
print("-" * 50);

const pastUnsentMessages = db.messages.find({
    scheduledAt: { $lte: now },
    status: { $nin: ["sent", "delivered", "read"] }
});

let pastUnsentCount = 0;
pastUnsentMessages.forEach(function(msg) {
    pastUnsentCount++;
    print("未送信メッセージ #" + pastUnsentCount + ":");
    print("  ID: " + msg._id);
    print("  ステータス: " + msg.status);
    if (msg.scheduledAt) {
        const diffMs = now - new Date(msg.scheduledAt);
        const diffMinutes = Math.floor(diffMs / (1000 * 60));
        print("  配信予定時刻: " + new Date(msg.scheduledAt).toISOString() + " (" + diffMinutes + "分前)");
    }
    print("");
});

if (pastUnsentCount === 0) {
    print("  ✅ 過去の配信予定時刻を持つ未送信メッセージはありません");
}

// 6. 最新メッセージ5件の概要
print("\n📅 最新メッセージ5件:");
print("-" * 50);

const recentMessages = db.messages.find().sort({ createdAt: -1 }).limit(5);
let recentCount = 0;

recentMessages.forEach(function(msg) {
    recentCount++;
    print("メッセージ #" + recentCount + ":");
    print("  ID: " + msg._id);
    print("  ステータス: " + msg.status);
    print("  作成日時: " + new Date(msg.createdAt).toISOString());
    if (msg.scheduledAt) {
        print("  配信予定時刻: " + new Date(msg.scheduledAt).toISOString());
    }
    print("  テキスト: " + (msg.originalText ? msg.originalText.substring(0, 30) + "..." : "なし"));
    print("");
});

print("\n🔍 調査完了");
print("=" * 60);