package handlers

import (
	"log"
	"net/http"
	"yanwari-message-backend/models"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// FriendRequestHandler は友達申請関連のハンドラー構造体
type FriendRequestHandler struct {
	userService          *models.UserService
	friendRequestService *models.FriendRequestService
	friendshipService    *models.FriendshipService
}

// NewFriendRequestHandler は新しい友達申請ハンドラーを作成
func NewFriendRequestHandler(userService *models.UserService, friendRequestService *models.FriendRequestService, friendshipService *models.FriendshipService) *FriendRequestHandler {
	return &FriendRequestHandler{
		userService:          userService,
		friendRequestService: friendRequestService,
		friendshipService:    friendshipService,
	}
}

// SendFriendRequestInput は友達申請送信のリクエストボディ
type SendFriendRequestInput struct {
	ToEmail string `json:"to_email" binding:"required,email"`
	Message string `json:"message"`
}

// SendFriendRequest は友達申請を送信するハンドラー
func (h *FriendRequestHandler) SendFriendRequest(c *gin.Context) {
	// Firebase認証からユーザー情報を取得
	firebaseUser, exists := c.Get("firebase_uid")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "認証が必要です",
		})
		return
	}
	
	// Firebase UIDからMongoDBユーザーを取得（自動同期対応）
	firebaseUID := firebaseUser.(string)
	user, err := h.userService.GetUserByFirebaseUID(c.Request.Context(), firebaseUID)
	if err != nil {
		// ユーザーが見つからない場合は自動同期を試行
		log.Printf("🔄 友達申請ハンドラー: ユーザー自動同期を開始 Firebase UID: %s", firebaseUID)
		// Firebase認証ハンドラーを使って自動同期（共通処理を再利用）
		// 注意: 直接的な依存を避けるため、ここではエラーレスポンスのみ返す
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "Firebase UID " + firebaseUID + " に対応するユーザーが見つかりません",
			"message": "ユーザー情報の同期が必要です。/firebase-auth/sync エンドポイントを呼び出してください",
			"firebase_uid": firebaseUID,
		})
		return
	}
	
	fromUserID := user.ID
	
	// リクエストボディを解析
	var input SendFriendRequestInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "無効なリクエストです",
		})
		return
	}
	
	// 送信先ユーザーを取得
	ctx := c.Request.Context()
	toUser, err := h.userService.GetUserByEmail(ctx, input.ToEmail)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error": "ユーザーが見つかりません",
		})
		return
	}
	
	// 自分自身に申請しようとしていないかチェック
	if fromUserID == toUser.ID {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "自分自身に友達申請することはできません",
		})
		return
	}
	
	// 既に友達関係にあるかチェック
	areFriends, err := h.friendshipService.AreFriends(ctx, fromUserID, toUser.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "友達関係の確認に失敗しました",
		})
		return
	}
	if areFriends {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "既に友達です",
		})
		return
	}
	
	// 既存の申請があるかチェック
	existingRequest, err := h.friendRequestService.GetPendingRequest(ctx, fromUserID, toUser.ID)
	if err == nil && existingRequest != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "既に申請済みです",
		})
		return
	}
	
	// 友達申請を作成
	friendRequest, err := h.friendRequestService.Create(ctx, fromUserID, toUser.ID, input.Message)
	if err != nil {
		// 詳細なエラーログを追加
		log.Printf("❌ 友達申請作成エラー: %v", err)
		log.Printf("❌ FromUserID: %s, ToUserID: %s", fromUserID.Hex(), toUser.ID.Hex())
		
		// ビジネスロジックエラーの場合は400を返す
		errorMessage := err.Error()
		if errorMessage == "既に友達申請を送信済みです" || 
		   errorMessage == "既にpending状態の友達申請が存在します" ||
		   errorMessage == "相手から友達申請が来ています。申請を確認してください" ||
		   errorMessage == "既に友達です" ||
		   errorMessage == "自分自身に友達申請を送ることはできません" {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": errorMessage,
			})
			return
		}
		
		// その他のエラーは500として扱う
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "友達申請の作成に失敗しました",
			"detail": errorMessage,
		})
		return
	}
	
	c.JSON(http.StatusCreated, gin.H{
		"message": "友達申請を送信しました",
		"data":    friendRequest,
	})
}

// GetReceivedFriendRequests は受信した友達申請一覧を取得するハンドラー
func (h *FriendRequestHandler) GetReceivedFriendRequests(c *gin.Context) {
	// Firebase認証からユーザー情報を取得
	firebaseUser, exists := c.Get("firebase_uid")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "認証が必要です",
		})
		return
	}
	
	// Firebase UIDからMongoDBユーザーを取得（自動同期対応）
	firebaseUID := firebaseUser.(string)
	user, err := h.userService.GetUserByFirebaseUID(c.Request.Context(), firebaseUID)
	if err != nil {
		// ユーザーが見つからない場合は自動同期を試行
		log.Printf("🔄 友達申請ハンドラー: ユーザー自動同期を開始 Firebase UID: %s", firebaseUID)
		// Firebase認証ハンドラーを使って自動同期（共通処理を再利用）
		// 注意: 直接的な依存を避けるため、ここではエラーレスポンスのみ返す
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "Firebase UID " + firebaseUID + " に対応するユーザーが見つかりません",
			"message": "ユーザー情報の同期が必要です。/firebase-auth/sync エンドポイントを呼び出してください",
			"firebase_uid": firebaseUID,
		})
		return
	}
	
	toUserID := user.ID
	
	// 受信した申請を取得
	ctx := c.Request.Context()
	requests, err := h.friendRequestService.GetReceivedRequests(ctx, toUserID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "友達申請の取得に失敗しました",
		})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"message": "受信した友達申請を取得しました",
		"data":    requests,
	})
}

// GetSentFriendRequests は送信した友達申請一覧を取得するハンドラー
func (h *FriendRequestHandler) GetSentFriendRequests(c *gin.Context) {
	// Firebase認証からユーザー情報を取得
	firebaseUser, exists := c.Get("firebase_uid")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "認証が必要です",
		})
		return
	}
	
	// Firebase UIDからMongoDBユーザーを取得（自動同期対応）
	firebaseUID := firebaseUser.(string)
	user, err := h.userService.GetUserByFirebaseUID(c.Request.Context(), firebaseUID)
	if err != nil {
		// ユーザーが見つからない場合は自動同期を試行
		log.Printf("🔄 友達申請ハンドラー: ユーザー自動同期を開始 Firebase UID: %s", firebaseUID)
		// Firebase認証ハンドラーを使って自動同期（共通処理を再利用）
		// 注意: 直接的な依存を避けるため、ここではエラーレスポンスのみ返す
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "Firebase UID " + firebaseUID + " に対応するユーザーが見つかりません",
			"message": "ユーザー情報の同期が必要です。/firebase-auth/sync エンドポイントを呼び出してください",
			"firebase_uid": firebaseUID,
		})
		return
	}
	
	fromUserID := user.ID
	
	// 送信した申請を取得
	ctx := c.Request.Context()
	requests, err := h.friendRequestService.GetSentRequests(ctx, fromUserID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "友達申請の取得に失敗しました",
		})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"message": "送信した友達申請を取得しました",
		"data":    requests,
	})
}

// AcceptFriendRequest は友達申請を承諾するハンドラー
func (h *FriendRequestHandler) AcceptFriendRequest(c *gin.Context) {
	// Firebase認証からユーザー情報を取得
	firebaseUser, exists := c.Get("firebase_uid")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "認証が必要です",
		})
		return
	}
	
	// Firebase UIDからMongoDBユーザーを取得（自動同期対応）
	firebaseUID := firebaseUser.(string)
	user, err := h.userService.GetUserByFirebaseUID(c.Request.Context(), firebaseUID)
	if err != nil {
		// ユーザーが見つからない場合は自動同期を試行
		log.Printf("🔄 友達申請ハンドラー: ユーザー自動同期を開始 Firebase UID: %s", firebaseUID)
		// Firebase認証ハンドラーを使って自動同期（共通処理を再利用）
		// 注意: 直接的な依存を避けるため、ここではエラーレスポンスのみ返す
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "Firebase UID " + firebaseUID + " に対応するユーザーが見つかりません",
			"message": "ユーザー情報の同期が必要です。/firebase-auth/sync エンドポイントを呼び出してください",
			"firebase_uid": firebaseUID,
		})
		return
	}
	
	toUserID := user.ID
	
	// 申請IDを取得
	requestIDStr := c.Param("id")
	requestID, err := primitive.ObjectIDFromHex(requestIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "無効な申請IDです",
		})
		return
	}
	
	// 申請を承諾
	ctx := c.Request.Context()
	err = h.friendRequestService.Accept(ctx, requestID, toUserID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "友達申請の承諾に失敗しました",
		})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"message": "友達申請を承諾しました",
	})
}

// RejectFriendRequest は友達申請を拒否するハンドラー
func (h *FriendRequestHandler) RejectFriendRequest(c *gin.Context) {
	// Firebase認証からユーザー情報を取得
	firebaseUser, exists := c.Get("firebase_uid")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "認証が必要です",
		})
		return
	}
	
	// Firebase UIDからMongoDBユーザーを取得（自動同期対応）
	firebaseUID := firebaseUser.(string)
	user, err := h.userService.GetUserByFirebaseUID(c.Request.Context(), firebaseUID)
	if err != nil {
		// ユーザーが見つからない場合は自動同期を試行
		log.Printf("🔄 友達申請ハンドラー: ユーザー自動同期を開始 Firebase UID: %s", firebaseUID)
		// Firebase認証ハンドラーを使って自動同期（共通処理を再利用）
		// 注意: 直接的な依存を避けるため、ここではエラーレスポンスのみ返す
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "Firebase UID " + firebaseUID + " に対応するユーザーが見つかりません",
			"message": "ユーザー情報の同期が必要です。/firebase-auth/sync エンドポイントを呼び出してください",
			"firebase_uid": firebaseUID,
		})
		return
	}
	
	toUserID := user.ID
	
	// 申請IDを取得
	requestIDStr := c.Param("id")
	requestID, err := primitive.ObjectIDFromHex(requestIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "無効な申請IDです",
		})
		return
	}
	
	// 申請を拒否
	ctx := c.Request.Context()
	err = h.friendRequestService.Reject(ctx, requestID, toUserID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "友達申請の拒否に失敗しました",
		})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"message": "友達申請を拒否しました",
	})
}

// CancelFriendRequest は友達申請をキャンセルするハンドラー
func (h *FriendRequestHandler) CancelFriendRequest(c *gin.Context) {
	// Firebase認証からユーザー情報を取得
	firebaseUser, exists := c.Get("firebase_uid")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "認証が必要です",
		})
		return
	}
	
	// Firebase UIDからMongoDBユーザーを取得（自動同期対応）
	firebaseUID := firebaseUser.(string)
	user, err := h.userService.GetUserByFirebaseUID(c.Request.Context(), firebaseUID)
	if err != nil {
		// ユーザーが見つからない場合は自動同期を試行
		log.Printf("🔄 友達申請ハンドラー: ユーザー自動同期を開始 Firebase UID: %s", firebaseUID)
		// Firebase認証ハンドラーを使って自動同期（共通処理を再利用）
		// 注意: 直接的な依存を避けるため、ここではエラーレスポンスのみ返す
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "Firebase UID " + firebaseUID + " に対応するユーザーが見つかりません",
			"message": "ユーザー情報の同期が必要です。/firebase-auth/sync エンドポイントを呼び出してください",
			"firebase_uid": firebaseUID,
		})
		return
	}
	
	fromUserID := user.ID
	
	// 申請IDを取得
	requestIDStr := c.Param("id")
	requestID, err := primitive.ObjectIDFromHex(requestIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "無効な申請IDです",
		})
		return
	}
	
	// 申請をキャンセル
	ctx := c.Request.Context()
	err = h.friendRequestService.Cancel(ctx, requestID, fromUserID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "友達申請のキャンセルに失敗しました",
		})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"message": "友達申請をキャンセルしました",
	})
}

// GetFriends は友達一覧を取得するハンドラー
func (h *FriendRequestHandler) GetFriends(c *gin.Context) {
	// Firebase認証からユーザー情報を取得
	firebaseUser, exists := c.Get("firebase_uid")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "認証が必要です",
		})
		return
	}
	
	// Firebase UIDからMongoDBユーザーを取得（自動同期対応）
	firebaseUID := firebaseUser.(string)
	user, err := h.userService.GetUserByFirebaseUID(c.Request.Context(), firebaseUID)
	if err != nil {
		// ユーザーが見つからない場合は自動同期を試行
		log.Printf("🔄 友達申請ハンドラー: ユーザー自動同期を開始 Firebase UID: %s", firebaseUID)
		// Firebase認証ハンドラーを使って自動同期（共通処理を再利用）
		// 注意: 直接的な依存を避けるため、ここではエラーレスポンスのみ返す
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "Firebase UID " + firebaseUID + " に対応するユーザーが見つかりません",
			"message": "ユーザー情報の同期が必要です。/firebase-auth/sync エンドポイントを呼び出してください",
			"firebase_uid": firebaseUID,
		})
		return
	}
	
	userObjID := user.ID
	
	// 友達一覧を取得
	ctx := c.Request.Context()
	friends, err := h.friendshipService.GetFriends(ctx, userObjID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "友達一覧の取得に失敗しました",
		})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"message": "友達一覧を取得しました",
		"data":    friends,
	})
}

// RemoveFriendInput は友達削除のリクエストボディ
type RemoveFriendInput struct {
	FriendEmail string `json:"friend_email" binding:"required,email"`
}

// RemoveFriend は友達を削除するハンドラー
func (h *FriendRequestHandler) RemoveFriend(c *gin.Context) {
	// Firebase認証からユーザー情報を取得
	firebaseUser, exists := c.Get("firebase_uid")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "認証が必要です",
		})
		return
	}
	
	// Firebase UIDからMongoDBユーザーを取得（自動同期対応）
	firebaseUID := firebaseUser.(string)
	user, err := h.userService.GetUserByFirebaseUID(c.Request.Context(), firebaseUID)
	if err != nil {
		// ユーザーが見つからない場合は自動同期を試行
		log.Printf("🔄 友達申請ハンドラー: ユーザー自動同期を開始 Firebase UID: %s", firebaseUID)
		// Firebase認証ハンドラーを使って自動同期（共通処理を再利用）
		// 注意: 直接的な依存を避けるため、ここではエラーレスポンスのみ返す
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "Firebase UID " + firebaseUID + " に対応するユーザーが見つかりません",
			"message": "ユーザー情報の同期が必要です。/firebase-auth/sync エンドポイントを呼び出してください",
			"firebase_uid": firebaseUID,
		})
		return
	}
	
	userObjID := user.ID
	
	// リクエストボディを解析
	var input RemoveFriendInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "無効なリクエストです",
		})
		return
	}
	
	// 友達のメールアドレスからユーザーIDを取得
	ctx := c.Request.Context()
	friendUser, err := h.userService.GetUserByEmail(ctx, input.FriendEmail)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error": "指定されたユーザーが見つかりません",
		})
		return
	}
	
	// 友達関係を削除
	err = h.friendshipService.Delete(ctx, userObjID, friendUser.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "友達削除に失敗しました",
		})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"message": "友達を削除しました",
	})
}

// RegisterRoutes は友達申請関連のルートを登録
func (h *FriendRequestHandler) RegisterRoutes(v1 *gin.RouterGroup, firebaseMiddleware gin.HandlerFunc) {
	// 友達申請関連エンドポイント
	friendRequests := v1.Group("/friend-requests")
	friendRequests.Use(firebaseMiddleware)
	{
		friendRequests.POST("/send", h.SendFriendRequest)          // 友達申請送信
		friendRequests.GET("/received", h.GetReceivedFriendRequests) // 受信した申請一覧
		friendRequests.GET("/sent", h.GetSentFriendRequests)      // 送信した申請一覧
		friendRequests.POST("/:id/accept", h.AcceptFriendRequest) // 申請承諾
		friendRequests.POST("/:id/reject", h.RejectFriendRequest) // 申請拒否
		friendRequests.POST("/:id/cancel", h.CancelFriendRequest) // 申請キャンセル
	}

	// 友達関連エンドポイント
	friends := v1.Group("/friends")
	friends.Use(firebaseMiddleware)
	{
		friends.GET("/", h.GetFriends)       // 友達一覧取得
		friends.DELETE("/remove", h.RemoveFriend) // 友達削除
	}
}