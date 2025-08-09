import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Import services, screens, and design system
import 'services/auth_service.dart';
import 'screens/auth_wrapper.dart';
import 'utils/design_system.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase初期化（エラーハンドリング付き）
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDMN2wUjE6NicanP0KP8ybnPgJZloMNOoI",
        authDomain: "yanwari-message.firebaseapp.com",
        projectId: "yanwari-message",
        storageBucket: "yanwari-message.appspot.com",
        messagingSenderId: "24525991821",
        appId: "1:24525991821:ios:abc123def456789", // iOS用AppID
        iosBundleId: "com.example.yanwariMessageMobile",
      ),
    );
    print('✅ Firebase初期化成功');
  } catch (e) {
    print('⚠️ Firebase初期化エラー: $e');
    print('アプリはFirebaseなしで起動します');
  }
  
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
        theme: YanwariDesignSystem.lightTheme,
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}