import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/design_system.dart';
import '../widgets/layout/page_container.dart';
import '../widgets/layout/page_title.dart';

class ScheduledMessagesScreenRedesigned extends StatefulWidget {
  const ScheduledMessagesScreenRedesigned({super.key});

  @override
  State<ScheduledMessagesScreenRedesigned> createState() => _ScheduledMessagesScreenRedesignedState();
}

class _ScheduledMessagesScreenRedesignedState extends State<ScheduledMessagesScreenRedesigned> {
  bool _isLoading = false;
  String _filter = 'pending'; // pending, sent
  List<Map<String, dynamic>> _scheduledMessages = [];
  late final ApiService _apiService;

  @override
  void initState() {
    super.initState();
    try {
      final authService = context.read<AuthService>();
      _apiService = ApiService(authService);
      _loadScheduledMessages();
    } catch (e) {
      print('ScheduledMessagesScreen 初期化エラー: $e');
    }
  }

  Future<void> _loadScheduledMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.getSchedules();

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
              'recipientName': schedule['recipientName'] ?? _getEmailUsername(schedule['recipientEmail'] ?? ''),
              'aiSuggested': schedule['aiSuggested'] ?? false,
              'reason': schedule['reason'],
              'originalText': schedule['originalText'],
              'selectedTone': schedule['selectedTone'] ?? 'gentle',
              'createdAt': schedule['createdAt'] != null 
                  ? DateTime.parse(schedule['createdAt']) 
                  : DateTime.now(),
            };
          }).toList();

          // 送信予定時刻順にソート
          _scheduledMessages.sort((a, b) => 
            (a['scheduledAt'] as DateTime).compareTo(b['scheduledAt'] as DateTime));
        });
      }
    } catch (e) {
      print('スケジュール一覧取得エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('送信予定の取得に失敗しました'),
            backgroundColor: YanwariDesignSystem.errorColor,
            action: SnackBarAction(
              label: '再試行',
              textColor: Colors.white,
              onPressed: _loadScheduledMessages,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getEmailUsername(String email) {
    if (email.contains('@')) {
      return email.split('@')[0];
    }
    return email;
  }

  List<Map<String, dynamic>> get _filteredMessages {
    switch (_filter) {
      case 'pending':
        return _scheduledMessages.where((msg) => 
          msg['status'] == 'scheduled' && 
          (msg['scheduledAt'] as DateTime).isAfter(DateTime.now())
        ).toList();
      case 'sent':
        return _scheduledMessages.where((msg) => 
          msg['status'] == 'sent' || 
          (msg['status'] == 'scheduled' && (msg['scheduledAt'] as DateTime).isBefore(DateTime.now()))
        ).toList();
      default:
        return _scheduledMessages.where((msg) => 
          msg['status'] == 'scheduled' && 
          (msg['scheduledAt'] as DateTime).isAfter(DateTime.now())
        ).toList();
    }
  }

  Future<void> _editSchedule(Map<String, dynamic> schedule) async {
    final DateTime? newDateTime = await _selectDateTime(
      initialDateTime: schedule['scheduledAt'] as DateTime,
    );

    if (newDateTime != null && mounted) {
      try {
        await _apiService.updateSchedule(
          scheduleId: schedule['id'],
          scheduledAt: newDateTime,
          timezone: 'Asia/Tokyo',
        );

        setState(() {
          final index = _scheduledMessages.indexWhere((msg) => msg['id'] == schedule['id']);
          if (index != -1) {
            _scheduledMessages[index]['scheduledAt'] = newDateTime;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('送信時刻を変更しました'),
            backgroundColor: YanwariDesignSystem.successColor,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('送信時刻の変更に失敗しました'),
            backgroundColor: YanwariDesignSystem.errorColor,
          ),
        );
      }
    }
  }

  Future<DateTime?> _selectDateTime({required DateTime initialDateTime}) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initialDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: YanwariDesignSystem.primaryColor,
              onPrimary: YanwariDesignSystem.textInverse,
              surface: Colors.white,
              onSurface: YanwariDesignSystem.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDateTime),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: YanwariDesignSystem.primaryColor,
                onPrimary: YanwariDesignSystem.textInverse,
                surface: Colors.white,
                onSurface: YanwariDesignSystem.textPrimary,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        return DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      }
    }
    return null;
  }

  Future<void> _deleteSchedule(Map<String, dynamic> schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: Colors.orange,
            ),
            const SizedBox(width: 8),
            const Text('送信予定を取り消し'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('以下の送信予定を取り消しますか？'),
            SizedBox(height: YanwariDesignSystem.spacingMd),
            Container(
              padding: EdgeInsets.all(YanwariDesignSystem.spacingSm),
              decoration: BoxDecoration(
                color: YanwariDesignSystem.backgroundSecondary,
                borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusSm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '送信先: ${schedule['recipientName']}',
                    style: YanwariDesignSystem.bodySm.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    schedule['messageText'].length > 50 
                        ? '${schedule['messageText'].substring(0, 50)}...' 
                        : schedule['messageText'],
                    style: YanwariDesignSystem.bodySm,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '予定: ${_formatDateTime(schedule['scheduledAt'] as DateTime)}',
                    style: YanwariDesignSystem.bodySm.copyWith(
                      color: YanwariDesignSystem.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: YanwariDesignSystem.spacingSm),
            Text(
              '※ 取り消し後、このメッセージは送信されません。',
              style: YanwariDesignSystem.bodySm.copyWith(
                color: Colors.orange,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: YanwariDesignSystem.errorColor,
            ),
            child: const Text('取り消し'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _apiService.deleteSchedule(schedule['id']);
        setState(() {
          _scheduledMessages.removeWhere((msg) => msg['id'] == schedule['id']);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('送信予定を取り消しました'),
            backgroundColor: YanwariDesignSystem.successColor,
          ),
        );
      } catch (e) {
        print('スケジュール削除エラー: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('取り消しに失敗しました'),
            backgroundColor: YanwariDesignSystem.errorColor,
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
      return DateFormat('M月d日 HH:mm').format(dateTime);
    }
  }

  String _getStatusText(Map<String, dynamic> schedule) {
    final scheduledAt = schedule['scheduledAt'] as DateTime;
    final status = schedule['status'] as String;
    final now = DateTime.now();

    if (status == 'sent') {
      return '送信済み';
    } else if (scheduledAt.isBefore(now)) {
      return '送信中';
    } else {
      return '送信予定';
    }
  }

  Color _getStatusColor(Map<String, dynamic> schedule) {
    final scheduledAt = schedule['scheduledAt'] as DateTime;
    final status = schedule['status'] as String;
    final now = DateTime.now();

    if (status == 'sent') {
      return YanwariDesignSystem.successColor;
    } else if (scheduledAt.isBefore(now)) {
      return Colors.orange;
    } else {
      return YanwariDesignSystem.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredMessages = _filteredMessages;
    
    return Scaffold(
      backgroundColor: YanwariDesignSystem.backgroundPrimary,
      appBar: AppBar(
        title: const Text(
          '送信予定',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadScheduledMessages,
            tooltip: '更新',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // フィルターボタン（送信予定・送信済みのみ）
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => _filter = 'pending'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _filter == 'pending' ? Colors.orange : Colors.grey.shade300,
                        foregroundColor: _filter == 'pending' ? Colors.white : Colors.black,
                      ),
                      child: Text('送信予定'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => _filter = 'sent'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _filter == 'sent' ? Colors.blue : Colors.grey.shade300,
                        foregroundColor: _filter == 'sent' ? Colors.white : Colors.black,
                      ),
                      child: Text('送信済み'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // メッセージ一覧
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.green),
                            SizedBox(height: 16),
                            Text('読み込み中...', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      )
                    : filteredMessages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.schedule, size: 80, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  _filter == 'pending' 
                                      ? '送信予定のメッセージはありません'
                                      : '送信済みのメッセージはありません',
                                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // メッセージ作成画面に遷移
                                    Navigator.of(context).pushNamed('/message-compose');
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('メッセージを作成'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredMessages.length,
                            itemBuilder: (context, index) {
                              final message = filteredMessages[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 受信者情報
                                      Row(
                                        children: [
                                          Icon(Icons.person, color: Colors.green, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              message['recipientName'] ?? message['recipientEmail'] ?? '不明',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          // ステータスバッジ
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(message).withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              _getStatusText(message),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: _getStatusColor(message),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // メッセージ内容
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          message['messageText'] ?? 'メッセージ内容を取得中...',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 12),
                                      
                                      // 送信予定時刻
                                      Row(
                                        children: [
                                          Icon(Icons.schedule, color: Colors.grey.shade600, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDateTime(message['scheduledAt'] as DateTime),
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
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: EdgeInsets.all(YanwariDesignSystem.spacingSm),
      decoration: BoxDecoration(
        color: YanwariDesignSystem.neutralColor,
        borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusMd),
      ),
      child: Row(
        children: [
          _buildFilterButton('pending', '送信予定', Icons.schedule),
          SizedBox(width: YanwariDesignSystem.spacingSm),
          _buildFilterButton('sent', '送信済み', Icons.check_circle),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String value, String label, IconData icon) {
    final isSelected = _filter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _filter = value;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: YanwariDesignSystem.spacingSm,
            horizontal: YanwariDesignSystem.spacingSm,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? YanwariDesignSystem.primaryColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusSm),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? YanwariDesignSystem.textInverse
                    : YanwariDesignSystem.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? YanwariDesignSystem.textInverse
                      : YanwariDesignSystem.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              YanwariDesignSystem.primaryColor,
            ),
          ),
          SizedBox(height: YanwariDesignSystem.spacingMd),
          Text(
            '送信予定を読み込み中...',
            style: YanwariDesignSystem.bodyMd.copyWith(
              color: YanwariDesignSystem.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule,
            size: 64,
            color: YanwariDesignSystem.textSecondary.withOpacity(0.5),
          ),
          SizedBox(height: YanwariDesignSystem.spacingMd),
          Text(
            _filter == 'pending' 
                ? '送信予定のメッセージはありません'
                : '送信済みのメッセージはありません',
            style: YanwariDesignSystem.bodyMd.copyWith(
              color: YanwariDesignSystem.textSecondary,
            ),
          ),
          SizedBox(height: YanwariDesignSystem.spacingMd),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed('/message-compose'),
            icon: const Icon(Icons.add),
            label: const Text('メッセージを作成'),
            style: YanwariDesignSystem.primaryButtonStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(List<Map<String, dynamic>> messages) {
    return RefreshIndicator(
      onRefresh: _loadScheduledMessages,
      color: YanwariDesignSystem.primaryColor,
      child: ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return _buildMessageCard(message);
        },
      ),
    );
  }

  Widget _buildMessageCard(Map<String, dynamic> message) {
    final scheduledAt = message['scheduledAt'] as DateTime;
    final isPending = scheduledAt.isAfter(DateTime.now()) && message['status'] != 'sent';
    
    return Container(
      margin: EdgeInsets.only(bottom: YanwariDesignSystem.spacingMd),
      padding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
      decoration: BoxDecoration(
        color: YanwariDesignSystem.neutralColor,
        borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusMd),
        border: Border.all(
          color: YanwariDesignSystem.borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー部分（受信者・ステータス）
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(YanwariDesignSystem.spacingSm),
                decoration: BoxDecoration(
                  color: YanwariDesignSystem.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.person,
                  size: 16,
                  color: YanwariDesignSystem.primaryColor,
                ),
              ),
              SizedBox(width: YanwariDesignSystem.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message['recipientName'],
                      style: YanwariDesignSystem.bodyMd.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      message['recipientEmail'],
                      style: YanwariDesignSystem.bodySm.copyWith(
                        color: YanwariDesignSystem.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // ステータスバッジ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(message).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(message),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(message),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: YanwariDesignSystem.spacingMd),
          
          // メッセージ内容
          Container(
            padding: EdgeInsets.all(YanwariDesignSystem.spacingSm),
            decoration: BoxDecoration(
              color: YanwariDesignSystem.backgroundPrimary,
              borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusSm),
            ),
            child: Text(
              message['messageText'],
              style: YanwariDesignSystem.bodyMd,
            ),
          ),
          
          SizedBox(height: YanwariDesignSystem.spacingMd),
          
          // 送信時刻と操作ボタン
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: YanwariDesignSystem.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDateTime(scheduledAt),
                style: YanwariDesignSystem.bodySm.copyWith(
                  color: YanwariDesignSystem.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (message['aiSuggested'] == true) ...[
                SizedBox(width: YanwariDesignSystem.spacingSm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: YanwariDesignSystem.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'AI提案',
                    style: TextStyle(
                      fontSize: 9,
                      color: YanwariDesignSystem.secondaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              // 操作ボタン
              if (isPending) ...[
                IconButton(
                  onPressed: () => _editSchedule(message),
                  icon: const Icon(Icons.edit),
                  iconSize: 20,
                  tooltip: '時刻変更',
                  color: YanwariDesignSystem.primaryColor,
                ),
                IconButton(
                  onPressed: () => _deleteSchedule(message),
                  icon: const Icon(Icons.cancel),
                  iconSize: 20,
                  tooltip: '取り消し',
                  color: YanwariDesignSystem.errorColor,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}