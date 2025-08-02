import 'package:dio/dio.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api/v1';
  late final Dio _dio;
  final AuthService _authService;

  ApiService(this._authService) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // リクエストインターセプター（認証トークン自動追加）
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _authService.getIdToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // 401エラーの場合、トークンが期限切れの可能性
        if (error.response?.statusCode == 401) {
          // トークンを再取得して再試行
          try {
            final token = await _authService.getIdToken();
            if (token != null) {
              final requestOptions = error.requestOptions;
              requestOptions.headers['Authorization'] = 'Bearer $token';
              
              // リクエストを再実行
              final response = await _dio.fetch(requestOptions);
              handler.resolve(response);
              return;
            }
          } catch (e) {
            // トークン再取得に失敗した場合はログアウト
            await _authService.signOut();
          }
        }
        handler.next(error);
      },
    ));
  }

  // ユーザープロフィール取得
  Future<Map<String, dynamic>> getUserProfile() async {
    final response = await _dio.get('/firebase-auth/profile');
    return response.data;
  }

  // Firebase→MongoDB同期
  Future<Map<String, dynamic>> syncUserToMongoDB(String name) async {
    final response = await _dio.post('/firebase-auth/sync', data: {
      'name': name,
      'timezone': 'Asia/Tokyo',
    });
    return response.data;
  }

  // メッセージ作成
  Future<Map<String, dynamic>> createMessage({
    required String originalText,
    required String recipientEmail,
  }) async {
    final response = await _dio.post('/messages/draft', data: {
      'originalText': originalText,
      'recipientEmail': recipientEmail,
    });
    return response.data;
  }

  // メッセージ一覧取得
  Future<Map<String, dynamic>> getMessages() async {
    final response = await _dio.get('/messages/');
    return response.data;
  }

  // メッセージ更新
  Future<Map<String, dynamic>> updateMessage({
    required String messageId,
    String? originalText,
    String? selectedTone,
  }) async {
    final data = <String, dynamic>{};
    if (originalText != null) data['originalText'] = originalText;
    if (selectedTone != null) data['selectedTone'] = selectedTone;

    final response = await _dio.put('/messages/$messageId', data: data);
    return response.data;
  }

  // トーン変換
  Future<Map<String, dynamic>> transformTones({
    required String messageId,
    required String originalText,
  }) async {
    final response = await _dio.post('/transform/tones', data: {
      'messageId': messageId,
      'originalText': originalText,
    });
    return response.data;
  }

  // AI時間提案
  Future<Map<String, dynamic>> suggestSchedule({
    required String messageId,
    required String messageText,
    required String selectedTone,
  }) async {
    final response = await _dio.post('/schedule/suggest', data: {
      'messageId': messageId,
      'messageText': messageText,
      'selectedTone': selectedTone,
    });
    return response.data;
  }

  // スケジュール作成
  Future<Map<String, dynamic>> createSchedule({
    required String messageId,
    required DateTime scheduledAt,
    required String timezone,
  }) async {
    final response = await _dio.post('/schedules/', data: {
      'messageId': messageId,
      'scheduledAt': scheduledAt.toIso8601String(),
      'timezone': timezone,
    });
    return response.data;
  }

  // スケジュール一覧取得
  Future<Map<String, dynamic>> getSchedules() async {
    final response = await _dio.get('/schedules/');
    return response.data;
  }

  // スケジュール更新
  Future<Map<String, dynamic>> updateSchedule({
    required String scheduleId,
    DateTime? scheduledAt,
    String? timezone,
  }) async {
    final data = <String, dynamic>{};
    if (scheduledAt != null) data['scheduledAt'] = scheduledAt.toIso8601String();
    if (timezone != null) data['timezone'] = timezone;

    final response = await _dio.put('/schedules/$scheduleId', data: data);
    return response.data;
  }

  // スケジュール削除
  Future<void> deleteSchedule(String scheduleId) async {
    await _dio.delete('/schedules/$scheduleId');
  }

  // 受信メッセージ一覧取得
  Future<Map<String, dynamic>> getReceivedMessages() async {
    final response = await _dio.get('/messages/received');
    return response.data;
  }

  // メッセージを既読にする
  Future<Map<String, dynamic>> markMessageAsRead(String messageId) async {
    final response = await _dio.put('/messages/$messageId/read');
    return response.data;
  }

  // 友達一覧取得
  Future<Map<String, dynamic>> getFriends() async {
    final response = await _dio.get('/friends/');
    return response.data;
  }

  // 友達申請送信
  Future<Map<String, dynamic>> sendFriendRequest({
    required String toEmail,
    String? message,
  }) async {
    final response = await _dio.post('/friend-requests/send', data: {
      'to_email': toEmail,
      if (message != null) 'message': message,
    });
    return response.data;
  }

  // 受信した友達申請一覧
  Future<Map<String, dynamic>> getReceivedFriendRequests() async {
    final response = await _dio.get('/friend-requests/received');
    return response.data;
  }

  // 送信した友達申請一覧
  Future<Map<String, dynamic>> getSentFriendRequests() async {
    final response = await _dio.get('/friend-requests/sent');
    return response.data;
  }

  // 友達申請を承諾
  Future<Map<String, dynamic>> acceptFriendRequest(String requestId) async {
    final response = await _dio.post('/friend-requests/$requestId/accept');
    return response.data;
  }

  // 友達申請を拒否
  Future<Map<String, dynamic>> rejectFriendRequest(String requestId) async {
    final response = await _dio.post('/friend-requests/$requestId/reject');
    return response.data;
  }

  // 友達申請をキャンセル
  Future<Map<String, dynamic>> cancelFriendRequest(String requestId) async {
    final response = await _dio.post('/friend-requests/$requestId/cancel');
    return response.data;
  }

  // 友達削除
  Future<void> removeFriend(String friendEmail) async {
    await _dio.delete('/friends/remove', data: {
      'friend_email': friendEmail,
    });
  }

  // メッセージ評価
  Future<Map<String, dynamic>> rateMessage({
    required String messageId,
    required int rating,
    String? comment,
  }) async {
    final response = await _dio.post('/messages/$messageId/rate', data: {
      'rating': rating,
      if (comment != null) 'comment': comment,
    });
    return response.data;
  }

  // メッセージ評価取得
  Future<Map<String, dynamic>> getMessageRating(String messageId) async {
    final response = await _dio.get('/messages/$messageId/rating');
    return response.data;
  }

  // 評価付き受信メッセージ一覧
  Future<Map<String, dynamic>> getInboxWithRatings() async {
    final response = await _dio.get('/messages/inbox-with-ratings');
    return response.data;
  }

  // ユーザー設定取得
  Future<Map<String, dynamic>> getUserSettings() async {
    final response = await _dio.get('/settings');
    return response.data;
  }

  // プロフィール更新
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? timezone,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (timezone != null) data['timezone'] = timezone;

    final response = await _dio.put('/settings/profile', data: data);
    return response.data;
  }

  // 通知設定更新
  Future<Map<String, dynamic>> updateNotificationSettings({
    bool? emailNotifications,
    bool? pushNotifications,
    bool? messageDelivered,
  }) async {
    final data = <String, dynamic>{};
    if (emailNotifications != null) data['email_notifications'] = emailNotifications;
    if (pushNotifications != null) data['push_notifications'] = pushNotifications;
    if (messageDelivered != null) data['message_delivered'] = messageDelivered;

    final response = await _dio.put('/settings/notifications', data: data);
    return response.data;
  }

  // ヘルスチェック
  Future<Map<String, dynamic>> healthCheck() async {
    final response = await _dio.get('/health');
    return response.data;
  }
}