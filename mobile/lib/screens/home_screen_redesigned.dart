import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/dashboard.dart';
import '../utils/design_system.dart';
import 'settings_screen.dart';
import 'delivery_status_screen.dart';

class HomeScreenRedesigned extends StatefulWidget {
  const HomeScreenRedesigned({super.key});

  @override
  State<HomeScreenRedesigned> createState() => _HomeScreenRedesignedState();
}

class _HomeScreenRedesignedState extends State<HomeScreenRedesigned> {
  DashboardData? _dashboardData;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  /// ダッシュボードデータを読み込み
  Future<void> _loadDashboardData() async {
    if (!context.read<AuthService>().isAuthenticated) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      final apiService = ApiService(authService);
      
      final response = await apiService.getDashboard();
      final dashboardData = DashboardData.fromJson(response['data']);
      
      setState(() {
        _dashboardData = dashboardData;
      });
    } catch (e) {
      print('ダッシュボードデータ読み込みエラー: $e');
      setState(() {
        _error = 'データの読み込みに失敗しました';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    return Scaffold(
      backgroundColor: YanwariDesignSystem.backgroundPrimary,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                YanwariDesignSystem.primaryColorLight,
                YanwariDesignSystem.backgroundPrimary,
              ],
              stops: const [0.0, 0.2],
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ヘッダー
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: YanwariDesignSystem.spacingMd,
                      vertical: YanwariDesignSystem.spacingLg,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'やんわり伝言',
                          style: YanwariDesignSystem.headingXl.copyWith(
                            color: YanwariDesignSystem.textPrimary,
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: YanwariDesignSystem.textPrimary,
                          ),
                          onSelected: (value) async {
                            if (value == 'logout') {
                              await context.read<AuthService>().signOut();
                            } else if (value == 'settings') {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const SettingsScreen()),
                              );
                            } else if (value == 'delivery-status') {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const DeliveryStatusScreen()),
                              );
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem<String>(
                              value: 'delivery-status',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.track_changes,
                                    color: YanwariDesignSystem.textPrimary,
                                  ),
                                  SizedBox(width: YanwariDesignSystem.spacingSm),
                                  const Text('送信状況'),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'settings',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.settings,
                                    color: YanwariDesignSystem.textPrimary,
                                  ),
                                  SizedBox(width: YanwariDesignSystem.spacingSm),
                                  const Text('設定'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.logout,
                                    color: YanwariDesignSystem.errorColor,
                                  ),
                                  SizedBox(width: YanwariDesignSystem.spacingSm),
                                  Text('ログアウト'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // ユーザー情報カード
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(YanwariDesignSystem.spacingLg),
                    decoration: BoxDecoration(
                      color: YanwariDesignSystem.neutralColor,
                      borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusXl),
                      boxShadow: [YanwariDesignSystem.shadowMd],
                      border: Border.all(
                        color: YanwariDesignSystem.borderColor.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: YanwariDesignSystem.secondaryColor,
                              child: Text(
                                user?.displayName?.substring(0, 1).toUpperCase() ?? 
                                user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                                style: YanwariDesignSystem.headingLg.copyWith(
                                  color: YanwariDesignSystem.textInverse,
                                ),
                              ),
                            ),
                            SizedBox(width: YanwariDesignSystem.spacingMd),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'こんにちは！',
                                    style: YanwariDesignSystem.bodySm,
                                  ),
                                  Text(
                                    user?.displayName ?? user?.email ?? 'ゲスト',
                                    style: YanwariDesignSystem.headingMd.copyWith(
                                      color: YanwariDesignSystem.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: YanwariDesignSystem.spacingMd),
                        Container(
                          padding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
                          decoration: BoxDecoration(
                            color: YanwariDesignSystem.primaryColorLight,
                            borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusMd),
                          ),
                          child: Text(
                            '今日も思いやりのあるコミュニケーションを心がけましょう ✨',
                            style: YanwariDesignSystem.bodyMd.copyWith(
                              color: YanwariDesignSystem.secondaryColorDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: YanwariDesignSystem.spacingXl),

                  // 統計情報セクション
                  Text(
                    '今月の活動',
                    style: YanwariDesignSystem.headingMd,
                  ),
                  SizedBox(height: YanwariDesignSystem.spacingMd),
                  
                  // データ読み込み状態の処理
                  if (_isLoading)
                    Container(
                      height: 120,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text('統計データを読み込み中...'),
                          ],
                        ),
                      ),
                    )
                  else if (_error != null)
                    Container(
                      height: 120,
                      padding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_error!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _loadDashboardData,
                              child: const Text('再試行'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.send_rounded,
                            title: '送信',
                            value: _dashboardData?.activityStats.thisMonth.messagesSent.toString() ?? '0',
                            color: YanwariDesignSystem.successColor,
                          ),
                        ),
                        SizedBox(width: YanwariDesignSystem.spacingSm),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.inbox_rounded,
                            title: '受信',
                            value: _dashboardData?.activityStats.thisMonth.messagesReceived.toString() ?? '0',
                            color: YanwariDesignSystem.secondaryColor,
                          ),
                        ),
                        SizedBox(width: YanwariDesignSystem.spacingSm),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.people_rounded,
                            title: '友達',
                            value: _dashboardData?.activityStats.total.friends.toString() ?? '0',
                            color: YanwariDesignSystem.primaryColorDark,
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: YanwariDesignSystem.spacingXl),

                  // 最近のメッセージ
                  Text(
                    '最近のメッセージ',
                    style: YanwariDesignSystem.headingMd,
                  ),
                  SizedBox(height: YanwariDesignSystem.spacingMd),
                  
                  // 最近のメッセージ表示
                  if (_dashboardData?.recentMessages.isEmpty ?? true)
                    Container(
                      padding: EdgeInsets.all(YanwariDesignSystem.spacingLg),
                      decoration: BoxDecoration(
                        color: YanwariDesignSystem.neutralColor,
                        borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusLg),
                        boxShadow: [YanwariDesignSystem.shadowSm],
                        border: Border.all(
                          color: YanwariDesignSystem.borderColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'まだメッセージがありません',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: YanwariDesignSystem.neutralColor,
                        borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusLg),
                        boxShadow: [YanwariDesignSystem.shadowSm],
                        border: Border.all(
                          color: YanwariDesignSystem.borderColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: _dashboardData!.recentMessages
                          .take(3) // 最大3件まで表示
                          .map((message) => Column(
                            children: [
                              _buildRecentMessageItem(
                                name: message.displayName,
                                message: message.text,
                                time: _formatRelativeTime(message.sentAt),
                                isRead: message.isRead,
                                type: message.type,
                              ),
                              if (message != _dashboardData!.recentMessages.last)
                                Divider(
                                  height: 1,
                                  color: YanwariDesignSystem.borderColor.withOpacity(0.3),
                                ),
                            ],
                          ))
                          .toList(),
                      ),
                    ),
                  SizedBox(height: 100), // ボトムナビゲーション分のスペース
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusLg),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: color,
          ),
          SizedBox(height: YanwariDesignSystem.spacingSm),
          Text(
            value,
            style: YanwariDesignSystem.headingLg.copyWith(
              color: color,
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

  /// 相対時間をフォーマット
  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}時間前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }

  Widget _buildRecentMessageItem({
    required String name,
    required String message,
    required String time,
    required bool isRead,
    String type = 'received', // 'sent' or 'received'
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: YanwariDesignSystem.spacingMd,
        vertical: YanwariDesignSystem.spacingSm,
      ),
      leading: CircleAvatar(
        backgroundColor: YanwariDesignSystem.primaryColor,
        child: Text(
          name.substring(0, 1),
          style: YanwariDesignSystem.bodyMd.copyWith(
            color: YanwariDesignSystem.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        name,
        style: YanwariDesignSystem.bodyMd.copyWith(
          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          color: YanwariDesignSystem.textPrimary,
        ),
      ),
      subtitle: Text(
        message,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: YanwariDesignSystem.bodySm.copyWith(
          color: isRead ? YanwariDesignSystem.textSecondary : YanwariDesignSystem.textPrimary,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            time,
            style: YanwariDesignSystem.caption,
          ),
          if (!isRead)
            Container(
              margin: EdgeInsets.only(top: YanwariDesignSystem.spacingXs),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: YanwariDesignSystem.secondaryColor,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}