import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'schedule_selection_screen.dart';

class ToneSelectionScreen extends StatefulWidget {
  final String messageId;
  final String originalText;
  final Map<String, dynamic> toneVariations;

  const ToneSelectionScreen({
    super.key,
    required this.messageId,
    required this.originalText,
    required this.toneVariations,
  });

  @override
  State<ToneSelectionScreen> createState() => _ToneSelectionScreenState();
}

class _ToneSelectionScreenState extends State<ToneSelectionScreen> {
  late final ApiService _apiService;
  String? _selectedTone;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(context.read<AuthService>());
  }

  Future<void> _selectToneAndProceed(String tone) async {
    setState(() {
      _selectedTone = tone;
      _isLoading = true;
    });

    try {
      // メッセージを更新して選択されたトーンを保存
      await _apiService.updateMessage(
        messageId: widget.messageId,
        selectedTone: tone,
      );

      // スケジュール選択画面に遷移
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScheduleSelectionScreen(
              messageId: widget.messageId,
              originalText: widget.originalText,
              selectedTone: tone,
              selectedToneText: widget.toneVariations[tone] ?? '',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'トーンを選択',
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
                // 元のメッセージ表示
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.edit_note,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '元のメッセージ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.originalText,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 説明文
                const Text(
                  '最適なトーンを選択してください',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // トーンオプション
                Expanded(
                  child: ListView(
                    children: [
                      _buildToneCard(
                        tone: 'gentle',
                        title: '💝 優しめトーン',
                        subtitle: '丁寧で思いやりのある表現',
                        text: widget.toneVariations['gentle'] ?? '',
                        color: const Color(0xFFE91E63),
                      ),
                      const SizedBox(height: 16),
                      _buildToneCard(
                        tone: 'constructive',
                        title: '🏗️ 建設的トーン',
                        subtitle: '問題解決に焦点を当てた表現',
                        text: widget.toneVariations['constructive'] ?? '',
                        color: const Color(0xFF2196F3),
                      ),
                      const SizedBox(height: 16),
                      _buildToneCard(
                        tone: 'casual',
                        title: '🎯 カジュアルトーン',
                        subtitle: 'フレンドリーで親しみやすい表現',
                        text: widget.toneVariations['casual'] ?? '',
                        color: const Color(0xFFFF9800),
                      ),
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
                          '選択を保存しています...',
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

  Widget _buildToneCard({
    required String tone,
    required String title,
    required String subtitle,
    required String text,
    required Color color,
  }) {
    final isSelected = _selectedTone == tone;

    return Card(
      elevation: isSelected ? 8 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: _isLoading ? null : () => _selectToneAndProceed(tone),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.1),
                      color.withOpacity(0.05),
                    ],
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
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
                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: color,
                    size: 28,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Color(0xFF2E2E2E),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'このトーンを選択',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}