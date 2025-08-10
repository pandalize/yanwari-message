import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../utils/design_system.dart';
import 'login_screen_redesigned.dart';
import '../widgets/main_navigation_wrapper.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: context.watch<AuthService>().authStateChanges,
      builder: (context, snapshot) {
        // ローディング中
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: YanwariDesignSystem.backgroundMuted,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ロゴアイコン
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: YanwariDesignSystem.secondaryColor,
                      borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusFull),
                      boxShadow: [YanwariDesignSystem.shadowMd],
                    ),
                    child: const Icon(
                      Icons.message_rounded,
                      size: 40,
                      color: YanwariDesignSystem.textInverse,
                    ),
                  ),
                  const SizedBox(height: YanwariDesignSystem.spacingLg),
                  const CircularProgressIndicator(
                    color: YanwariDesignSystem.secondaryColor,
                  ),
                  const SizedBox(height: YanwariDesignSystem.spacingMd),
                  Text(
                    'やんわり伝言',
                    style: YanwariDesignSystem.headingLg.copyWith(
                      color: YanwariDesignSystem.secondaryColor,
                    ),
                  ),
                  const SizedBox(height: YanwariDesignSystem.spacingSm),
                  Text(
                    '初期化中...',
                    style: YanwariDesignSystem.bodyMd.copyWith(
                      color: YanwariDesignSystem.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // ユーザーがログインしているか確認
        if (snapshot.hasData && snapshot.data != null) {
          // ログイン済み → ナビゲーション付きホーム画面
          return const MainNavigationWrapper();
        } else {
          // 未ログイン → ログイン画面
          return const LoginScreenRedesigned();
        }
      },
    );
  }
}