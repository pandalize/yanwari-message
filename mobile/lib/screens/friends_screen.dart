import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/friend_service.dart';
import '../utils/design_system.dart';
import '../models/friend.dart';
import 'add_friend_screen.dart';
import 'friend_requests_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  late final FriendService _friendService;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    final apiService = ApiService(authService);
    _friendService = FriendService(apiService, authService);
    _initializeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _friendService.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    if (!_isInitialized) {
      await _friendService.loadAll();
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _friendService.loadAll();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  List<Friend> get _filteredFriends {
    return _friendService.searchFriends(_searchQuery);
  }

  void _showRemoveFriendConfirmation(Friend friend) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('友達削除'),
          content: Text('${friend.friend.name}さんを友達から削除しますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _friendService.removeFriend(friend.friend.email);
                if (_friendService.errorMessage != null) {
                  _showErrorSnackBar(_friendService.errorMessage!);
                } else {
                  _showSuccessSnackBar('友達を削除しました');
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: YanwariDesignSystem.errorColor,
              ),
              child: const Text('削除'),
            ),
          ],
        );
      },
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
    return ChangeNotifierProvider.value(
      value: _friendService,
      child: Scaffold(
        backgroundColor: YanwariDesignSystem.backgroundMuted,
        appBar: AppBar(
          title: const Text('友達'),
          backgroundColor: YanwariDesignSystem.backgroundPrimary,
          elevation: 0,
          actions: [
            // 友達申請管理ボタン
            Consumer<FriendService>(
              builder: (context, friendService, child) {
                final requestCount = friendService.receivedRequestsCount;
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ChangeNotifierProvider.value(
                              value: _friendService,
                              child: const FriendRequestsScreen(),
                            ),
                          ),
                        );
                      },
                    ),
                    if (requestCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: YanwariDesignSystem.errorColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$requestCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            // 友達追加ボタン
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider.value(
                      value: _friendService,
                      child: const AddFriendScreen(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: Consumer<FriendService>(
          builder: (context, friendService, child) {
            if (!_isInitialized && friendService.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: Column(
                children: [
                  // 検索バー
                  Container(
                    padding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
                    color: YanwariDesignSystem.backgroundPrimary,
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: YanwariDesignSystem.inputDecoration(
                        hintText: '友達を検索',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),

                  // 統計情報
                  Container(
                    padding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
                    color: YanwariDesignSystem.backgroundPrimary,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.people,
                            title: '友達',
                            count: friendService.friendsCount,
                            color: YanwariDesignSystem.primaryColorDark,
                          ),
                        ),
                        SizedBox(width: YanwariDesignSystem.spacingSm),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.mail_outline,
                            title: '申請中',
                            count: friendService.sentRequestsCount,
                            color: YanwariDesignSystem.secondaryColor,
                          ),
                        ),
                        SizedBox(width: YanwariDesignSystem.spacingSm),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.notifications_active,
                            title: '受信',
                            count: friendService.receivedRequestsCount,
                            color: YanwariDesignSystem.errorColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // エラーメッセージ
                  if (friendService.errorMessage != null)
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
                              friendService.errorMessage!,
                              style: YanwariDesignSystem.bodySm.copyWith(
                                color: YanwariDesignSystem.errorColor,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            iconSize: 18,
                            color: YanwariDesignSystem.errorColor,
                            onPressed: () => friendService.clearError(),
                          ),
                        ],
                      ),
                    ),

                  // 友達リスト
                  Expanded(
                    child: _buildFriendsList(friendService),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(YanwariDesignSystem.spacingSm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusMd),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: YanwariDesignSystem.spacingXs),
          Text(
            '$count',
            style: YanwariDesignSystem.headingMd.copyWith(
              color: color,
              fontSize: YanwariDesignSystem.fontSizeLg,
            ),
          ),
          Text(
            title,
            style: YanwariDesignSystem.caption.copyWith(
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList(FriendService friendService) {
    final friends = _filteredFriends;

    if (friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
              size: 64,
              color: YanwariDesignSystem.textTertiary,
            ),
            SizedBox(height: YanwariDesignSystem.spacingMd),
            Text(
              _searchQuery.isNotEmpty 
                  ? '検索結果がありません'
                  : 'まだ友達がいません',
              style: YanwariDesignSystem.headingMd.copyWith(
                color: YanwariDesignSystem.textTertiary,
              ),
            ),
            SizedBox(height: YanwariDesignSystem.spacingSm),
            Text(
              _searchQuery.isNotEmpty 
                  ? '別のキーワードで検索してみてください'
                  : '友達を追加して、やんわり伝言を始めましょう',
              style: YanwariDesignSystem.bodyMd.copyWith(
                color: YanwariDesignSystem.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty) ...[
              SizedBox(height: YanwariDesignSystem.spacingLg),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider.value(
                        value: _friendService,
                        child: const AddFriendScreen(),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.person_add),
                label: const Text('友達を追加'),
                style: YanwariDesignSystem.primaryButtonStyle,
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        return Card(
          margin: EdgeInsets.only(bottom: YanwariDesignSystem.spacingSm),
          child: ListTile(
            contentPadding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
            leading: CircleAvatar(
              backgroundColor: YanwariDesignSystem.primaryColor,
              radius: 28,
              child: Text(
                friend.friend.name.isNotEmpty
                    ? friend.friend.name.substring(0, 1).toUpperCase()
                    : friend.friend.email.substring(0, 1).toUpperCase(),
                style: YanwariDesignSystem.headingMd.copyWith(
                  color: YanwariDesignSystem.textPrimary,
                ),
              ),
            ),
            title: Text(
              friend.friend.name.isNotEmpty 
                  ? friend.friend.name 
                  : friend.friend.email,
              style: YanwariDesignSystem.bodyLg.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (friend.friend.name.isNotEmpty)
                  Text(
                    friend.friend.email,
                    style: YanwariDesignSystem.bodySm,
                  ),
                SizedBox(height: YanwariDesignSystem.spacingXs),
                Text(
                  '友達になった日: ${_formatDate(friend.createdAt)}',
                  style: YanwariDesignSystem.caption,
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'remove') {
                  _showRemoveFriendConfirmation(friend);
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_remove,
                        color: YanwariDesignSystem.errorColor,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text('友達削除'),
                    ],
                  ),
                ),
              ],
              child: Icon(
                Icons.more_vert,
                color: YanwariDesignSystem.textSecondary,
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '今日';
    } else if (difference.inDays == 1) {
      return '昨日';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}週間前';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}ヶ月前';
    } else {
      return '${(difference.inDays / 365).floor()}年前';
    }
  }
}