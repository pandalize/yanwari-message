import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/friend_service.dart';
import '../utils/design_system.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'メールアドレスを入力してください';
    }
    
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return '正しいメールアドレス形式で入力してください';
    }
    
    return null;
  }

  Future<void> _sendFriendRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final friendService = context.read<FriendService>();
    final email = _emailController.text.trim();
    final message = _messageController.text.trim();

    // 既に友達かどうかをチェック
    if (friendService.isFriend(email)) {
      _showErrorSnackBar('$email は既にあなたの友達です');
      return;
    }

    // 既に申請中かどうかをチェック
    if (friendService.hasPendingRequestTo(email)) {
      _showErrorSnackBar('$email には既に友達申請を送信済みです');
      return;
    }

    // 相手から申請が来ているかをチェック
    if (friendService.hasPendingRequestFrom(email)) {
      _showErrorSnackBar('$email から友達申請が来ています。友達申請の管理画面から確認してください');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await friendService.sendFriendRequest(
      toEmail: email,
      message: message.isNotEmpty ? message : null,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      _showSuccessSnackBar('友達申請を送信しました');
      _emailController.clear();
      _messageController.clear();
      // 少し待ってから前の画面に戻る
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } else if (friendService.errorMessage != null) {
      _showErrorSnackBar(friendService.errorMessage!);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: YanwariDesignSystem.errorColor,
        duration: const Duration(seconds: 4),
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
        title: const Text('友達を追加'),
        backgroundColor: YanwariDesignSystem.backgroundPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 説明カード
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(YanwariDesignSystem.spacingLg),
                decoration: YanwariDesignSystem.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: YanwariDesignSystem.secondaryColor,
                          size: 24,
                        ),
                        SizedBox(width: YanwariDesignSystem.spacingSm),
                        Text(
                          '友達追加について',
                          style: YanwariDesignSystem.headingMd.copyWith(
                            color: YanwariDesignSystem.secondaryColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: YanwariDesignSystem.spacingMd),
                    Text(
                      '友達のメールアドレスを入力して友達申請を送信できます。相手が申請を承認すると、やんわり伝言のやり取りができるようになります。',
                      style: YanwariDesignSystem.bodyMd,
                    ),
                  ],
                ),
              ),

              SizedBox(height: YanwariDesignSystem.spacingLg),

              // メールアドレス入力
              Text(
                'メールアドレス',
                style: YanwariDesignSystem.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: YanwariDesignSystem.spacingSm),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLoading,
                decoration: YanwariDesignSystem.inputDecoration(
                  hintText: 'friend@example.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: _validateEmail,
                onFieldSubmitted: (_) => _sendFriendRequest(),
              ),

              SizedBox(height: YanwariDesignSystem.spacingLg),

              // メッセージ入力（オプション）
              Text(
                'メッセージ（任意）',
                style: YanwariDesignSystem.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: YanwariDesignSystem.spacingSm),
              TextFormField(
                controller: _messageController,
                maxLines: 3,
                enabled: !_isLoading,
                decoration: YanwariDesignSystem.inputDecoration(
                  hintText: 'こんにちは！友達になりませんか？',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 48.0),
                    child: Icon(Icons.message_outlined),
                  ),
                ),
              ),

              SizedBox(height: YanwariDesignSystem.spacingXl),

              // 送信ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendFriendRequest,
                  style: YanwariDesignSystem.primaryButtonStyle.copyWith(
                    minimumSize: MaterialStateProperty.all(
                      Size(double.infinity, 56),
                    ),
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  YanwariDesignSystem.textInverse,
                                ),
                              ),
                            ),
                            SizedBox(width: YanwariDesignSystem.spacingSm),
                            const Text('送信中...'),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send),
                            SizedBox(width: YanwariDesignSystem.spacingSm),
                            const Text('友達申請を送信'),
                          ],
                        ),
                ),
              ),

              SizedBox(height: YanwariDesignSystem.spacingLg),

              // 注意事項
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
                decoration: BoxDecoration(
                  color: YanwariDesignSystem.backgroundTertiary,
                  borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '注意事項',
                      style: YanwariDesignSystem.bodyMd.copyWith(
                        fontWeight: FontWeight.w600,
                        color: YanwariDesignSystem.textSecondary,
                      ),
                    ),
                    SizedBox(height: YanwariDesignSystem.spacingSm),
                    Text(
                      '• 入力されたメールアドレスのユーザーが存在しない場合は申請できません\n'
                      '• 既に友達のユーザーには申請できません\n'
                      '• 同じユーザーに重複して申請することはできません\n'
                      '• 相手が申請を承認するまで、やんわり伝言は送信できません',
                      style: YanwariDesignSystem.bodySm.copyWith(
                        color: YanwariDesignSystem.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}