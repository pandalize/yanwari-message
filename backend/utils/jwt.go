package utils

import (
	"errors"
	"os"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// JWTカスタムクレーム
type CustomClaims struct {
	UserID string `json:"user_id"`
	Email  string `json:"email"`
	Name   string `json:"name"`
	jwt.RegisteredClaims
}

// JWT生成関数
func GenerateJWT(userID, email, name string) (string, error) {
	// JWT秘密鍵を環境変数から取得
	secretKey := os.Getenv("JWT_SECRET_KEY")
	if secretKey == "" {
		return "", errors.New("JWT_SECRET_KEY が設定されていません")
	}

	// トークンの有効期限（24時間）
	expirationTime := time.Now().Add(24 * time.Hour)

	// カスタムクレームの作成
	claims := &CustomClaims{
		UserID: userID,
		Email:  email,
		Name:   name,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expirationTime),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			Issuer:    "yanwari-message",
		},
	}

	// トークンの生成
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString([]byte(secretKey))
	if err != nil {
		return "", err
	}

	return tokenString, nil
}

// JWT検証関数
func ValidateJWT(tokenString string) (*CustomClaims, error) {
	// JWT秘密鍵を環境変数から取得
	secretKey := os.Getenv("JWT_SECRET_KEY")
	if secretKey == "" {
		return nil, errors.New("JWT_SECRET_KEY が設定されていません")
	}

	// トークンのパース
	token, err := jwt.ParseWithClaims(tokenString, &CustomClaims{}, func(token *jwt.Token) (interface{}, error) {
		// 署名方法の確認
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("無効な署名方法です")
		}
		return []byte(secretKey), nil
	})

	if err != nil {
		return nil, err
	}

	// クレームの取得
	if claims, ok := token.Claims.(*CustomClaims); ok && token.Valid {
		return claims, nil
	}

	return nil, errors.New("無効なトークンです")
}

// リフレッシュトークンの生成（有効期限: 30日）
func GenerateRefreshToken(userID string) (string, error) {
	secretKey := os.Getenv("JWT_REFRESH_SECRET_KEY")
	if secretKey == "" {
		secretKey = os.Getenv("JWT_SECRET_KEY") // フォールバック
		if secretKey == "" {
			return "", errors.New("JWT_REFRESH_SECRET_KEY が設定されていません")
		}
	}

	expirationTime := time.Now().Add(30 * 24 * time.Hour)

	claims := &jwt.RegisteredClaims{
		Subject:   userID,
		ExpiresAt: jwt.NewNumericDate(expirationTime),
		IssuedAt:  jwt.NewNumericDate(time.Now()),
		Issuer:    "yanwari-message-refresh",
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString([]byte(secretKey))
	if err != nil {
		return "", err
	}

	return tokenString, nil
}

// リフレッシュトークンの検証
func ValidateRefreshToken(tokenString string) (string, error) {
	secretKey := os.Getenv("JWT_REFRESH_SECRET_KEY")
	if secretKey == "" {
		secretKey = os.Getenv("JWT_SECRET_KEY") // フォールバック
		if secretKey == "" {
			return "", errors.New("JWT_REFRESH_SECRET_KEY が設定されていません")
		}
	}

	token, err := jwt.ParseWithClaims(tokenString, &jwt.RegisteredClaims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("無効な署名方法です")
		}
		return []byte(secretKey), nil
	})

	if err != nil {
		return "", err
	}

	if claims, ok := token.Claims.(*jwt.RegisteredClaims); ok && token.Valid {
		return claims.Subject, nil
	}

	return "", errors.New("無効なリフレッシュトークンです")
}