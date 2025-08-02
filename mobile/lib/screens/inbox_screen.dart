import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/api_service.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  late final ApiService _apiService;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(context.read<AuthService>());
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getInboxWithRatings();
      
      print('🔍 Debug - API Response Type: ${response.runtimeType}');
      print('🔍 Debug - API Response: $response');
      
      setState(() {
        _messages = <Map<String, dynamic>>[];
        
        if (response != null && response is Map<String, dynamic>) {
          print('🔍 Debug - Response keys: ${response.keys.toList()}');
          
          // Try different possible response structures
          List<dynamic>? messagesList;
          
          // Case 1: Nested data.messages structure
          if (response['data'] is Map && response['data']['messages'] is List) {
            messagesList = response['data']['messages'] as List<dynamic>;
            print('✅ Found messages in data.messages field, count: ${messagesList.length}');
          }
          // Case 2: Direct data field with array
          else if (response['data'] is List) {
            messagesList = response['data'] as List<dynamic>;
            print('✅ Found messages in data field, count: ${messagesList.length}');
          }
          // Case 3: Direct messages field with array
          else if (response['messages'] is List) {
            messagesList = response['messages'] as List<dynamic>;
            print('✅ Found messages in messages field, count: ${messagesList.length}');
          }
          // Case 4: Root level is array (wrapped in success response)
          else if (response.containsKey('success') && response['success'] == true) {
            // Find the array field
            for (String key in response.keys) {
              if (response[key] is List) {
                messagesList = response[key] as List<dynamic>;
                print('✅ Found messages in $key field, count: ${messagesList.length}');
                break;
              }
            }
          }
          
          // Parse the messages list
          if (messagesList != null) {
            try {
              for (var item in messagesList) {
                if (item is Map<String, dynamic>) {
                  _messages.add(item);
                }
              }
              print('📋 Debug - Successfully parsed ${_messages.length} messages');
            } catch (e) {
              print('❌ Error parsing messages array: $e');
            }
          } else {
            print('⚠️ No messages array found in response');
          }
        } else {
          print('❌ Invalid response format: ${response?.runtimeType}');
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'メッセージの読み込みに失敗しました: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String messageId) async {
    try {
      await _apiService.markMessageAsRead(messageId);
      await _loadMessages(); // リロードして既読状態を更新
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('既読処理に失敗しました: $e')),
      );
    }
  }

  Future<void> _rateMessage(String messageId, int rating) async {
    try {
      await _apiService.rateMessage(messageId: messageId, rating: rating);
      await _loadMessages(); // リロードして評価を更新
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('評価を送信しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('評価の送信に失敗しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '受信トレイ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF42A5F5),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF42A5F5),
              Colors.white,
            ],
            stops: [0.0, 0.2],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // エラーメッセージ
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),

              // メッセージ一覧
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF42A5F5),
                        ),
                      )
                    : _messages.isEmpty
                        ? _buildEmptyState()
                        : _buildMessageList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '受信したメッセージはありません',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '友達からのやんわり伝言を\nお待ちください',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageCard(message);
      },
    );
  }

  Widget _buildMessageCard(Map<String, dynamic> message) {
    final bool isRead = message['readAt'] != null;
    final String finalText = message['finalText'] ?? message['originalText'] ?? '';
    final String senderName = message['senderName'] ?? 'Unknown User';
    final String createdAt = message['createdAt'] ?? '';
    final int? rating = message['rating'] is int ? message['rating'] : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isRead ? 2 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isRead
            ? BorderSide.none
            : const BorderSide(color: Color(0xFF42A5F5), width: 2),
      ),
      child: InkWell(
        onTap: () => _showMessageDetail(message),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー情報
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF42A5F5),
                    child: Text(
                      senderName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          senderName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        Text(
                          _formatDate(createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isRead)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF42A5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '未読',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // メッセージ本文
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  finalText,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // アクションボタン
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 評価表示
                  if (rating != null)
                    Row(
                      children: [
                        const Text(
                          '評価: ',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        ...List.generate(5, (i) => Icon(
                          i < rating ? Icons.star : Icons.star_border,
                          size: 16,
                          color: Colors.amber,
                        )),
                      ],
                    )
                  else
                    const Text(
                      '未評価',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),

                  // アクションボタン
                  Row(
                    children: [
                      if (!isRead)
                        TextButton.icon(
                          onPressed: () => _markAsRead(message['_id']),
                          icon: const Icon(Icons.mark_email_read, size: 16),
                          label: const Text('既読', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF42A5F5),
                          ),
                        ),
                      if (rating == null)
                        TextButton.icon(
                          onPressed: () => _showRatingDialog(message['_id']),
                          icon: const Icon(Icons.star_rate, size: 16),
                          label: const Text('評価', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.amber.shade700,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageDetail(Map<String, dynamic> message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${message['senderName'] ?? 'Unknown User'}からのメッセージ'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '受信日時: ${_formatDate(message['createdAt'])}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message['finalText'] ?? message['originalText'] ?? '',
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
          if (message['readAt'] == null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _markAsRead(message['_id']);
              },
              child: const Text('既読にする'),
            ),
        ],
      ),
    );
  }

  void _showRatingDialog(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メッセージを評価'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('このメッセージはどうでしたか？'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _rateMessage(messageId, index + 1);
                  },
                  icon: const Icon(Icons.star_border),
                  color: Colors.amber,
                  iconSize: 32,
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}日前';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}時間前';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}分前';
      } else {
        return 'たった今';
      }
    } catch (e) {
      return dateString;
    }
  }
}