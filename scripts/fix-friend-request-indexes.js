// MongoDB友達申請インデックス修正スクリプト
// 使用方法: docker cp ./scripts/fix-friend-request-indexes.js $(docker-compose ps -q mongodb):/tmp/ && docker-compose exec mongodb mongosh yanwari-message /tmp/fix-friend-request-indexes.js

print("🔧 友達申請インデックス修正スクリプト開始");

// 現在のインデックス確認
print("📋 現在のインデックス一覧:");
db.friend_requests.getIndexes().forEach(idx => {
    print(`  - ${idx.name}: ${JSON.stringify(idx.key)}`);
});

// 古いインデックスの存在確認と削除
const oldIndexes = ["sender_id_1_recipient_id_1", "recipient_id_1_status_1"];
let removed = 0;

oldIndexes.forEach(indexName => {
    try {
        // インデックスが存在するかチェック
        const existing = db.friend_requests.getIndexes().find(idx => idx.name === indexName);
        if (existing) {
            print(`🗑️  古いインデックス削除中: ${indexName}`);
            db.friend_requests.dropIndex(indexName);
            print(`✅ 削除完了: ${indexName}`);
            removed++;
        } else {
            print(`ℹ️  インデックス未存在: ${indexName}`);
        }
    } catch (error) {
        print(`❌ インデックス削除エラー (${indexName}): ${error.message}`);
    }
});

// 必要なインデックスの存在確認
print("\n🔍 必要なインデックス確認中...");
const requiredIndexes = [
    { name: "from_user_id_1_to_user_id_1", keys: ["from_user_id", "to_user_id"], unique: true },
    { name: "status_1", keys: ["status"], unique: false },
    { name: "to_user_id_1", keys: ["to_user_id"], unique: false }
];

requiredIndexes.forEach(reqIdx => {
    const exists = db.friend_requests.getIndexes().find(idx => idx.name === reqIdx.name);
    if (exists) {
        print(`✅ 必須インデックス存在: ${reqIdx.name}`);
    } else {
        print(`⚠️  必須インデックス未存在: ${reqIdx.name}`);
    }
});

// 修正後のインデックス一覧
print("\n📋 修正後のインデックス一覧:");
db.friend_requests.getIndexes().forEach(idx => {
    const uniqueStr = idx.unique ? " (unique)" : "";
    print(`  ✅ ${idx.name}: ${JSON.stringify(idx.key)}${uniqueStr}`);
});

// 結果サマリー
print("\n🎯 修正結果サマリー:");
print(`  - 削除された古いインデックス: ${removed}件`);
print(`  - 現在のインデックス数: ${db.friend_requests.getIndexes().length}件`);

if (removed > 0) {
    print("\n🎉 友達申請インデックス修正が完了しました！");
    print("   友達申請機能が正常に動作するはずです。");
} else {
    print("\n✅ インデックスは既に正常な状態です。");
}

print("\n🧪 動作テスト方法:");
print("   1. Bob でログイン: bob@yanwari-message.com");
print("   2. Charlie に友達申請: charlie@yanwari-message.com");
print("   3. 正常に申請が送信されることを確認");