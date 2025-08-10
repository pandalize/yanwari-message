import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/design_system.dart';

/// 設定画面
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _messageDelivered = true;
  String _timezone = 'Asia/Tokyo';
  
  Map<String, dynamic>? _userSettings;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  /// ユーザー設定を読み込み
  Future<void> _loadUserSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = context.read<AuthService>();
      final apiService = ApiService(authService);
      
      final response = await apiService.getUserSettings();
      final settings = response['data'];
      
      setState(() {
        _userSettings = settings;
        _nameController.text = settings['name'] ?? '';
        _timezone = settings['timezone'] ?? 'Asia/Tokyo';
        _emailNotifications = settings['notifications']?['email_notifications'] ?? true;
        _pushNotifications = settings['notifications']?['push_notifications'] ?? true;
        _messageDelivered = settings['notifications']?['message_delivered'] ?? true;
      });
    } catch (e) {
      print('設定読み込みエラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('設定の読み込みに失敗しました')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// プロフィール更新
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = context.read<AuthService>();
      final apiService = ApiService(authService);

      await apiService.updateProfile(
        name: _nameController.text.trim(),
        timezone: _timezone,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('プロフィールを更新しました')),
        );
      }
    } catch (e) {
      print('プロフィール更新エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('プロフィールの更新に失敗しました')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 通知設定更新
  Future<void> _updateNotificationSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = context.read<AuthService>();
      final apiService = ApiService(authService);

      await apiService.updateNotificationSettings(
        emailNotifications: _emailNotifications,
        pushNotifications: _pushNotifications,
        messageDelivered: _messageDelivered,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('通知設定を更新しました')),
        );
      }
    } catch (e) {
      print('通知設定更新エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('通知設定の更新に失敗しました')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// ログアウト
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthService>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    return Scaffold(
      backgroundColor: YanwariDesignSystem.backgroundPrimary,
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: YanwariDesignSystem.primaryColor,
        foregroundColor: YanwariDesignSystem.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('設定を読み込み中...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // プロフィール設定
                    _buildSectionCard(
                      title: 'プロフィール設定',
                      children: [
                        // 表示名
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: '表示名',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '表示名を入力してください';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: YanwariDesignSystem.spacingMd),

                        // メールアドレス（読み取り専用）
                        TextFormField(
                          initialValue: user?.email ?? '',
                          decoration: const InputDecoration(
                            labelText: 'メールアドレス',
                            border: OutlineInputBorder(),
                          ),
                          enabled: false,
                        ),
                        SizedBox(height: YanwariDesignSystem.spacingMd),

                        // タイムゾーン
                        DropdownButtonFormField<String>(
                          value: _timezone,
                          decoration: const InputDecoration(
                            labelText: 'タイムゾーン',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Asia/Tokyo', child: Text('Asia/Tokyo (JST)')),
                            DropdownMenuItem(value: 'UTC', child: Text('UTC')),
                            DropdownMenuItem(value: 'America/New_York', child: Text('America/New_York (EST)')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _timezone = value;
                              });
                            }
                          },
                        ),
                        SizedBox(height: YanwariDesignSystem.spacingMd),

                        // 更新ボタン
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: YanwariDesignSystem.secondaryColor,
                              foregroundColor: YanwariDesignSystem.textPrimary,
                            ),
                            child: const Text('プロフィールを更新'),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: YanwariDesignSystem.spacingXl),

                    // 通知設定
                    _buildSectionCard(
                      title: '通知設定',
                      children: [
                        SwitchListTile(
                          title: const Text('メール通知'),
                          subtitle: const Text('新しいメッセージの通知をメールで受け取る'),
                          value: _emailNotifications,
                          onChanged: (value) {
                            setState(() {
                              _emailNotifications = value;
                            });
                            _updateNotificationSettings();
                          },
                          activeColor: YanwariDesignSystem.successColor,
                        ),
                        SwitchListTile(
                          title: const Text('プッシュ通知'),
                          subtitle: const Text('アプリからの通知を受け取る'),
                          value: _pushNotifications,
                          onChanged: (value) {
                            setState(() {
                              _pushNotifications = value;
                            });
                            _updateNotificationSettings();
                          },
                          activeColor: YanwariDesignSystem.successColor,
                        ),
                        SwitchListTile(
                          title: const Text('配信完了通知'),
                          subtitle: const Text('メッセージが配信されたときに通知を受け取る'),
                          value: _messageDelivered,
                          onChanged: (value) {
                            setState(() {
                              _messageDelivered = value;
                            });
                            _updateNotificationSettings();
                          },
                          activeColor: YanwariDesignSystem.successColor,
                        ),
                      ],
                    ),

                    SizedBox(height: YanwariDesignSystem.spacingXl),

                    // アカウント操作
                    _buildSectionCard(
                      title: 'アカウント',
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.logout,
                            color: YanwariDesignSystem.errorColor,
                          ),
                          title: const Text('ログアウト'),
                          subtitle: const Text('アカウントからログアウトします'),
                          onTap: _logout,
                        ),
                      ],
                    ),

                    SizedBox(height: YanwariDesignSystem.spacingXl),

                    // アプリ情報
                    _buildSectionCard(
                      title: 'アプリ情報',
                      children: [
                        ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: const Text('バージョン'),
                          subtitle: const Text('1.0.0'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.code),
                          title: const Text('オープンソース'),
                          subtitle: const Text('このアプリはオープンソースです'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// セクションカードを構築
  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: YanwariDesignSystem.headingMd.copyWith(
              color: YanwariDesignSystem.textPrimary,
            ),
          ),
          SizedBox(height: YanwariDesignSystem.spacingMd),
          ...children,
        ],
      ),
    );
  }
}