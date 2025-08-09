import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/api_service.dart';

class ScheduleSelectionScreen extends StatefulWidget {
  final String messageId;
  final String originalText;
  final String selectedTone;
  final String selectedToneText;
  final String recipientName;
  final String recipientEmail;

  const ScheduleSelectionScreen({
    super.key,
    required this.messageId,
    required this.originalText,
    required this.selectedTone,
    required this.selectedToneText,
    required this.recipientName,
    required this.recipientEmail,
  });

  @override
  State<ScheduleSelectionScreen> createState() => _ScheduleSelectionScreenState();
}

class _ScheduleSelectionScreenState extends State<ScheduleSelectionScreen> {
  late final ApiService _apiService;
  bool _isLoading = false;
  bool _isLoadingSuggestions = true;
  List<Map<String, dynamic>> _suggestions = [];
  DateTime? _customDateTime;
  
  // メッセージ詳細情報
  String _actualRecipientName = '';
  String _actualRecipientEmail = '';
  String _actualOriginalText = '';
  String _actualSelectedToneText = '';

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(context.read<AuthService>());
    
    // 渡された値を初期値として設定
    _actualRecipientName = widget.recipientName;
    _actualRecipientEmail = widget.recipientEmail;
    _actualOriginalText = widget.originalText;
    _actualSelectedToneText = widget.selectedToneText;
    
    _loadMessageDetails();
    _loadScheduleSuggestions();
  }

  Future<void> _loadMessageDetails() async {
    try {
      print('📝 メッセージ詳細取得開始: ${widget.messageId}');
      
      final response = await _apiService.getMessage(widget.messageId);
      
      if (response['data'] != null) {
        final messageData = response['data'];
        print('📝 取得したメッセージ詳細: $messageData');
        
        // 受信者情報を更新
        if (messageData['recipientEmail'] != null && messageData['recipientEmail'].isNotEmpty) {
          _actualRecipientEmail = messageData['recipientEmail'];
          print('📝 受信者メール更新: $_actualRecipientEmail');
        }
        
        // メッセージ内容を更新
        if (messageData['originalText'] != null && messageData['originalText'].isNotEmpty) {
          _actualOriginalText = messageData['originalText'];
          print('📝 元メッセージ更新: $_actualOriginalText');
        }
        
        // トーン変換結果を更新
        if (messageData['variations'] != null) {
          final variations = messageData['variations'];
          final selectedTone = widget.selectedTone;
          if (variations[selectedTone] != null) {
            _actualSelectedToneText = variations[selectedTone];
            print('📝 選択トーン($selectedTone)テキスト更新: $_actualSelectedToneText');
          }
        }
        
        // 受信者名を取得（メールアドレスから推定）
        if (_actualRecipientName.isEmpty && _actualRecipientEmail.isNotEmpty) {
          // メールアドレスのローカル部分から名前を推定
          final localPart = _actualRecipientEmail.split('@')[0];
          _actualRecipientName = localPart.replaceAll('.', ' ').replaceAll('_', ' ');
          print('📝 受信者名推定: $_actualRecipientName');
        }
        
        if (mounted) {
          setState(() {}); // UIを更新
        }
      }
    } catch (e) {
      print('📝 メッセージ詳細取得エラー: $e');
      // エラーが発生しても、渡された値を使用して続行
    }
  }

  Future<void> _loadScheduleSuggestions() async {
    try {
      print('🤖 AI提案要求開始');
      print('  - messageId: ${widget.messageId}');
      print('  - selectedTone: ${widget.selectedTone}');
      print('  - messageText: ${_actualSelectedToneText.isNotEmpty ? _actualSelectedToneText : widget.selectedToneText}');
      
      final response = await _apiService.suggestSchedule(
        messageId: widget.messageId,
        messageText: _actualSelectedToneText.isNotEmpty ? _actualSelectedToneText : widget.selectedToneText,
        selectedTone: widget.selectedTone,
      );

      print('🤖 AI提案レスポンス受信: $response');
      
      if (response != null && response['data'] != null) {
        final aiData = response['data'];
        final suggestedOptions = aiData['suggested_options'];
        print('🤖 AI分析結果: ${aiData['message_type']}, 緊急度: ${aiData['urgency_level']}');
        print('🤖 推奨タイミング: ${aiData['recommended_timing']}');
        print('🤖 理由: ${aiData['reasoning']}');
        print('🤖 提案オプション: $suggestedOptions');
        
        if (mounted) {
          setState(() {
            // suggested_optionsを_suggestions形式に変換
            _suggestions = [];
            if (suggestedOptions != null && suggestedOptions is List) {
              for (var option in suggestedOptions) {
                final delayMinutes = option['delay_minutes'] ?? 0;
                final now = DateTime.now();
                final scheduledAt = now.add(Duration(minutes: delayMinutes));
                
                _suggestions.add({
                  'display_name': option['option'] ?? 'AI提案',
                  'reasoning': option['reason'] ?? aiData['reasoning'],
                  'scheduled_at': scheduledAt.toIso8601String(),
                  'priority': option['priority'] ?? '推奨',
                });
              }
            }
            _isLoadingSuggestions = false;
          });
          print('🤖 変換後提案数: ${_suggestions.length}');
        }
      } else {
        print('🤖 レスポンスが空またはnull');
        if (mounted) {
          setState(() {
            _suggestions = [];
            _isLoadingSuggestions = false;
          });
        }
      }
    } catch (e) {
      print('🤖 AI提案エラー: $e');
      if (mounted) {
        setState(() {
          _isLoadingSuggestions = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI提案の取得に失敗しました: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _scheduleMessage(DateTime scheduledAt) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      await _apiService.createSchedule(
        messageId: widget.messageId,
        scheduledAt: scheduledAt,
        timezone: 'Asia/Tokyo',
      );

      if (mounted) {
        // 成功画面に遷移またはホームに戻る
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📅 メッセージが送信予定に登録されました！'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('スケジュール設定に失敗しました: $e'),
            backgroundColor: Colors.red,
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

  Future<void> _sendImmediately() async {
    await _scheduleMessage(DateTime.now());
  }

  Future<void> _selectCustomDateTime() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            // DatePickerのチェックマークを非表示にする
            checkboxTheme: CheckboxThemeData(
              checkColor: MaterialStateProperty.all(Colors.transparent),
            ),
            // 選択された日付の背景色は保持
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF81C784), // 選択時の背景色
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      // 今日の日付が選択された場合、現在時刻+1時間を初期値にする
      // 未来の日付が選択された場合は、9:00を初期値にする
      TimeOfDay initialTime;
      if (selectedDate.year == now.year && 
          selectedDate.month == now.month && 
          selectedDate.day == now.day) {
        // 今日の場合：現在時刻+1時間
        final nextHour = now.add(const Duration(hours: 1));
        initialTime = TimeOfDay.fromDateTime(nextHour);
      } else {
        // 未来の日付の場合：9:00
        initialTime = const TimeOfDay(hour: 9, minute: 0);
      }
      
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: Theme.of(context).copyWith(
              // TimePickerのチェックマークを非表示にする
              checkboxTheme: CheckboxThemeData(
                checkColor: MaterialStateProperty.all(Colors.transparent),
              ),
              // 選択された時刻の背景色は保持
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: const Color(0xFF81C784), // 選択時の背景色
              ),
            ),
            child: child!,
          );
        },
      );

      if (selectedTime != null) {
        final customDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        // 過去の時間チェック
        final now = DateTime.now();
        if (customDateTime.isBefore(now)) {
          // 過去の時間が選択された場合、エラーメッセージを表示
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('過去の時間は選択できません。現在時刻以降の時間を選択してください。'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return; // 過去の時間は設定しない
        }

        setState(() {
          _customDateTime = customDateTime;
        });
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '今すぐ';
      } else {
        return '${difference.inHours}時間後';
      }
    } else if (difference.inDays == 1) {
      return '明日 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '送信タイミング',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF81C784),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF81C784),
              Colors.white,
            ],
            stops: [0.0, 0.15],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 送信先情報
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 20,
                            color: Color(0xFF2E7D32),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '送信先',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _actualRecipientName.isNotEmpty ? _actualRecipientName : widget.recipientName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _actualRecipientEmail.isNotEmpty ? _actualRecipientEmail : widget.recipientEmail,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 選択されたメッセージプレビュー
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.message,
                            color: Color(0xFF81C784),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '送信するメッセージ (${_getToneDisplayName(widget.selectedTone)})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          _actualSelectedToneText.isNotEmpty ? _actualSelectedToneText : widget.selectedToneText,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 送信タイミング選択
                const Text(
                  '送信タイミングを選択',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: ListView(
                    children: [
                      // 今すぐ送信
                      _buildScheduleOption(
                        icon: Icons.send,
                        title: '今すぐ送信',
                        subtitle: '即座にメッセージを送信',
                        onTap: _isLoading ? null : _sendImmediately,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 12),

                      // AI提案セクション
                      const Text(
                        '🤖 AI による送信タイミング提案',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      if (_isLoadingSuggestions)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: const Row(
                            children: [
                              CircularProgressIndicator(
                                color: Colors.blue,
                                strokeWidth: 3,
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AI が最適なタイミングを分析中...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'メッセージの内容と相手の状況を考慮しています',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._suggestions.map((suggestion) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade50, Colors.white],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200, width: 2),
                            ),
                            child: _buildScheduleOption(
                              icon: Icons.auto_awesome,
                              title: '${suggestion['display_name'] ?? 'AI提案'} ✨',
                              subtitle: '💡 ${suggestion['reasoning'] ?? 'AIが分析した最適なタイミング'}',
                              onTap: _isLoading
                                  ? null
                                  : () => _scheduleMessage(
                                        DateTime.parse(suggestion['scheduled_at']),
                                      ),
                              color: Colors.blue,
                              isAiSuggestion: true,
                            ),
                          );
                        }).toList(),

                      // AI提案がない場合の表示
                      if (!_isLoadingSuggestions && _suggestions.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'AI提案を取得できませんでした。下記からお選びください。',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 12),
                      
                      // カスタム時間設定
                      _buildScheduleOption(
                        icon: Icons.schedule,
                        title: 'カスタム時間',
                        subtitle: _customDateTime != null
                            ? _formatDateTime(_customDateTime!)
                            : '日時を指定して送信',
                        onTap: _isLoading ? null : _selectCustomDateTime,
                        color: Colors.orange,
                      ),

                      // カスタム時間が設定されている場合の送信ボタン
                      if (_customDateTime != null) ...[
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () => _scheduleMessage(_customDateTime!),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            '${_formatDateTime(_customDateTime!)} に送信',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ローディング表示
                if (_isLoading)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF81C784),
                        ),
                        SizedBox(width: 16),
                        Text(
                          'スケジュールを設定中...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    required Color color,
    bool isAiSuggestion = false,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isAiSuggestion) ...[
                          const Icon(
                            Icons.auto_awesome,
                            color: Colors.blue,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: color.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getToneDisplayName(String tone) {
    switch (tone) {
      case 'gentle':
        return '優しめトーン';
      case 'constructive':
        return '建設的トーン';
      case 'casual':
        return 'カジュアルトーン';
      default:
        return tone;
    }
  }
}