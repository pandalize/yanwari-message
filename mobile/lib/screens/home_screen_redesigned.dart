import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../utils/design_system.dart';

class HomeScreenRedesigned extends StatelessWidget {
  const HomeScreenRedesigned({super.key});

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
                              // 設定画面へ遷移
                            }
                          },
                          itemBuilder: (BuildContext context) => [
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
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.send_rounded,
                          title: '送信',
                          value: '12',
                          color: YanwariDesignSystem.successColor,
                        ),
                      ),
                      SizedBox(width: YanwariDesignSystem.spacingSm),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.inbox_rounded,
                          title: '受信',
                          value: '8',
                          color: YanwariDesignSystem.secondaryColor,
                        ),
                      ),
                      SizedBox(width: YanwariDesignSystem.spacingSm),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.people_rounded,
                          title: '友達',
                          value: '15',
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
                      children: [
                        _buildRecentMessageItem(
                          name: '田中さん',
                          message: 'ミーティングの件、了解しました！',
                          time: '2時間前',
                          isRead: false,
                        ),
                        Divider(
                          height: 1,
                          color: YanwariDesignSystem.borderColor.withOpacity(0.3),
                        ),
                        _buildRecentMessageItem(
                          name: '佐藤さん',
                          message: 'お疲れ様でした。明日もよろしくお願いします。',
                          time: '昨日',
                          isRead: true,
                        ),
                        Divider(
                          height: 1,
                          color: YanwariDesignSystem.borderColor.withOpacity(0.3),
                        ),
                        _buildRecentMessageItem(
                          name: '鈴木さん',
                          message: 'プレゼン資料、確認しました。',
                          time: '2日前',
                          isRead: true,
                        ),
                      ],
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

  Widget _buildRecentMessageItem({
    required String name,
    required String message,
    required String time,
    required bool isRead,
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