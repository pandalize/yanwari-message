import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: context.watch<AuthService>().authStateChanges,
      builder: (context, snapshot) {
        // ローディング中
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF81C784),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'やんわり伝言',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF81C784),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '初期化中...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // ユーザーがログインしているか確認
        if (snapshot.hasData && snapshot.data != null) {
          // ログイン済み → ホーム画面
          return const HomeScreen();
        } else {
          // 未ログイン → ログイン画面
          return const LoginScreen();
        }
      },
    );
  }
}