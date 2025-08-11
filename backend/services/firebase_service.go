package services

import (
	"context"
	"fmt"
	"os"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
	"google.golang.org/api/option"
)

// FirebaseService Firebase Admin SDKを使用した認証サービス
type FirebaseService struct {
	Auth *auth.Client
	ctx  context.Context
}

// NewFirebaseService Firebaseサービスを作成
func NewFirebaseService() (*FirebaseService, error) {
	ctx := context.Background()
	
	// Firebase Emulatorの確認
	emulatorHost := os.Getenv("FIREBASE_AUTH_EMULATOR_HOST")
	isEmulator := emulatorHost != ""
	
	if isEmulator {
		// Firebase Emulator用の初期化
		projectID := os.Getenv("FIREBASE_PROJECT_ID")
		if projectID == "" {
			projectID = "yanwari-message" // デフォルトプロジェクトID
		}
		
		config := &firebase.Config{
			ProjectID: projectID,
		}
		
		// Emulator環境設定を確実に設定
		os.Setenv("FIREBASE_AUTH_EMULATOR_HOST", emulatorHost)
		
		app, err := firebase.NewApp(ctx, config)
		if err != nil {
			return nil, fmt.Errorf("Firebase Emulatorアプリの初期化に失敗しました: %v", err)
		}
		
		authClient, err := app.Auth(ctx)
		if err != nil {
			return nil, fmt.Errorf("Firebase Emulator認証クライアントの初期化に失敗しました: %v", err)
		}
		
		fmt.Printf("✅ Firebase Emulator接続成功 (%s)\n", emulatorHost)
		return &FirebaseService{
			Auth: authClient,
			ctx:  ctx,
		}, nil
	}
	
	// Firebase Admin SDKの認証情報を環境変数から取得
	privateKeyPath := os.Getenv("FIREBASE_PRIVATE_KEY_PATH")
	if privateKeyPath == "" {
		privateKeyPath = "./config/firebase-admin-key.json"
	}
	
	// ファイルが存在しない場合は環境変数での初期化を試行
	if _, err := os.Stat(privateKeyPath); os.IsNotExist(err) {
		// プロジェクトIDのみで初期化（開発・テスト環境用）
		projectID := os.Getenv("FIREBASE_PROJECT_ID")
		if projectID == "" {
			return nil, fmt.Errorf("Firebase設定が見つかりません。FIREBASE_PROJECT_IDまたはFIREBASE_PRIVATE_KEY_PATHを設定してください")
		}
		
		config := &firebase.Config{
			ProjectID: projectID,
		}
		
		app, err := firebase.NewApp(ctx, config)
		if err != nil {
			return nil, fmt.Errorf("Firebaseアプリの初期化に失敗しました: %v", err)
		}
		
		authClient, err := app.Auth(ctx)
		if err != nil {
			return nil, fmt.Errorf("Firebase認証クライアントの初期化に失敗しました: %v", err)
		}
		
		return &FirebaseService{
			Auth: authClient,
			ctx:  ctx,
		}, nil
	}
	
	// JSON認証ファイルを使用した初期化
	opt := option.WithCredentialsFile(privateKeyPath)
	app, err := firebase.NewApp(ctx, nil, opt)
	if err != nil {
		return nil, fmt.Errorf("Firebaseアプリの初期化に失敗しました: %v", err)
	}
	
	authClient, err := app.Auth(ctx)
	if err != nil {
		return nil, fmt.Errorf("Firebase認証クライアントの初期化に失敗しました: %v", err)
	}
	
	return &FirebaseService{
		Auth: authClient,
		ctx:  ctx,
	}, nil
}

// VerifyIDToken Firebase ID Tokenを検証
func (fs *FirebaseService) VerifyIDToken(idToken string) (*auth.Token, error) {
	if idToken == "" {
		return nil, fmt.Errorf("IDトークンが空です")
	}
	
	token, err := fs.Auth.VerifyIDToken(fs.ctx, idToken)
	if err != nil {
		return nil, fmt.Errorf("IDトークンの検証に失敗しました: %v", err)
	}
	
	return token, nil
}

// GetUserByUID Firebase UIDでユーザー情報を取得
func (fs *FirebaseService) GetUserByUID(uid string) (*auth.UserRecord, error) {
	if uid == "" {
		return nil, fmt.Errorf("UIDが空です")
	}
	
	user, err := fs.Auth.GetUser(fs.ctx, uid)
	if err != nil {
		return nil, fmt.Errorf("ユーザー情報の取得に失敗しました: %v", err)
	}
	
	return user, nil
}

// CreateUser Firebase認証でユーザーを作成
func (fs *FirebaseService) CreateUser(email string, password string) (*auth.UserRecord, error) {
	if email == "" || password == "" {
		return nil, fmt.Errorf("メールアドレスとパスワードが必要です")
	}
	
	params := (&auth.UserToCreate{}).
		Email(email).
		Password(password).
		EmailVerified(false)
	
	user, err := fs.Auth.CreateUser(fs.ctx, params)
	if err != nil {
		return nil, fmt.Errorf("ユーザーの作成に失敗しました: %v", err)
	}
	
	return user, nil
}

// CreateUserWithEmailOnly Firebase認証でメールアドレスのみでユーザーを作成（移行用）
func (fs *FirebaseService) CreateUserWithEmailOnly(email string) (*auth.UserRecord, error) {
	if email == "" {
		return nil, fmt.Errorf("メールアドレスが必要です")
	}
	
	params := (&auth.UserToCreate{}).
		Email(email).
		EmailVerified(true) // 既存ユーザーは検証済みとして扱う
	
	user, err := fs.Auth.CreateUser(fs.ctx, params)
	if err != nil {
		return nil, fmt.Errorf("移行用ユーザーの作成に失敗しました: %v", err)
	}
	
	return user, nil
}

// UpdateUser Firebase認証でユーザー情報を更新
func (fs *FirebaseService) UpdateUser(uid string, updates *auth.UserToUpdate) (*auth.UserRecord, error) {
	if uid == "" {
		return nil, fmt.Errorf("UIDが必要です")
	}
	
	user, err := fs.Auth.UpdateUser(fs.ctx, uid, updates)
	if err != nil {
		return nil, fmt.Errorf("ユーザー情報の更新に失敗しました: %v", err)
	}
	
	return user, nil
}

// DeleteUser Firebase認証でユーザーを削除
func (fs *FirebaseService) DeleteUser(uid string) error {
	if uid == "" {
		return fmt.Errorf("UIDが必要です")
	}
	
	err := fs.Auth.DeleteUser(fs.ctx, uid)
	if err != nil {
		return fmt.Errorf("ユーザーの削除に失敗しました: %v", err)
	}
	
	return nil
}

// GeneratePasswordResetLink パスワードリセットリンクを生成
func (fs *FirebaseService) GeneratePasswordResetLink(email string) (string, error) {
	if email == "" {
		return "", fmt.Errorf("メールアドレスが必要です")
	}
	
	link, err := fs.Auth.PasswordResetLink(fs.ctx, email)
	if err != nil {
		return "", fmt.Errorf("パスワードリセットリンクの生成に失敗しました: %v", err)
	}
	
	return link, nil
}

// GenerateEmailVerificationLink メール確認リンクを生成
func (fs *FirebaseService) GenerateEmailVerificationLink(email string) (string, error) {
	if email == "" {
		return "", fmt.Errorf("メールアドレスが必要です")
	}
	
	link, err := fs.Auth.EmailVerificationLink(fs.ctx, email)
	if err != nil {
		return "", fmt.Errorf("メール確認リンクの生成に失敗しました: %v", err)
	}
	
	return link, nil
}

// SetCustomClaims ユーザーにカスタムクレームを設定
func (fs *FirebaseService) SetCustomClaims(uid string, claims map[string]interface{}) error {
	if uid == "" {
		return fmt.Errorf("UIDが必要です")
	}
	
	err := fs.Auth.SetCustomUserClaims(fs.ctx, uid, claims)
	if err != nil {
		return fmt.Errorf("カスタムクレームの設定に失敗しました: %v", err)
	}
	
	return nil
}