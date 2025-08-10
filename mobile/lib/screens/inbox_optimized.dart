import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../widgets/message_list_item.dart';
import '../widgets/message_detail_sheet.dart';
import '../widgets/treemap_visualization.dart';

// メイン画面を軽量化
class InboxOptimizedScreen extends StatefulWidget {
  const InboxOptimizedScreen({super.key});

  @override
  State<InboxOptimizedScreen> createState() => _InboxOptimizedScreenState();
}

class _InboxOptimizedScreenState extends State<InboxOptimizedScreen> {
  late final ApiService _apiService;
  final StreamController<List<Map<String, dynamic>>> _messagesController = 
      StreamController.broadcast();
  
  List<Map<String, dynamic>> _cachedMessages = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _displayMode = 'list-desc';
  Timer? _updateTimer;
  
  // パフォーマンス最適化用
  DateTime? _lastFetchTime;
  static const _minFetchInterval = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(context.read<AuthService>());
    _loadMessagesInBackground();
    _startOptimizedPeriodicUpdate();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _messagesController.close();
    super.dispose();
  }

  // バックグラウンドでメッセージを取得
  Future<void> _loadMessagesInBackground({bool forceRefresh = false}) async {
    // 頻繁な再取得を防ぐ
    if (!forceRefresh && _lastFetchTime != null) {
      final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
      if (timeSinceLastFetch < _minFetchInterval) {
        return;
      }
    }

    // バックグラウンドで非同期処理
    compute(_fetchMessagesInIsolate, _apiService).then((messages) {
      if (mounted) {
        setState(() {
          _cachedMessages = messages;
          _isLoading = false;
          _lastFetchTime = DateTime.now();
        });
        _messagesController.add(messages);
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'メッセージの読み込みに失敗しました: $error';
          _isLoading = false;
        });
      }
    });
  }

  // Isolateで実行される関数（UIをブロックしない）
  static Future<List<Map<String, dynamic>>> _fetchMessagesInIsolate(
      ApiService apiService) async {
    final result = await apiService.getInboxWithRatings();
    
    if (result != null && result is Map<String, dynamic>) {
      List<dynamic>? messagesList;
      if (result['data'] is Map && 
          (result['data'] as Map)['messages'] is List) {
        messagesList = (result['data'] as Map)['messages'] as List<dynamic>;
      } else if (result['messages'] is List) {
        messagesList = result['messages'] as List<dynamic>;
      }
      
      if (messagesList != null) {
        return messagesList
            .whereType<Map<String, dynamic>>()
            .toList();
      }
    }
    return [];
  }

  // 効率的な定期更新
  void _startOptimizedPeriodicUpdate() {
    _updateTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted && !_isLoading) {
        // 差分更新のみ
        _updateMessagesIncrementally();
      }
    });
  }

  // 差分更新（新着メッセージのみチェック）
  Future<void> _updateMessagesIncrementally() async {
    // 最新のメッセージIDを取得
    final latestId = _cachedMessages.isNotEmpty 
        ? _cachedMessages.first['id'] 
        : null;
    
    // サーバーに新着確認
    // ここでは簡略化のため全取得しているが、
    // 本来は差分APIを使用すべき
    _loadMessagesInBackground();
  }

  // 既読処理を最適化
  Future<void> _markAsReadOptimized(String messageId) async {
    // UIを即座に更新（楽観的更新）
    final index = _cachedMessages.indexWhere((m) => m['id'] == messageId);
    if (index != -1) {
      setState(() {
        _cachedMessages[index]['is_read'] = true;
      });
    }
    
    // バックグラウンドでAPIコール
    _apiService.markAsRead(messageId).catchError((error) {
      // エラー時はロールバック
      if (mounted && index != -1) {
        setState(() {
          _cachedMessages[index]['is_read'] = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorState()
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          const Text(
            '受信トレイ',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          // 表示モード切り替えボタン
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'list-desc', icon: Icon(Icons.arrow_downward)),
              ButtonSegment(value: 'list-asc', icon: Icon(Icons.arrow_upward)),
              ButtonSegment(value: 'treemap', icon: Icon(Icons.grid_view)),
            ],
            selected: {_displayMode},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _displayMode = newSelection.first;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_cachedMessages.isEmpty) {
      return _buildEmptyState();
    }

    // StreamBuilderで自動更新
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _messagesController.stream,
      initialData: _cachedMessages,
      builder: (context, snapshot) {
        final messages = snapshot.data ?? _cachedMessages;
        
        if (_displayMode == 'treemap') {
          // TreeMapを別ウィジェットに分離
          return TreemapVisualization(
            messages: messages,
            onMessageTap: _showMessageDetail,
          );
        }
        
        // リストビューを最適化
        return _buildOptimizedListView(messages);
      },
    );
  }

  Widget _buildOptimizedListView(List<Map<String, dynamic>> messages) {
    // ソート処理
    final sortedMessages = List<Map<String, dynamic>>.from(messages);
    if (_displayMode == 'list-asc') {
      sortedMessages.sort((a, b) {
        final aTime = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
        final bTime = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
        return aTime.compareTo(bTime);
      });
    } else {
      sortedMessages.sort((a, b) {
        final aTime = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
        final bTime = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
    }

    // ListView.builderで仮想化
    return ListView.builder(
      itemCount: sortedMessages.length,
      itemBuilder: (context, index) {
        final message = sortedMessages[index];
        // 個別のウィジェットに分離
        return MessageListItem(
          message: message,
          onTap: () => _showMessageDetail(message),
          onMarkAsRead: () => _markAsReadOptimized(message['id']),
        );
      },
    );
  }

  void _showMessageDetail(Map<String, dynamic> message) {
    // BottomSheetを使用（軽量）
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MessageDetailSheet(
        message: message,
        onDelete: () => _deleteMessage(message['id']),
        onRatingUpdate: (rating) => _updateRating(message['id'], rating),
      ),
    );
  }

  Future<void> _deleteMessage(String messageId) async {
    // 楽観的削除
    setState(() {
      _cachedMessages.removeWhere((m) => m['id'] == messageId);
    });
    _messagesController.add(_cachedMessages);
    
    // バックグラウンドでAPI呼び出し
    _apiService.deleteMessage(messageId).catchError((error) {
      // エラー時は再取得
      _loadMessagesInBackground(forceRefresh: true);
    });
  }

  Future<void> _updateRating(String messageId, int rating) async {
    // 楽観的更新
    final index = _cachedMessages.indexWhere((m) => m['id'] == messageId);
    if (index != -1) {
      setState(() {
        _cachedMessages[index]['rating'] = rating;
      });
    }
    
    // バックグラウンドでAPI呼び出し
    _apiService.updateRating(messageId, rating).catchError((error) {
      // エラー時は再取得
      _loadMessagesInBackground(forceRefresh: true);
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'メッセージがありません',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'エラーが発生しました',
            style: TextStyle(fontSize: 16, color: Colors.red[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadMessagesInBackground(forceRefresh: true),
            child: const Text('再試行'),
          ),
        ],
      ),
    );
  }
}