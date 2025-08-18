package handlers

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"

	"yanwari-message-backend/models"
)


// RegisterRequest ユーザー登録リクエスト
type RegisterRequest struct {
	Name     string `json:"name" binding:"required"`           // 必須、ユーザー名
	Email    string `json:"email" binding:"required,email"`    // 必須、メール形式
	Password string `json:"password" binding:"required"`       // 必須（長さは別途チェック）
}

// LoginRequest ログインリクエスト
type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

// AuthResponse 認証成功時のレスポンス
type AuthResponse struct {
	AccessToken  string       `json:"access_token"`
	RefreshToken string       `json:"refresh_token"`
	ExpiresIn    int64        `json:"expires_in"`    // アクセストークンの有効期限（秒）
	User         *models.User `json:"user"`
}

// hashPassword bcryptを使用してパスワードをハッシュ化
func hashPassword(password string) (string, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return "", fmt.Errorf("パスワードハッシュ化エラー: %w", err)
	}
	return string(hash), nil
}

// verifyPassword パスワードとbcryptハッシュの照合
func verifyPassword(password, storedHash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(storedHash), []byte(password))
	return err == nil
}

// JWTClaims JWT用のカスタムクレーム
type JWTClaims struct {
	UserID string `json:"user_id"`
	Email  string `json:"email"`
	jwt.RegisteredClaims
}

// TokenPair アクセストークンとリフレッシュトークンのペア
type TokenPair struct {
	AccessToken  string
	RefreshToken string
	ExpiresIn    int64
}

// JWTService JWT関連の処理を担当
type JWTService struct {
	secretKey []byte
}

// NewJWTService JWTサービスのコンストラクタ
func NewJWTService() *JWTService {
	// 環境変数からJWT秘密鍵を取得（本番環境では必須）
	secretKey := os.Getenv("JWT_SECRET_KEY")
	if secretKey == "" {
		// 開発環境用のデフォルトキー（本番では絶対に使用しない）
		secretKey = "your-super-secret-jwt-key-change-this-in-production"
	}
	
	return &JWTService{
		secretKey: []byte(secretKey),
	}
}

// GenerateTokenPair アクセストークンとリフレッシュトークンを生成
func (j *JWTService) GenerateTokenPair(userID, email string) (*TokenPair, error) {
	now := time.Now()
	
	// アクセストークン（15分）
	accessClaims := JWTClaims{
		UserID: userID,
		Email:  email,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(now.Add(15 * time.Minute)),
			IssuedAt:  jwt.NewNumericDate(now),
			NotBefore: jwt.NewNumericDate(now),
			ID:        uuid.New().String(),
			Subject:   userID,
		},
	}
	
	accessToken, err := jwt.NewWithClaims(jwt.SigningMethodHS256, accessClaims).SignedString(j.secretKey)
	if err != nil {
		return nil, fmt.Errorf("アクセストークン生成エラー: %w", err)
	}
	
	// リフレッシュトークン（14日）
	refreshClaims := JWTClaims{
		UserID: userID,
		Email:  email,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(now.Add(14 * 24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(now),
			NotBefore: jwt.NewNumericDate(now),
			ID:        uuid.New().String(),
			Subject:   userID,
		},
	}
	
	refreshToken, err := jwt.NewWithClaims(jwt.SigningMethodHS256, refreshClaims).SignedString(j.secretKey)
	if err != nil {
		return nil, fmt.Errorf("リフレッシュトークン生成エラー: %w", err)
	}
	
	return &TokenPair{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		ExpiresIn:    15 * 60, // 15分（秒）
	}, nil
}

// ValidateToken JWTトークンを検証してクレームを取得
func (j *JWTService) ValidateToken(tokenString string) (*JWTClaims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &JWTClaims{}, func(token *jwt.Token) (interface{}, error) {
		// 署名方法の検証
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("予期しない署名方法: %v", token.Header["alg"])
		}
		return j.secretKey, nil
	})
	
	if err != nil {
		return nil, fmt.Errorf("トークン解析エラー: %w", err)
	}
	
	if claims, ok := token.Claims.(*JWTClaims); ok && token.Valid {
		return claims, nil
	}
	
	return nil, fmt.Errorf("無効なトークンまたはクレーム")
}

// AuthHandler 認証関連のハンドラー
type AuthHandler struct {
	jwtService  *JWTService
	userService *models.UserService
}

// NewAuthHandler 認証ハンドラーのコンストラクタ
func NewAuthHandler(userService *models.UserService) *AuthHandler {
	return &AuthHandler{
		jwtService:  NewJWTService(),
		userService: userService,
	}
}

// Register ユーザー登録
// POST /api/v1/auth/register
func (h *AuthHandler) Register(c *gin.Context) {
	var req RegisterRequest
	
	// 1. リクエストボディのバインド＆バリデーション
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "リクエストが無効です",
			"details": err.Error(),
		})
		return
	}
	
	// 2. 追加バリデーション（パスワード強度チェック）
	if len(req.Password) < 8 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "パスワードは8文字以上である必要があります",
		})
		return
	}
	
	// 3. ユーザーの重複チェック（データベースで確認）
	ctx := context.Background()
	exists, err := h.userService.EmailExists(ctx, req.Email)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "重複チェック中にエラーが発生しました",
		})
		return
	}
	
	if exists {
		c.JSON(http.StatusConflict, gin.H{
			"error": "このメールアドレスは既に登録されています",
		})
		return
	}
	
	// 4. パスワードハッシュ化
	hashedPassword, err := hashPassword(req.Password)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "パスワード処理中にエラーが発生しました",
		})
		return
	}
	
	// 5. ユーザーデータ作成
	user := &models.User{
		Name:         req.Name,
		Email:        req.Email,
		PasswordHash: hashedPassword,
	}
	
	// 6. データベース保存
	if err := h.userService.CreateUser(ctx, user); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "ユーザー作成中にエラーが発生しました",
		})
		return
	}
	
	// 7. JWTトークン生成
	tokenPair, err := h.jwtService.GenerateTokenPair(user.ID.Hex(), user.Email)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "認証トークン生成中にエラーが発生しました",
		})
		return
	}
	
	// 8. レスポンス返却（パスワード情報は除外）
	response := AuthResponse{
		AccessToken:  tokenPair.AccessToken,
		RefreshToken: tokenPair.RefreshToken,
		ExpiresIn:    tokenPair.ExpiresIn,
		User:         user,
	}
	
	c.JSON(http.StatusCreated, gin.H{
		"message": "ユーザー登録が完了しました",
		"data":    response,
	})
}

// Login ユーザーログイン
// POST /api/v1/auth/login
func (h *AuthHandler) Login(c *gin.Context) {
	var req LoginRequest
	
	// 1. リクエストボディのバインド＆バリデーション
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "リクエストが無効です",
			"details": err.Error(),
		})
		return
	}
	
	// 2. データベースからユーザー情報を取得
	ctx := context.Background()
	fmt.Printf("🔍 [Login] ユーザー検索: %s\n", req.Email)
	user, err := h.userService.GetUserByEmail(ctx, req.Email)
	if err != nil {
		// ユーザーが見つからない場合も、セキュリティのため詳細なエラーは返さない
		fmt.Printf("❌ [Login] ユーザー取得エラー: %v\n", err)
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "メールアドレスまたはパスワードが正しくありません",
		})
		return
	}
	fmt.Printf("✅ [Login] ユーザー取得成功: %s (Hash: %s)\n", user.Email, user.PasswordHash[:20]+"...")
	
	// 3. パスワード検証
	fmt.Printf("🔍 [Login] パスワード検証中...\n")
	if !verifyPassword(req.Password, user.PasswordHash) {
		fmt.Printf("❌ [Login] パスワード検証失敗\n")
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "メールアドレスまたはパスワードが正しくありません",
		})
		return
	}
	fmt.Printf("✅ [Login] パスワード検証成功\n")
	
	// 4. JWTトークン生成
	tokenPair, err := h.jwtService.GenerateTokenPair(user.ID.Hex(), user.Email)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "認証トークン生成中にエラーが発生しました",
		})
		return
	}
	
	// 5. レスポンス返却
	response := AuthResponse{
		AccessToken:  tokenPair.AccessToken,
		RefreshToken: tokenPair.RefreshToken,
		ExpiresIn:    tokenPair.ExpiresIn,
		User:         user,
	}
	
	c.JSON(http.StatusOK, gin.H{
		"message": "ログインに成功しました",
		"data":    response,
	})
}

// RefreshTokenRequest リフレッシュトークンリクエスト
type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

// RefreshToken リフレッシュトークン
// POST /api/v1/auth/refresh
func (h *AuthHandler) RefreshToken(c *gin.Context) {
	var req RefreshTokenRequest
	
	// 1. リクエストボディのバインド＆バリデーション
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "リクエストが無効です",
			"details": err.Error(),
		})
		return
	}
	
	// 2. リフレッシュトークンの検証
	claims, err := h.jwtService.ValidateToken(req.RefreshToken)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "無効なリフレッシュトークンです",
		})
		return
	}
	
	// 3. トークンの有効期限チェック
	if time.Now().After(claims.ExpiresAt.Time) {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "リフレッシュトークンの有効期限が切れています",
		})
		return
	}
	
	// 4. ユーザー情報の存在確認（現在は仮実装）
	// TODO: データベース実装時に実際のユーザー検索に置き換え
	if claims.UserID == "" || claims.Email == "" {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "無効なユーザー情報です",
		})
		return
	}
	
	// 5. 新しいトークンペアを生成
	newTokenPair, err := h.jwtService.GenerateTokenPair(claims.UserID, claims.Email)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "新しいトークンの生成中にエラーが発生しました",
		})
		return
	}
	
	// 6. ユーザー情報をデータベースから取得
	ctx := context.Background()
	user, err := h.userService.GetUserByID(ctx, claims.UserID)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "ユーザー情報の取得に失敗しました",
		})
		return
	}
	
	// 7. レスポンス返却
	response := AuthResponse{
		AccessToken:  newTokenPair.AccessToken,
		RefreshToken: newTokenPair.RefreshToken,
		ExpiresIn:    newTokenPair.ExpiresIn,
		User:         user,
	}
	
	c.JSON(http.StatusOK, gin.H{
		"message": "トークンのリフレッシュが完了しました",
		"data":    response,
	})
}

// Logout ユーザーログアウト
// POST /api/v1/auth/logout
func (h *AuthHandler) Logout(c *gin.Context) {
	// 1. Authorizationヘッダーからトークンを取得
	authHeader := c.GetHeader("Authorization")
	if authHeader == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "認証ヘッダーが必要です",
		})
		return
	}
	
	// 2. "Bearer "プレフィックスを除去
	const bearerPrefix = "Bearer "
	if len(authHeader) < len(bearerPrefix) || authHeader[:len(bearerPrefix)] != bearerPrefix {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "無効な認証ヘッダー形式です",
		})
		return
	}
	
	token := authHeader[len(bearerPrefix):]
	
	// 3. トークンの検証
	claims, err := h.jwtService.ValidateToken(token)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "無効なトークンです",
		})
		return
	}
	
	// 4. トークンの無効化（ブラックリスト機能）
	// 注意: 本格的な実装では、RedisやDBにトークンIDを保存してブラックリスト管理を行う
	// TODO: データベース実装時に追加
	// - トークンJTI（JWT ID）をブラックリストテーブルに追加
	// - 有効期限付きでブラックリストを管理
	// blacklistService.AddToBlacklist(claims.ID, claims.ExpiresAt.Time)
	
	// 5. ログアウト成功のレスポンス
	c.JSON(http.StatusOK, gin.H{
		"message": "ログアウトが完了しました",
		"data": gin.H{
			"user_id":    claims.UserID,
			"logged_out": true,
		},
	})
}

// JWTMiddleware JWT認証ミドルウェア
func JWTMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 既に認証済みかチェック（重複実行を防ぐ）
		if userID, exists := c.Get("userID"); exists && userID != nil {
			c.Next()
			return
		}
		
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "認証ヘッダーが必要です"})
			c.Abort()
			return
		}

		// Bearer トークンの形式をチェック
		const bearerPrefix = "Bearer "
		if len(authHeader) < len(bearerPrefix) || authHeader[:len(bearerPrefix)] != bearerPrefix {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "無効な認証形式です"})
			c.Abort()
			return
		}

		tokenString := authHeader[len(bearerPrefix):]
		
		// JWTサービスを初期化
		jwtService := NewJWTService()
		
		// トークンを検証
		claims, err := jwtService.ValidateToken(tokenString)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "無効なトークンです"})
			c.Abort()
			return
		}

		// ユーザーIDをコンテキストに設定（文字列として保存）
		c.Set("userID", claims.UserID)
		c.Set("email", claims.Email)
		c.Next()
	}
}