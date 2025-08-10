import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'schedule_screen.dart';

class ToneTransformScreen extends StatefulWidget {
  final String messageId;
  final String originalText;
  final String recipientEmail;
  final String recipientName;

  const ToneTransformScreen({
    super.key,
    required this.messageId,
    required this.originalText,
    required this.recipientEmail,
    required this.recipientName,
  });

  @override
  State<ToneTransformScreen> createState() => _ToneTransformScreenState();
}

class _ToneTransformScreenState extends State<ToneTransformScreen> {
  bool _isLoading = false;
  Map<String, String> _transformedTexts = {};
  String? _selectedTone;
  late final ApiService _apiService;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _apiService = ApiService(_authService);
    _transformTone();
  }

  Future<void> _transformTone() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.transformTones(
        messageId: widget.messageId,
        originalText: widget.originalText,
      );

      print('トーン変換API レスポンス: $response');
      
      if (response['data'] != null) {
        final data = response['data'];
        print('data フィールド: $data');
        print('data型: ${data.runtimeType}');
        
        if (data['variations'] != null) {
          final variations = data['variations'];
          print('variations フィールド: $variations');
          print('variations型: ${variations.runtimeType}');
          
          if (variations is Map<String, dynamic>) {
            setState(() {
              _transformedTexts = {
                'gentle': _cleanResponseText(variations['gentle'] ?? ''),
                'constructive': _cleanResponseText(variations['constructive'] ?? ''),
                'casual': _cleanResponseText(variations['casual'] ?? ''),
              };
            });
            print('トーン変換成功: ${_transformedTexts.keys.length}個のトーン');
          } else if (variations is List) {
            // レスポンスがList形式の場合の処理
            final Map<String, String> transformedMap = {};
            for (var item in variations) {
              if (item is Map<String, dynamic> && item['tone'] != null && item['text'] != null) {
                transformedMap[item['tone']] = _cleanResponseText(item['text']);
              }
            }
            setState(() {
              _transformedTexts = {
                'gentle': transformedMap['gentle'] ?? '',
                'constructive': transformedMap['constructive'] ?? '',
                'casual': transformedMap['casual'] ?? '',
              };
            });
            print('トーン変換成功（List形式）: ${_transformedTexts.keys.length}個のトーン');
          } else {
            throw Exception('予期しないvariations構造: ${variations.runtimeType}');
          }
        } else {
          throw Exception('variationsフィールドが見つかりません: $data');
        }
      } else {
        throw Exception('dataフィールドが見つかりません: $response');
      }
    } catch (e) {
      print('トーン変換エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('トーン変換に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectTone(String tone) {
    setState(() {
      _selectedTone = tone;
    });
  }

  // レスポンステキストから不要なタグを除去
  String _cleanResponseText(String text) {
    if (text.isEmpty) return text;
    
    String cleaned = text;
    
    // よくあるXMLタグやHTMLタグを除去
    final tagsToRemove = [
      '</response>',
      '<response>',
      '</text>',
      '<text>',
      '</message>',
      '<message>',
      '</content>',
      '<content>',
      '</answer>',
      '<answer>',
    ];
    
    for (String tag in tagsToRemove) {
      cleaned = cleaned.replaceAll(tag, '');
    }
    
    // 前後の空白を除去
    cleaned = cleaned.trim();
    
    print('テキスト清理: 元の長さ=${text.length}, 清理後の長さ=${cleaned.length}');
    if (text != cleaned) {
      print('除去されたタグが含まれていました');
    }
    
    return cleaned;
  }

  Future<void> _proceedToSchedule() async {
    if (_selectedTone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('トーンを選択してください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 選択したトーンを保存
      await _apiService.updateMessage(
        messageId: widget.messageId,
        selectedTone: _selectedTone!,
      );

      // 選択したトーンのテキストを取得
      final selectedText = _transformedTexts[_selectedTone!] ?? widget.originalText;

      // スケジュール選択画面に遷移
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScheduleScreen(
              messageId: widget.messageId,
              originalText: selectedText, // 変換後のテキストを渡す
              selectedTone: _selectedTone!,
              recipientEmail: widget.recipientEmail,
              recipientName: widget.recipientName,
            ),
          ),
        );
      }
    } catch (e) {
      print('トーン保存エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラーが発生しました: $e'),
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
        title: const Text('トーンを選択'),
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

          // 元のメッセージ
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '元のメッセージ:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
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
                    widget.originalText,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),

          // トーン選択肢
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF92C9FF)),
                        SizedBox(height: 16),
                        Text('AIがトーンを変換しています...', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : _transformedTexts.isEmpty
                    ? const Center(
                        child: Text('トーン変換に失敗しました', style: TextStyle(color: Colors.red)),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          _buildToneOption(
                            '💝 優しめトーン',
                            _transformedTexts['gentle'] ?? '',
                            'gentle',
                          ),
                          const SizedBox(height: 16),
                          _buildToneOption(
                            '🏗️ 建設的トーン',
                            _transformedTexts['constructive'] ?? '',
                            'constructive',
                          ),
                          const SizedBox(height: 16),
                          _buildToneOption(
                            '🎯 カジュアルトーン',
                            _transformedTexts['casual'] ?? '',
                            'casual',
                          ),
                        ],
                      ),
          ),

          // 次へ進むボタン
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: (_isLoading || _selectedTone == null) ? null : _proceedToSchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedTone != null 
                    ? const Color(0xFF92C9FF) 
                    : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : _selectedTone == null
                      ? const Text('トーンを選択してください', style: TextStyle(fontSize: 16))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('送信日時の選択に進む', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToneOption(String title, String text, String tone) {
    final bool isSelected = _selectedTone == tone;
    
    return GestureDetector(
      onTap: () => _selectTone(tone),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF92C9FF).withOpacity(0.1) 
              : const Color(0xFFF8F9FA), // 統一された薄い灰色の背景
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF92C9FF) : const Color(0xFFE0E0E0),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF92C9FF) : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}