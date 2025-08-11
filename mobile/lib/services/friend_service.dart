import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'auth_service.dart';
import '../models/friend.dart';
import '../models/user.dart';

/// FriendService は友達関連の操作を提供するサービスクラス
class FriendService extends ChangeNotifier {
  final ApiService _apiService;
  final AuthService _authService;

  // 友達リスト
  List<Friend> _friends = [];
  List<Friend> get friends => List.unmodifiable(_friends);

  // 友達申請リスト
  List<FriendRequest> _receivedRequests = [];
  List<FriendRequest> _sentRequests = [];
  
  List<FriendRequest> get receivedRequests => List.unmodifiable(_receivedRequests);
  List<FriendRequest> get sentRequests => List.unmodifiable(_sentRequests);

  // 状態管理
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  FriendService(this._apiService, this._authService);

  /// エラーメッセージをクリア
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 友達一覧を取得
  Future<void> loadFriends() async {
    try {
      _setLoading(true);
      _clearError();

      print('🏃 友達一覧取得開始');
      final response = await _apiService.getFriends();
      print('📋 友達一覧レスポンス: ${response.toString()}');

      if (response['data'] != null) {
        final List<dynamic> friendsData = response['data'] as List<dynamic>;
        _friends = friendsData
            .map((json) => Friend.fromJson(json as Map<String, dynamic>))
            .toList();
        
        print('✅ 友達一覧取得完了: ${_friends.length}人');
      } else {
        _friends = [];
        print('📋 友達がいません');
      }
    } catch (e) {
      print('❌ 友達一覧取得エラー: $e');
      _setError('友達一覧の取得に失敗しました: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 友達申請一覧を取得
  Future<void> loadFriendRequests() async {
    try {
      _setLoading(true);
      _clearError();

      print('🏃 友達申請一覧取得開始');
      
      // 受信した申請を取得
      final receivedResponse = await _apiService.getReceivedFriendRequests();
      if (receivedResponse['data'] != null) {
        final List<dynamic> receivedData = receivedResponse['data'] as List<dynamic>;
        _receivedRequests = receivedData
            .map((json) => FriendRequest.fromJson(json as Map<String, dynamic>))
            .toList();
        print('📥 受信申請: ${_receivedRequests.length}件');
      } else {
        _receivedRequests = [];
      }

      // 送信した申請を取得
      final sentResponse = await _apiService.getSentFriendRequests();
      if (sentResponse['data'] != null) {
        final List<dynamic> sentData = sentResponse['data'] as List<dynamic>;
        _sentRequests = sentData
            .map((json) => FriendRequest.fromJson(json as Map<String, dynamic>))
            .toList();
        print('📤 送信申請: ${_sentRequests.length}件');
      } else {
        _sentRequests = [];
      }

      print('✅ 友達申請一覧取得完了');
    } catch (e) {
      print('❌ 友達申請一覧取得エラー: $e');
      _setError('友達申請一覧の取得に失敗しました: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 全てのデータを読み込み
  Future<void> loadAll() async {
    await Future.wait([
      loadFriends(),
      loadFriendRequests(),
    ]);
  }

  /// 友達申請を送信
  Future<bool> sendFriendRequest({
    required String toEmail,
    String? message,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      print('🏃 友達申請送信開始: $toEmail');
      await _apiService.sendFriendRequest(toEmail: toEmail, message: message);
      
      // 送信後に申請リストを更新
      await loadFriendRequests();
      print('✅ 友達申請送信完了');
      return true;
    } catch (e) {
      print('❌ 友達申請送信エラー: $e');
      _setError('友達申請の送信に失敗しました: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 友達申請を承諾
  Future<bool> acceptFriendRequest(String requestId) async {
    try {
      _setLoading(true);
      _clearError();

      print('🏃 友達申請承諾開始: $requestId');
      await _apiService.acceptFriendRequest(requestId);
      
      // 承諾後に友達リストと申請リストを更新
      await Future.wait([
        loadFriends(),
        loadFriendRequests(),
      ]);
      
      print('✅ 友達申請承諾完了');
      return true;
    } catch (e) {
      print('❌ 友達申請承諾エラー: $e');
      _setError('友達申請の承諾に失敗しました: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 友達申請を拒否
  Future<bool> rejectFriendRequest(String requestId) async {
    try {
      _setLoading(true);
      _clearError();

      print('🏃 友達申請拒否開始: $requestId');
      await _apiService.rejectFriendRequest(requestId);
      
      // 拒否後に申請リストを更新
      await loadFriendRequests();
      print('✅ 友達申請拒否完了');
      return true;
    } catch (e) {
      print('❌ 友達申請拒否エラー: $e');
      _setError('友達申請の拒否に失敗しました: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 友達申請をキャンセル
  Future<bool> cancelFriendRequest(String requestId) async {
    try {
      _setLoading(true);
      _clearError();

      print('🏃 友達申請キャンセル開始: $requestId');
      await _apiService.cancelFriendRequest(requestId);
      
      // キャンセル後に申請リストを更新
      await loadFriendRequests();
      print('✅ 友達申請キャンセル完了');
      return true;
    } catch (e) {
      print('❌ 友達申請キャンセルエラー: $e');
      _setError('友達申請のキャンセルに失敗しました: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 友達を削除
  Future<bool> removeFriend(String friendEmail) async {
    try {
      _setLoading(true);
      _clearError();

      print('🏃 友達削除開始: $friendEmail');
      await _apiService.removeFriend(friendEmail);
      
      // 削除後に友達リストを更新
      await loadFriends();
      print('✅ 友達削除完了');
      return true;
    } catch (e) {
      print('❌ 友達削除エラー: $e');
      _setError('友達の削除に失敗しました: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 友達を名前で検索
  List<Friend> searchFriends(String query) {
    if (query.trim().isEmpty) {
      return friends;
    }

    final lowercaseQuery = query.toLowerCase();
    return friends.where((friend) {
      final name = friend.friend.name.toLowerCase();
      final email = friend.friend.email.toLowerCase();
      return name.contains(lowercaseQuery) || email.contains(lowercaseQuery);
    }).toList();
  }

  /// 特定のユーザーが友達かどうかをチェック
  bool isFriend(String userEmail) {
    return friends.any((friend) => friend.friend.email == userEmail);
  }

  /// 特定のユーザーに申請中かどうかをチェック
  bool hasPendingRequestTo(String userEmail) {
    return sentRequests.any((request) => 
        request.toUser?.email == userEmail && request.isPending);
  }

  /// 特定のユーザーから申請を受けているかどうかをチェック
  bool hasPendingRequestFrom(String userEmail) {
    return receivedRequests.any((request) => 
        request.fromUser?.email == userEmail && request.isPending);
  }

  /// 友達数を取得
  int get friendsCount => friends.length;

  /// 受信した友達申請数を取得
  int get receivedRequestsCount => receivedRequests.length;

  /// 送信した友達申請数を取得
  int get sentRequestsCount => sentRequests.length;

  /// ユーザー検索結果
  List<FriendSearchResult> _searchResults = [];
  List<FriendSearchResult> get searchResults => List.unmodifiable(_searchResults);

  /// 最後の検索クエリ
  String _lastSearchQuery = '';
  String get lastSearchQuery => _lastSearchQuery;

  /// プライベートメソッド群
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}