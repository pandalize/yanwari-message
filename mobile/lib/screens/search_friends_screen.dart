import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/friend_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/design_system.dart';
import '../models/user.dart';

class SearchFriendsScreen extends StatefulWidget {
  const SearchFriendsScreen({super.key});

  @override
  State<SearchFriendsScreen> createState() => _SearchFriendsScreenState();
}

class _SearchFriendsScreenState extends State<SearchFriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  List<AppUser> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String _errorMessage = '';

  late final ApiService _apiService;
  late final FriendService _friendService;

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    _apiService = ApiService(authService);
    _friendService = context.read<FriendService>();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? _validateSearchQuery(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '検索キーワードを入力してください';
    }
    if (value.trim().length < 2) {
      return '2文字以上で入力してください';
    }
    return null;
  }

  Future<void> _searchUsers() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final query = _searchController.text.trim();
    
    setState(() {
      _isSearching = true;
      _errorMessage = '';
      _searchResults = [];
    });

    try {
      // API検索機能はまだ実装されていないため、モックデータを使用
      // 本来は: final response = await _apiService.searchUsers(query);
      await Future.delayed(const Duration(seconds: 1)); // 検索のシミュレーション
      
      // モックデータ（実際のAPIが実装されたら削除）
      final mockResults = _generateMockSearchResults(query);
      
      setState(() {
        _searchResults = mockResults;
        _hasSearched = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'ユーザーの検索に失敗しました: $e';
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  // モックデータ生成（API実装後は削除）
  List<AppUser> _generateMockSearchResults(String query) {
    final mockUsers = [
      AppUser(
        id: '1',
        name: '田中太郎',
        email: 'tanaka@example.com',
        firebaseUid: 'mock1',
        timezone: 'Asia/Tokyo',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
      AppUser(
        id: '2',
        name: '佐藤花子',
        email: 'sato@example.com',
        firebaseUid: 'mock2',
        timezone: 'Asia/Tokyo',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now(),
      ),
      AppUser(
        id: '3',
        name: '山田次郎',
        email: 'yamada@example.com',
        firebaseUid: 'mock3',
        timezone: 'Asia/Tokyo',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now(),
      ),
    ];

    // 簡単な検索ロジック
    return mockUsers.where((user) {
      final lowerQuery = query.toLowerCase();
      return user.name.toLowerCase().contains(lowerQuery) ||
             user.email.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  Future<void> _sendFriendRequest(AppUser user) async {
    // 友達申請送信ダイアログを表示
    final result = await showDialog<String?>(
      context: context,
      builder: (BuildContext context) => _buildFriendRequestDialog(user),
    );

    if (result != null) {
      final success = await _friendService.sendFriendRequest(
        toEmail: user.email,
        message: result.isNotEmpty ? result : null,
      );

      if (success) {
        _showSuccessSnackBar('${user.name}さんに友達申請を送信しました');
        // 検索結果を更新
        await _searchUsers();
      } else if (_friendService.errorMessage != null) {
        _showErrorSnackBar(_friendService.errorMessage!);
      }
    }
  }

  Widget _buildFriendRequestDialog(AppUser user) {
    final messageController = TextEditingController();
    
    return AlertDialog(
      title: Text('${user.name}さんに友達申請を送信'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'メッセージ（任意）',
            style: YanwariDesignSystem.bodyMd.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: YanwariDesignSystem.spacingSm),
          TextField(
            controller: messageController,
            maxLines: 3,
            decoration: YanwariDesignSystem.inputDecoration(
              hintText: 'こんにちは！友達になりませんか？',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(messageController.text);
          },
          style: YanwariDesignSystem.primaryButtonStyle,
          child: const Text('送信'),
        ),
      ],
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: YanwariDesignSystem.errorColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: YanwariDesignSystem.successColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YanwariDesignSystem.backgroundMuted,
      appBar: AppBar(
        title: const Text('友達を検索'),
        backgroundColor: YanwariDesignSystem.backgroundPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 検索フォーム
          Container(
            padding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
            color: YanwariDesignSystem.backgroundPrimary,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _searchController,
                          decoration: YanwariDesignSystem.inputDecoration(
                            hintText: '名前またはメールアドレスで検索',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchResults = [];
                                        _hasSearched = false;
                                        _errorMessage = '';
                                      });
                                    },
                                  )
                                : null,
                          ),
                          validator: _validateSearchQuery,
                          onChanged: (value) => setState(() {}),
                          onFieldSubmitted: (_) => _searchUsers(),
                        ),
                      ),
                      SizedBox(width: YanwariDesignSystem.spacingSm),
                      ElevatedButton(
                        onPressed: _isSearching ? null : _searchUsers,
                        style: YanwariDesignSystem.primaryButtonStyle,
                        child: _isSearching
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    YanwariDesignSystem.textInverse,
                                  ),
                                ),
                              )
                            : const Text('検索'),
                      ),
                    ],
                  ),
                  // 検索のヒント
                  SizedBox(height: YanwariDesignSystem.spacingSm),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(YanwariDesignSystem.spacingSm),
                    decoration: BoxDecoration(
                      color: YanwariDesignSystem.primaryColorLight,
                      borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusSm),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: YanwariDesignSystem.textSecondary,
                        ),
                        SizedBox(width: YanwariDesignSystem.spacingXs),
                        Expanded(
                          child: Text(
                            'ユーザーの名前またはメールアドレスで検索できます',
                            style: YanwariDesignSystem.caption.copyWith(
                              color: YanwariDesignSystem.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // エラーメッセージ
          if (_errorMessage.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
              color: YanwariDesignSystem.errorColor.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: YanwariDesignSystem.errorColor,
                  ),
                  SizedBox(width: YanwariDesignSystem.spacingSm),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: YanwariDesignSystem.bodySm.copyWith(
                        color: YanwariDesignSystem.errorColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    iconSize: 18,
                    color: YanwariDesignSystem.errorColor,
                    onPressed: () => setState(() => _errorMessage = ''),
                  ),
                ],
              ),
            ),

          // 検索結果
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('検索中...'),
          ],
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: YanwariDesignSystem.textTertiary,
            ),
            SizedBox(height: YanwariDesignSystem.spacingMd),
            Text(
              '友達を検索してみましょう',
              style: YanwariDesignSystem.headingMd.copyWith(
                color: YanwariDesignSystem.textTertiary,
              ),
            ),
            SizedBox(height: YanwariDesignSystem.spacingSm),
            Text(
              '上の検索バーに名前またはメールアドレスを入力してください',
              style: YanwariDesignSystem.bodyMd.copyWith(
                color: YanwariDesignSystem.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: YanwariDesignSystem.textTertiary,
            ),
            SizedBox(height: YanwariDesignSystem.spacingMd),
            Text(
              '検索結果が見つかりませんでした',
              style: YanwariDesignSystem.headingMd.copyWith(
                color: YanwariDesignSystem.textTertiary,
              ),
            ),
            SizedBox(height: YanwariDesignSystem.spacingSm),
            Text(
              '別のキーワードで検索してみてください',
              style: YanwariDesignSystem.bodyMd.copyWith(
                color: YanwariDesignSystem.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(AppUser user) {
    final isFriend = _friendService.isFriend(user.email);
    final hasPendingRequestTo = _friendService.hasPendingRequestTo(user.email);
    final hasPendingRequestFrom = _friendService.hasPendingRequestFrom(user.email);

    return Card(
      margin: EdgeInsets.only(bottom: YanwariDesignSystem.spacingSm),
      child: ListTile(
        contentPadding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
        leading: CircleAvatar(
          backgroundColor: YanwariDesignSystem.primaryColor,
          radius: 28,
          child: Text(
            user.name.isNotEmpty
                ? user.name.substring(0, 1).toUpperCase()
                : user.email.substring(0, 1).toUpperCase(),
            style: YanwariDesignSystem.headingMd.copyWith(
              color: YanwariDesignSystem.textPrimary,
            ),
          ),
        ),
        title: Text(
          user.name.isNotEmpty ? user.name : user.email,
          style: YanwariDesignSystem.bodyLg.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.name.isNotEmpty)
              Text(
                user.email,
                style: YanwariDesignSystem.bodySm,
              ),
            SizedBox(height: YanwariDesignSystem.spacingXs),
            _buildUserStatusChip(isFriend, hasPendingRequestTo, hasPendingRequestFrom),
          ],
        ),
        trailing: _buildActionButton(
          user,
          isFriend,
          hasPendingRequestTo,
          hasPendingRequestFrom,
        ),
      ),
    );
  }

  Widget _buildUserStatusChip(bool isFriend, bool hasPendingRequestTo, bool hasPendingRequestFrom) {
    if (isFriend) {
      return Chip(
        label: const Text('友達'),
        backgroundColor: YanwariDesignSystem.successColor.withOpacity(0.3),
        labelStyle: YanwariDesignSystem.caption.copyWith(
          color: YanwariDesignSystem.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        visualDensity: VisualDensity.compact,
      );
    } else if (hasPendingRequestTo) {
      return Chip(
        label: const Text('申請中'),
        backgroundColor: YanwariDesignSystem.secondaryColor.withOpacity(0.1),
        labelStyle: YanwariDesignSystem.caption.copyWith(
          color: YanwariDesignSystem.secondaryColor,
          fontWeight: FontWeight.w600,
        ),
        visualDensity: VisualDensity.compact,
      );
    } else if (hasPendingRequestFrom) {
      return Chip(
        label: const Text('申請受信中'),
        backgroundColor: YanwariDesignSystem.primaryColor.withOpacity(0.3),
        labelStyle: YanwariDesignSystem.caption.copyWith(
          color: YanwariDesignSystem.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        visualDensity: VisualDensity.compact,
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget? _buildActionButton(
    AppUser user,
    bool isFriend,
    bool hasPendingRequestTo,
    bool hasPendingRequestFrom,
  ) {
    if (isFriend || hasPendingRequestTo) {
      return null; // 友達または申請中の場合はボタンを表示しない
    }

    if (hasPendingRequestFrom) {
      return ElevatedButton(
        onPressed: () {
          // 友達申請画面に遷移するかダイアログを表示
          _showPendingRequestDialog(user);
        },
        style: YanwariDesignSystem.primaryButtonStyle.copyWith(
          minimumSize: MaterialStateProperty.all(const Size(80, 32)),
        ),
        child: const Text('確認'),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => _sendFriendRequest(user),
      icon: const Icon(Icons.person_add, size: 16),
      label: const Text('申請'),
      style: YanwariDesignSystem.primaryButtonStyle.copyWith(
        minimumSize: MaterialStateProperty.all(const Size(80, 32)),
      ),
    );
  }

  void _showPendingRequestDialog(AppUser user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${user.name}さんから友達申請'),
          content: Text('${user.name}さんから友達申請が届いています。友達申請管理画面で確認してください。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}