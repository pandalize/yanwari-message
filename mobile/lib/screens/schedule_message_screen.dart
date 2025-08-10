import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/design_system.dart';

class ScheduleMessageScreen extends StatefulWidget {
  final String messageId;
  final String originalText;
  final String selectedTone;
  final String finalText;
  final String recipientEmail;
  final String recipientName;

  const ScheduleMessageScreen({
    super.key,
    required this.messageId,
    required this.originalText,
    required this.selectedTone,
    required this.finalText,
    required this.recipientEmail,
    required this.recipientName,
  });

  @override
  State<ScheduleMessageScreen> createState() => _ScheduleMessageScreenState();
}

class _ScheduleMessageScreenState extends State<ScheduleMessageScreen> {
  bool _isLoading = false;
  bool _isLoadingAI = false;
  String? _selectedOption;
  DateTime? _customDateTime;
  late final ApiService _apiService;
  late final AuthService _authService;
  
  // AI提案オプション
  List<Map<String, dynamic>> _aiOptions = [];
  
  // 基本オプション
  final List<Map<String, dynamic>> _baseOptions = [
    {
      'id': 'now',
      'label': '今すぐ送信',
      'icon': Icons.send,
      'type': 'preset',
      'description': 'すぐにメッセージを送信します',
    },
    {
      'id': 'custom',
      'label': 'カスタム日時',
      'icon': Icons.calendar_today,
      'type': 'preset',
      'description': '日時を自由に設定できます',
    },
  ];

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _apiService = ApiService(_authService);
    _selectedOption = 'now';
    _initializeScheduleOptions();
  }

  Future<void> _initializeScheduleOptions() async {
    // AI提案を取得
    await _getAISuggestions();
  }

  Future<void> _getAISuggestions() async {
    setState(() {
      _isLoadingAI = true;
    });

    try {
      final response = await _apiService.getScheduleSuggestions(
        messageId: widget.messageId,
        messageText: widget.finalText,
        selectedTone: widget.selectedTone,
      );

      if (response['data'] != null && response['data']['suggestions'] != null) {
        final suggestions = response['data']['suggestions'] as List;
        setState(() {
          _aiOptions = suggestions.map((suggestion) {
            return {
              'id': suggestion['id'] ?? 'suggestion_${DateTime.now().millisecondsSinceEpoch}',
              'label': suggestion['label'] ?? '提案',
              'icon': _getIconForSuggestion(suggestion['reason']),
              'type': 'ai',
              'scheduledAt': suggestion['scheduledAt'],
              'reason': suggestion['reason'],
              'description': suggestion['description'] ?? suggestion['reason'],
            };
          }).toList();
        });
      }
    } catch (e) {
      print('AI提案の取得に失敗: $e');
      // AI提案が失敗しても基本機能は使える
    } finally {
      setState(() {
        _isLoadingAI = false;
      });
    }
  }

  IconData _getIconForSuggestion(String? reason) {
    if (reason == null) return Icons.schedule;
    
    if (reason.contains('緊急') || reason.contains('急い')) {
      return Icons.priority_high;
    } else if (reason.contains('朝') || reason.contains('午前')) {
      return Icons.wb_sunny;
    } else if (reason.contains('夕') || reason.contains('夜')) {
      return Icons.nights_stay;
    } else if (reason.contains('会議') || reason.contains('仕事')) {
      return Icons.work;
    }
    return Icons.schedule;
  }

  Future<void> _selectDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
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
        initialTime: TimeOfDay(
          hour: DateTime.now().hour + 1,
          minute: 0,
        ),
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
        setState(() {
          _customDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          _selectedOption = 'custom';
        });
      }
    }
  }

  Future<void> _scheduleMessage() async {
    if (_selectedOption == null) {
      _showErrorDialog('送信タイミングを選択してください');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedOption == 'now') {
        // 今すぐ送信
        await _sendImmediately();
      } else if (_selectedOption == 'custom') {
        // カスタム日時で送信
        if (_customDateTime == null) {
          throw Exception('日時が選択されていません');
        }
        await _scheduleForDateTime(_customDateTime!);
      } else {
        // AI提案のオプション
        final option = _aiOptions.firstWhere(
          (opt) => opt['id'] == _selectedOption,
          orElse: () => throw Exception('無効な選択です'),
        );
        final scheduledAt = DateTime.parse(option['scheduledAt']);
        await _scheduleForDateTime(scheduledAt);
      }

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('送信の設定に失敗しました: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendImmediately() async {
    // メッセージを直接送信済み状態に更新
    await _apiService.updateMessageWithData(
      messageId: widget.messageId,
      updates: {
        'status': 'sent',
        'sentAt': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> _scheduleForDateTime(DateTime scheduledAt) async {
    // スケジュールを作成
    await _apiService.createSchedule(
      messageId: widget.messageId,
      scheduledAt: scheduledAt,
      timezone: 'Asia/Tokyo',
    );

    // メッセージをスケジュール済み状態に更新
    await _apiService.updateMessageWithData(
      messageId: widget.messageId,
      updates: {
        'status': 'scheduled',
        'scheduledAt': scheduledAt.toIso8601String(),
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: YanwariDesignSystem.successColor,
            ),
            const SizedBox(width: 8),
            const Text('送信設定完了'),
          ],
        ),
        content: Text(
          _selectedOption == 'now'
              ? 'メッセージを送信しました！'
              : 'メッセージの送信を予約しました。\n指定した時刻に自動的に送信されます。',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('ホームに戻る'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.error,
              color: YanwariDesignSystem.errorColor,
            ),
            const SizedBox(width: 8),
            const Text('エラー'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allOptions = [..._baseOptions, ..._aiOptions];

    return Scaffold(
      backgroundColor: YanwariDesignSystem.backgroundPrimary,
      appBar: AppBar(
        title: const Text(
          '送信タイミング設定',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // メッセージプレビュー
            _buildMessagePreview(),
            SizedBox(height: YanwariDesignSystem.spacingLg),

            // 送信タイミング選択
            Text(
              '送信タイミングを選択',
              style: YanwariDesignSystem.headingSm.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: YanwariDesignSystem.spacingMd),

            // オプション一覧
            ...allOptions.map((option) => _buildOptionCard(option)),

            // カスタム日時表示
            if (_selectedOption == 'custom' && _customDateTime != null)
              _buildCustomDateTimeDisplay(),

            // AI提案ローディング
            if (_isLoadingAI) _buildAILoadingCard(),

            SizedBox(height: YanwariDesignSystem.spacingXl),

            // 送信ボタン
            _buildScheduleButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagePreview() {
    return Container(
      padding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
      decoration: BoxDecoration(
        color: YanwariDesignSystem.surfacePrimary,
        borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusMd),
        border: Border.all(color: YanwariDesignSystem.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person,
                size: 16,
                color: YanwariDesignSystem.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '送信先: ${widget.recipientName}',
                style: YanwariDesignSystem.bodySm.copyWith(
                  color: YanwariDesignSystem.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: YanwariDesignSystem.spacingSm),
          Text(
            '送信メッセージ',
            style: YanwariDesignSystem.bodySm.copyWith(
              fontWeight: FontWeight.bold,
              color: YanwariDesignSystem.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.finalText,
            style: YanwariDesignSystem.bodyMd,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(Map<String, dynamic> option) {
    final isSelected = _selectedOption == option['id'];
    final isAI = option['type'] == 'ai';

    return GestureDetector(
      onTap: () {
        if (option['id'] == 'custom') {
          _selectDateTime();
        } else {
          setState(() {
            _selectedOption = option['id'];
          });
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: YanwariDesignSystem.spacingSm),
        padding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
        decoration: BoxDecoration(
          color: isSelected
              ? YanwariDesignSystem.primaryColor.withOpacity(0.1)
              : YanwariDesignSystem.surfacePrimary,
          borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusMd),
          border: Border.all(
            color: isSelected
                ? YanwariDesignSystem.primaryColor
                : YanwariDesignSystem.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isAI
                    ? YanwariDesignSystem.accentColor.withOpacity(0.1)
                    : YanwariDesignSystem.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                option['icon'],
                color: isAI
                    ? YanwariDesignSystem.accentColor
                    : YanwariDesignSystem.primaryColor,
              ),
            ),
            SizedBox(width: YanwariDesignSystem.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        option['label'],
                        style: YanwariDesignSystem.bodyMd.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isAI) ...[
                        SizedBox(width: YanwariDesignSystem.spacingSm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: YanwariDesignSystem.accentColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'AI提案',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (option['description'] != null)
                    Text(
                      option['description'],
                      style: YanwariDesignSystem.bodySm.copyWith(
                        color: YanwariDesignSystem.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: YanwariDesignSystem.primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomDateTimeDisplay() {
    return Container(
      margin: EdgeInsets.only(
        top: YanwariDesignSystem.spacingSm,
        bottom: YanwariDesignSystem.spacingSm,
      ),
      padding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
      decoration: BoxDecoration(
        color: YanwariDesignSystem.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusMd),
        border: Border.all(
          color: YanwariDesignSystem.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            color: YanwariDesignSystem.primaryColor,
          ),
          SizedBox(width: YanwariDesignSystem.spacingSm),
          Text(
            '送信予定: ${DateFormat('M月d日 H:mm').format(_customDateTime!)}',
            style: YanwariDesignSystem.bodyMd.copyWith(
              fontWeight: FontWeight.bold,
              color: YanwariDesignSystem.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAILoadingCard() {
    return Container(
      margin: EdgeInsets.only(bottom: YanwariDesignSystem.spacingSm),
      padding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
      decoration: BoxDecoration(
        color: YanwariDesignSystem.surfacePrimary,
        borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusMd),
        border: Border.all(color: YanwariDesignSystem.borderColor),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                YanwariDesignSystem.accentColor,
              ),
            ),
          ),
          SizedBox(width: YanwariDesignSystem.spacingMd),
          Text(
            'AI提案を生成中...',
            style: YanwariDesignSystem.bodyMd.copyWith(
              color: YanwariDesignSystem.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _scheduleMessage,
        style: YanwariDesignSystem.primaryButtonStyle.copyWith(
          padding: MaterialStateProperty.all(
            EdgeInsets.symmetric(
              vertical: YanwariDesignSystem.spacingMd,
            ),
          ),
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        YanwariDesignSystem.textInverse,
                      ),
                    ),
                  ),
                  SizedBox(width: YanwariDesignSystem.spacingSm),
                  const Text('設定中...'),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _selectedOption == 'now' ? Icons.send : Icons.schedule,
                    color: YanwariDesignSystem.textInverse,
                  ),
                  SizedBox(width: YanwariDesignSystem.spacingSm),
                  Text(
                    _selectedOption == 'now' ? '今すぐ送信' : '送信予約',
                  ),
                ],
              ),
      ),
    );
  }
}