package main

import (
    "context"
    "fmt"
    "log"
    "yanwari-message-backend/database"
    "yanwari-message-backend/models"
    "github.com/joho/godotenv"
)

func main() {
    godotenv.Load()
    
    ctx := context.Background()
    client, err := database.Connect()
    if err \!= nil {
        log.Fatal("DB接続エラー:", err)
    }
    defer client.Disconnect(ctx)
    
    db := client.Database("yanwari-message")
    userService := models.NewUserService(db)
    
    // Bobを検索
    bob, err := userService.GetByEmail(ctx, "bob@yanwari.com")
    if err \!= nil {
        fmt.Printf("Bobが見つかりません: %v\n", err)
    } else {
        fmt.Printf("Bob found: ID=%s, Name=%s, FirebaseUID=%s\n", 
            bob.ID.Hex(), bob.Name, bob.FirebaseUID)
    }
    
    // Aliceも確認
    alice, err := userService.GetUserByFirebaseUID(ctx, "42KXtAePGIhXdeClVDJcEf1Qpz63")
    if err \!= nil {
        fmt.Printf("Aliceが見つかりません: %v\n", err)
    } else {
        fmt.Printf("Alice found: ID=%s, Name=%s, Email=%s\n", 
            alice.ID.Hex(), alice.Name, alice.Email)
    }
}
