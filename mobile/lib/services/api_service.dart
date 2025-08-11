import 'package:dio/dio.dart';
import 'auth_service.dart';

class ApiService {
  // Flutter Web版の場合、絶対パスでAPIサーバーにアクセス
  static const String baseUrl = 'http://127.0.0.1:8080/api/v1';
  late final Dio _dio;
  final AuthService _authService;

  ApiService(this._authService) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 120), // AI処理のため2分に延長
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // リクエストインターセプター（認証トークン自動追加）
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        print('API リクエスト: ${options.method} ${options.uri}');
        final token = await _authService.getIdToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          print('Firebase IDトークン追加済み');
        } else {
          print('Firebase IDトークンが取得できませんでした');
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        print('API エラー: ${error.message}');
        print('Status Code: ${error.response?.statusCode}');
        print('Response Data: ${error.response?.data}');
        
        // 401エラーの場合、トークンが期限切れの可能性
        if (error.response?.statusCode == 401) {
          print('401エラー: 認証が必要です');
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
            print('トークン再取得に失敗: $e');
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
    String? reason,
  }) async {
    print('📡 [API] createMessage() 開始');
    print('📡 [API] originalText: ${originalText.length > 50 ? originalText.substring(0, 50) + "..." : originalText}');
    print('📡 [API] recipientEmail: $recipientEmail');
    print('📡 [API] reason: ${reason ?? "(なし)"}');
    
    try {
      final data = {
        'originalText': originalText,
        'recipientEmail': recipientEmail,
      };
      
      if (reason != null && reason.trim().isNotEmpty) {
        data['reason'] = reason.trim();
      }
      
      final response = await _dio.post('/messages/draft', data: data);
      print('📡 [API] createMessage() 成功: ${response.statusCode}');
      print('📡 [API] レスポンス: ${response.data}');
      return response.data;
    } catch (e) {
      print('📡 [API] createMessage() エラー: $e');
      rethrow;
    }
  }

  // メッセージ一覧取得
  Future<Map<String, dynamic>> getMessages() async {
    final response = await _dio.get('/messages/');
    return response.data;
  }

  // メッセージ詳細取得
  Future<Map<String, dynamic>> getMessage(String messageId) async {
    final response = await _dio.get('/messages/$messageId');
    return response.data;
  }

  // メッセージ更新
  Future<Map<String, dynamic>> updateMessage({
    required String messageId,
    String? originalText,
    String? reason,
    String? selectedTone,
  }) async {
    final data = <String, dynamic>{};
    if (originalText != null) data['originalText'] = originalText;
    if (reason != null && reason.trim().isNotEmpty) data['reason'] = reason.trim();
    if (selectedTone != null) data['selectedTone'] = selectedTone;

    final response = await _dio.put('/messages/$messageId', data: data);
    return response.data;
  }

  // 下書き一覧取得
  Future<Map<String, dynamic>> getDrafts() async {
    print('📡 [API] getDrafts() 開始');
    try {
      final response = await _dio.get('/messages/drafts');
      print('📡 [API] getDrafts() 成功: ${response.statusCode}');
      // レスポンスの要約のみ表示（詳細は省略）
      if (response.data != null && response.data['data'] != null) {
        final messages = response.data['data']['messages'] as List?;
        print('📡 [API] 取得した下書き数: ${messages?.length ?? 0}');
      }
      return response.data;
    } catch (e) {
      print('📡 [API] getDrafts() エラー: $e');
      rethrow;
    }
  }

  // 下書き削除
  Future<void> deleteDraft(String messageId) async {
    await _dio.delete('/messages/$messageId');
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
    final requestData = {
      'messageId': messageId,
      'messageText': messageText,
      'selectedTone': selectedTone,
    };
    
    print('🌐 AI提案API要求');
    print('  URL: /schedule/suggest');
    print('  データ: $requestData');
    
    try {
      final response = await _dio.post('/schedule/suggest', data: requestData);
      print('🌐 AI提案API成功: ${response.statusCode}');
      print('🌐 レスポンスデータ: ${response.data}');
      return response.data;
    } catch (e) {
      print('🌐 AI提案API失敗: $e');
      if (e.toString().contains('DioException')) {
        print('🌐 詳細エラー情報: $e');
      }
      rethrow;
    }
  }

  // スケジュール作成
  Future<Map<String, dynamic>> createSchedule({
    required String messageId,
    required DateTime scheduledAt,
    required String timezone,
  }) async {
    // タイムゾーン付きのISO 8601フォーマットに変換
    final isoWithTimezone = '${scheduledAt.toIso8601String()}+09:00';
    
    print('API送信データ: scheduledAt=$isoWithTimezone, timezone=$timezone');
    
    final response = await _dio.post('/schedules/', data: {
      'messageId': messageId,
      'scheduledAt': isoWithTimezone,
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

  // メッセージを既読にする（エイリアス）
  Future<Map<String, dynamic>> markAsRead(String messageId) async {
    return await markMessageAsRead(messageId);
  }

  // 評価付き受信メッセージ一覧取得
  Future<Map<String, dynamic>?> getInboxWithRatings() async {
    try {
      final response = await _dio.get('/messages/inbox-with-ratings');
      return response.data;
    } catch (e) {
      print('Error fetching inbox with ratings: $e');
      return null;
    }
  }

  // 送信予定メッセージ一覧取得
  Future<Map<String, dynamic>?> getScheduledMessages() async {
    try {
      final response = await _dio.get('/schedules/', queryParameters: {
        'page': 1,
        'limit': 100,
        'status': 'pending',
      });
      return response.data;
    } catch (e) {
      print('Error fetching scheduled messages: $e');
      return null;
    }
  }

  // 送信済みメッセージ一覧取得
  Future<Map<String, dynamic>?> getSentMessages() async {
    try {
      final response = await _dio.get('/messages/sent', queryParameters: {
        'page': 1,
        'limit': 100,
      });
      return response.data;
    } catch (e) {
      print('Error fetching sent messages: $e');
      return null;
    }
  }

  // メッセージ評価機能
  Future<Map<String, dynamic>> rateMessage(String messageId, int rating) async {
    try {
      print('📝 メッセージ評価API呼び出し開始');
      print('   messageId: $messageId');
      print('   rating: $rating');
      print('   エンドポイント: ${_dio.options.baseUrl}/messages/$messageId/rate');
      
      final response = await _dio.post('/messages/$messageId/rate', data: {
        'rating': rating,
      });
      
      print('✅ 評価API成功:');
      print('   ステータスコード: ${response.statusCode}');
      print('   レスポンス: ${response.data}');
      return response.data;
    } catch (e) {
      print('❌ 評価API エラー詳細:');
      print('   エラー: $e');
      if (e is DioException) {
        print('   HTTPステータス: ${e.response?.statusCode}');
        print('   レスポンスデータ: ${e.response?.data}');
        print('   リクエストURL: ${e.requestOptions.uri}');
        print('   リクエストデータ: ${e.requestOptions.data}');
      }
      rethrow;
    }
  }

  // メッセージ評価取得
  Future<Map<String, dynamic>?> getMessageRating(String messageId) async {
    try {
      final response = await _dio.get('/messages/$messageId/rating');
      return response.data;
    } catch (e) {
      print('評価取得API エラー: $e');
      return null;
    }
  }

  // メッセージ評価削除
  Future<void> deleteMessageRating(String messageId) async {
    try {
      await _dio.delete('/messages/$messageId/rating');
      print('評価削除成功: messageId=$messageId');
    } catch (e) {
      print('評価削除API エラー: $e');
      rethrow;
    }
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

  // ユーザー検索（友達検索用）
  Future<Map<String, dynamic>> searchUsers({
    required String query,
    int? limit,
    int? offset,
  }) async {
    final queryParams = <String, dynamic>{
      'q': query,
    };
    
    if (limit != null) queryParams['limit'] = limit;
    if (offset != null) queryParams['offset'] = offset;
    
    try {
      final response = await _dio.get('/users/search', queryParameters: queryParams);
      return response.data;
    } catch (e) {
      print('ユーザー検索API エラー: $e');
      // APIがまだ実装されていない場合のフォールバック
      if (e.toString().contains('404')) {
        // モックレスポンスを返す（開発中のため）
        return {
          'success': true,
          'data': {
            'users': [],
            'total': 0,
            'query': query,
          },
        };
      }
      rethrow;
    }
  }

  // メールアドレスでユーザー検索
  Future<Map<String, dynamic>> findUserByEmail(String email) async {
    try {
      final response = await _dio.get('/users/find-by-email', queryParameters: {
        'email': email,
      });
      return response.data;
    } catch (e) {
      print('メールアドレス検索API エラー: $e');
      // APIがまだ実装されていない場合のフォールバック
      if (e.toString().contains('404')) {
        return {
          'success': false,
          'error': 'User not found',
          'data': null,
        };
      }
      rethrow;
    }
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