package main

import (
	"fmt"
	"golang.org/x/crypto/bcrypt"
)

func main() {
	password := "password123"
	
	// 新しいハッシュを生成
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		fmt.Printf("Error generating hash: %v\n", err)
		return
	}
	
	fmt.Printf("New hash for 'password123': %s\n", string(hash))
	
	// 既存のハッシュとの比較
	existingHash := "$2a$10$LQv3c1yqBwEHxkVz0HQGEOuPiTDc.HGOEOqP7qYLZZ4WYAFRn7kBS"
	err1 := bcrypt.CompareHashAndPassword([]byte(existingHash), []byte(password))
	fmt.Printf("Existing hash validation: %v\n", err1 == nil)
	
	// 新しいハッシュとの比較
	err2 := bcrypt.CompareHashAndPassword(hash, []byte(password))
	fmt.Printf("New hash validation: %v\n", err2 == nil)
}