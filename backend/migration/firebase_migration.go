package migration

import (
	"context"
	"fmt"
	"log"
	"time"

	"yanwari-message-backend/models"
	"yanwari-message-backend/services"
)

// UserMigration ユーザーデータのFirebase移行を管理
type UserMigration struct {
	userService     *models.UserService
	firebaseService *services.FirebaseService
	ctx             context.Context
}

// NewUserMigration UserMigrationのコンストラクタ
func NewUserMigration(userService *models.UserService, firebaseService *services.FirebaseService) *UserMigration {
	return &UserMigration{
		userService:     userService,
		firebaseService: firebaseService,
		ctx:             context.Background(),
	}
}

// MigrationResult 移行結果を表すデータ構造
type MigrationResult struct {
	TotalUsers    int      `json:"total_users"`
	SuccessCount  int      `json:"success_count"`
	ErrorCount    int      `json:"error_count"`
	SkippedCount  int      `json:"skipped_count"`
	ErrorEmails   []string `json:"error_emails"`
	SkippedEmails []string `json:"skipped_emails"`
	Duration      string   `json:"duration"`
}

// MigrateUsersToFirebase 既存のMongoDBユーザーをFirebaseに移行
func (um *UserMigration) MigrateUsersToFirebase() (*MigrationResult, error) {
	startTime := time.Now()
	log.Println("🚀 Firebase移行を開始します...")

	// 1. MongoDB から全ユーザー取得
	users, err := um.userService.GetAllUsers(um.ctx)
	if err != nil {
		return nil, fmt.Errorf("ユーザー一覧取得エラー: %w", err)
	}

	result := &MigrationResult{
		TotalUsers:    len(users),
		ErrorEmails:   []string{},
		SkippedEmails: []string{},
	}

	log.Printf("📊 移行対象ユーザー数: %d", result.TotalUsers)

	// 2. 各ユーザーをFirebaseに移行
	for i, user := range users {
		log.Printf("📤 [%d/%d] ユーザー移行中: %s", i+1, result.TotalUsers, user.Email)

		// 既にFirebase UIDがある場合はスキップ
		if user.FirebaseUID != "" {
			log.Printf("⏭️  既にFirebase UIDが設定済み: %s (UID: %s)", user.Email, user.FirebaseUID)
			result.SkippedCount++
			result.SkippedEmails = append(result.SkippedEmails, user.Email)
			continue
		}

		// Firebase認証でユーザーを作成
		firebaseUser, err := um.firebaseService.CreateUserWithEmailOnly(user.Email)
		if err != nil {
			log.Printf("❌ Firebase移行失敗 - Email: %s, Error: %v", user.Email, err)
			result.ErrorCount++
			result.ErrorEmails = append(result.ErrorEmails, user.Email)
			continue
		}

		// MongoDB に Firebase UID を記録
		err = um.userService.UpdateFirebaseUID(um.ctx, user.ID, firebaseUser.UID)
		if err != nil {
			log.Printf("❌ MongoDB更新失敗 - Email: %s, Firebase UID: %s, Error: %v", 
				user.Email, firebaseUser.UID, err)
			
			// Firebase上で作成したユーザーを削除（ロールバック）
			if deleteErr := um.firebaseService.DeleteUser(firebaseUser.UID); deleteErr != nil {
				log.Printf("⚠️  Firebase ユーザー削除失敗 (ロールバック) - UID: %s, Error: %v", 
					firebaseUser.UID, deleteErr)
			}
			
			result.ErrorCount++
			result.ErrorEmails = append(result.ErrorEmails, user.Email)
			continue
		}

		// 移行成功
		log.Printf("✅ 移行成功 - Email: %s, Firebase UID: %s", user.Email, firebaseUser.UID)
		result.SuccessCount++

		// API制限を避けるため少し待機
		if i > 0 && i%10 == 0 {
			log.Printf("⏰ API制限対策のため1秒待機中...")
			time.Sleep(1 * time.Second)
		}
	}

	// 3. 結果をまとめ
	result.Duration = time.Since(startTime).String()
	
	log.Println("🎉 Firebase移行完了!")
	log.Printf("📈 結果サマリー:")
	log.Printf("   - 総ユーザー数: %d", result.TotalUsers)
	log.Printf("   - 成功: %d", result.SuccessCount)
	log.Printf("   - エラー: %d", result.ErrorCount)
	log.Printf("   - スキップ: %d", result.SkippedCount)
	log.Printf("   - 所要時間: %s", result.Duration)

	if result.ErrorCount > 0 {
		log.Printf("❌ エラーが発生したユーザー: %v", result.ErrorEmails)
	}

	if result.SkippedCount > 0 {
		log.Printf("⏭️  スキップしたユーザー: %v", result.SkippedEmails)
	}

	return result, nil
}

// VerifyMigration 移行結果を検証
func (um *UserMigration) VerifyMigration() error {
	log.Println("🔍 移行結果の検証を開始...")

	// MongoDB から全ユーザー取得
	users, err := um.userService.GetAllUsers(um.ctx)
	if err != nil {
		return fmt.Errorf("検証用ユーザー取得エラー: %w", err)
	}

	var successCount, errorCount int
	var errorUsers []string

	for _, user := range users {
		if user.FirebaseUID == "" {
			log.Printf("❌ Firebase UIDが未設定: %s", user.Email)
			errorCount++
			errorUsers = append(errorUsers, user.Email)
			continue
		}

		// Firebase側でユーザーが存在するか確認
		_, err := um.firebaseService.GetUserByUID(user.FirebaseUID)
		if err != nil {
			log.Printf("❌ Firebase上にユーザーが存在しません - Email: %s, UID: %s, Error: %v", 
				user.Email, user.FirebaseUID, err)
			errorCount++
			errorUsers = append(errorUsers, user.Email)
			continue
		}

		successCount++
	}

	log.Printf("✅ 検証結果:")
	log.Printf("   - 成功: %d / %d", successCount, len(users))
	log.Printf("   - エラー: %d", errorCount)

	if errorCount > 0 {
		log.Printf("❌ 問題があるユーザー: %v", errorUsers)
		return fmt.Errorf("移行検証で %d 件のエラーが見つかりました", errorCount)
	}

	log.Println("🎉 移行検証に成功しました!")
	return nil
}

// CreateFirebaseIndexes Firebase UIDのインデックスを作成
func (um *UserMigration) CreateFirebaseIndexes() error {
	log.Println("📋 Firebase UID インデックスを作成中...")
	
	err := um.userService.CreateFirebaseUIDIndex(um.ctx)
	if err != nil {
		return fmt.Errorf("Firebase UIDインデックス作成エラー: %w", err)
	}
	
	log.Println("✅ Firebase UID インデックス作成完了")
	return nil
}

// GetMigrationStatus 移行状況を取得
func (um *UserMigration) GetMigrationStatus() (*MigrationResult, error) {
	users, err := um.userService.GetAllUsers(um.ctx)
	if err != nil {
		return nil, fmt.Errorf("移行状況取得エラー: %w", err)
	}

	result := &MigrationResult{
		TotalUsers:    len(users),
		ErrorEmails:   []string{},
		SkippedEmails: []string{},
	}

	for _, user := range users {
		if user.FirebaseUID != "" {
			result.SuccessCount++
		} else {
			result.ErrorCount++
			result.ErrorEmails = append(result.ErrorEmails, user.Email)
		}
	}

	return result, nil
}