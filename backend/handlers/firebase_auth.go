package handlers

import (
	"context"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"yanwari-message-backend/middleware"
	"yanwari-message-backend/migration"
	"yanwari-message-backend/models"
	"yanwari-message-backend/services"
)

// FirebaseAuthHandler Firebase認証を使用した認証ハンドラー
type FirebaseAuthHandler struct {
	userService     *models.UserService
	firebaseService *services.FirebaseService
}

// NewFirebaseAuthHandler FirebaseAuthHandlerのコンストラクタ
func NewFirebaseAuthHandler(userService *models.UserService, firebaseService *services.FirebaseService) *FirebaseAuthHandler {
	return &FirebaseAuthHandler{
		userService:     userService,
		firebaseService: firebaseService,
	}
}

// GetUserProfile Firebase認証を使用してユーザープロフィールを取得
func (h *FirebaseAuthHandler) GetUserProfile(c *gin.Context) {
	// Firebase UIDを取得
	firebaseUID, exists := middleware.GetFirebaseUID(c)
	if !exists {
		log.Printf("Firebase認証ハンドラー: Firebase UIDが取得できません")
		c.JSON(http.StatusUnauthorized, gin.H{
			"error":   "認証エラー",
			"message": "Firebase UIDが取得できませんでした",
		})
		return
	}

	// MongoDBからユーザー情報を取得
	user, err := h.userService.GetUserByFirebaseUID(c.Request.Context(), firebaseUID)
	if err != nil {
		log.Printf("🔄 Firebase認証ハンドラー: MongoDB にユーザーが見つかりません: %v", err)
		log.Printf("🔄 Firebase UID: %s の自動同期を試行中...", firebaseUID)
		
		// Firebase上でのユーザー情報を取得して自動作成
		firebaseUser, fbErr := h.firebaseService.GetUserByUID(firebaseUID)
		if fbErr != nil {
			log.Printf("❌ Firebase ユーザー情報取得エラー: %v", fbErr)
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "Firebase UID " + firebaseUID + " に対応するユーザーが見つかりません",
				"message": "Firebase UID " + firebaseUID + " のユーザーが見つかりません",
			})
			return
		}

		// 新しいユーザーをMongoDBに作成
		newUser := &models.User{
			Email:       firebaseUser.Email,
			FirebaseUID: firebaseUID,
			Name:        firebaseUser.DisplayName,
			Timezone:    "Asia/Tokyo",
		}

		// 表示名が空の場合はメールアドレスから生成
		if newUser.Name == "" {
			newUser.Name = firebaseUser.Email
		}

		createErr := h.userService.CreateUserWithFirebaseUID(c.Request.Context(), newUser)
		if createErr != nil {
			log.Printf("❌ 自動同期失敗 - ユーザー作成エラー: %v", createErr)
			c.JSON(http.StatusInternalServerError, gin.H{
				"error":   "ユーザー自動作成エラー",
				"message": "MongoDBへのユーザー作成に失敗しました",
			})
			return
		}

		log.Printf("✅ 自動同期成功: %s (Firebase UID: %s)", newUser.Email, firebaseUID)
		user = newUser
	}

	// レスポンス
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data": gin.H{
			"user": user,
		},
	})
}

// GetOrCreateUserFromFirebase Firebase UIDからMongoDBユーザーを取得し、存在しない場合は自動作成
func (h *FirebaseAuthHandler) GetOrCreateUserFromFirebase(ctx context.Context, firebaseUID string) (*models.User, error) {
	// MongoDBからユーザー情報を取得
	user, err := h.userService.GetUserByFirebaseUID(ctx, firebaseUID)
	if err == nil {
		// ユーザーが見つかった場合はそのまま返す
		return user, nil
	}

	log.Printf("🔄 ユーザー自動同期開始: Firebase UID %s", firebaseUID)

	// Firebase上でのユーザー情報を取得
	firebaseUser, fbErr := h.firebaseService.GetUserByUID(firebaseUID)
	if fbErr != nil {
		log.Printf("❌ Firebase ユーザー情報取得エラー: %v", fbErr)
		return nil, fbErr
	}

	// 新しいユーザーをMongoDBに作成
	newUser := &models.User{
		Email:       firebaseUser.Email,
		FirebaseUID: firebaseUID,
		Name:        firebaseUser.DisplayName,
		Timezone:    "Asia/Tokyo",
	}

	// 表示名が空の場合はメールアドレスから生成
	if newUser.Name == "" {
		newUser.Name = firebaseUser.Email
	}

	createErr := h.userService.CreateUserWithFirebaseUID(ctx, newUser)
	if createErr != nil {
		log.Printf("❌ 自動同期失敗 - ユーザー作成エラー: %v", createErr)
		return nil, createErr
	}

	log.Printf("✅ ユーザー自動同期成功: %s (Firebase UID: %s)", newUser.Email, firebaseUID)
	return newUser, nil
}

// SyncUserFromFirebase Firebase認証でログインした際にMongoDBにユーザー情報を同期
func (h *FirebaseAuthHandler) SyncUserFromFirebase(c *gin.Context) {
	// Firebase UIDとメールアドレスを取得
	firebaseUID, exists := middleware.GetFirebaseUID(c)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error":   "認証エラー",
			"message": "Firebase UIDが取得できませんでした",
		})
		return
	}

	_, exists = middleware.GetUserEmail(c)
	if !exists {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "データ不足",
			"message": "メールアドレスが取得できませんでした",
		})
		return
	}

	// 既存ユーザーをチェック
	existingUser, err := h.userService.GetUserByFirebaseUID(c.Request.Context(), firebaseUID)
	if err == nil {
		// 既存ユーザーが見つかった場合
		log.Printf("既存ユーザーと同期: %s (Firebase UID: %s)", existingUser.Email, firebaseUID)
		c.JSON(http.StatusOK, gin.H{
			"status": "success",
			"data": gin.H{
				"user":     existingUser,
				"new_user": false,
			},
		})
		return
	}

	// Firebase上でのユーザー情報を取得
	firebaseUser, err := h.firebaseService.GetUserByUID(firebaseUID)
	if err != nil {
		log.Printf("Firebase認証ハンドラー: Firebase ユーザー情報取得エラー: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Firebase エラー",
			"message": "Firebase上でユーザー情報が取得できませんでした",
		})
		return
	}

	// 新しいユーザーをMongoDBに作成
	newUser := &models.User{
		Email:       firebaseUser.Email,
		FirebaseUID: firebaseUID,
		Name:        firebaseUser.DisplayName, // Firebase上での表示名があれば使用
		Timezone:    "Asia/Tokyo",             // デフォルトタイムゾーン
	}

	// 表示名が空の場合はメールアドレスから生成
	if newUser.Name == "" {
		newUser.Name = firebaseUser.Email
	}

	err = h.userService.CreateUserWithFirebaseUID(c.Request.Context(), newUser)
	if err != nil {
		log.Printf("Firebase認証ハンドラー: 新規ユーザー作成エラー: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "ユーザー作成エラー",
			"message": "MongoDBへのユーザー作成に失敗しました",
		})
		return
	}

	log.Printf("新規ユーザー作成: %s (Firebase UID: %s)", newUser.Email, firebaseUID)
	c.JSON(http.StatusCreated, gin.H{
		"status": "success",
		"data": gin.H{
			"user":     newUser,
			"new_user": true,
		},
	})
}

// RunMigration データベース移行を実行（管理者用）
func (h *FirebaseAuthHandler) RunMigration(c *gin.Context) {
	log.Println("🚀 Firebase移行を開始...")

	// 移行実行
	migrationService := migration.NewUserMigration(h.userService, h.firebaseService)
	
	// Firebase UIDインデックスを先に作成
	if err := migrationService.CreateFirebaseIndexes(); err != nil {
		log.Printf("❌ インデックス作成エラー: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "インデックス作成エラー",
			"message": err.Error(),
		})
		return
	}

	// 移行実行
	result, err := migrationService.MigrateUsersToFirebase()
	if err != nil {
		log.Printf("❌ 移行エラー: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "移行エラー",
			"message": err.Error(),
		})
		return
	}

	// 移行結果を検証
	if err := migrationService.VerifyMigration(); err != nil {
		log.Printf("⚠️ 移行検証で問題が見つかりました: %v", err)
		c.JSON(http.StatusOK, gin.H{
			"status":             "completed_with_warnings",
			"migration_result":   result,
			"verification_error": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":           "success",
		"migration_result": result,
	})
}

// GetMigrationStatus 移行状況を取得
func (h *FirebaseAuthHandler) GetMigrationStatus(c *gin.Context) {
	migrationService := migration.NewUserMigration(h.userService, h.firebaseService)
	
	status, err := migrationService.GetMigrationStatus()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "移行状況取得エラー",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   status,
	})
}

// GeneratePasswordResetLink パスワードリセットリンクを生成
func (h *FirebaseAuthHandler) GeneratePasswordResetLink(c *gin.Context) {
	var req struct {
		Email string `json:"email" binding:"required,email"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "入力エラー",
			"message": "有効なメールアドレスを入力してください",
		})
		return
	}

	link, err := h.firebaseService.GeneratePasswordResetLink(req.Email)
	if err != nil {
		log.Printf("パスワードリセットリンク生成エラー: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "リンク生成エラー",
			"message": "パスワードリセットリンクの生成に失敗しました",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data": gin.H{
			"reset_link": link,
		},
	})
}

// GenerateEmailVerificationLink メール確認リンクを生成
func (h *FirebaseAuthHandler) GenerateEmailVerificationLink(c *gin.Context) {
	var req struct {
		Email string `json:"email" binding:"required,email"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "入力エラー",
			"message": "有効なメールアドレスを入力してください",
		})
		return
	}

	link, err := h.firebaseService.GenerateEmailVerificationLink(req.Email)
	if err != nil {
		log.Printf("メール確認リンク生成エラー: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "リンク生成エラー",
			"message": "メール確認リンクの生成に失敗しました",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data": gin.H{
			"verification_link": link,
		},
	})
}

// RegisterRoutes Firebase認証関連のルートを登録
func (h *FirebaseAuthHandler) RegisterRoutes(router *gin.RouterGroup, firebaseMiddleware gin.HandlerFunc) {
	// Firebase認証が必要なルート
	protected := router.Group("/firebase-auth")
	protected.Use(firebaseMiddleware)
	{
		protected.GET("/profile", h.GetUserProfile)           // プロフィール取得
		protected.POST("/sync", h.SyncUserFromFirebase)       // Firebase→MongoDB同期
		protected.POST("/migration", h.RunMigration)          // 移行実行（管理者用）
		protected.GET("/migration/status", h.GetMigrationStatus) // 移行状況確認
	}

	// 認証不要のユーティリティルート
	utils := router.Group("/firebase-auth/utils")
	{
		utils.POST("/password-reset", h.GeneratePasswordResetLink)        // パスワードリセット
		utils.POST("/email-verification", h.GenerateEmailVerificationLink) // メール確認
	}
}