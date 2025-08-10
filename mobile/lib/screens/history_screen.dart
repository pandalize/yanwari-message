import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/design_system.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with TickerProviderStateMixin {
  late ApiService _apiService;
  late TabController _tabController;
  
  bool _isLoading = false;
  String _searchQuery = '';
  bool _sortAscending = false;
  
  List<Map<String, dynamic>> _scheduledMessages = [];
  List<Map<String, dynamic>> _sentMessages = [];
  
  // 詳細モーダル用
  Map<String, dynamic>? _selectedMessage;
  bool _showDetailModal = false;
  bool _isLoadingDetail = false;
  String _detailError = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    try {
      final authService = context.read<AuthService>();
      _apiService = ApiService(authService);
      _loadData();
    } catch (e) {
      print('HistoryScreen初期化エラー: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadScheduledMessages(),
        _loadSentMessages(),
      ]);
    } catch (e) {
      print('データ読み込みエラー: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadScheduledMessages() async {
    print('🔄 [History] 送信予定メッセージを読み込み中...');
    
    // 現在のユーザー情報を確認
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;
    print('🔄 [History] 現在のログインユーザー: ${currentUser?.email} (UID: ${currentUser?.uid})');
    
    try {
      final response = await _apiService.getSchedules();
      
      if (response['data'] != null && response['data']['schedules'] != null) {
        final schedules = response['data']['schedules'] as List;
        print('🔄 [History] 取得したスケジュール数: ${schedules.length}');
        
        List<Map<String, dynamic>> scheduledList = [];
        
        for (var schedule in schedules) {
          // メッセージの詳細を取得
          try {
            final messageResponse = await _apiService.getMessage(schedule['messageId']);
            final message = messageResponse['data'];
            
            // 配信済みメッセージのログを出力するが、表示は継続
            if (message != null && ['sent', 'delivered', 'read'].contains(message['status'])) {
              print('⚠️ スケジュール ${schedule['id']} は既に配信済み (${message['status']}) ですが、一覧に表示します');
              // continue; // コメントアウトして表示を継続
            }
            
            String recipientName = 'Unknown User';
            String recipientEmail = 'unknown@example.com';
            
            // 受信者情報を取得
            if (message != null && message['recipientId'] != null) {
              try {
                final userResponse = await _apiService.getUser(message['recipientId']);
                final userData = userResponse['data'];
                if (userData != null) {
                  recipientName = userData['name'] ?? userData['email'] ?? 'Unknown User';
                  recipientEmail = userData['email'] ?? 'unknown@example.com';
                  print('🔄 [History] 受信者情報取得成功: $recipientName ($recipientEmail)');
                } else {
                  print('⚠️ [History] 受信者データが空: ${message['recipientId']}');
                }
              } catch (e) {
                print('⚠️ [History] 受信者情報取得エラー: $e');
                // エラー時はデフォルト値を使用
              }
            }
            
            scheduledList.add({
              'id': schedule['id'],
              'messageId': schedule['messageId'],
              'recipientName': recipientName,
              'recipientEmail': recipientEmail,
              'scheduledAt': _parseDateTime(schedule['scheduledAt']),
              'status': 'scheduled',
              'originalText': message?['originalText'] ?? 'スケジュールされたメッセージ',
              'finalText': message?['finalText'] ?? message?['originalText'] ?? 'スケジュールされたメッセージ',
              'selectedTone': message?['selectedTone'] ?? 'gentle',
            });
          } catch (e) {
            print('⚠️ メッセージ詳細取得エラー: $e');
            // エラー時もスケジュール情報は表示（スケジュール基本情報から）
            scheduledList.add({
              'id': schedule['id'],
              'messageId': schedule['messageId'],
              'recipientName': 'スケジュール${schedule['id'].toString().length > 8 ? schedule['id'].toString().substring(0,8) + '...' : schedule['id'].toString()}',
              'recipientEmail': 'scheduled@example.com',
              'scheduledAt': _parseDateTime(schedule['scheduledAt']),
              'status': 'scheduled',
              'originalText': 'エラー時のスケジュール表示',
              'finalText': '${_formatDateTime(_parseDateTime(schedule['scheduledAt']))}に送信予定',
              'selectedTone': 'gentle',
            });
            print('✅ エラー時スケジュール追加: ${schedule['id']}');
          }
        }
        
        setState(() {
          _scheduledMessages = scheduledList;
        });
        
        print('✅ [History] 送信予定メッセージ読み込み完了: ${_scheduledMessages.length}件');
        print('✅ [History] スケジュール詳細: ${_scheduledMessages.map((s) => "${s['id']}: ${s['recipientName']} - ${s['finalText']?.length != null && s['finalText'].length > 30 ? s['finalText'].substring(0, 30) + '...' : s['finalText']}")}');
      }
    } catch (e) {
      print('送信予定メッセージ取得エラー: $e');
      setState(() {
        _scheduledMessages = [];
      });
    }
  }

  Future<void> _loadSentMessages() async {
    print('🔄 [History] 送信済みメッセージを読み込み中...');
    try {
      final response = await _apiService.getSentMessages();
      
      if (response != null && response['data'] != null && response['data']['messages'] != null) {
        final messages = response['data']['messages'] as List;
        print('🔄 [History] 取得した送信済みメッセージ数: ${messages.length}');
        
        List<Map<String, dynamic>> sentList = [];
        
        for (var message in messages) {
          String recipientName = 'Unknown User';
          String recipientEmail = 'unknown@example.com';
          
          // 受信者情報を取得（簡略化）
          if (message['recipientId'] != null) {
            // TODO: 実際の受信者情報取得API実装
            recipientName = 'Recipient';
            recipientEmail = 'recipient@example.com';
          }
          
          sentList.add({
            'id': message['id'],
            'recipientName': recipientName,
            'recipientEmail': recipientEmail,
            'sentAt': _parseDateTime(message['sentAt'] ?? message['updatedAt']),
            'isRead': message['status'] == 'read',
            'status': message['status'],
            'originalText': message['originalText'] ?? 'メッセージ',
            'finalText': message['finalText'] ?? message['originalText'] ?? 'メッセージ',
            'selectedTone': message['selectedTone'] ?? 'gentle',
          });
        }
        
        setState(() {
          _sentMessages = sentList;
        });
        
        print('🔄 [History] 送信済みメッセージ読み込み完了: ${_sentMessages.length}件');
      }
    } catch (e) {
      print('送信済みメッセージ取得エラー: $e');
      setState(() {
        _sentMessages = [];
      });
    }
  }

  List<Map<String, dynamic>> get _filteredScheduledMessages {
    var filtered = _scheduledMessages.where((msg) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return (msg['recipientName'] as String).toLowerCase().contains(query) ||
             (msg['recipientEmail'] as String).toLowerCase().contains(query);
    }).toList();
    
    filtered.sort((a, b) {
      final dateA = a['scheduledAt'] as DateTime;
      final dateB = b['scheduledAt'] as DateTime;
      return _sortAscending 
          ? dateA.compareTo(dateB)
          : dateB.compareTo(dateA);
    });
    
    return filtered;
  }

  List<Map<String, dynamic>> get _filteredSentMessages {
    var filtered = _sentMessages.where((msg) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return (msg['recipientName'] as String).toLowerCase().contains(query) ||
             (msg['recipientEmail'] as String).toLowerCase().contains(query);
    }).toList();
    
    filtered.sort((a, b) {
      final dateA = a['sentAt'] as DateTime;
      final dateB = b['sentAt'] as DateTime;
      return _sortAscending 
          ? dateA.compareTo(dateB)
          : dateB.compareTo(dateA);
    });
    
    return filtered;
  }

  DateTime _parseDateTime(String dateTimeString) {
    try {
      // Parse the datetime string (handles both UTC and timezone-aware formats)
      final parsedDateTime = DateTime.parse(dateTimeString);
      
      // Always convert to local for consistent handling
      final localDateTime = parsedDateTime.isUtc ? parsedDateTime.toLocal() : parsedDateTime;
      
      // Log timezone info for debugging (similar to web version)
      print('🕐 [DateTime] Parsing: "$dateTimeString" → Local: ${localDateTime.toString()}');
      
      return localDateTime;
    } catch (e) {
      print('⚠️ DateTime parsing error for "$dateTimeString": $e');
      // Fallback to current time if parsing fails
      return DateTime.now();
    }
  }

  String _formatDateTime(DateTime dateTime) {
    // Convert to local timezone for consistent display
    final localDateTime = dateTime.toLocal();
    return DateFormat('MM/dd/yyyy HH:mm').format(localDateTime);
  }

  String _getStatusLabel(String status) {
    const labels = {
      'scheduled': '送信予定',
      'sent': '送信済み',
      'delivered': '送信済み',
      'read': '既読',
      'draft': '下書き',
    };
    return labels[status] ?? status;
  }

  String _getToneLabel(String tone) {
    const labels = {
      'gentle': 'やんわり',
      'constructive': '建設的',
      'casual': 'カジュアル',
    };
    return labels[tone] ?? tone;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.orange;
      case 'sent':
      case 'delivered':
        return YanwariDesignSystem.secondaryColor;
      case 'read':
        return YanwariDesignSystem.successColor;
      default:
        return Colors.grey;
    }
  }

  Future<void> _editMessage(String scheduleId) async {
    print('📝 編集ボタンがクリックされました: $scheduleId');
    
    final schedule = _scheduledMessages.firstWhere(
      (s) => s['id'] == scheduleId,
      orElse: () => {},
    );
    
    if (schedule.isEmpty || schedule['messageId'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('編集対象のメッセージが見つかりません')),
      );
      return;
    }
    
    try {
      // メッセージ作成画面に遷移
      Navigator.pushNamed(
        context,
        '/message-compose',
        arguments: {
          'editId': scheduleId,
          'originalText': schedule['originalText'] ?? '',
          'recipientEmail': schedule['recipientEmail'] ?? '',
          'recipientName': schedule['recipientName'] ?? '',
          'editScheduleId': scheduleId,
        },
      );
    } catch (error) {
      print('メッセージ編集準備エラー: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メッセージの編集準備に失敗しました')),
      );
    }
  }

  Future<void> _cancelSchedule(String scheduleId) async {
    print('🗑️ キャンセルボタンがクリックされました: $scheduleId');
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('スケジュールキャンセル'),
        content: const Text('このスケジュールをキャンセルしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('いいえ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: YanwariDesignSystem.errorColor,
            ),
            child: const Text('はい'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      await _apiService.deleteSchedule(scheduleId);
      await _loadScheduledMessages();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('スケジュールをキャンセルしました'),
            backgroundColor: YanwariDesignSystem.successColor,
          ),
        );
      }
    } catch (error) {
      print('スケジュールキャンセルエラー: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('スケジュールのキャンセルに失敗しました'),
            backgroundColor: YanwariDesignSystem.errorColor,
          ),
        );
      }
    }
  }

  void _showMessageDetail(Map<String, dynamic> message) {
    setState(() {
      _selectedMessage = message;
      _showDetailModal = true;
      _detailError = '';
    });
  }

  void _closeDetailModal() {
    setState(() {
      _showDetailModal = false;
      _selectedMessage = null;
      _detailError = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YanwariDesignSystem.backgroundPrimary,
      appBar: AppBar(
        title: const Text(
          '送信履歴',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: '更新',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '送信予定'),
            Tab(text: '送信済み'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 検索バー
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: '検索',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _sortAscending = !_sortAscending;
                      });
                    },
                    icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                    tooltip: '順番切替',
                  ),
                ],
              ),
            ),
            
            // タブビュー
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 送信予定タブ
                  _buildScheduledMessagesTab(),
                  
                  // 送信済みタブ
                  _buildSentMessagesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      
      // 詳細モーダル
      bottomSheet: _showDetailModal ? _buildDetailModal() : null,
    );
  }

  Widget _buildScheduledMessagesTab() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 16),
            Text('読み込み中...', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }
    
    final filteredMessages = _filteredScheduledMessages;
    
    print('🔍 [UI] フィルタリング済み送信予定メッセージ数: ${filteredMessages.length}');
    print('🔍 [UI] 元データ数: ${_scheduledMessages.length}');
    
    if (filteredMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.schedule, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _scheduledMessages.isEmpty 
                ? '送信予定のメッセージはありません\n(データ取得数: ${_scheduledMessages.length})'
                : '検索条件に一致する送信予定がありません\n(全データ数: ${_scheduledMessages.length})',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('更新'),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredMessages.length,
      itemBuilder: (context, index) {
        final message = filteredMessages[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _showMessageDetail(message),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ヘッダー
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          message['recipientName'] ?? '不明',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(message['status']).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusLabel(message['status']),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(message['status']),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // 送信時刻
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.grey.shade600, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateTime(message['scheduledAt']),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      
                      // アクションボタン
                      TextButton(
                        onPressed: () => _editMessage(message['id']),
                        child: const Text('編集', style: TextStyle(color: Colors.blue)),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => _cancelSchedule(message['id']),
                        child: const Text('キャンセル', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSentMessagesTab() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 16),
            Text('読み込み中...', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }
    
    final filteredMessages = _filteredSentMessages;
    
    if (filteredMessages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '送信済みのメッセージはありません',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredMessages.length,
      itemBuilder: (context, index) {
        final message = filteredMessages[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _showMessageDetail(message),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ヘッダー
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          message['recipientName'] ?? '不明',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (message['isRead'] == true)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: YanwariDesignSystem.successColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '既読',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // 送信時刻
                  Row(
                    children: [
                      Icon(Icons.send, color: Colors.grey.shade600, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateTime(message['sentAt']),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailModal() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ヘッダー
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'メッセージ詳細',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _closeDetailModal,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // 詳細内容
          Expanded(
            child: _isLoadingDetail
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('メッセージを読み込み中...'),
                      ],
                    ),
                  )
                : _detailError.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _detailError,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                // TODO: 再試行ロジック
                              },
                              child: const Text('再試行'),
                            ),
                          ],
                        ),
                      )
                    : _selectedMessage != null
                        ? SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailSection(
                                  '送信先',
                                  _selectedMessage!['recipientName'] ?? '不明',
                                ),
                                _buildDetailSection(
                                  '送信日時',
                                  _formatDateTime(
                                    _selectedMessage!['scheduledAt'] ??
                                    _selectedMessage!['sentAt'] ??
                                    DateTime.now(),
                                  ),
                                ),
                                _buildDetailSection(
                                  'ステータス',
                                  _getStatusLabel(_selectedMessage!['status'] ?? ''),
                                ),
                                if (_selectedMessage!['finalText'] != null)
                                  _buildDetailSection(
                                    '送信メッセージ',
                                    _selectedMessage!['finalText'],
                                    isMessage: true,
                                  ),
                                if (_selectedMessage!['selectedTone'] != null)
                                  _buildDetailSection(
                                    '選択したトーン',
                                    _getToneLabel(_selectedMessage!['selectedTone']),
                                  ),
                              ],
                            ),
                          )
                        : const Center(child: Text('詳細を読み込めませんでした')),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String label, String value, {bool isMessage = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isMessage ? 12 : 8),
            decoration: BoxDecoration(
              color: isMessage ? Colors.green.shade50 : Colors.grey.shade50,
              border: Border.all(
                color: isMessage ? Colors.green.shade200 : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}