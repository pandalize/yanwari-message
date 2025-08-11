import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../widgets/treemap_widget.dart';

class InboxOnlyScreen extends StatefulWidget {
  const InboxOnlyScreen({super.key});

  @override
  State<InboxOnlyScreen> createState() => _InboxOnlyScreenState();
}

class _InboxOnlyScreenState extends State<InboxOnlyScreen> {
  late final ApiService _apiService;
  
  // 受信メッセージのみ
  List<Map<String, dynamic>> _receivedMessages = [];
  
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  String _displayMode = 'list-desc'; // list-desc, list-asc, treemap
  Map<String, dynamic>? _selectedMessage;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(context.read<AuthService>());
    _loadReceivedMessages();
    _startPeriodicUpdate();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicUpdate() {
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !_isLoading) {
        _loadReceivedMessages(silent: true);
      }
    });
  }

  Future<void> _loadReceivedMessages({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // 受信メッセージのみ取得
      final result = await _apiService.getInboxWithRatings();

      setState(() {
        // 受信メッセージ
        _receivedMessages = <Map<String, dynamic>>[];
        if (result != null && result is Map<String, dynamic>) {
          List<dynamic>? messagesList;
          if (result['data'] is Map && (result['data'] as Map)['messages'] is List) {
            messagesList = (result['data'] as Map)['messages'] as List<dynamic>;
          } else if (result['messages'] is List) {
            messagesList = result['messages'] as List<dynamic>;
          }
          if (messagesList != null) {
            for (var msg in messagesList) {
              if (msg is Map<String, dynamic>) {
                _receivedMessages.add(msg);
              }
            }
          }
        }

        if (!silent) _isLoading = false;
      });
    } catch (e) {
      if (!silent) {
        setState(() {
          _errorMessage = 'メッセージの読み込みに失敗しました: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(String messageId) async {
    try {
      await _apiService.markAsRead(messageId);
      _loadReceivedMessages();
    } catch (e) {
      print('既読マークエラー: $e');
    }
  }

  // ソートされたメッセージのgetter
  List<Map<String, dynamic>> get _sortedMessages {
    final List<Map<String, dynamic>> sorted = List.from(_receivedMessages);
    
    if (_displayMode == 'list-asc') {
      // 古い順（日付の昇順）
      sorted.sort((a, b) {
        final dateA = a['createdAt'] != null ? DateTime.parse(a['createdAt']).millisecondsSinceEpoch : 0;
        final dateB = b['createdAt'] != null ? DateTime.parse(b['createdAt']).millisecondsSinceEpoch : 0;
        return dateA.compareTo(dateB);
      });
    } else {
      // 新しい順（日付の降順）- デフォルト
      sorted.sort((a, b) {
        final dateA = a['createdAt'] != null ? DateTime.parse(a['createdAt']).millisecondsSinceEpoch : 0;
        final dateB = b['createdAt'] != null ? DateTime.parse(b['createdAt']).millisecondsSinceEpoch : 0;
        return dateB.compareTo(dateA);
      });
    }
    
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return _buildPageContainer();
  }

  // Web版 PageContainer.vue equivalent
  Widget _buildPageContainer() {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // var(--background-primary) equivalent
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 32), // Web版: 32px 20px
          width: double.infinity,
          child: Column(
            children: [
              // Web版 PageTitle.vue equivalent
              _buildPageTitle(),
              const SizedBox(height: 32), // Web版: margin: 0 0 32px 0
              // Web版 InboxList.vue equivalent
              Expanded(child: _buildInboxContainer()),
            ],
          ),
        ),
      ),
    );
  }

  // Web版 PageTitle.vue equivalent (受信トレイ専用)
  Widget _buildPageTitle() {
    return Container(
      width: double.infinity,
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '受信トレイ',
              style: TextStyle(
                color: Color(0xFF1F2937), // var(--text-primary)
                fontSize: 24, // Web版と同じ
                fontWeight: FontWeight.w600,
                height: 1.5, // var(--line-height-base)
              ),
            ),
          ),
          if (_isRefreshing)
            Container(
              padding: const EdgeInsets.all(8),
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF3B82F6),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF3B82F6)),
              onPressed: () => _loadReceivedMessages(),
              tooltip: '更新',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF3B82F6),
                elevation: 2,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInboxContainer() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // 表示モード選択ドロップダウン
              if (_receivedMessages.isNotEmpty) _buildDisplayModeHeader(),
              
              // 認証初期化中の表示
              if (_isLoading && _receivedMessages.isEmpty) 
                _buildLoadingState()
              // エラー状態
              else if (_errorMessage != null)
                _buildErrorState()
              // 空の状態
              else if (_receivedMessages.isEmpty)
                _buildEmptyState()
              // 通常の一覧表示
              else
                Expanded(child: _buildContentView()),
            ],
          ),
          
          // メッセージ詳細モーダル（統一されたポップアップを使用するため無効化）
          // if (_selectedMessage != null) _buildMessageDetailModal(),
        ],
      ),
    );
  }

  // Web版 loading-state equivalent
  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(32), // Web版: 2rem
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: Color(0xFF3B82F6),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 16),
          Text(
            '読み込み中...',
            style: TextStyle(
              color: Color(0xFF6B7280), // Web版と同じ色
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // Web版 error-state equivalent
  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(32), // Web版: 2rem
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '❌ $_errorMessage',
            style: const TextStyle(
              color: Color(0xFFDC2626), // Web版: #dc2626
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadReceivedMessages(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Web版: 0.5rem 1rem
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6), // Web版と同じ
              ),
            ),
            child: const Text('再試行'),
          ),
        ],
      ),
    );
  }

  // Web版 empty-state equivalent
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32), // Web版: 2rem
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Color(0xFFE5E7EB),
          ),
          const SizedBox(height: 16),
          const Text(
            '受信メッセージがありません',
            style: TextStyle(
              color: Color(0xFF6B7280), // Web版と同じ色
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadReceivedMessages(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text('再読み込み'),
          ),
        ],
      ),
    );
  }

  // コンテンツビュー（リストまたはツリーマップ）
  Widget _buildContentView() {
    if (_displayMode == 'treemap') {
      return _buildTreemapView();
    } else {
      return _buildListView();
    }
  }

  // ツリーマップビュー
  Widget _buildTreemapView() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: _buildTreemapContent(),
    );
  }

  // ツリーマップコンテンツ
  Widget _buildTreemapContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // コンテナの利用可能なサイズを動的に計算
        final availableWidth = constraints.maxWidth - 32; // パディング考慮
        final availableHeight = constraints.maxHeight - 32; // パディング考慮
        
        return Container(
          width: availableWidth,
          height: availableHeight,
          child: TreemapWidget(
            messages: _receivedMessages,
            width: availableWidth,
            height: availableHeight,
            onMessageTap: (message) {
              // メッセージタップ時の処理
              final messageId = message['_id'] ?? message['id'];
              if (messageId != null && message['readAt'] == null) {
                _markAsRead(messageId);
              }
              _showMessageDetail(message);
            },
          ),
        );
      },
    );
  }

  // 送信者別メッセージ一覧モーダル
  void _showSenderMessagesModal(String senderName, List<Map<String, dynamic>> messages) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Color(0xFFF9FAFB),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // ハンドル
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF9CA3AF),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            
            // ヘッダー
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF3B82F6),
                    child: Text(
                      senderName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          senderName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${messages.length}件のメッセージ',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // メッセージ一覧
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: _buildMessageItem(message),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Web版 list-view equivalent
  Widget _buildListView() {
    final sortedMessages = _sortedMessages;
    
    return RefreshIndicator(
      onRefresh: () => _loadReceivedMessages(),
      color: const Color(0xFF3B82F6),
      child: ListView.builder(
        padding: const EdgeInsets.all(16), // Web版: 0 1rem 1rem 1rem
        itemCount: sortedMessages.length,
        itemBuilder: (context, index) {
          final message = sortedMessages[index];
          return _buildMessageItem(message);
        },
      ),
    );
  }

  // メッセージアイテムを構築するメソッド
  Widget _buildMessageItem(Map<String, dynamic> message) {
    final isRead = message['readAt'] != null;
    final rating = message['rating'] is int ? message['rating'] as int : 0;
    final senderName = message['sender']?['name'] ?? 
                      message['sender']?['email'] ?? 
                      message['from']?['name'] ?? 
                      message['from']?['email'] ?? 
                      message['fromEmail'] ?? 
                      message['senderName'] ?? 
                      message['senderEmail'] ?? 
                      '送信者不明';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isRead 
              ? const Color(0xFFE5E7EB).withOpacity(0.1)
              : const Color(0xFF10B981).withOpacity(0.3),
          width: isRead ? 1 : 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          print('📨 メッセージアイテムがタップされました');
          print('   メッセージID: ${message['_id']}');
          print('   既読状態: $isRead');
          
          if (!isRead && message['_id'] != null) {
            _markAsRead(message['_id']);
          }
          _showMessageDetail(message);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF3B82F6),
                        child: Text(
                          senderName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            senderName,
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatDate(message['createdAt']),
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!isRead)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '新着',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              // メッセージ内容（やんわり変換後のみ）
              if (message['transformedText'] != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'メッセージ:',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message['transformedText'],
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              
              // 評価
              if (rating > 0) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      '評価: ',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    ...List.generate(5, (index) {
                      return Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        size: 16,
                        color: index < rating 
                            ? const Color(0xFFFBBF24) 
                            : const Color(0xFF9CA3AF),
                      );
                    }),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // メッセージ詳細モーダルを構築するメソッド
  Widget _buildMessageDetailModal() {
    if (_selectedMessage == null) return const SizedBox.shrink();
    
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ハンドル
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9CA3AF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                // 送信者情報
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFF3B82F6),
                      child: Text(
                        (_selectedMessage!['sender']?['name'] ?? 
                         _selectedMessage!['sender']?['email'] ?? 
                         _selectedMessage!['from']?['name'] ?? 
                         _selectedMessage!['from']?['email'] ?? 
                         _selectedMessage!['fromEmail'] ?? 
                         _selectedMessage!['senderName'] ?? 
                         _selectedMessage!['senderEmail'] ?? '?')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedMessage!['sender']?['name'] ?? 
                            _selectedMessage!['sender']?['email'] ?? 
                            _selectedMessage!['from']?['name'] ?? 
                            _selectedMessage!['from']?['email'] ?? 
                            _selectedMessage!['fromEmail'] ?? 
                            _selectedMessage!['senderName'] ?? 
                            _selectedMessage!['senderEmail'] ?? '送信者不明',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatDate(_selectedMessage!['createdAt']),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _selectedMessage = null),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF3F4F6),
                        foregroundColor: const Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // メッセージ内容（やんわり変換後のみ）
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_selectedMessage!['transformedText'] != null) ...[
                          const Text(
                            '💌 受信したメッセージ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0369A1),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F9FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFBAE6FD)),
                            ),
                            child: Text(
                              _selectedMessage!['transformedText'],
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF374151),
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // メッセージ評価セクション
                          const Text(
                            '⭐ このメッセージを評価',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF059669),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'やんわりとした伝え方の効果はいかがでしたか？',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // 5段階評価UI
                          _buildRatingWidget(_selectedMessage!['rating'] is int ? _selectedMessage!['rating'] as int : 0),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // アクションボタン
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => setState(() => _selectedMessage = null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('閉じる'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMessageDetail(Map<String, dynamic> message) {
    final messageId = message['_id'] ?? message['id'];
    print('🔍 メッセージ詳細ポップアップを表示');
    print('   メッセージID: $messageId');
    print('   現在の評価: ${message['rating']}');
    print('   メッセージキー: ${message.keys.join(', ')}');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // モーダル内での現在の評価を取得（StatefulBuilder内で毎回計算）
          int getModalCurrentRating() {
            int rating = 0;
            if (message['rating'] is int) rating = message['rating'] as int;
            else if (message['userRating'] is int) rating = message['userRating'] as int;
            else if (message['messageRating'] is int) rating = message['messageRating'] as int;
            else if (message['ratingValue'] is int) rating = message['ratingValue'] as int;
            
            print('🌟 getModalCurrentRating(): $rating');
            print('   message[\'rating\']: ${message['rating']}');
            print('   message[\'userRating\']: ${message['userRating']}');
            return rating;
          }
          
          return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Color(0xFFF9FAFB),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ハンドル
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9CA3AF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                // 送信者情報
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFF3B82F6),
                      child: Text(
                        (message['sender']?['name'] ?? 
                         message['sender']?['email'] ?? 
                         message['from']?['name'] ?? 
                         message['from']?['email'] ?? 
                         message['fromEmail'] ?? 
                         message['senderName'] ?? 
                         message['senderEmail'] ?? '?')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message['sender']?['name'] ?? 
                            message['sender']?['email'] ?? 
                            message['from']?['name'] ?? 
                            message['from']?['email'] ?? 
                            message['fromEmail'] ?? 
                            message['senderName'] ?? 
                            message['senderEmail'] ?? '送信者不明',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatDate(message['createdAt']),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF3F4F6),
                        foregroundColor: const Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // メッセージ内容と評価
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // トーン変換後メッセージ
                        Builder(
                          builder: (context) {
                            // メッセージテキストを複数のフィールドから取得を試行
                            String? messageText = message['transformedText'] ?? 
                                                 message['finalText'] ?? 
                                                 message['message']?['transformedText'] ?? 
                                                 message['message']?['finalText'] ?? 
                                                 message['selectedToneText'] ?? 
                                                 message['text'] ?? 
                                                 message['content'] ?? 
                                                 message['body'];
                            
                            if (messageText != null && messageText.isNotEmpty) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                          const Text(
                            '💌 受信したメッセージ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0369A1),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F9FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFBAE6FD)),
                            ),
                            child: Text(
                              messageText,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF374151),
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // メッセージ評価セクション
                          const Text(
                            '⭐ このメッセージを評価',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF059669),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'やんわりとした伝え方の効果はいかがでしたか？',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // 5段階評価UI
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Column(
                              children: [
                                // 評価スターUI
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(5, (index) {
                                    final starIndex = index + 1;
                                    final currentRating = getModalCurrentRating();
                                    final isSelected = starIndex <= currentRating;
                                    
                                    return GestureDetector(
                                      onTap: () async {
                                        // 評価処理中は操作を無効にする
                                        if (message['isRatingInProgress'] == true) {
                                          print('⚠️ 評価処理中のため操作をスキップ');
                                          return;
                                        }
                                        
                                        print('⭐ 星$starIndex タップされました');
                                        // メッセージIDを確認（_id または id フィールド）
                                        final messageId = message['_id'] ?? message['id'];
                                        print('   メッセージID: $messageId');
                                        print('   現在の評価: ${message['rating']}');
                                        
                                        // 評価を更新
                                        await _rateMessageInModal(messageId, starIndex, message, setModalState);
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(4),
                                          color: message['isRatingInProgress'] == true 
                                            ? Colors.grey.withOpacity(0.1)
                                            : Colors.transparent,
                                        ),
                                        child: Icon(
                                          isSelected ? Icons.star : Icons.star_border,
                                          size: 36,
                                          color: message['isRatingInProgress'] == true
                                            ? const Color(0xFFD1D5DB).withOpacity(0.5)
                                            : (isSelected ? const Color(0xFFFBBF24) : const Color(0xFFD1D5DB)),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 12),
                                
                                // 評価説明テキスト
                                Text(
                                  message['isRatingInProgress'] == true 
                                    ? '評価を更新中...' 
                                    : _getRatingText(getModalCurrentRating()),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: message['isRatingInProgress'] == true 
                                      ? const Color(0xFF6B7280)
                                      : (getModalCurrentRating() > 0 ? const Color(0xFF059669) : const Color(0xFF6B7280)),
                                    fontWeight: message['isRatingInProgress'] == true 
                                      ? FontWeight.normal
                                      : (getModalCurrentRating() > 0 ? FontWeight.w600 : FontWeight.normal),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                                ],
                              );
                            } else {
                              // メッセージテキストがない場合の表示
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE5E7EB)),
                                    ),
                                    child: Column(
                                      children: [
                                        const Icon(
                                          Icons.message_outlined,
                                          size: 48,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'メッセージ内容を読み込み中...',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'デバッグ情報: ${message.keys.join(', ')}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // メッセージがない場合も評価セクションを表示
                                  const Text(
                                    '⭐ このメッセージを評価',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF059669),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'やんわりとした伝え方の効果はいかがでしたか？',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // 5段階評価UI
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE5E7EB)),
                                    ),
                                    child: Column(
                                      children: [
                                        // 評価スターUI
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: List.generate(5, (index) {
                                            final starIndex = index + 1;
                                            final currentRating = getModalCurrentRating();
                                            final isSelected = starIndex <= currentRating;
                                            
                                            return GestureDetector(
                                              onTap: () async {
                                                // 評価処理中は操作を無効にする
                                                if (message['isRatingInProgress'] == true) {
                                                  print('⚠️ 評価処理中のため操作をスキップ');
                                                  return;
                                                }
                                                
                                                print('⭐ 星$starIndex タップされました (内容なしセクション)');
                                                // メッセージIDを確認（_id または id フィールド）
                                                final messageId = message['_id'] ?? message['id'];
                                                print('   メッセージID: $messageId');
                                                print('   現在の評価: ${message['rating']}');
                                                
                                                // 評価を更新
                                                await _rateMessageInModal(messageId, starIndex, message, setModalState);
                                              },
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 200),
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(4),
                                                  color: message['isRatingInProgress'] == true 
                                                    ? Colors.grey.withOpacity(0.1)
                                                    : Colors.transparent,
                                                ),
                                                child: Icon(
                                                  isSelected ? Icons.star : Icons.star_border,
                                                  size: 36,
                                                  color: message['isRatingInProgress'] == true
                                                    ? const Color(0xFFD1D5DB).withOpacity(0.5)
                                                    : (isSelected ? const Color(0xFFFBBF24) : const Color(0xFFD1D5DB)),
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                        const SizedBox(height: 12),
                                        
                                        // 評価説明テキスト
                                        Text(
                                          message['isRatingInProgress'] == true 
                                            ? '評価を更新中...' 
                                            : _getRatingText(getModalCurrentRating()),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: message['isRatingInProgress'] == true 
                                              ? const Color(0xFF6B7280)
                                              : (getModalCurrentRating() > 0 ? const Color(0xFF059669) : const Color(0xFF6B7280)),
                                            fontWeight: message['isRatingInProgress'] == true 
                                              ? FontWeight.normal
                                              : (getModalCurrentRating() > 0 ? FontWeight.w600 : FontWeight.normal),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                // アクションボタン
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('閉じる'),
                  ),
                ),
              ],
            ),
          ),
        );
        },
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    
    try {
      final date = DateTime.parse(dateString).toLocal();
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}分前';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}時間前';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}日前';
      } else {
        return '${date.month}/${date.day}';
      }
    } catch (e) {
      return '';
    }
  }

  // 表示モード選択ドロップダウンヘッダー
  Widget _buildDisplayModeHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '受信メッセージ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD1D5DB), width: 2),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: DropdownButton<String>(
              value: _displayMode,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, size: 20, color: Color(0xFF6B7280)),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w500,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'list-desc', 
                  child: Text('一覧（新しい順）')
                ),
                DropdownMenuItem(
                  value: 'list-asc', 
                  child: Text('一覧（古い順）')
                ),
                DropdownMenuItem(
                  value: 'treemap', 
                  child: Text('ツリーマップ表示')
                ),
              ],
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _displayMode = value;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // 5段階評価ウィジェット
  Widget _buildRatingWidget(int currentRating) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          // 評価スターUI
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              final isSelected = starIndex <= currentRating;
              
              return GestureDetector(
                onTap: () => _rateMessage(starIndex),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    isSelected ? Icons.star : Icons.star_border,
                    size: 36,
                    color: isSelected ? const Color(0xFFFBBF24) : const Color(0xFFD1D5DB),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          
          // 評価説明テキスト
          Text(
            _getRatingText(currentRating),
            style: TextStyle(
              fontSize: 14,
              color: currentRating > 0 ? const Color(0xFF059669) : const Color(0xFF6B7280),
              fontWeight: currentRating > 0 ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 評価に応じたテキストを取得
  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return '😔 あまり良くなかった';
      case 2:
        return '🙁 少し物足りなかった';
      case 3:
        return '😐 普通だった';
      case 4:
        return '😊 良かった';
      case 5:
        return '🤗 とても良かった';
      default:
        return 'タップして評価してください';
    }
  }

  // モーダル内でのメッセージ評価機能
  Future<void> _rateMessageInModal(String? messageId, int rating, Map<String, dynamic> message, StateSetter setModalState) async {
    if (messageId == null || messageId.isEmpty) {
      print('❌ メッセージIDがnullまたは空です: messageId=$messageId');
      return;
    }
    
    // 評価処理中の状態を設定
    setModalState(() {
      message['isRatingInProgress'] = true;
    });
    
    try {
      print('⭐ 評価処理開始: messageId=$messageId, rating=$rating, currentRating=${message['rating']}');
      
      // バックエンドAPIを呼び出して評価を登録
      final response = await _apiService.rateMessage(messageId, rating);
      print('⭐ 評価API応答: $response');
      
      // ローカル状態を更新（モーダル内とメインリスト両方）
      setModalState(() {
        message['rating'] = rating;
        message['isRatingInProgress'] = false;
      });
      
      setState(() {
        // メッセージリスト内の対応するメッセージも更新
        for (int i = 0; i < _receivedMessages.length; i++) {
          if (_receivedMessages[i]['_id'] == messageId) {
            _receivedMessages[i]['rating'] = rating;
            break;
          }
        }
      });
      
      // 成功メッセージを表示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('評価を${rating}星で登録しました'),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      print('評価完了: messageId=$messageId, rating=$rating');
    } catch (e) {
      print('❌ 評価処理エラー: $e');
      
      // エラー時は処理中状態をリセット
      setModalState(() {
        message['isRatingInProgress'] = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('評価の登録に失敗しました'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // メッセージ評価機能
  Future<void> _rateMessage(int rating) async {
    if (_selectedMessage == null || _selectedMessage!['_id'] == null) return;
    
    try {
      // 評価APIを呼び出し（APIServiceにrateMessageメソッドが必要）
      // await _apiService.rateMessage(_selectedMessage!['_id'], rating);
      
      // 一時的にローカル状態のみ更新（API実装後に上記のコメントを外す）
      setState(() {
        _selectedMessage!['rating'] = rating;
        
        // メッセージリスト内の対応するメッセージも更新
        for (int i = 0; i < _receivedMessages.length; i++) {
          if (_receivedMessages[i]['_id'] == _selectedMessage!['_id']) {
            _receivedMessages[i]['rating'] = rating;
            break;
          }
        }
      });
      
      // 成功メッセージを表示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('評価を${rating}星で登録しました'),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('評価エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('評価の登録に失敗しました'),
            backgroundColor: Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}