package handlers

import (
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"golang.org/x/crypto/argon2"
)

// User ユーザーデータモデル
// データベースに保存するユーザー情報を表現
type User struct {
	ID           string    `json:"id" db:"id"`
	Email        string    `json:"email" db:"email"`
	PasswordHash string    `json:"-" db:"password_hash"` // JSONには含めない（セキュリティ上重要）
	Salt         string    `json:"-" db:"salt"`
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
	UpdatedAt    time.Time `json:"updated_at" db:"updated_at"`
}

// RegisterRequest ユーザー登録リクエスト
type RegisterRequest struct {
	Email    string `json:"email" binding:"required,email"`       // 必須、メール形式
	Password string `json:"password" binding:"required,min=8"`    // 必須、8文字以上
}

// LoginRequest ログインリクエスト
type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

// AuthResponse 認証成功時のレスポンス
type AuthResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresIn    int64  `json:"expires_in"`    // アクセストークンの有効期限（秒）
	User         *User  `json:"user"`
}

// PasswordConfig Argon2パスワードハッシュ化設定
// プロダクション環境では適切な値に調整が必要
type PasswordConfig struct {
	Memory      uint32 // メモリ使用量（KB）
	Iterations  uint32 // 反復回数
	Parallelism uint8  // 並列数
	SaltLength  uint32 // ソルト長
	KeyLength   uint32 // ハッシュ長
}

// デフォルトのパスワード設定（セキュリティとパフォーマンスのバランス）
var defaultPasswordConfig = PasswordConfig{
	Memory:      64 * 1024, // 64MB
	Iterations:  3,         // 3回反復
	Parallelism: 2,         // 2並列
	SaltLength:  32,        // 32バイトソルト
	KeyLength:   32,        // 32バイトハッシュ
}

// generateSalt 暗号学的に安全なランダムソルトを生成
func generateSalt(length uint32) ([]byte, error) {
	salt := make([]byte, length)
	_, err := rand.Read(salt)
	if err != nil {
		return nil, fmt.Errorf("ソルト生成エラー: %w", err)
	}
	return salt, nil
}

// hashPassword Argon2を使用してパスワードをハッシュ化
// 戻り値: ハッシュ値, ソルト, エラー
func hashPassword(password string, config PasswordConfig) (string, string, error) {
	// ランダムソルト生成
	salt, err := generateSalt(config.SaltLength)
	if err != nil {
		return "", "", err
	}

	// Argon2でハッシュ化（IDバリアント使用 - 最もセキュア）
	hash := argon2.IDKey(
		[]byte(password),    // パスワード
		salt,                // ソルト
		config.Iterations,   // 反復回数
		config.Memory,       // メモリ使用量
		config.Parallelism,  // 並列数
		config.KeyLength,    // 出力ハッシュ長
	)

	// Base64エンコードで保存用文字列に変換
	hashB64 := base64.StdEncoding.EncodeToString(hash)
	saltB64 := base64.StdEncoding.EncodeToString(salt)

	return hashB64, saltB64, nil
}

// verifyPassword パスワードとハッシュの照合
func verifyPassword(password, storedHash, storedSalt string, config PasswordConfig) bool {
	// Base64デコード
	salt, err := base64.StdEncoding.DecodeString(storedSalt)
	if err != nil {
		return false
	}

	storedHashBytes, err := base64.StdEncoding.DecodeString(storedHash)
	if err != nil {
		return false
	}

	// 入力パスワードを同じ設定でハッシュ化
	hash := argon2.IDKey(
		[]byte(password),
		salt,
		config.Iterations,
		config.Memory,
		config.Parallelism,
		config.KeyLength,
	)

	// 定数時間での比較（タイミング攻撃対策）
	if len(hash) != len(storedHashBytes) {
		return false
	}

	var result byte
	for i := 0; i < len(hash); i++ {
		result |= hash[i] ^ storedHashBytes[i]
	}

	return result == 0
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
	jwtService *JWTService
	// TODO: UserService（データベース操作）を追加予定
}

// NewAuthHandler 認証ハンドラーのコンストラクタ
func NewAuthHandler() *AuthHandler {
	return &AuthHandler{
		jwtService: NewJWTService(),
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
	
	// 3. ユーザーの重複チェック（本来はデータベースで確認）
	// TODO: データベース実装時に追加
	// 現在は仮の処理として、特定のメールアドレスで重複エラーを発生
	if req.Email == "test@example.com" {
		c.JSON(http.StatusConflict, gin.H{
			"error": "このメールアドレスは既に登録されています",
		})
		return
	}
	
	// 4. パスワードハッシュ化
	hashedPassword, salt, err := hashPassword(req.Password, defaultPasswordConfig)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "パスワード処理中にエラーが発生しました",
		})
		return
	}
	
	// 5. ユーザーデータ作成
	userID := uuid.New().String()
	now := time.Now()
	
	user := &User{
		ID:           userID,
		Email:        req.Email,
		PasswordHash: hashedPassword,
		Salt:         salt,
		CreatedAt:    now,
		UpdatedAt:    now,
	}
	
	// 6. データベース保存（現在は未実装）
	// TODO: データベース実装時に追加
	// userService.CreateUser(user)
	
	// 7. JWTトークン生成
	tokenPair, err := h.jwtService.GenerateTokenPair(user.ID, user.Email)
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
	
	// 2. ユーザー情報をデータベースから取得（現在は仮実装）
	// TODO: データベース実装時に置き換え
	// 現在は特定のメール・パスワードでデモンストレーション
	var user *User
	if req.Email == "demo@example.com" && req.Password == "password123" {
		// デモ用のユーザーデータ
		userID := uuid.New().String()
		hashedPassword, salt, _ := hashPassword("password123", defaultPasswordConfig)
		
		user = &User{
			ID:           userID,
			Email:        req.Email,
			PasswordHash: hashedPassword,
			Salt:         salt,
			CreatedAt:    time.Now().Add(-24 * time.Hour), // 1日前に作成
			UpdatedAt:    time.Now(),
		}
	} else {
		// ユーザーが見つからない、またはパスワードが間違っている
		// セキュリティのため、具体的なエラー理由は明かさない
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "メールアドレスまたはパスワードが正しくありません",
		})
		return
	}
	
	// 3. パスワード検証（実際のデータベース実装時用のコード例）
	// 現在はデモのためスキップ（上記で既に検証済み）
	/*
	if !verifyPassword(req.Password, user.PasswordHash, user.Salt, defaultPasswordConfig) {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "メールアドレスまたはパスワードが正しくありません",
		})
		return
	}
	*/
	
	// 4. JWTトークン生成
	tokenPair, err := h.jwtService.GenerateTokenPair(user.ID, user.Email)
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
	
	// 6. ユーザー情報を取得してレスポンスに含める（現在は仮実装）
	// TODO: データベース実装時に実際のユーザー取得に置き換え
	user := &User{
		ID:        claims.UserID,
		Email:     claims.Email,
		CreatedAt: time.Now().Add(-24 * time.Hour), // 仮の作成日時
		UpdatedAt: time.Now(),
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