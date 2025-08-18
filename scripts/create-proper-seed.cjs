// 正しいbcryptハッシュを生成してシーダーを更新するスクリプト
const bcrypt = require('bcryptjs');

async function generateProperSeed() {
    // password123 のbcryptハッシュを生成
    const password = 'password123';
    const saltRounds = 10;
    
    const hash1 = await bcrypt.hash(password, saltRounds);
    const hash2 = await bcrypt.hash(password, saltRounds);
    const hash3 = await bcrypt.hash(password, saltRounds);
    
    console.log('🔐 生成されたパスワードハッシュ:');
    console.log(`Alice: ${hash1}`);
    console.log(`Bob: ${hash2}`);
    console.log(`Charlie: ${hash3}`);
    
    // 検証
    console.log('\n✅ ハッシュ検証:');
    console.log(`Alice検証: ${await bcrypt.compare(password, hash1)}`);
    console.log(`Bob検証: ${await bcrypt.compare(password, hash2)}`);
    console.log(`Charlie検証: ${await bcrypt.compare(password, hash3)}`);
    
    // 新しいシーダー用のJavaScriptオブジェクト生成
    const usersData = [
        {
            name: "田中 あかり",
            email: "alice@yanwari-message.com",
            password_hash: hash1,
            profile: {
                bio: "デザイナーとして働いています。美しいデザインと心地よいコミュニケーションを大切にしています。",
                avatar_url: "https://api.dicebear.com/7.x/avataaars/svg?seed=alice",
                timezone: "Asia/Tokyo"
            },
            created_at: "2025-01-15T09:00:00.000Z",
            updated_at: "2025-01-18T10:00:00.000Z"
        },
        {
            name: "佐藤 ひろし",
            email: "bob@yanwari-message.com",
            password_hash: hash2,
            profile: {
                bio: "エンジニアとして新しい技術を学び続けています。チームワークを重視した開発が得意です。",
                avatar_url: "https://api.dicebear.com/7.x/avataaars/svg?seed=bob",
                timezone: "Asia/Tokyo"
            },
            created_at: "2025-01-16T10:30:00.000Z",
            updated_at: "2025-01-18T08:45:00.000Z"
        },
        {
            name: "鈴木 みゆき",
            email: "charlie@yanwari-message.com",
            password_hash: hash3,
            profile: {
                bio: "プロジェクトマネージャーとして、チームの調和と効率的な進行をサポートしています。",
                avatar_url: "https://api.dicebear.com/7.x/avataaars/svg?seed=charlie",
                timezone: "Asia/Tokyo"
            },
            created_at: "2025-01-17T14:15:00.000Z",
            updated_at: "2025-01-18T16:20:00.000Z"
        }
    ];
    
    console.log('\n📝 正しいシーダーファイル用データ:');
    console.log(JSON.stringify(usersData, null, 2));
}

generateProperSeed().catch(console.error);