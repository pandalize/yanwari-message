package handlers

import (
	"net/http"
	"yanwari-message-backend/database"
	"yanwari-message-backend/models"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// SendFriendRequestInput は友達申請送信のリクエストボディ
type SendFriendRequestInput struct {
	ToUserEmail string `json:"to_user_email" binding:"required,email"`
	Message     string `json:"message"`
}

// SendFriendRequest は友達申請を送信するハンドラー
func SendFriendRequest(c *gin.Context) {
	// JWTからユーザーIDを取得
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "認証が必要です",
		})
		return
	}
	
	fromUserID, err := primitive.ObjectIDFromHex(userID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "無効なユーザーIDです",
		})
		return
	}
	
	// リクエストボディを解析
	var input SendFriendRequestInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "無効なリクエストです",
		})
		return
	}
	
	// データベース接続を取得
	db := database.GetDB()
	userService := models.NewUserService(db)
	friendRequestService := models.NewFriendRequestService(db)
	
	// 送信先ユーザーを取得
	toUser, err := userService.GetUserByEmail(c.Request.Context(), input.ToUserEmail)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error": "ユーザーが見つかりません",
		})
		return
	}
	
	// 友達申請を作成
	request, err := friendRequestService.Create(c.Request.Context(), fromUserID, toUser.ID, input.Message)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": err.Error(),
		})
		return
	}
	
	c.JSON(http.StatusCreated, gin.H{
		"message": "友達申請を送信しました",
		"data":    request,
	})
}

// GetReceivedFriendRequests は受信した友達申請一覧を取得するハンドラー
func GetReceivedFriendRequests(c *gin.Context) {
	// JWTからユーザーIDを取得
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "認証が必要です",
		})
		return
	}
	
	userObjectID, err := primitive.ObjectIDFromHex(userID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "無効なユーザーIDです",
		})
		return
	}
	
	// データベース接続を取得
	db := database.GetDB()
	friendRequestService := models.NewFriendRequestService(db)
	
	// 受信した友達申請を取得
	requests, err := friendRequestService.GetReceivedRequests(c.Request.Context(), userObjectID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "友達申請の取得に失敗しました",
		})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"data": requests,
	})
}

// GetSentFriendRequests は送信した友達申請一覧を取得するハンドラー
func GetSentFriendRequests(c *gin.Context) {
	// JWTからユーザーIDを取得
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "認証が必要です",
		})
		return
	}
	
	userObjectID, err := primitive.ObjectIDFromHex(userID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "無効なユーザーIDです",
		})
		return
	}
	
	// データベース接続を取得
	db := database.GetDB()
	friendRequestService := models.NewFriendRequestService(db)
	
	// 送信した友達申請を取得
	requests, err := friendRequestService.GetSentRequests(c.Request.Context(), userObjectID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "友達申請の取得に失敗しました",
		})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"data": requests,
	})
}

// AcceptFriendRequest は友達申請を承諾するハンドラー
func AcceptFriendRequest(c *gin.Context) {
	// JWTからユーザーIDを取得
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "認証が必要です",
		})
		return
	}
	
	userObjectID, err := primitive.ObjectIDFromHex(userID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "無効なユーザーIDです",
		})
		return
	}
	
	// リクエストIDを取得
	requestID, err := primitive.ObjectIDFromHex(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "無効な申請IDです",
		})
		return
	}
	
	// データベース接続を取得
	db := database.GetDB()
	friendRequestService := models.NewFriendRequestService(db)
	
	// 友達申請を承諾
	err = friendRequestService.Accept(c.Request.Context(), requestID, userObjectID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": err.Error(),
		})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"message": "友達申請を承諾しました",
	})
}

// RejectFriendRequest は友達申請を拒否するハンドラー
func RejectFriendRequest(c *gin.Context) {
	// JWTからユーザーIDを取得
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "認証が必要です",
		})
		return
	}
	
	userObjectID, err := primitive.ObjectIDFromHex(userID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "無効なユーザーIDです",
		})
		return
	}
	
	// リクエストIDを取得
	requestID, err := primitive.ObjectIDFromHex(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "無効な申請IDです",
		})
		return
	}
	
	// データベース接続を取得
	db := database.GetDB()
	friendRequestService := models.NewFriendRequestService(db)
	
	// 友達申請を拒否
	err = friendRequestService.Reject(c.Request.Context(), requestID, userObjectID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": err.Error(),
		})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"message": "友達申請を拒否しました",
	})
}

// CancelFriendRequest は送信した友達申請をキャンセルするハンドラー
func CancelFriendRequest(c *gin.Context) {
	// JWTからユーザーIDを取得
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "認証が必要です",
		})
		return
	}
	
	userObjectID, err := primitive.ObjectIDFromHex(userID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "無効なユーザーIDです",
		})
		return
	}
	
	// リクエストIDを取得
	requestID, err := primitive.ObjectIDFromHex(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "無効な申請IDです",
		})
		return
	}
	
	// データベース接続を取得
	db := database.GetDB()
	friendRequestService := models.NewFriendRequestService(db)
	
	// 友達申請をキャンセル
	err = friendRequestService.Cancel(c.Request.Context(), requestID, userObjectID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": err.Error(),
		})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"message": "友達申請をキャンセルしました",
	})
}

// GetFriends はユーザーの友達一覧を取得するハンドラー
func GetFriends(c *gin.Context) {
	// JWTからユーザーIDを取得
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "認証が必要です",
		})
		return
	}
	
	userObjectID, err := primitive.ObjectIDFromHex(userID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "無効なユーザーIDです",
		})
		return
	}
	
	// データベース接続を取得
	db := database.GetDB()
	friendshipService := models.NewFriendshipService(db)
	
	// 友達一覧を取得
	friends, err := friendshipService.GetFriends(c.Request.Context(), userObjectID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "友達一覧の取得に失敗しました",
		})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"data": friends,
	})
}

// RemoveFriendInput は友達削除のリクエストボディ
type RemoveFriendInput struct {
	FriendEmail string `json:"friend_email" binding:"required,email"`
}

// RemoveFriend は友達を削除するハンドラー
func RemoveFriend(c *gin.Context) {
	// JWTからユーザーIDを取得
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "認証が必要です",
		})
		return
	}
	
	userObjectID, err := primitive.ObjectIDFromHex(userID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "無効なユーザーIDです",
		})
		return
	}
	
	// リクエストボディを解析
	var input RemoveFriendInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "無効なリクエストです",
		})
		return
	}
	
	// データベース接続を取得
	db := database.GetDB()
	userService := models.NewUserService(db)
	friendshipService := models.NewFriendshipService(db)
	
	// 友達ユーザーを取得
	friendUser, err := userService.GetByEmail(c.Request.Context(), input.FriendEmail)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error": "ユーザーが見つかりません",
		})
		return
	}
	
	// 友達関係を削除
	err = friendshipService.Delete(c.Request.Context(), userObjectID, friendUser.ID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": err.Error(),
		})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"message": "友達を削除しました",
	})
}