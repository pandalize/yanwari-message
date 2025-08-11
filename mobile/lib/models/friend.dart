import 'user.dart';

/// Friend は友達関係を表すモデル
class Friend {
  final String friendshipId;
  final AppUser friend;
  final DateTime createdAt;

  Friend({
    required this.friendshipId,
    required this.friend,
    required this.createdAt,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      friendshipId: json['friendship_id'] ?? '',
      friend: AppUser.fromJson(json['friend'] ?? {}),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'friendship_id': friendshipId,
      'friend': friend.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// FriendRequest は友達申請を表すモデル
class FriendRequest {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String status; // pending, accepted, rejected, canceled
  final String? message;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AppUser? fromUser;
  final AppUser? toUser;

  FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.status,
    this.message,
    required this.createdAt,
    required this.updatedAt,
    this.fromUser,
    this.toUser,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] ?? '',
      fromUserId: json['from_user_id'] ?? '',
      toUserId: json['to_user_id'] ?? '',
      status: json['status'] ?? 'pending',
      message: json['message'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      fromUser: json['from_user'] != null ? AppUser.fromJson(json['from_user']) : null,
      toUser: json['to_user'] != null ? AppUser.fromJson(json['to_user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'status': status,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'from_user': fromUser?.toJson(),
      'to_user': toUser?.toJson(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isCanceled => status == 'canceled';

  /// 表示用のユーザー情報を取得（送信者または受信者）
  AppUser? getDisplayUser(String currentUserId) {
    if (fromUserId == currentUserId) {
      return toUser; // 送信した申請の場合は相手のユーザー情報
    } else {
      return fromUser; // 受信した申請の場合は送信者のユーザー情報
    }
  }

  /// 申請タイプを判定（送信か受信か）
  bool isSentBy(String currentUserId) {
    return fromUserId == currentUserId;
  }
}

/// 友達検索結果用モデル
class FriendSearchResult {
  final AppUser user;
  final bool isAlreadyFriend;
  final bool hasPendingRequest;
  final String? pendingRequestStatus; // sent, received

  FriendSearchResult({
    required this.user,
    required this.isAlreadyFriend,
    required this.hasPendingRequest,
    this.pendingRequestStatus,
  });

  factory FriendSearchResult.fromUser(AppUser user) {
    return FriendSearchResult(
      user: user,
      isAlreadyFriend: false,
      hasPendingRequest: false,
    );
  }

  FriendSearchResult copyWith({
    AppUser? user,
    bool? isAlreadyFriend,
    bool? hasPendingRequest,
    String? pendingRequestStatus,
  }) {
    return FriendSearchResult(
      user: user ?? this.user,
      isAlreadyFriend: isAlreadyFriend ?? this.isAlreadyFriend,
      hasPendingRequest: hasPendingRequest ?? this.hasPendingRequest,
      pendingRequestStatus: pendingRequestStatus ?? this.pendingRequestStatus,
    );
  }
}

