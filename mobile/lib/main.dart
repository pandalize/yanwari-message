import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Import services and screens
import 'services/auth_service.dart';
import 'screens/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase初期化
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDMN2wUjE6NicanP0KP8ybnPgJZloMNOoI",
      authDomain: "yanwari-message.firebaseapp.com",
      projectId: "yanwari-message",
      storageBucket: "yanwari-message.appspot.com",
      messagingSenderId: "123456789",
      appId: "1:123456789:android:abcdef123456",
      iosBundleId: "com.example.yanwariMessageMobile",
    ),
  );
  
  runApp(const YanwariApp());
}

class YanwariApp extends StatelessWidget {
  const YanwariApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'やんわり伝言',
        theme: ThemeData(
          // やんわりとした優しい色合いのテーマ
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF81C784), // 優しい緑色
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          // 日本語フォント対応
          fontFamily: 'NotoSansJP',
        ),
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}