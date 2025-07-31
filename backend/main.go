package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"

	"yanwari-message-backend/database"
	"yanwari-message-backend/handlers"
	"yanwari-message-backend/models"
	"yanwari-message-backend/services"
)

// サーバー起動時間を記録
var serverStartTime = time.Now()

func main() {
	// 環境変数の読み込み
	if err := godotenv.Load(); err != nil {
		log.Println("Warning: .env file not found - using system environment variables")
	}

	// Gin のモード設定
	ginMode := os.Getenv("GIN_MODE")
	if ginMode != "" {
		gin.SetMode(ginMode)
	}
	log.Printf("Application starting in %s mode", gin.Mode())

	// データベース接続
	db, err := database.Connect()
	if err != nil {
		log.Fatal("MongoDB接続に失敗しました:", err)
	}
	defer func() {
		if err := db.Close(); err != nil {
			log.Printf("MongoDB切断エラー: %v", err)
		}
	}()

	// ユーザーサービスの初期化
	userService := models.NewUserService(db.Database)
	
	// メッセージサービスの初期化
	messageService := models.NewMessageService(db.Database, userService)
	
	// スケジュールサービスの初期化
	scheduleService := models.NewScheduleService(db.Database, messageService)
	
	// インデックス作成
	ctx := context.Background()
	if err := userService.CreateEmailIndex(ctx); err != nil {
		log.Printf("警告: メールインデックス作成エラー: %v", err)
	}
	if err := userService.CreateNameIndex(ctx); err != nil {
		log.Printf("警告: 名前インデックス作成エラー: %v", err)
	}
	if err := messageService.CreateIndexes(ctx); err != nil {
		log.Printf("警告: メッセージインデックス作成エラー: %v", err)
	}

	// 配信サービスの初期化
	deliveryService := services.NewDeliveryService(messageService, scheduleService)
	// 1分間隔でスケジュール配信をチェック
	deliveryService.Start(1 * time.Minute)

	// Ginルーターの初期化
	r := gin.Default()

	// CORS設定（環境変数から読み込み）
	config := cors.DefaultConfig()
	allowedOrigins := os.Getenv("ALLOWED_ORIGINS")
	if allowedOrigins != "" {
		// カンマ区切りの文字列を配列に変換
		origins := strings.Split(allowedOrigins, ",")
		// 空白を除去
		for i, origin := range origins {
			origins[i] = strings.TrimSpace(origin)
		}
		config.AllowOrigins = origins
		log.Printf("CORS origins set from environment: %v", origins)
	} else {
		// デフォルト設定
		config.AllowOrigins = []string{"http://localhost:5173", "http://localhost:3000"}
		log.Printf("Using default CORS origins: %v", config.AllowOrigins)
	}
	config.AllowMethods = []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"}
	config.AllowHeaders = []string{"Origin", "Content-Type", "Accept", "Authorization"}
	config.AllowCredentials = true
	r.Use(cors.New(config))

	// セキュリティヘッダー（本番環境向け）
	if gin.Mode() == gin.ReleaseMode {
		r.Use(func(c *gin.Context) {
			c.Header("X-Content-Type-Options", "nosniff")
			c.Header("X-Frame-Options", "DENY")
			c.Header("X-XSS-Protection", "1; mode=block")
			c.Header("Strict-Transport-Security", "max-age=63072000; includeSubDomains; preload")
			c.Next()
		})
		log.Println("Security headers enabled for production mode")
	}

	// ヘルスチェックエンドポイント（データベース接続含む）
	r.GET("/health", func(c *gin.Context) {
		// データベース接続チェック
		dbStatus := "ok"
		var dbError string
		if err := db.HealthCheck(); err != nil {
			dbStatus = "error"
			dbError = err.Error()
		}

		// システム全体のステータス判定
		overallStatus := "ok"
		statusCode := http.StatusOK
		if dbStatus == "error" {
			overallStatus = "degraded"
			statusCode = http.StatusServiceUnavailable
		}

		response := gin.H{
			"status":     overallStatus,
			"message":    "Health check completed",
			"timestamp":  time.Now().Format(time.RFC3339),
			"port":       os.Getenv("PORT"),
			"components": gin.H{
				"server": gin.H{
					"status": "ok",
					"uptime": time.Since(serverStartTime).String(),
				},
				"database": gin.H{
					"status": dbStatus,
					"type":   "MongoDB Atlas",
				},
			},
		}

		// エラー情報があれば追加
		if dbError != "" {
			response["components"].(gin.H)["database"].(gin.H)["error"] = dbError
		}

		c.JSON(statusCode, response)
	})

	// 基本的なAPIエンドポイント
	r.GET("/api/status", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":      "running",
			"service":     "yanwari-message-backend",
			"environment": gin.Mode(),
		})
	})

	// サービスの初期化
	userSettingsService := models.NewUserSettingsService(db.Database, userService)
	friendRequestService := models.NewFriendRequestService(db.Database)
	friendshipService := models.NewFriendshipService(db.Database)
	messageRatingService := models.NewMessageRatingService(db.Database)
	
	// ユーザー設定インデックス作成
	if err := userSettingsService.CreateIndexes(ctx); err != nil {
		log.Printf("警告: ユーザー設定インデックス作成エラー: %v", err)
	}

	// ハンドラーの初期化
	authHandler := handlers.NewAuthHandler(userService)
	userHandler := handlers.NewUserHandler(userService)
	messageHandler := handlers.NewMessageHandler(messageService)
	transformHandler := handlers.NewTransformHandler(messageService)
	scheduleHandler := handlers.NewScheduleHandler(scheduleService, messageService, deliveryService)
	settingsHandler := handlers.NewSettingsHandler(userService, userSettingsService)
	friendRequestHandler := handlers.NewFriendRequestHandler(userService, friendRequestService, friendshipService)
	messageRatingHandler := handlers.NewMessageRatingHandler(messageRatingService, messageService)

	// JWTミドルウェア
	jwtMiddleware := handlers.JWTMiddleware()

	// API v1 ルートグループ
	v1 := r.Group("/api/v1")
	{
		// 認証関連エンドポイント
		auth := v1.Group("/auth")
		{
			auth.POST("/register", authHandler.Register)   // ユーザー登録
			auth.POST("/login", authHandler.Login)         // ログイン
			auth.POST("/refresh", authHandler.RefreshToken) // トークンリフレッシュ
			auth.POST("/logout", authHandler.Logout)       // ログアウト
		}

		// ユーザー関連エンドポイント
		userHandler.RegisterRoutes(v1, jwtMiddleware)

		// メッセージ関連エンドポイント
		messageHandler.RegisterRoutes(v1, jwtMiddleware)

		// メッセージ評価関連エンドポイント
		messageRatingHandler.RegisterRoutes(v1, jwtMiddleware)

		// 友達申請・友達関連エンドポイント
		friendRequestHandler.RegisterRoutes(v1, jwtMiddleware)

		// AIトーン変換関連エンドポイント
		transformHandler.RegisterRoutes(v1, jwtMiddleware)

		// スケジュール関連エンドポイント
		scheduleHandler.RegisterRoutes(v1, jwtMiddleware)

		// 設定関連エンドポイント
		settings := v1.Group("/settings").Use(jwtMiddleware)
		{
			settings.GET("", settingsHandler.GetSettings)                           // 設定取得
			settings.PUT("/profile", settingsHandler.UpdateProfile)                 // プロフィール更新
			settings.PUT("/password", settingsHandler.ChangePassword)               // パスワード変更
			settings.PUT("/notifications", settingsHandler.UpdateNotificationSettings) // 通知設定更新
			settings.PUT("/messages", settingsHandler.UpdateMessageSettings)       // メッセージ設定更新
			settings.DELETE("/account", settingsHandler.DeleteAccount)             // アカウント削除
		}
	}

	// HTTPサーバーの設定
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	srv := &http.Server{
		Addr:    ":" + port,
		Handler: r,
	}

	// グレースフルシャットダウンの実装
	go func() {
		log.Printf("Server starting on port %s", port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	// シグナル待機
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("Shutting down server...")

	// シャットダウンタイムアウト設定（30秒）
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// 配信サービスの停止
	log.Println("Stopping delivery service...")
	deliveryService.Stop()

	// HTTPサーバーのグレースフルシャットダウン
	if err := srv.Shutdown(ctx); err != nil {
		log.Printf("Server forced to shutdown: %v", err)
	} else {
		log.Println("Server gracefully stopped")
	}

	// データベース接続のクリーンアップは defer で既に設定済み
	log.Println("Application shutdown complete")
}