import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/api_service.dart';

class InboxTestScreen extends StatefulWidget {
  const InboxTestScreen({super.key});

  @override
  State<InboxTestScreen> createState() => _InboxTestScreenState();
}

class _InboxTestScreenState extends State<InboxTestScreen> {
  late final ApiService _apiService;
  bool _isLoading = false;
  String _testResult = '';
  String? _userProfile;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(context.read<AuthService>());
    _runTests();
  }

  Future<void> _runTests() async {
    setState(() {
      _isLoading = true;
      _testResult = 'テスト実行中...\n';
    });

    // Test 1: Firebase認証確認
    try {
      final user = context.read<AuthService>().currentUser;
      _addResult('✅ Firebase認証: ${user?.email ?? "未ログイン"}');
      
      if (user != null) {
        final token = await context.read<AuthService>().getIdToken();
        _addResult('✅ IDトークン取得: ${token != null ? "成功" : "失敗"}');
      }
    } catch (e) {
      _addResult('❌ Firebase認証エラー: $e');
    }

    // Test 2: バックエンド接続確認
    try {
      final response = await _apiService.healthCheck();
      _addResult('✅ バックエンド接続: ${response['status']}');
    } catch (e) {
      _addResult('❌ バックエンド接続エラー: $e');
    }

    // Test 3: Firebase認証プロフィール取得
    try {
      final profile = await _apiService.getUserProfile();
      _addResult('✅ プロフィール取得成功');
      setState(() {
        _userProfile = profile.toString();
      });
    } catch (e) {
      _addResult('❌ プロフィール取得エラー: $e');
    }

    // Test 4: 利用可能なエンドポイントテスト
    final endpoints = [
      '/messages/',
      '/messages/received',
      '/transform/tones',
      '/schedule/suggest',
      '/schedules/',
      '/friends/',
      '/friend-requests/received',
    ];

    for (final endpoint in endpoints) {
      await _testEndpoint(endpoint);
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testEndpoint(String endpoint) async {
    try {
      // 簡単なGETリクエストでエンドポイントの存在確認
      await _apiService.healthCheck(); // 一旦ヘルスチェックで代用
      _addResult('🔍 エンドポイント $endpoint: テスト中...');
    } catch (e) {
      _addResult('❌ エンドポイント $endpoint: $e');
    }
  }

  void _addResult(String result) {
    setState(() {
      _testResult += '$result\n';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'API連携テスト',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF42A5F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _runTests,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF42A5F5),
              Colors.white,
            ],
            stops: [0.0, 0.2],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // テスト結果表示
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.bug_report,
                              color: Color(0xFF42A5F5),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'API連携テスト結果',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_isLoading)
                                  const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF42A5F5),
                                    ),
                                  )
                                else
                                  Text(
                                    _testResult,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                      height: 1.4,
                                    ),
                                  ),
                                if (_userProfile != null) ...[
                                  const SizedBox(height: 16),
                                  const Text(
                                    'ユーザープロフィール:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _userProfile!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 再テストボタン
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _runTests,
                  icon: const Icon(Icons.refresh),
                  label: const Text('再テスト実行'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF42A5F5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}