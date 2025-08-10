import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../services/auth_service.dart';
import '../services/api_service.dart';

class ScheduleOnlyScreen extends StatefulWidget {
  const ScheduleOnlyScreen({super.key});

  @override
  State<ScheduleOnlyScreen> createState() => _ScheduleOnlyScreenState();
}

class _ScheduleOnlyScreenState extends State<ScheduleOnlyScreen> 
    with SingleTickerProviderStateMixin {
  late final ApiService _apiService;
  late TabController _tabController;
  
  // 送信予定メッセージ
  List<Map<String, dynamic>> _scheduledMessages = [];
  // 送信済みメッセージ
  List<Map<String, dynamic>> _sentMessages = [];
  
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  String _displayMode = 'list-desc'; // list-desc, list-asc
  Map<String, dynamic>? _selectedMessage;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(context.read<AuthService>());
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          // タブが変更された時に再描画
        });
      }
    });
    _loadAllMessages();
    _startPeriodicUpdate();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startPeriodicUpdate() {
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !_isLoading) {
        _loadAllMessages(silent: true);
      }
    });
  }

  Future<void> _loadAllMessages({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      print('=== Loading messages from API ===');
      // 並行して送信予定と送信済みのAPIを呼び出す
      final results = await Future.wait([
        _apiService.getScheduledMessages(), // 送信予定メッセージ
        _apiService.getSentMessages(),      // 送信済みメッセージ
      ]);
      
      print('=== API Response Debug ===');
      print('Scheduled response: ${results[0]}');
      print('Sent response: ${results[1]}');

      setState(() {
        // 送信予定メッセージ
        _scheduledMessages = <Map<String, dynamic>>[];
        if (results[0] != null && results[0] is Map<String, dynamic>) {
          final result0 = results[0] as Map<String, dynamic>;
          List<dynamic>? schedulesList;
          if (result0['data'] is Map && (result0['data'] as Map)['schedules'] is List) {
            schedulesList = (result0['data'] as Map)['schedules'] as List<dynamic>;
          } else if (result0['schedules'] is List) {
            schedulesList = result0['schedules'] as List<dynamic>;
          }
          if (schedulesList != null) {
            print('Found ${schedulesList.length} scheduled messages');
            for (var schedule in schedulesList) {
              if (schedule is Map<String, dynamic>) {
                print('Schedule item structure: $schedule');
                _scheduledMessages.add(schedule);
              }
            }
          } else {
            print('No scheduled messages found in response');
          }
        }

        // 送信済みメッセージ
        _sentMessages = <Map<String, dynamic>>[];
        if (results[1] != null && results[1] is Map<String, dynamic>) {
          final result1 = results[1] as Map<String, dynamic>;
          List<dynamic>? sentList;
          if (result1['data'] is Map && (result1['data'] as Map)['messages'] is List) {
            sentList = (result1['data'] as Map)['messages'] as List<dynamic>;
          } else if (result1['messages'] is List) {
            sentList = result1['messages'] as List<dynamic>;
          }
          if (sentList != null) {
            print('Found ${sentList.length} sent messages');
            for (var msg in sentList) {
              if (msg is Map<String, dynamic>) {
                print('Sent message structure: $msg');
                _sentMessages.add(msg);
              }
            }
          } else {
            print('No sent messages found in response');
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
      _loadAllMessages();
    } catch (e) {
      print('既読マークエラー: $e');
    }
  }

  // 現在のタブに応じたメッセージリストを取得
  List<Map<String, dynamic>> get _currentMessages {
    switch (_tabController.index) {
      case 0:
        return _scheduledMessages;
      case 1:
        return _sentMessages;
      default:
        return [];
    }
  }

  // ソートされたメッセージのgetter
  List<Map<String, dynamic>> get _sortedMessages {
    final List<Map<String, dynamic>> sorted = List.from(_currentMessages);
    
    if (_displayMode == 'list-asc') {
      // 古い順（日付の昇順）
      sorted.sort((a, b) {
        // タブに応じて適切な日付フィールドを使用
        String dateFieldA = _tabController.index == 0 ? 'scheduledAt' : 'sentAt';
        String dateFieldB = _tabController.index == 0 ? 'scheduledAt' : 'sentAt';
        
        final dateA = a[dateFieldA] != null ? DateTime.parse(a[dateFieldA]).millisecondsSinceEpoch : 0;
        final dateB = b[dateFieldB] != null ? DateTime.parse(b[dateFieldB]).millisecondsSinceEpoch : 0;
        return dateA.compareTo(dateB);
      });
    } else {
      // 新しい順（日付の降順）- デフォルト
      sorted.sort((a, b) {
        // タブに応じて適切な日付フィールドを使用
        String dateFieldA = _tabController.index == 0 ? 'scheduledAt' : 'sentAt';
        String dateFieldB = _tabController.index == 0 ? 'scheduledAt' : 'sentAt';
        
        final dateA = a[dateFieldA] != null ? DateTime.parse(a[dateFieldA]).millisecondsSinceEpoch : 0;
        final dateB = b[dateFieldB] != null ? DateTime.parse(b[dateFieldB]).millisecondsSinceEpoch : 0;
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
              Expanded(child: _buildInboxList()),
            ],
          ),
        ),
      ),
    );
  }

  // Web版 PageTitle.vue equivalent with Tabs
  Widget _buildPageTitle() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'メッセージ予定',
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
                  onPressed: () => _loadAllMessages(),
                  tooltip: '更新',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF3B82F6),
                    elevation: 2,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // タブバー
        Container(
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
          child: TabBar(
            controller: _tabController,
            onTap: (_) => setState(() {
              _selectedMessage = null;
            }),
            indicator: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(8),
            ),
            indicatorPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFF6B7280),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.schedule, size: 18),
                    const SizedBox(width: 8),
                    const Text('送信予定'),
                    if (_scheduledMessages.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _tabController.index == 0 ? Colors.white.withOpacity(0.3) : const Color(0xFFFFA726).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_scheduledMessages.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _tabController.index == 0 ? Colors.white : const Color(0xFFFFA726),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.send, size: 18),
                    const SizedBox(width: 8),
                    const Text('送信済み'),
                    if (_sentMessages.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _tabController.index == 1 ? Colors.white.withOpacity(0.3) : const Color(0xFF66BB6A).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_sentMessages.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _tabController.index == 1 ? Colors.white : const Color(0xFF66BB6A),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Web版 InboxList.vue equivalent with Tabs
  Widget _buildInboxList() {
    return Expanded(
      child: TabBarView(
        controller: _tabController,
        children: [
          // 送信予定タブ
          _buildTabContent(_scheduledMessages, '送信予定'),
          // 送信済みタブ
          _buildTabContent(_sentMessages, '送信済み'),
        ],
      ),
    );
  }

  Widget _buildTabContent(List<Map<String, dynamic>> messages, String title) {
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
              if (messages.isNotEmpty) _buildDisplayModeHeader(),
              
              // 認証初期化中の表示
              if (_isLoading && messages.isEmpty) 
                _buildLoadingState()
              // エラー状態
              else if (_errorMessage != null)
                _buildErrorState()
              // 空の状態
              else if (messages.isEmpty)
                _buildEmptyState(title)
              // 通常の一覧表示
              else
                Expanded(child: _buildListView()),
            ],
          ),
          
          // メッセージ詳細モーダル
          if (_selectedMessage != null) _buildMessageDetailModal(),
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
            onPressed: () => _loadAllMessages(),
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
  Widget _buildEmptyState(String title) {
    String emptyMessage;
    IconData emptyIcon;
    
    switch (_tabController.index) {
      case 0:
        emptyMessage = '送信予定のメッセージがありません';
        emptyIcon = Icons.schedule_outlined;
        break;
      case 1:
        emptyMessage = '送信済みメッセージがありません';
        emptyIcon = Icons.send_outlined;
        break;
      default:
        emptyMessage = 'メッセージがありません';
        emptyIcon = Icons.message_outlined;
    }
    
    return Container(
      padding: const EdgeInsets.all(32), // Web版: 2rem
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            emptyIcon,
            size: 64,
            color: const Color(0xFFE5E7EB),
          ),
          const SizedBox(height: 16),
          Text(
            emptyMessage,
            style: const TextStyle(
              color: Color(0xFF6B7280), // Web版と同じ色
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadAllMessages(),
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

  // Web版 list-view equivalent
  Widget _buildListView() {
    final sortedMessages = _sortedMessages;
    
    return RefreshIndicator(
      onRefresh: () => _loadAllMessages(),
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
    
    // デバッグ: メッセージの構造を確認
    print('Message structure for ${_tabController.index == 0 ? "scheduled" : "sent"}: $message');
    
    // 送信予定か送信済みかでレシピエント名を取得
    String recipientName = '受信者不明';
    if (_tabController.index == 0) {
      // 送信予定の場合 - スケジュールデータから取得
      // スケジュールAPIは message フィールドにメッセージ情報を含む
      final messageData = message['message'] as Map<String, dynamic>?;
      recipientName = messageData?['recipient_info']?['name'] ?? 
                     messageData?['recipient_info']?['email'] ?? 
                     messageData?['recipient_email'] ?? 
                     message['recipientName'] ?? 
                     message['recipientEmail'] ?? 
                     message['recipient']?['name'] ?? 
                     message['recipient']?['email'] ?? 
                     '受信者不明';
      print('Scheduled recipient: $recipientName');
    } else {
      // 送信済みの場合 - メッセージデータから取得
      recipientName = message['recipient_info']?['name'] ?? 
                     message['recipient_info']?['email'] ?? 
                     message['recipient_email'] ?? 
                     message['recipient']?['name'] ?? 
                     message['recipient']?['email'] ?? 
                     message['recipientName'] ?? 
                     message['recipientEmail'] ?? 
                     message['to']?['name'] ?? 
                     message['to']?['email'] ?? 
                     message['toEmail'] ?? 
                     '受信者不明';
      print('Sent recipient: $recipientName');
    }
    
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
          color: _tabController.index == 0 
              ? const Color(0xFFFFA726).withOpacity(0.3) // 送信予定はオレンジ
              : (isRead 
                  ? const Color(0xFFE5E7EB).withOpacity(0.1)
                  : const Color(0xFF66BB6A).withOpacity(0.3)), // 送信済みは緑
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMessage = message;
          });
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
                        backgroundColor: _tabController.index == 0 
                            ? const Color(0xFFFFA726) 
                            : const Color(0xFF66BB6A),
                        child: Text(
                          recipientName.substring(0, 1).toUpperCase(),
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
                            recipientName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatDate(_tabController.index == 0 ? message['scheduledAt'] : message['sentAt']),
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isRead && _tabController.index == 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF66BB6A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '既読',
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
              
              // メッセージ内容プレビュー（トーン変換後のみ）
              Builder(
                builder: (context) {
                  // メッセージテキストを複数のフィールドから取得を試行
                  String? messageText;
                  
                  if (_tabController.index == 0) {
                    // 送信予定: messageフィールド内を探す
                    final msgData = message['message'] as Map<String, dynamic>?;
                    messageText = msgData?['transformed_text'] ?? 
                                 msgData?['final_text'] ?? 
                                 msgData?['original_text'] ?? 
                                 message['finalText'] ?? 
                                 message['transformedText'] ?? 
                                 message['text'];
                  } else {
                    // 送信済み: 直接フィールドを探す
                    messageText = message['transformed_text'] ?? 
                                 message['final_text'] ?? 
                                 message['original_text'] ?? 
                                 message['finalText'] ?? 
                                 message['transformedText'] ?? 
                                 message['text'];
                  }
                  
                  if (messageText != null && messageText.length > 50) {
                    print('Message text found: ${messageText.substring(0, 50)}...');
                  } else {
                    print('Message text found: $messageText');
                  }
                  
                  if (messageText != null && messageText.isNotEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _tabController.index == 0 
                            ? const Color(0xFFFFF3E0) // 送信予定は薄いオレンジ
                            : const Color(0xFFF0F9FF), // 送信済みは薄い青
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'やんわり変換後:',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            messageText,
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Color(0xFF9CA3AF)),
                          SizedBox(width: 8),
                          Text(
                            'メッセージを読み込み中...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
              
              // 評価（送信済みの場合のみ）
              if (_tabController.index == 1 && rating > 0) ...[
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
                
                // 受信者情報
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: _tabController.index == 0 
                          ? const Color(0xFFFFA726) 
                          : const Color(0xFF66BB6A),
                      child: Text(
                        (_selectedMessage!['recipientName']?.substring(0, 1) ?? 
                         _selectedMessage!['recipientEmail']?.substring(0, 1) ?? 
                         _selectedMessage!['recipient']?['name']?.substring(0, 1) ?? 
                         _selectedMessage!['recipient']?['email']?.substring(0, 1) ?? 
                         _selectedMessage!['message']?['recipient']?['name']?.substring(0, 1) ?? 
                         _selectedMessage!['message']?['recipient']?['email']?.substring(0, 1) ?? 
                         _selectedMessage!['to']?['name']?.substring(0, 1) ?? 
                         _selectedMessage!['to']?['email']?.substring(0, 1) ?? 
                         _selectedMessage!['toEmail']?.substring(0, 1) ?? '?')
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
                            _selectedMessage!['recipientName'] ?? 
                            _selectedMessage!['recipientEmail'] ?? 
                            _selectedMessage!['recipient']?['name'] ?? 
                            _selectedMessage!['recipient']?['email'] ?? 
                            _selectedMessage!['message']?['recipient']?['name'] ?? 
                            _selectedMessage!['message']?['recipient']?['email'] ?? 
                            _selectedMessage!['to']?['name'] ?? 
                            _selectedMessage!['to']?['email'] ?? 
                            _selectedMessage!['toEmail'] ?? '受信者不明',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatDate(_tabController.index == 0 ? _selectedMessage!['scheduledAt'] : _selectedMessage!['sentAt']),
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
                        Builder(
                          builder: (context) {
                            // メッセージテキストを複数のフィールドから取得を試行
                            String? messageText = _selectedMessage!['finalText'] ?? 
                                                 _selectedMessage!['transformedText'] ?? 
                                                 _selectedMessage!['message']?['finalText'] ?? 
                                                 _selectedMessage!['message']?['transformedText'] ?? 
                                                 _selectedMessage!['selectedToneText'] ?? 
                                                 _selectedMessage!['text'] ?? 
                                                 _selectedMessage!['content'];
                            
                            if (messageText != null && messageText.isNotEmpty) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                          Text(
                            _tabController.index == 0 ? '📅 送信予定メッセージ' : '✨ やんわり変換後',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _tabController.index == 0 
                                  ? const Color(0xFFFF8F00) 
                                  : const Color(0xFF0369A1),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _tabController.index == 0 
                                  ? const Color(0xFFFFF3E0)
                                  : const Color(0xFFF0F9FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _tabController.index == 0 
                                    ? const Color(0xFFFFCC80)
                                    : const Color(0xFFBAE6FD)
                              ),
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
                                ],
                              );
                            } else {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                          // やんわり変換後メッセージがない場合の表示
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.message_outlined,
                                  size: 48,
                                  color: Color(0xFF9CA3AF),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'メッセージ内容がありません',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF6B7280),
                                  ),
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
                    onPressed: () => setState(() => _selectedMessage = null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _tabController.index == 0 
                          ? const Color(0xFFFFA726) 
                          : const Color(0xFF66BB6A),
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
    // 同じモーダル表示ロジックを使用
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    
    try {
      final date = DateTime.parse(dateString).toLocal();
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inMinutes < 60) {
        if (difference.inMinutes < 0) {
          return '${(-difference.inMinutes)}分後';
        }
        return '${difference.inMinutes}分前';
      } else if (difference.inHours < 24) {
        if (difference.inHours < 0) {
          return '${(-difference.inHours)}時間後';
        }
        return '${difference.inHours}時間前';
      } else if (difference.inDays < 7) {
        if (difference.inDays < 0) {
          return '${(-difference.inDays)}日後';
        }
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
    String headerTitle;
    switch (_tabController.index) {
      case 0:
        headerTitle = '送信予定';
        break;
      case 1:
        headerTitle = '送信済み';
        break;
      default:
        headerTitle = 'メッセージ';
    }
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            headerTitle,
            style: const TextStyle(
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
}