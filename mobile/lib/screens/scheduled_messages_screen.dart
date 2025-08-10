import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/design_system.dart';

class ScheduledMessagesScreen extends StatefulWidget {
  const ScheduledMessagesScreen({super.key});

  @override
  State<ScheduledMessagesScreen> createState() => _ScheduledMessagesScreenState();
}

class _ScheduledMessagesScreenState extends State<ScheduledMessagesScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _scheduledMessages = [];
  late final ApiService _apiService;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _apiService = ApiService(_authService);
    _loadScheduledMessages();
  }

  Future<void> _loadScheduledMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.getSchedules();
      print('スケジュール一覧レスポンス: $response');

      if (response['data'] != null && response['data']['schedules'] != null) {
        final schedules = response['data']['schedules'] as List;
        setState(() {
          _scheduledMessages = schedules.map((schedule) {
            return {
              'id': schedule['_id'] ?? schedule['id'],
              'messageId': schedule['messageId'],
              'scheduledAt': DateTime.parse(schedule['scheduledAt']),
              'status': schedule['status'] ?? 'scheduled',
              'messageText': schedule['messageText'] ?? '内容を取得中...',
              'recipientEmail': schedule['recipientEmail'] ?? '',
              'aiSuggested': schedule['aiSuggested'] ?? false,
              'reason': schedule['reason'],
              'originalText': schedule['originalText'],
            };
          }).toList();
        });
      }
    } catch (e) {
      print('スケジュール一覧取得エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('送信予定の取得に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteSchedule(String scheduleId, String messageText) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('送信予定を取り消し'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('以下の送信予定を取り消しますか？'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                messageText.length > 50 
                    ? '${messageText.substring(0, 50)}...' 
                    : messageText,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('取り消し'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.deleteSchedule(scheduleId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('送信予定を取り消しました'),
            backgroundColor: Colors.green,
          ),
        );
        _loadScheduledMessages(); // リストを再読み込み
      } catch (e) {
        print('スケジュール削除エラー: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('取り消しに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = dateTime.difference(now);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes <= 0) {
          return '送信中';
        } else {
          return '${diff.inMinutes}分後';
        }
      } else {
        return '${diff.inHours}時間後';
      }
    } else if (diff.inDays == 1) {
      return '明日 ${DateFormat('HH:mm').format(dateTime)}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}日後 ${DateFormat('HH:mm').format(dateTime)}';
    } else {
      return DateFormat('MM月dd日 HH:mm').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('送信予定'),
        backgroundColor: const Color(0xFF92C9FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadScheduledMessages,
            tooltip: '更新',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadScheduledMessages,
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF92C9FF)),
                    SizedBox(height: 16),
                    Text(
                      '送信予定を読み込み中...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : _scheduledMessages.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule_send,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '送信予定のメッセージはありません',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'メッセージを作成して送信予約をすると、ここに表示されます',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _scheduledMessages.length,
                    itemBuilder: (context, index) {
                      final message = _scheduledMessages[index];
                      final isAISuggested = message['aiSuggested'] == true;
                      final isPast = message['scheduledAt'].isBefore(DateTime.now());
                      final status = message['status'];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ヘッダー行
                              Row(
                                children: [
                                  Icon(
                                    status == 'sent' ? Icons.check_circle :
                                    status == 'sending' ? Icons.send :
                                    Icons.schedule,
                                    size: 20,
                                    color: status == 'sent' ? Colors.green :
                                           status == 'sending' ? Colors.orange :
                                           const Color(0xFF92C9FF),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _formatDateTime(message['scheduledAt']),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isPast ? Colors.grey : const Color(0xFF333333),
                                      ),
                                    ),
                                  ),
                                  if (isAISuggested)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF92C9FF).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFF92C9FF).withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.psychology,
                                            size: 12,
                                            color: const Color(0xFF92C9FF),
                                          ),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'AI推奨',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF92C9FF),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (status == 'scheduled')
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => _deleteSchedule(
                                        message['id'],
                                        message['messageText'],
                                      ),
                                      tooltip: '送信予定を取り消し',
                                    ),
                                ],
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // メッセージ内容
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE9ECEF)),
                                ),
                                child: Text(
                                  message['messageText'].length > 150
                                      ? '${message['messageText'].substring(0, 150)}...'
                                      : message['messageText'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isPast ? Colors.grey : const Color(0xFF333333),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // 受信者情報
                              Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    '送信先: ${message['recipientEmail']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              
                              // AI推奨理由
                              if (isAISuggested && message['reason'] != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.lightbulb_outline, size: 16, color: Colors.orange),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'AI提案理由: ${message['reason']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              
                              // 正確な日時
                              const SizedBox(height: 8),
                              Text(
                                '予定日時: ${DateFormat('yyyy年MM月dd日 HH:mm').format(message['scheduledAt'])}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}