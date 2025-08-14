import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/design_system.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _activeSection = 'account';
  bool _isLoading = false;
  String _message = '';
  String _messageType = '';

  // フォームコントローラー
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // 設定値
  bool _emailNotifications = true;
  bool _sendNotifications = true;
  bool _browserNotifications = false;
  String _defaultTone = 'gentle';
  String _timeRestriction = 'none';
  bool _autoSave = true;
  String _language = 'ja';
  String _timezone = 'Asia/Tokyo';
  String _dateFormat = 'YYYY/MM/DD';

  final List<Map<String, String>> _settingsSections = [
    {'id': 'account', 'label': 'アカウント', 'icon': 'person'},
    {'id': 'notifications', 'label': '通知', 'icon': 'notifications'},
    {'id': 'language', 'label': '言語・地域', 'icon': 'language'},
    {'id': 'messages', 'label': 'メッセージ', 'icon': 'message'},
    {'id': 'logout', 'label': 'ログアウト', 'icon': 'logout'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  IconData _getIconForSection(String iconName) {
    switch (iconName) {
      case 'person':
        return Icons.person_outline;
      case 'notifications':
        return Icons.notifications_outlined;
      case 'language':
        return Icons.language_outlined;
      case 'message':
        return Icons.message_outlined;
      case 'logout':
        return Icons.logout_outlined;
      default:
        return Icons.settings_outlined;
    }
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 実際のAPIから設定を読み込み
      await Future.delayed(const Duration(milliseconds: 500));
      
      // サンプルデータ
      _displayNameController.text = 'ユーザー名';
      _emailController.text = 'user@example.com';
      
    } catch (error) {
      _showMessage('設定の読み込みに失敗しました', 'error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateAllSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 実際のAPI呼び出し
      await Future.delayed(const Duration(seconds: 1));
      _showMessage('設定を更新しました', 'success');
    } catch (error) {
      _showMessage('設定の更新に失敗しました', 'error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (error) {
      _showMessage('ログアウトに失敗しました', 'error');
    }
  }

  void _showMessage(String text, String type) {
    setState(() {
      _message = text;
      _messageType = type;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: type == 'success' 
          ? YanwariDesignSystem.successColor 
          : YanwariDesignSystem.errorColor,
        duration: const Duration(seconds: 3),
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _message = '';
          _messageType = '';
        });
      }
    });
  }

  Widget _buildSidebarNavigation() {
    return Container(
      width: 200,
      decoration: YanwariDesignSystem.cardDecoration,
      child: Column(
        children: _settingsSections.map((section) {
          final isActive = _activeSection == section['id'];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _activeSection = section['id']!;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: YanwariDesignSystem.spacingMd,
                  vertical: YanwariDesignSystem.spacingMd,
                ),
                decoration: BoxDecoration(
                  color: isActive ? YanwariDesignSystem.backgroundSecondary : Colors.transparent,
                  border: Border(
                    bottom: BorderSide(
                      color: YanwariDesignSystem.borderColor.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getIconForSection(section['icon']!),
                      size: 18,
                      color: isActive 
                        ? YanwariDesignSystem.textPrimary 
                        : YanwariDesignSystem.textSecondary,
                    ),
                    const SizedBox(width: YanwariDesignSystem.spacingSm),
                    Text(
                      section['label']!,
                      style: YanwariDesignSystem.bodyMd.copyWith(
                        fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                        color: isActive 
                          ? YanwariDesignSystem.textPrimary 
                          : YanwariDesignSystem.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'アカウント設定',
          style: YanwariDesignSystem.headingMd,
        ),
        const SizedBox(height: YanwariDesignSystem.spacingLg),
        _buildFormField(
          label: 'ユーザー名',
          controller: _displayNameController,
          hintText: '今のユーザーネーム',
        ),
        const SizedBox(height: YanwariDesignSystem.spacingMd),
        _buildFormField(
          label: 'メールアドレス',
          controller: _emailController,
          hintText: '今のメールアドレス',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: YanwariDesignSystem.spacingLg),
        Text(
          'パスワード変更',
          style: YanwariDesignSystem.bodyLg.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: YanwariDesignSystem.spacingMd),
        _buildFormField(
          label: '現在のパスワード',
          controller: _currentPasswordController,
          obscureText: true,
        ),
        const SizedBox(height: YanwariDesignSystem.spacingMd),
        _buildFormField(
          label: '新しいパスワード',
          controller: _newPasswordController,
          obscureText: true,
        ),
        const SizedBox(height: YanwariDesignSystem.spacingMd),
        _buildFormField(
          label: 'パスワード再入力',
          controller: _confirmPasswordController,
          obscureText: true,
        ),
        const SizedBox(height: YanwariDesignSystem.spacingXl),
        Center(
          child: SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _updateAllSettings,
              style: YanwariDesignSystem.primaryButtonStyle,
              child: Text(
                _isLoading ? '更新中...' : '更新する',
                style: YanwariDesignSystem.button.copyWith(
                  color: YanwariDesignSystem.textInverse,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🔔', style: TextStyle(fontSize: 20)),
            const SizedBox(width: YanwariDesignSystem.spacingSm),
            Text(
              '通知設定',
              style: YanwariDesignSystem.headingMd,
            ),
          ],
        ),
        const SizedBox(height: YanwariDesignSystem.spacingLg),
        _buildToggleItem(
          title: 'メール通知',
          subtitle: 'メッセージ受信時にメール通知を送信',
          value: _emailNotifications,
          onChanged: (value) {
            setState(() {
              _emailNotifications = value;
            });
          },
        ),
        _buildToggleItem(
          title: '送信完了通知',
          subtitle: 'メッセージ送信完了時に通知',
          value: _sendNotifications,
          onChanged: (value) {
            setState(() {
              _sendNotifications = value;
            });
          },
        ),
        _buildToggleItem(
          title: 'アプリ内通知',
          subtitle: 'アプリ内での通知表示',
          value: _browserNotifications,
          onChanged: (value) {
            setState(() {
              _browserNotifications = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildLanguageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🌍', style: TextStyle(fontSize: 20)),
            const SizedBox(width: YanwariDesignSystem.spacingSm),
            Text(
              '言語・地域設定',
              style: YanwariDesignSystem.headingMd,
            ),
          ],
        ),
        const SizedBox(height: YanwariDesignSystem.spacingLg),
        _buildDropdownField(
          label: '言語',
          value: _language,
          items: const [
            {'value': 'ja', 'label': '日本語'},
            {'value': 'en', 'label': 'English'},
            {'value': 'ko', 'label': '한국어'},
            {'value': 'zh', 'label': '中文'},
          ],
          onChanged: (value) {
            setState(() {
              _language = value!;
            });
          },
          hint: 'アプリケーションの表示言語を選択',
        ),
        const SizedBox(height: YanwariDesignSystem.spacingMd),
        _buildDropdownField(
          label: 'タイムゾーン',
          value: _timezone,
          items: const [
            {'value': 'Asia/Tokyo', 'label': '日本標準時 (JST)'},
            {'value': 'America/New_York', 'label': '東部標準時 (EST)'},
            {'value': 'America/Los_Angeles', 'label': '太平洋標準時 (PST)'},
            {'value': 'Europe/London', 'label': 'グリニッジ標準時 (GMT)'},
          ],
          onChanged: (value) {
            setState(() {
              _timezone = value!;
            });
          },
          hint: 'メッセージの送信時間などに使用されます',
        ),
        const SizedBox(height: YanwariDesignSystem.spacingMd),
        _buildDropdownField(
          label: '日付形式',
          value: _dateFormat,
          items: const [
            {'value': 'YYYY/MM/DD', 'label': '2024/01/15'},
            {'value': 'MM/DD/YYYY', 'label': '01/15/2024'},
            {'value': 'DD/MM/YYYY', 'label': '15/01/2024'},
            {'value': 'YYYY-MM-DD', 'label': '2024-01-15'},
          ],
          onChanged: (value) {
            setState(() {
              _dateFormat = value!;
            });
          },
          hint: '日付の表示形式を選択',
        ),
      ],
    );
  }

  Widget _buildMessageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('💬', style: TextStyle(fontSize: 20)),
            const SizedBox(width: YanwariDesignSystem.spacingSm),
            Text(
              'メッセージ設定',
              style: YanwariDesignSystem.headingMd,
            ),
          ],
        ),
        const SizedBox(height: YanwariDesignSystem.spacingLg),
        _buildDropdownField(
          label: 'デフォルトトーン',
          value: _defaultTone,
          items: const [
            {'value': 'gentle', 'label': '💝 やんわり'},
            {'value': 'constructive', 'label': '🏗️ 建設的'},
            {'value': 'casual', 'label': '🎯 カジュアル'},
          ],
          onChanged: (value) {
            setState(() {
              _defaultTone = value!;
            });
          },
          hint: '新しいメッセージ作成時の初期トーン',
        ),
        const SizedBox(height: YanwariDesignSystem.spacingMd),
        _buildDropdownField(
          label: '送信時間制限',
          value: _timeRestriction,
          items: const [
            {'value': 'none', 'label': '制限なし'},
            {'value': 'business_hours', 'label': '営業時間のみ（9:00-18:00）'},
            {'value': 'extended_hours', 'label': '拡張時間（8:00-20:00）'},
          ],
          onChanged: (value) {
            setState(() {
              _timeRestriction = value!;
            });
          },
          hint: 'メッセージ送信可能な時間帯',
        ),
        const SizedBox(height: YanwariDesignSystem.spacingMd),
        _buildToggleItem(
          title: '下書きの自動保存',
          subtitle: 'メッセージ入力中に自動的に下書きを保存',
          value: _autoSave,
          onChanged: (value) {
            setState(() {
              _autoSave = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildLogoutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🚪', style: TextStyle(fontSize: 20)),
            const SizedBox(width: YanwariDesignSystem.spacingSm),
            Text(
              'ログアウト',
              style: YanwariDesignSystem.headingMd,
            ),
          ],
        ),
        const SizedBox(height: YanwariDesignSystem.spacingLg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(YanwariDesignSystem.spacingXl),
          decoration: YanwariDesignSystem.cardDecoration,
          child: Column(
            children: [
              Text(
                '現在のアカウントからログアウトします。\n再度ログインするにはメールアドレスとパスワードが必要です。',
                style: YanwariDesignSystem.bodyMd.copyWith(
                  color: YanwariDesignSystem.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: YanwariDesignSystem.spacingXl),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: YanwariDesignSystem.errorColor,
                    foregroundColor: YanwariDesignSystem.textInverse,
                    padding: const EdgeInsets.symmetric(
                      horizontal: YanwariDesignSystem.spacingLg,
                      vertical: YanwariDesignSystem.spacingMd,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusMd),
                    ),
                  ),
                  child: const Text('ログアウトする'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: YanwariDesignSystem.bodySm.copyWith(
            fontWeight: FontWeight.w500,
            color: YanwariDesignSystem.textPrimary,
          ),
        ),
        const SizedBox(height: YanwariDesignSystem.spacingSm),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: YanwariDesignSystem.inputDecoration(
            hintText: hintText,
          ),
          style: YanwariDesignSystem.bodyMd,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<Map<String, String>> items,
    required Function(String?) onChanged,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: YanwariDesignSystem.bodySm.copyWith(
            fontWeight: FontWeight.w500,
            color: YanwariDesignSystem.textPrimary,
          ),
        ),
        const SizedBox(height: YanwariDesignSystem.spacingSm),
        DropdownButtonFormField<String>(
          value: value,
          decoration: YanwariDesignSystem.inputDecoration(),
          style: YanwariDesignSystem.bodyMd,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item['value'],
              child: Text(item['label']!),
            );
          }).toList(),
          onChanged: onChanged,
        ),
        if (hint != null) ...[
          const SizedBox(height: YanwariDesignSystem.spacingXs),
          Text(
            hint,
            style: YanwariDesignSystem.caption.copyWith(
              color: YanwariDesignSystem.textMuted,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildToggleItem({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: YanwariDesignSystem.spacingMd,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: YanwariDesignSystem.borderColor.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: YanwariDesignSystem.bodyMd.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: YanwariDesignSystem.spacingXs),
                Text(
                  subtitle,
                  style: YanwariDesignSystem.bodySm.copyWith(
                    color: YanwariDesignSystem.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: YanwariDesignSystem.secondaryColor,
            inactiveThumbColor: YanwariDesignSystem.grayColor,
            inactiveTrackColor: YanwariDesignSystem.grayColorLight,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContent() {
    switch (_activeSection) {
      case 'account':
        return _buildAccountSection();
      case 'notifications':
        return _buildNotificationSection();
      case 'language':
        return _buildLanguageSection();
      case 'messages':
        return _buildMessageSection();
      case 'logout':
        return _buildLogoutSection();
      default:
        return _buildAccountSection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YanwariDesignSystem.backgroundMuted,
      appBar: AppBar(
        title: const Text('設定'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                
                if (isWide) {
                  // タブレット・デスクトップレイアウト
                  return Padding(
                    padding: const EdgeInsets.all(YanwariDesignSystem.spacingLg),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSidebarNavigation(),
                        const SizedBox(width: YanwariDesignSystem.spacingLg),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(YanwariDesignSystem.spacingXl),
                            decoration: YanwariDesignSystem.cardDecoration,
                            child: SingleChildScrollView(
                              child: _buildSectionContent(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  // モバイルレイアウト
                  return Column(
                    children: [
                      // セクション選択タブ
                      Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: YanwariDesignSystem.backgroundPrimary,
                          boxShadow: [YanwariDesignSystem.shadowSm],
                        ),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _settingsSections.length,
                          itemBuilder: (context, index) {
                            final section = _settingsSections[index];
                            final isActive = _activeSection == section['id'];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _activeSection = section['id']!;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: YanwariDesignSystem.spacingMd,
                                  vertical: YanwariDesignSystem.spacingSm,
                                ),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: YanwariDesignSystem.spacingXs,
                                  vertical: YanwariDesignSystem.spacingSm,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive 
                                    ? YanwariDesignSystem.secondaryColor 
                                    : Colors.transparent,
                                  borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusFull),
                                ),
                                child: Center(
                                  child: Text(
                                    section['label']!,
                                    style: YanwariDesignSystem.bodySm.copyWith(
                                      fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                                      color: isActive 
                                        ? YanwariDesignSystem.textInverse 
                                        : YanwariDesignSystem.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // コンテンツエリア
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(YanwariDesignSystem.spacingLg),
                          child: _buildSectionContent(),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
    );
  }
}