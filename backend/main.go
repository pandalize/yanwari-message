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
	ginSwagger "github.com/swaggo/gin-swagger"
	swaggerFiles "github.com/swaggo/files"

	"yanwari-message-backend/database"
	_ "yanwari-message-backend/docs"
	"yanwari-message-backend/handlers"
	"yanwari-message-backend/middleware"
	"yanwari-message-backend/models"
	"yanwari-message-backend/services"
)

// サーバー起動時間を記録
var serverStartTime = time.Now()

// @title Yanwari Message API
// @version 1.0
// @description やんわり伝言サービス - AIを使って気まずい用件を優しく伝えるサービスのAPI
// @termsOfService http://swagger.io/terms/

// @contact.name API Support
// @contact.url http://www.swagger.io/support
// @contact.email support@swagger.io

// @license.name MIT
// @license.url https://opensource.org/licenses/MIT

// @host localhost:8080
// @BasePath /api/v1
// @schemes http

// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
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

	// Firebase サービスの初期化
	firebaseService, err := services.NewFirebaseService()
	if err != nil {
		log.Printf("警告: Firebase初期化エラー (開発モードで継続): %v", err)
		firebaseService = nil // Firebase無効で継続
	} else {
		log.Println("✅ Firebase Admin SDK初期化完了")
	}

	// サービスの初期化
	userSettingsService := models.NewUserSettingsService(db.Database, userService)
	friendRequestService := models.NewFriendRequestService(db.Database)
	friendshipService := models.NewFriendshipService(db.Database)
	messageRatingService := models.NewMessageRatingService(db.Database)
	
	// ユーザー設定インデックス作成
	if err := userSettingsService.CreateIndexes(ctx); err != nil {
		log.Printf("警告: ユーザー設定インデックス作成エラー: %v", err)
	}
	
	// Firebase UIDインデックス作成
	if err := userService.CreateFirebaseUIDIndex(ctx); err != nil {
		log.Printf("警告: Firebase UIDインデックス作成エラー: %v", err)
	}

	// ハンドラーの初期化（JWT認証ハンドラーは廃止）
	userHandler := handlers.NewUserHandler(userService)
	messageHandler := handlers.NewMessageHandler(messageService)
	transformHandler := handlers.NewTransformHandler(messageService)
	scheduleHandler := handlers.NewScheduleHandler(scheduleService, messageService, deliveryService)
	settingsHandler := handlers.NewSettingsHandler(userService, userSettingsService)
	friendRequestHandler := handlers.NewFriendRequestHandler(userService, friendRequestService, friendshipService)
	messageRatingHandler := handlers.NewMessageRatingHandler(messageRatingService, messageService)
	
	// Firebase認証ハンドラーの初期化
	var firebaseAuthHandler *handlers.FirebaseAuthHandler
	var firebaseMiddleware gin.HandlerFunc
	
	if firebaseService != nil {
		firebaseAuthHandler = handlers.NewFirebaseAuthHandler(userService, firebaseService)
		firebaseMiddleware = middleware.FirebaseAuthMiddleware(firebaseService)
		log.Println("✅ Firebase認証ハンドラー初期化完了")
	} else {
		log.Println("⚠️ Firebase認証ハンドラーをスキップ（Firebase未初期化）")
	}

	// Firebase認証が必須（JWT認証は廃止）
	if firebaseService == nil || firebaseMiddleware == nil {
		log.Fatal("❌ Firebase認証が必須です。Firebase設定を確認してください。")
	}

	// API v1 ルートグループ
	v1 := r.Group("/api/v1")
	{
		// Firebase認証関連エンドポイント（認証不要・ユーティリティ）
		firebaseAuthHandler.RegisterRoutes(v1, firebaseMiddleware)

		// すべてのAPIエンドポイントでFirebase認証を使用
		userHandler.RegisterRoutes(v1, firebaseMiddleware)
		messageHandler.RegisterRoutes(v1, firebaseMiddleware)
		messageRatingHandler.RegisterRoutes(v1, firebaseMiddleware)
		friendRequestHandler.RegisterRoutes(v1, firebaseMiddleware)
		transformHandler.RegisterRoutes(v1, firebaseMiddleware)
		scheduleHandler.RegisterRoutes(v1, firebaseMiddleware)
		settingsHandler.RegisterRoutes(v1, firebaseMiddleware)
		
		log.Println("✅ 全APIエンドポイントでFirebase認証を使用")
	}

	// Swagger UI endpoints (development only)
	if gin.Mode() == gin.DebugMode {
		r.GET("/docs/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))
		r.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))
		log.Println("📖 Swagger UI enabled at: http://localhost:8080/docs/index.html")
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