import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../services/friend_service.dart';
import '../utils/design_system.dart';
import '../models/friend.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final friendService = context.read<FriendService>();
    await friendService.loadFriendRequests();
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
        title: const Text('友達申請'),
        backgroundColor: YanwariDesignSystem.backgroundPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: YanwariDesignSystem.secondaryColor,
          labelColor: YanwariDesignSystem.textPrimary,
          unselectedLabelColor: YanwariDesignSystem.textSecondary,
          tabs: const [
            Tab(
              icon: Icon(Icons.inbox),
              text: '受信した申請',
            ),
            Tab(
              icon: Icon(Icons.outbox),
              text: '送信した申請',
            ),
          ],
        ),
      ),
      body: Consumer<FriendService>(
        builder: (context, friendService, child) {
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReceivedRequests(friendService),
                _buildSentRequests(friendService),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReceivedRequests(FriendService friendService) {
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

  Widget _buildSentRequests(FriendService friendService) {
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
              '友達申請を送信すると、その状況をここで確認できます',
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
    final fromUser = request.fromUser;
    
    return Card(
      margin: EdgeInsets.only(bottom: YanwariDesignSystem.spacingSm),
      child: Padding(
        padding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ユーザー情報
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: YanwariDesignSystem.primaryColor,
                  radius: 24,
                  child: Text(
                    fromUser?.name.isNotEmpty == true
                        ? fromUser!.name.substring(0, 1).toUpperCase()
                        : fromUser?.email.substring(0, 1).toUpperCase() ?? '?',
                    style: YanwariDesignSystem.bodyLg.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: YanwariDesignSystem.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fromUser?.name.isNotEmpty == true 
                            ? fromUser!.name 
                            : fromUser?.email ?? '不明なユーザー',
                        style: YanwariDesignSystem.bodyLg.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (fromUser?.name.isNotEmpty == true)
                        Text(
                          fromUser!.email,
                          style: YanwariDesignSystem.bodySm,
                        ),
                      Text(
                        DateFormat('yyyy/MM/dd HH:mm').format(request.createdAt),
                        style: YanwariDesignSystem.caption,
                      ),
                    ],
                  ),
                ),
                _buildRequestStatusChip(request.status),
              ],
            ),

            // メッセージ
            if (request.message != null && request.message!.isNotEmpty) ...[
              SizedBox(height: YanwariDesignSystem.spacingMd),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(YanwariDesignSystem.spacingSm),
                decoration: BoxDecoration(
                  color: YanwariDesignSystem.backgroundSecondary,
                  borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusSm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'メッセージ',
                      style: YanwariDesignSystem.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: YanwariDesignSystem.spacingXs),
                    Text(
                      request.message!,
                      style: YanwariDesignSystem.bodySm,
                    ),
                  ],
                ),
              ),
            ],

            // アクションボタン
            if (request.isPending) ...[
              SizedBox(height: YanwariDesignSystem.spacingMd),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: friendService.isLoading 
                          ? null 
                          : () => _acceptRequest(request.id, friendService),
                      icon: const Icon(Icons.check),
                      label: const Text('承認'),
                      style: YanwariDesignSystem.primaryButtonStyle,
                    ),
                  ),
                  SizedBox(width: YanwariDesignSystem.spacingSm),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: friendService.isLoading 
                          ? null 
                          : () => _rejectRequest(request.id, friendService),
                      icon: const Icon(Icons.close),
                      label: const Text('拒否'),
                      style: YanwariDesignSystem.secondaryButtonStyle.copyWith(
                        backgroundColor: MaterialStateProperty.all(YanwariDesignSystem.errorColor),
                        foregroundColor: MaterialStateProperty.all(YanwariDesignSystem.textInverse),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSentRequestCard(FriendRequest request, FriendService friendService) {
    final toUser = request.toUser;
    
    return Card(
      margin: EdgeInsets.only(bottom: YanwariDesignSystem.spacingSm),
      child: Padding(
        padding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ユーザー情報
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: YanwariDesignSystem.primaryColor,
                  radius: 24,
                  child: Text(
                    toUser?.name.isNotEmpty == true
                        ? toUser!.name.substring(0, 1).toUpperCase()
                        : toUser?.email.substring(0, 1).toUpperCase() ?? '?',
                    style: YanwariDesignSystem.bodyLg.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: YanwariDesignSystem.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        toUser?.name.isNotEmpty == true 
                            ? toUser!.name 
                            : toUser?.email ?? '不明なユーザー',
                        style: YanwariDesignSystem.bodyLg.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (toUser?.name.isNotEmpty == true)
                        Text(
                          toUser!.email,
                          style: YanwariDesignSystem.bodySm,
                        ),
                      Text(
                        DateFormat('yyyy/MM/dd HH:mm').format(request.createdAt),
                        style: YanwariDesignSystem.caption,
                      ),
                    ],
                  ),
                ),
                _buildRequestStatusChip(request.status),
              ],
            ),

            // メッセージ
            if (request.message != null && request.message!.isNotEmpty) ...[
              SizedBox(height: YanwariDesignSystem.spacingMd),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(YanwariDesignSystem.spacingSm),
                decoration: BoxDecoration(
                  color: YanwariDesignSystem.backgroundSecondary,
                  borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusSm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '送信したメッセージ',
                      style: YanwariDesignSystem.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: YanwariDesignSystem.spacingXs),
                    Text(
                      request.message!,
                      style: YanwariDesignSystem.bodySm,
                    ),
                  ],
                ),
              ),
            ],

            // キャンセルボタン
            if (request.isPending) ...[
              SizedBox(height: YanwariDesignSystem.spacingMd),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: friendService.isLoading 
                      ? null 
                      : () => _cancelRequest(request.id, friendService),
                  icon: const Icon(Icons.cancel),
                  label: const Text('申請をキャンセル'),
                  style: YanwariDesignSystem.secondaryButtonStyle.copyWith(
                    backgroundColor: MaterialStateProperty.all(YanwariDesignSystem.errorColor),
                    foregroundColor: MaterialStateProperty.all(YanwariDesignSystem.textInverse),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRequestStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case 'pending':
        backgroundColor = YanwariDesignSystem.secondaryColor.withOpacity(0.1);
        textColor = YanwariDesignSystem.secondaryColor;
        label = '申請中';
        icon = Icons.hourglass_empty;
        break;
      case 'accepted':
        backgroundColor = YanwariDesignSystem.successColor.withOpacity(0.3);
        textColor = YanwariDesignSystem.textPrimary;
        label = '承認済み';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        backgroundColor = YanwariDesignSystem.errorColor.withOpacity(0.1);
        textColor = YanwariDesignSystem.errorColor;
        label = '拒否済み';
        icon = Icons.cancel;
        break;
      case 'canceled':
        backgroundColor = YanwariDesignSystem.grayColor.withOpacity(0.2);
        textColor = YanwariDesignSystem.textSecondary;
        label = 'キャンセル済み';
        icon = Icons.cancel_outlined;
        break;
      default:
        backgroundColor = YanwariDesignSystem.grayColor.withOpacity(0.2);
        textColor = YanwariDesignSystem.textSecondary;
        label = status;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          SizedBox(width: YanwariDesignSystem.spacingXs),
          Text(
            label,
            style: YanwariDesignSystem.caption.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptRequest(String requestId, FriendService friendService) async {
    final success = await friendService.acceptFriendRequest(requestId);
    if (success) {
      _showSuccessSnackBar('友達申請を承認しました');
    } else if (friendService.errorMessage != null) {
      _showErrorSnackBar(friendService.errorMessage!);
    }
  }

  Future<void> _rejectRequest(String requestId, FriendService friendService) async {
    final success = await friendService.rejectFriendRequest(requestId);
    if (success) {
      _showSuccessSnackBar('友達申請を拒否しました');
    } else if (friendService.errorMessage != null) {
      _showErrorSnackBar(friendService.errorMessage!);
    }
  }

  Future<void> _cancelRequest(String requestId, FriendService friendService) async {
    // 確認ダイアログを表示
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('申請をキャンセル'),
          content: const Text('友達申請をキャンセルしますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('いいえ'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: YanwariDesignSystem.errorColor,
              ),
              child: const Text('はい'),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirmed) {
      final success = await friendService.cancelFriendRequest(requestId);
      if (success) {
        _showSuccessSnackBar('友達申請をキャンセルしました');
      } else if (friendService.errorMessage != null) {
        _showErrorSnackBar(friendService.errorMessage!);
      }
    }
  }
}