import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/friend_service.dart';
import '../utils/design_system.dart';
import '../models/friend.dart';
import 'add_friend_screen.dart';
import 'friend_requests_screen.dart';

class FriendManagementScreen extends StatefulWidget {
  const FriendManagementScreen({super.key});

  @override
  State<FriendManagementScreen> createState() => _FriendManagementScreenState();
}

class _FriendManagementScreenState extends State<FriendManagementScreen> {
  late final FriendService _friendService;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isInitialized = false;
  int _selectedIndex = 0; // 0: 友達, 1: 受信申請, 2: 送信申請

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
      child: _buildPageContainer(),
    );
  }

  Widget _buildPageContainer() {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // var(--background-primary) equivalent
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 32), // Web版: 32px 20px
          width: double.infinity,
          child: Column(
            children: [
              // Web版 PageTitle.vue equivalent
              _buildPageTitle(),
              const SizedBox(height: 32), // Web版: margin: 0 0 32px 0
              // メインコンテンツ
              Expanded(child: _buildMainContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageTitle() {
    return Consumer<FriendService>(
      builder: (context, friendService, child) {
        return Column(
          children: [
            Container(
              width: double.infinity,
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '友達管理',
                      style: TextStyle(
                        color: Color(0xFF1F2937), // var(--text-primary)
                        fontSize: 24, // Web版と同じ
                        fontWeight: FontWeight.w600,
                        height: 1.5, // var(--line-height-base)
                      ),
                    ),
                  ),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      elevation: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // タブバー
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildTabBar(friendService),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabBar(FriendService friendService) {
    return Container(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTabItem(
            index: 0,
            icon: Icons.people,
            title: '友達',
            count: friendService.friendsCount,
            isSelected: _selectedIndex == 0,
          ),
          _buildTabItem(
            index: 1,
            icon: Icons.inbox,
            title: '受信申請',
            count: friendService.receivedRequestsCount,
            isSelected: _selectedIndex == 1,
          ),
          _buildTabItem(
            index: 2,
            icon: Icons.outbox,
            title: '送信申請',
            count: friendService.sentRequestsCount,
            isSelected: _selectedIndex == 2,
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required String title,
    required int count,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Consumer<FriendService>(
      builder: (context, friendService, child) {
        if (!_isInitialized && friendService.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: _buildContentArea(friendService),
        );
      },
    );
  }

  Widget _buildContentArea(FriendService friendService) {
    switch (_selectedIndex) {
      case 0:
        return _buildFriendsTab(friendService);
      case 1:
        return _buildReceivedRequestsContent(friendService);
      case 2:
        return _buildSentRequestsContent(friendService);
      default:
        return _buildFriendsTab(friendService);
    }
  }

  Widget _buildFriendsTab(FriendService friendService) {
    return Column(
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





  Widget _buildReceivedRequestsContent(FriendService friendService) {
    if (friendService.isLoading && friendService.receivedRequests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final requests = friendService.receivedRequests;

    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: YanwariDesignSystem.textTertiary,
            ),
            SizedBox(height: YanwariDesignSystem.spacingMd),
            Text(
              '受信した友達申請はありません',
              style: YanwariDesignSystem.headingMd.copyWith(
                color: YanwariDesignSystem.textTertiary,
              ),
            ),
            SizedBox(height: YanwariDesignSystem.spacingSm),
            Text(
              '他のユーザーから友達申請が届くとここに表示されます',
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
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _buildReceivedRequestCard(request, friendService);
      },
    );
  }

  Widget _buildSentRequestsContent(FriendService friendService) {
    if (friendService.isLoading && friendService.sentRequests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final requests = friendService.sentRequests;

    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.outbox_outlined,
              size: 64,
              color: YanwariDesignSystem.textTertiary,
            ),
            SizedBox(height: YanwariDesignSystem.spacingMd),
            Text(
              '送信した友達申請はありません',
              style: YanwariDesignSystem.headingMd.copyWith(
                color: YanwariDesignSystem.textTertiary,
              ),
            ),
            SizedBox(height: YanwariDesignSystem.spacingSm),
            Text(
              '友達を追加して申請を送信しましょう',
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
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _buildSentRequestCard(request, friendService);
      },
    );
  }

  Widget _buildReceivedRequestCard(FriendRequest request, FriendService friendService) {
    return Card(
      margin: EdgeInsets.only(bottom: YanwariDesignSystem.spacingSm),
      child: ListTile(
        contentPadding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
        leading: CircleAvatar(
          backgroundColor: YanwariDesignSystem.primaryColor,
          radius: 28,
          child: Text(
            (request.fromUser?.name?.isNotEmpty ?? false)
                ? request.fromUser!.name.substring(0, 1).toUpperCase()
                : (request.fromUser?.email.substring(0, 1).toUpperCase() ?? '?'),
            style: YanwariDesignSystem.headingMd.copyWith(
              color: YanwariDesignSystem.textPrimary,
            ),
          ),
        ),
        title: Text(
          (request.fromUser?.name?.isNotEmpty ?? false)
              ? request.fromUser!.name 
              : (request.fromUser?.email ?? 'Unknown'),
          style: YanwariDesignSystem.bodyLg.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (request.fromUser?.name?.isNotEmpty ?? false)
              Text(
                request.fromUser?.email ?? 'Unknown',
                style: YanwariDesignSystem.bodySm,
              ),
            SizedBox(height: YanwariDesignSystem.spacingXs),
            Text(
              '申請日時: ${_formatDate(request.createdAt)}',
              style: YanwariDesignSystem.caption,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                await friendService.acceptFriendRequest(request.id);
                if (friendService.errorMessage != null) {
                  _showErrorSnackBar(friendService.errorMessage!);
                } else {
                  _showSuccessSnackBar('友達申請を承認しました');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: YanwariDesignSystem.successColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(60, 32),
                padding: EdgeInsets.symmetric(
                  horizontal: YanwariDesignSystem.spacingSm,
                ),
              ),
              child: const Text('承認'),
            ),
            SizedBox(width: YanwariDesignSystem.spacingXs),
            OutlinedButton(
              onPressed: () async {
                await friendService.rejectFriendRequest(request.id);
                if (friendService.errorMessage != null) {
                  _showErrorSnackBar(friendService.errorMessage!);
                } else {
                  _showSuccessSnackBar('友達申請を拒否しました');
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: YanwariDesignSystem.errorColor,
                side: BorderSide(color: YanwariDesignSystem.errorColor),
                minimumSize: const Size(60, 32),
                padding: EdgeInsets.symmetric(
                  horizontal: YanwariDesignSystem.spacingSm,
                ),
              ),
              child: const Text('拒否'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentRequestCard(FriendRequest request, FriendService friendService) {
    return Card(
      margin: EdgeInsets.only(bottom: YanwariDesignSystem.spacingSm),
      child: ListTile(
        contentPadding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
        leading: CircleAvatar(
          backgroundColor: YanwariDesignSystem.secondaryColor,
          radius: 28,
          child: Text(
            (request.toUser?.name?.isNotEmpty ?? false)
                ? request.toUser!.name.substring(0, 1).toUpperCase()
                : (request.toUser?.email.substring(0, 1).toUpperCase() ?? '?'),
            style: YanwariDesignSystem.headingMd.copyWith(
              color: YanwariDesignSystem.textPrimary,
            ),
          ),
        ),
        title: Text(
          (request.toUser?.name?.isNotEmpty ?? false)
              ? request.toUser!.name 
              : (request.toUser?.email ?? 'Unknown'),
          style: YanwariDesignSystem.bodyLg.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (request.toUser?.name?.isNotEmpty ?? false)
              Text(
                request.toUser?.email ?? 'Unknown',
                style: YanwariDesignSystem.bodySm,
              ),
            SizedBox(height: YanwariDesignSystem.spacingXs),
            Text(
              '申請日時: ${_formatDate(request.createdAt)}',
              style: YanwariDesignSystem.caption,
            ),
            SizedBox(height: YanwariDesignSystem.spacingXs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: request.status == 'accepted'
                    ? YanwariDesignSystem.successColor
                    : YanwariDesignSystem.secondaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                request.status == 'accepted' ? '承認済み' : '承認待ち',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: request.status != 'accepted'
            ? OutlinedButton(
                onPressed: () async {
                  await friendService.cancelFriendRequest(request.id);
                  if (friendService.errorMessage != null) {
                    _showErrorSnackBar(friendService.errorMessage!);
                  } else {
                    _showSuccessSnackBar('友達申請をキャンセルしました');
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: YanwariDesignSystem.errorColor,
                  side: BorderSide(color: YanwariDesignSystem.errorColor),
                  minimumSize: const Size(80, 32),
                  padding: EdgeInsets.symmetric(
                    horizontal: YanwariDesignSystem.spacingSm,
                  ),
                ),
                child: const Text('キャンセル'),
              )
            : null,
      ),
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