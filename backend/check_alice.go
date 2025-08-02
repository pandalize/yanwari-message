package main

import (
    "context"
    "fmt"
    "log"
    "yanwari-message-backend/database"
    "yanwari-message-backend/models"
    "github.com/joho/godotenv"
    "go.mongodb.org/mongo-driver/bson"
)

func main() {
    godotenv.Load()
    
    ctx := context.Background()
    db, err := database.Connect()
    if err \!= nil {
        log.Fatal("DB接続エラー:", err)
    }
    
    userService := models.NewUserService(db.Database)
    
    // Firebase UIDでAliceを検索
    alice, err := userService.GetUserByFirebaseUID(ctx, "42KXtAePGIhXdeClVDJcEf1Qpz63")
    if err \!= nil {
        fmt.Printf("AliceがFirebase UIDで見つかりません: %v\n", err)
        
        // メールアドレスで検索してみる
        users := db.Database.Collection("users")
        var user models.User
        err2 := users.FindOne(ctx, bson.M{"email": "alice@yanwari.com"}).Decode(&user)
        if err2 \!= nil {
            fmt.Printf("Aliceがメールアドレスでも見つかりません: %v\n", err2)
        } else {
            fmt.Printf("Aliceが見つかりました（メールアドレス検索）:\n")
            fmt.Printf("  ID: %s\n", user.ID.Hex())
            fmt.Printf("  Name: %s\n", user.Name)
            fmt.Printf("  Email: %s\n", user.Email)
            fmt.Printf("  FirebaseUID: '%s'\n", user.FirebaseUID)
            fmt.Printf("  CreatedAt: %v\n", user.CreatedAt)
        }
    } else {
        fmt.Printf("AliceがFirebase UIDで見つかりました:\n")
        fmt.Printf("  ID: %s\n", alice.ID.Hex())
        fmt.Printf("  Name: %s\n", alice.Name)
        fmt.Printf("  Email: %s\n", alice.Email)
        fmt.Printf("  FirebaseUID: '%s'\n", alice.FirebaseUID)
    }
}
