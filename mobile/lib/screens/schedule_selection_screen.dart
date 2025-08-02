import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/api_service.dart';

class ScheduleSelectionScreen extends StatefulWidget {
  final String messageId;
  final String originalText;
  final String selectedTone;
  final String selectedToneText;

  const ScheduleSelectionScreen({
    super.key,
    required this.messageId,
    required this.originalText,
    required this.selectedTone,
    required this.selectedToneText,
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

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(context.read<AuthService>());
    _loadScheduleSuggestions();
  }

  Future<void> _loadScheduleSuggestions() async {
    try {
      final response = await _apiService.suggestSchedule(
        messageId: widget.messageId,
        messageText: widget.selectedToneText,
        selectedTone: widget.selectedTone,
      );

      setState(() {
        _suggestions = List<Map<String, dynamic>>.from(
          response['data']['suggestions'] ?? []
        );
        _isLoadingSuggestions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSuggestions = false;
      });
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
    setState(() {
      _isLoading = true;
    });

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
      setState(() {
        _isLoading = false;
      });
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
    );

    if (selectedDate != null) {
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
      );

      if (selectedTime != null) {
        final customDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

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
                          widget.selectedToneText,
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

                      // AI提案
                      if (_isLoadingSuggestions)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Row(
                            children: [
                              CircularProgressIndicator(
                                color: Color(0xFF81C784),
                              ),
                              SizedBox(width: 16),
                              Text(
                                'AI が最適なタイミングを分析中...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._suggestions.map((suggestion) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildScheduleOption(
                              icon: Icons.smart_toy,
                              title: suggestion['display_name'] ?? 'AI提案',
                              subtitle: suggestion['reasoning'] ?? '',
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