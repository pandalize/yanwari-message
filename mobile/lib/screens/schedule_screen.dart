import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';

class ScheduleScreen extends StatefulWidget {
  final String messageId;
  final String originalText;
  final String selectedTone;
  final String recipientEmail;
  final String recipientName;

  const ScheduleScreen({
    super.key,
    required this.messageId,
    required this.originalText,
    required this.selectedTone,
    required this.recipientEmail,
    required this.recipientName,
  });

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  bool _isLoading = false;
  bool _isLoadingAI = false;
  String? _selectedOption;
  DateTime? _customDateTime;
  late final ApiService _apiService;
  late final AuthService _authService;
  List<Map<String, dynamic>> _scheduleOptions = [];

  // 基本オプション（今すぐとカスタム）
  final List<Map<String, dynamic>> _baseOptions = [
    {'id': 'now', 'label': '今すぐ送信', 'icon': Icons.send, 'type': 'preset'},
    {'id': 'custom', 'label': 'カスタム日時', 'icon': Icons.calendar_today, 'type': 'preset'},
  ];

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _apiService = ApiService(_authService);
    _selectedOption = 'now'; // デフォルトは「今すぐ送信」
    _initializeScheduleOptions();
  }

  Future<void> _initializeScheduleOptions() async {
    // 基本オプションを先に表示
    setState(() {
      _scheduleOptions = List.from(_baseOptions);
    });

    // AI提案を取得
    await _loadAISuggestions();
  }

  Future<void> _loadAISuggestions() async {
    setState(() {
      _isLoadingAI = true;
    });

    try {
      final response = await _apiService.suggestSchedule(
        messageId: widget.messageId,
        messageText: widget.originalText,
        selectedTone: widget.selectedTone,
      );

      print('🤖 AI提案レスポンス: $response');

      if (response['data'] != null && response['data']['suggestions'] != null) {
        final suggestions = response['data']['suggestions'] as List;
        final aiOptions = <Map<String, dynamic>>[];

        print('📋 AI提案数: ${suggestions.length}');
        
        for (int i = 0; i < suggestions.length; i++) {
          var suggestion = suggestions[i];
          if (suggestion is Map<String, dynamic>) {
            final delayMinutes = suggestion['delay_minutes'] ?? 0;
            final description = suggestion['description'] ?? '提案された時間';
            final reason = suggestion['reason'] ?? 'AIによる最適化提案';
            
            // より分かりやすい時間表示を生成
            final suggestedTime = DateTime.now().add(Duration(minutes: delayMinutes));
            final timeLabel = _formatAISuggestionTime(suggestedTime, delayMinutes);
            
            aiOptions.add({
              'id': 'ai_${delayMinutes}_$i',
              'label': timeLabel,
              'originalLabel': description,
              'icon': Icons.psychology,
              'type': 'ai',
              'delay_minutes': delayMinutes,
              'reason': reason,
              'suggested_time': suggestedTime,
            });
            
            print('✨ AI提案$i: $timeLabel (${delayMinutes}分後) - $reason');
          }
        }

        if (aiOptions.isNotEmpty) {
          setState(() {
            // AI提案がある場合の順序
            _scheduleOptions = [
              _baseOptions[0], // 今すぐ送信
              ...aiOptions, // AI提案
              _baseOptions[1], // カスタム日時
            ];
          });
          print('✅ AI提案を${aiOptions.length}件追加しました');
        } else {
          print('⚠️ AI提案が空でした');
          _setDefaultOptions();
        }
      } else {
        print('⚠️ AI提案データが見つかりませんでした');
        _setDefaultOptions();
      }
    } catch (e) {
      print('❌ AI提案取得エラー: $e');
      // エラー時はデフォルト提案を使用
      _setDefaultOptions();
    } finally {
      setState(() {
        _isLoadingAI = false;
      });
    }
  }
  
  void _setDefaultOptions() {
    final now = DateTime.now();
    setState(() {
      _scheduleOptions = [
        _baseOptions[0], // 今すぐ送信
        {
          'id': 'ai_60_default',
          'label': '${_formatTime(now.add(const Duration(hours: 1)))} (1時間後)',
          'icon': Icons.psychology,
          'type': 'ai',
          'delay_minutes': 60,
          'reason': '適度な時間をおいて相手に配慮した送信',
          'suggested_time': now.add(const Duration(hours: 1)),
        },
        {
          'id': 'ai_540_default',
          'label': '明日の朝9:00',
          'icon': Icons.psychology,
          'type': 'ai',
          'delay_minutes': 540,
          'reason': '朝の時間帯で相手が確認しやすいタイミング',
          'suggested_time': DateTime(now.year, now.month, now.day + 1, 9, 0),
        },
        {
          'id': 'ai_1440_default',
          'label': '明日の${_formatTime(now)} (24時間後)',
          'icon': Icons.psychology,
          'type': 'ai',
          'delay_minutes': 1440,
          'reason': '1日考える時間を置いて冷静に伝える',
          'suggested_time': now.add(const Duration(days: 1)),
        },
        _baseOptions[1], // カスタム日時
      ];
    });
  }
  
  String _formatAISuggestionTime(DateTime time, int delayMinutes) {
    final now = DateTime.now();
    
    if (delayMinutes < 60) {
      // 1時間未満
      return '${_formatTime(time)} (${delayMinutes}分後)';
    } else if (delayMinutes < 1440) {
      // 24時間未満
      final hours = delayMinutes ~/ 60;
      if (time.day == now.day) {
        return '今日 ${_formatTime(time)} (${hours}時間後)';
      } else {
        return '明日 ${_formatTime(time)}';
      }
    } else {
      // 24時間以上
      final days = delayMinutes ~/ 1440;
      if (days == 1) {
        return '明日 ${_formatTime(time)}';
      } else {
        return '${days}日後 ${_formatTime(time)}';
      }
    }
  }
  
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  bool _canScheduleMessage() {
    if (_selectedOption == null) return false;
    
    // カスタム日時の場合、実際に日時が設定されているかチェック
    if (_selectedOption == 'custom') {
      return _customDateTime != null;
    }
    
    // その他の場合は選択されていれば有効
    return true;
  }

  DateTime _getScheduledDateTime() {
    if (_selectedOption == 'now') {
      return DateTime.now();
    } else if (_selectedOption == 'custom') {
      return _customDateTime ?? DateTime.now();
    } else if (_selectedOption?.startsWith('ai_') == true) {
      // AI提案の場合、delay_minutesを使用
      final option = _scheduleOptions.firstWhere(
        (opt) => opt['id'] == _selectedOption,
        orElse: () => {'delay_minutes': 0},
      );
      final delayMinutes = option['delay_minutes'] ?? 0;
      return DateTime.now().add(Duration(minutes: delayMinutes));
    }
    return DateTime.now();
  }

  Future<void> _selectCustomDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      // 今日を選択した場合、現在時刻より後の時間のみ許可
      final isToday = date.year == now.year && 
                     date.month == now.month && 
                     date.day == now.day;
      
      TimeOfDay initialTime;
      if (isToday) {
        // 今日の場合、現在時刻の1時間後を初期値に設定
        final oneHourLater = now.add(const Duration(hours: 1));
        initialTime = TimeOfDay(hour: oneHourLater.hour, minute: oneHourLater.minute);
      } else {
        initialTime = const TimeOfDay(hour: 9, minute: 0);
      }

      final time = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );

      if (time != null && mounted) {
        final selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        // 過去の時刻をチェック
        if (selectedDateTime.isBefore(now)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('過去の時刻は選択できません。現在時刻より後の時間を選択してください。'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        // 現在時刻から5分以内の時刻をチェック
        if (selectedDateTime.difference(now).inMinutes < 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('送信時刻は現在時刻から最低5分後に設定してください。'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        setState(() {
          _customDateTime = selectedDateTime;
        });
      } else {
        // 時刻選択をキャンセルした場合、選択状態をリセット
        setState(() {
          if (_selectedOption == 'custom') {
            _selectedOption = 'now'; // デフォルトに戻す
          }
        });
      }
    } else {
      // 日付選択をキャンセルした場合、選択状態をリセット
      setState(() {
        if (_selectedOption == 'custom') {
          _selectedOption = 'now'; // デフォルトに戻す
        }
      });
    }
  }

  Future<void> _scheduleMessage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final scheduledAt = _getScheduledDateTime();
      
      print('スケジュール送信時刻: $scheduledAt');
      print('ISO 8601フォーマット: ${scheduledAt.toIso8601String()}');
      
      // スケジュール作成
      await _apiService.createSchedule(
        messageId: widget.messageId,
        scheduledAt: scheduledAt,
        timezone: 'Asia/Tokyo',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedOption == 'now' 
              ? 'メッセージを送信しました' 
              : 'メッセージを予約しました',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // ホーム画面に戻る（すべての画面をクリア）
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      print('スケジュール作成エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('送信予約に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('送信日時を選択'),
        backgroundColor: const Color(0xFF92C9FF),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 受信者情報
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('送信先:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  widget.recipientName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.recipientEmail,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),

          // 選択したトーン表示
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.selectedTone == 'gentle' ? Icons.favorite :
                      widget.selectedTone == 'constructive' ? Icons.build :
                      Icons.sports_score,
                      size: 16,
                      color: const Color(0xFF92C9FF),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.selectedTone == 'gentle' ? '優しめトーン' :
                      widget.selectedTone == 'constructive' ? '建設的トーン' :
                      'カジュアルトーン',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92C9FF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE9ECEF)),
                  ),
                  child: Text(
                    widget.originalText.length > 100
                        ? '${widget.originalText.substring(0, 100)}...'
                        : widget.originalText,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '送信日時を選択してください',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // AI提案ヘッダー
          if (!_isLoadingAI && _scheduleOptions.where((opt) => opt['type'] == 'ai').isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF92C9FF).withOpacity(0.1),
                    const Color(0xFF92C9FF).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF92C9FF).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: const Color(0xFF92C9FF),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI提案時間',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92C9FF),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'メッセージ内容から最適なタイミングを分析しました',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // 時間選択オプション
          Expanded(
            child: _isLoadingAI && _scheduleOptions.length <= 2
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF92C9FF)),
                        SizedBox(height: 16),
                        Text(
                          'AIが最適な送信時間を分析しています...',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'メッセージ内容とトーンから\n最適なタイミングを提案します',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _scheduleOptions.length,
                    itemBuilder: (context, index) {
                      final option = _scheduleOptions[index];
                      final isSelected = _selectedOption == option['id'];
                      final isCustom = option['id'] == 'custom';
                      final isAI = option['type'] == 'ai';

                return GestureDetector(
                  onTap: () async {
                    if (isCustom) {
                      // カスタムの場合は、日時選択が完了してから選択状態にする
                      await _selectCustomDateTime();
                      // 日時が選択された場合のみ選択状態にする
                      if (_customDateTime != null) {
                        setState(() {
                          _selectedOption = option['id'];
                        });
                      }
                    } else {
                      // カスタム以外は通常通り選択
                      setState(() {
                        _selectedOption = option['id'];
                      });
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF92C9FF).withOpacity(0.1)
                          : const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF92C9FF)
                            : const Color(0xFFE0E0E0),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          option['icon'],
                          color: isSelected
                              ? const Color(0xFF92C9FF)
                              : Colors.grey,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      option['label'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? const Color(0xFF92C9FF)
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (isAI)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF92C9FF),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.auto_awesome,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'AI推奨',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              if (isCustom && _customDateTime != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('yyyy年MM月dd日 HH:mm')
                                      .format(_customDateTime!),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                              if (isAI && option['reason'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  option['reason'],
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF92C9FF),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 送信ボタン
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _canScheduleMessage() ? _scheduleMessage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _canScheduleMessage() ? const Color(0xFF92C9FF) : Colors.grey.shade300,
                foregroundColor: _canScheduleMessage() ? Colors.white : Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      _canScheduleMessage() 
                          ? (_selectedOption == 'now' ? '送信する' : '予約する')
                          : 'カスタム日時を設定してください',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}