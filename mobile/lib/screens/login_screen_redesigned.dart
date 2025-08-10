import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/design_system.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreenRedesigned extends StatefulWidget {
  const LoginScreenRedesigned({super.key});

  @override
  State<LoginScreenRedesigned> createState() => _LoginScreenRedesignedState();
}

class _LoginScreenRedesignedState extends State<LoginScreenRedesigned> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await context.read<AuthService>().signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } catch (e) {
      setState(() {
        _errorMessage = _formatErrorMessage(e.toString());
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatErrorMessage(String error) {
    if (error.contains('user-not-found')) {
      return 'このメールアドレスは登録されていません';
    } else if (error.contains('wrong-password')) {
      return 'パスワードが間違っています';
    } else if (error.contains('invalid-email')) {
      return '正しいメールアドレスを入力してください';
    } else if (error.contains('network-request-failed')) {
      return 'ネットワークエラーが発生しました';
    }
    return 'ログインに失敗しました。もう一度お試しください。';
  }

  void _setDemoAccount(String type) {
    if (type == 'alice') {
      _emailController.text = 'alice@yanwari.com';
      _passwordController.text = 'AliceDemo123!';
    } else {
      _emailController.text = 'bob@yanwari.com';
      _passwordController.text = 'BobDemo123!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YanwariDesignSystem.backgroundMuted,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
            ),
            child: Padding(
              padding: const EdgeInsets.all(YanwariDesignSystem.spacingLg),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: YanwariDesignSystem.spacing2xl),
                    
                    // ロゴとタイトル
                    _buildHeader(),
                    
                    const SizedBox(height: YanwariDesignSystem.spacing2xl),
                    
                    // ログインフォーム
                    _buildLoginForm(),
                    
                    const SizedBox(height: YanwariDesignSystem.spacingXl),
                    
                    // デモアカウント
                    _buildDemoAccounts(),
                    
                    const SizedBox(height: YanwariDesignSystem.spacing2xl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
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
        
        // タイトル
        Text(
          'やんわり伝言',
          textAlign: TextAlign.center,
          style: YanwariDesignSystem.headingXl.copyWith(
            color: YanwariDesignSystem.secondaryColor,
          ),
        ),
        
        const SizedBox(height: YanwariDesignSystem.spacingSm),
        
        // サブタイトル
        Text(
          '思いやりのあるコミュニケーション',
          textAlign: TextAlign.center,
          style: YanwariDesignSystem.bodyMd.copyWith(
            color: YanwariDesignSystem.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(YanwariDesignSystem.spacingLg),
      decoration: YanwariDesignSystem.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // フォームタイトル
          Text(
            'ログイン',
            style: YanwariDesignSystem.headingMd,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: YanwariDesignSystem.spacingLg),
          
          // メールアドレス入力
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: YanwariDesignSystem.bodyMd,
            decoration: YanwariDesignSystem.inputDecoration(
              labelText: 'メールアドレス',
              hintText: 'example@yanwari.com',
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'メールアドレスを入力してください';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return '正しいメールアドレスを入力してください';
              }
              return null;
            },
          ),
          
          const SizedBox(height: YanwariDesignSystem.spacingMd),
          
          // パスワード入力
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: YanwariDesignSystem.bodyMd,
            decoration: YanwariDesignSystem.inputDecoration(
              labelText: 'パスワード',
              hintText: 'パスワードを入力',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: YanwariDesignSystem.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'パスワードを入力してください';
              }
              if (value.length < 6) {
                return 'パスワードは6文字以上で入力してください';
              }
              return null;
            },
          ),
          
          const SizedBox(height: YanwariDesignSystem.spacingLg),
          
          // エラーメッセージ
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(YanwariDesignSystem.spacingMd),
              decoration: BoxDecoration(
                color: YanwariDesignSystem.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusMd),
                border: Border.all(
                  color: YanwariDesignSystem.errorColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: YanwariDesignSystem.errorColor,
                    size: 20,
                  ),
                  const SizedBox(width: YanwariDesignSystem.spacingSm),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: YanwariDesignSystem.bodySm.copyWith(
                        color: YanwariDesignSystem.errorColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: YanwariDesignSystem.spacingMd),
          ],
          
          // ログインボタン
          ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: YanwariDesignSystem.primaryButtonStyle.copyWith(
              minimumSize: MaterialStateProperty.all(
                const Size(double.infinity, 48),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        YanwariDesignSystem.textInverse,
                      ),
                    ),
                  )
                : Text(
                    'ログイン',
                    style: YanwariDesignSystem.button.copyWith(
                      color: YanwariDesignSystem.textInverse,
                    ),
                  ),
          ),
          
          const SizedBox(height: YanwariDesignSystem.spacingMd),
          
          // 新規登録リンク
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterScreen()),
              );
            },
            child: Text(
              '新規登録はこちら',
              style: YanwariDesignSystem.bodyMd.copyWith(
                color: YanwariDesignSystem.secondaryColor,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoAccounts() {
    return Column(
      children: [
        Text(
          'デモアカウント',
          style: YanwariDesignSystem.headingMd.copyWith(
            color: YanwariDesignSystem.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: YanwariDesignSystem.spacingMd),
        
        Text(
          'すぐに体験したい方はこちらをお使いください',
          style: YanwariDesignSystem.bodySm.copyWith(
            color: YanwariDesignSystem.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: YanwariDesignSystem.spacingMd),
        
        Row(
          children: [
            Expanded(
              child: _buildDemoButton(
                'alice',
                '👩 Alice',
                YanwariDesignSystem.primaryColor,
                'alice@yanwari.com',
              ),
            ),
            const SizedBox(width: YanwariDesignSystem.spacingMd),
            Expanded(
              child: _buildDemoButton(
                'bob',
                '👨 Bob',
                YanwariDesignSystem.secondaryColor,
                'bob@yanwari.com',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDemoButton(
    String type,
    String label,
    Color color,
    String email,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusMd),
        border: Border.all(color: color),
        color: color.withOpacity(0.1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _setDemoAccount(type),
          borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(YanwariDesignSystem.spacingMd),
            child: Column(
              children: [
                Text(
                  label,
                  style: YanwariDesignSystem.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: YanwariDesignSystem.spacingXs),
                Text(
                  email,
                  style: YanwariDesignSystem.caption.copyWith(
                    color: YanwariDesignSystem.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}