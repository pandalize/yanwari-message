import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'message_compose_screen_redesigned.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';

class RecipientSelectScreen extends StatefulWidget {
  const RecipientSelectScreen({super.key});

  @override
  State<RecipientSelectScreen> createState() => _RecipientSelectScreenState();
}

class _RecipientSelectScreenState extends State<RecipientSelectScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _filteredFriends = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedRecipientEmail;
  String? _selectedRecipientName;
  String? _currentUserEmail;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterFriends);
    _loadCurrentUserAndFriends();
  }
  
  Future<void> _loadCurrentUserAndFriends() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // 現在のユーザーのメールアドレスを取得
      final authService = Provider.of<AuthService>(context, listen: false);
      _currentUserEmail = authService.currentUser?.email?.toLowerCase();
      print('現在のユーザー: $_currentUserEmail');
      
      // 友達リストを取得
      final apiService = ApiService(authService);
      final response = await apiService.getFriends();
      
      if (response['data'] != null && response['data']['friends'] != null) {
        final friendsList = response['data']['friends'] as List;
        // 自分自身を除外
        _friends = friendsList.where((friend) {
          final friendEmail = (friend['friend']?['email'] ?? '').toLowerCase();
          return friendEmail != _currentUserEmail;
        }).cast<Map<String, dynamic>>().toList();
        
        print('友達リスト (自分除外後): ${_friends.length}人');
        _filteredFriends = List.from(_friends);
      } else {
        // APIから友達が取得できない場合はデモデータを使用（自分自身を除外）
        final demoFriends = [
          {
            'friend': {
              'name': 'Alice Demo',
              'email': 'alice@yanwari.com',
            }
          },
          {
            'friend': {
              'name': 'Bob Demo', 
              'email': 'bob@yanwari.com',
            }
          }
        ];
        
        // デモデータからも自分自身を除外
        _friends = demoFriends.where((friend) {
          final friendEmail = (friend['friend']?['email'] ?? '').toLowerCase();
          return friendEmail != _currentUserEmail;
        }).cast<Map<String, dynamic>>().toList();
        
        _filteredFriends = List.from(_friends);
      }
    } catch (e) {
      print('友達リスト取得エラー: $e');
      // エラー時はデモデータを使用（自分自身を除外）
      final demoFriends = [
        {
          'friend': {
            'name': 'Alice Demo',
            'email': 'alice@yanwari.com',
          }
        },
        {
          'friend': {
            'name': 'Bob Demo', 
            'email': 'bob@yanwari.com',
          }
        }
      ];
      
      _friends = demoFriends.where((friend) {
        final friendEmail = (friend['friend']?['email'] ?? '').toLowerCase();
        return friendEmail != _currentUserEmail;
      }).cast<Map<String, dynamic>>().toList();
      
      _filteredFriends = List.from(_friends);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterFriends() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFriends = List.from(_friends);
      } else {
        _filteredFriends = _friends.where((friend) {
          final name = (friend['friend']?['name'] ?? '').toLowerCase();
          final email = (friend['friend']?['email'] ?? '').toLowerCase();
          return name.contains(query) || email.contains(query);
        }).toList();
      }
    });
  }

  void _selectRecipient(String email, String name) {
    setState(() {
      _selectedRecipientEmail = email;
      _selectedRecipientName = name;
    });
  }

  void _proceedToMessageCompose() {
    if (_selectedRecipientEmail != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessageComposeScreenRedesigned(
            recipientEmail: _selectedRecipientEmail!,
            recipientName: _selectedRecipientName!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('送信先を選択'),
        backgroundColor: const Color(0xFF92C9FF),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 検索バー
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '友達を検索...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // 友達リスト
            Expanded(
              child: _buildFriendsList(),
            ),
            
            // 次へボタン
            if (_selectedRecipientEmail != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 16),
                child: ElevatedButton(
                  onPressed: _proceedToMessageCompose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF92C9FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('メッセージを作成'),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF92C9FF)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_filteredFriends.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '検索結果が見つかりません',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredFriends.length,
      itemBuilder: (context, index) {
        final friendship = _filteredFriends[index];
        final friend = friendship['friend'] as Map<String, dynamic>?;
        final name = friend?['name'] ?? friend?['email'] ?? '名前不明';
        final email = friend?['email'] ?? '';
        final isSelected = _selectedRecipientEmail == email;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected ? const Color(0xFFE8F3FF) : Colors.white,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isSelected ? const Color(0xFF92C9FF) : const Color(0xFFCDE6FF),
              child: Text(
                name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(email),
            onTap: () => _selectRecipient(email, name),
          ),
        );
      },
    );
  }
}