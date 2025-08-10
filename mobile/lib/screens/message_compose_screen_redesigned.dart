import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import '../utils/design_system.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../widgets/layout/page_container.dart';
import '../widgets/layout/page_title.dart';
import '../widgets/draft_list_view.dart';
import 'tone_selection_screen.dart';

class MessageComposeScreenRedesigned extends StatefulWidget {
  final String recipientEmail;
  final String recipientName;
  
  const MessageComposeScreenRedesigned({
    super.key,
    required this.recipientEmail,
    required this.recipientName,
  });

  @override
  State<MessageComposeScreenRedesigned> createState() => _MessageComposeScreenRedesignedState();
}

class _MessageComposeScreenRedesignedState extends State<MessageComposeScreenRedesigned> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _reasonController = TextEditingController(); // 理由・背景用
  late final ApiService _apiService;
  bool _isLoading = false;
  String? _errorMessage;
  
  // 下書き機能追加
  List<Map<String, dynamic>> _drafts = [];
  String? _currentDraftId;
  bool _isDraftsLoading = false;
  bool _isAutoSaving = false;
  
  // 自動保存のタイマー
  Timer? _autoSaveTimer;
  
  // 初期読み込み完了フラグ
  bool _hasInitialLoad = false;
  // 下書き読み込みの重複防止フラグ
  bool _isLoadingDrafts = false;
  
  // DraftListViewのリフレッシュ関数を保持
  VoidCallback? _refreshDraftList;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(context.read<AuthService>());
    // リアルタイム文字数カウント & 自動下書き保存
    _messageController.addListener(() {
      setState(() {});
      _scheduleAutoSave();
    });
    _reasonController.addListener(() {
      setState(() {});
      _scheduleAutoSave();
    });
    // 下書きを読み込み
    print('🚀 initState: 下書き初期読み込み開始');
    _loadDrafts();
  }
  
  // 下書きを読み込む
  // 下書きを読み込む（シンプル版）
  Future<void> _loadDrafts() async {
    // 既に読み込み中の場合はスキップ
    if (_isLoadingDrafts) return;
    
    _isLoadingDrafts = true;
    setState(() => _isDraftsLoading = true);

    try {
      final response = await _apiService.getDrafts();
      
      // 📊 詳細デバッグログ追加
      print('🔍 [LoadDrafts] APIレスポンス全体: $response');
      if (response != null && response['data'] != null) {
        print('🔍 [LoadDrafts] data部分: ${response['data']}');
        final draftsData = response['data'] as Map<String, dynamic>;
        final draftsList = draftsData['messages'] as List<dynamic>? ?? [];
        print('🔍 [LoadDrafts] messages配列: ${draftsList.length}件');
        print('🔍 [LoadDrafts] 各メッセージ内容:');
        for (int i = 0; i < draftsList.length; i++) {
          print('  📝 [$i] ${draftsList[i]}');
        }
        
        final newDrafts = draftsList
            .where((d) => d is Map<String, dynamic>)
            .map((d) => d as Map<String, dynamic>)
            .toList();
        
        // 更新日時で降順ソート（最新が上）
        newDrafts.sort((a, b) {
          try {
            final aUpdated = a['updatedAt'] ?? a['updated_at'] ?? a['createdAt'] ?? a['created_at'] ?? '';
            final bUpdated = b['updatedAt'] ?? b['updated_at'] ?? b['createdAt'] ?? b['created_at'] ?? '';
            final aDate = DateTime.parse(aUpdated.toString());
            final bDate = DateTime.parse(bUpdated.toString());
            return bDate.compareTo(aDate);
          } catch (e) {
            return 0;
          }
        });
        
        // 最大5件まで表示
        final finalDrafts = newDrafts.take(5).toList();
        
        // 現在編集中の下書きを保持
        if (_currentDraftId != null && !finalDrafts.any((d) => (d['id'] ?? d['_id']) == _currentDraftId)) {
          final currentDraft = _drafts.firstWhere(
            (d) => (d['id'] ?? d['_id']) == _currentDraftId,
            orElse: () => <String, dynamic>{},
          );
          if (currentDraft.isNotEmpty) {
            finalDrafts.insert(0, currentDraft);
          }
        }
        
        // 🎯 最終的に表示される下書きリストをログ出力
        print('🎯 [LoadDrafts] 最終表示用下書きリスト: ${finalDrafts.length}件');
        for (int i = 0; i < finalDrafts.length; i++) {
          final draft = finalDrafts[i];
          final id = draft['id'] ?? draft['_id'] ?? 'no-id';
          final text = (draft['originalText'] ?? '').toString();
          final shortText = text.length > 30 ? text.substring(0, 30) + '...' : text;
          print('  🎯 [$i] ID:$id テキスト:$shortText');
        }
        
        setState(() {
          _drafts = finalDrafts;
          _isDraftsLoading = false;
          _hasInitialLoad = true;
        });
      }
    } catch (e) {
      print('下書き読み込みエラー: $e');
    } finally {
      _isLoadingDrafts = false;
      setState(() => _isDraftsLoading = false);
    }
  }

  // 自動保存をスケジュール
  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    
    // メッセージまたは理由が空でない場合のみ自動保存をスケジュール
    if ((_messageController.text.trim().isNotEmpty || _reasonController.text.trim().isNotEmpty) && !_isAutoSaving && !_isLoading) {
      _autoSaveTimer = Timer(const Duration(seconds: 3), () {
        _autoSaveDraft();
      });
    }
  }

  // 自動下書き保存
  Future<void> _autoSaveDraft() async {
    if ((_messageController.text.trim().isEmpty && _reasonController.text.trim().isEmpty) || _isAutoSaving || _isLoading) {
      return;
    }

    setState(() {
      _isAutoSaving = true;
    });

    try {
      if (_currentDraftId != null) {
        // 既存の下書きを更新
        await _apiService.updateMessage(
          messageId: _currentDraftId!,
          originalText: _messageController.text.trim(),
          reason: _reasonController.text.trim(),
        );
      } else {
        // 新規下書き作成
        final response = await _apiService.createMessage(
          originalText: _messageController.text.trim(),
          recipientEmail: widget.recipientEmail,
          reason: _reasonController.text.trim(),
        );
        _currentDraftId = response['data']['id'];
      }
      
      // DraftListView を即座にリフレッシュ
      _refreshDraftList?.call();
      
      // 下書き一覧を更新（エラーが出てもUIは継続）
      _loadDrafts().catchError((e) {
        print('自動保存後の下書き一覧更新エラー: $e');
      });
      
    } catch (e) {
      print('自動保存エラー: $e');
      // 自動保存のエラーは控えめに処理（ユーザーには見せない）
    } finally {
      if (mounted) {
        setState(() {
          _isAutoSaving = false;
        });
      }
    }
  }

  // 手動で下書きを保存（シンプル版）
  Future<void> _saveDraft() async {
    final text = _messageController.text.trim();
    final reason = _reasonController.text.trim();
    
    // 空メッセージチェック
    if (text.isEmpty && reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('保存するメッセージまたは理由を入力してください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isAutoSaving = true);

    try {
      Map<String, dynamic> response;
      
      // APIで保存（新規または更新）
      if (_currentDraftId != null) {
        // 既存の下書きを更新
        response = await _apiService.updateMessage(
          messageId: _currentDraftId!,
          originalText: text,
          reason: reason,
        );
      } else {
        // 新規下書き作成
        response = await _apiService.createMessage(
          originalText: text,
          recipientEmail: widget.recipientEmail,
          reason: reason,
        );
        _currentDraftId = response['data']['id'];
      }
      
      // 保存成功後の処理
      if (mounted) {
        // 成功メッセージを表示
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📝 下書きを保存しました'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // DraftListView を即座にリフレッシュ
        _refreshDraftList?.call();
        
        // 下書きリストを更新（既存のロジックも保持）
        _addOrUpdateDraftInList({
          'id': _currentDraftId,
          'originalText': text,
          'reason': reason,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(), // 更新日時を追加
          'status': 'draft',
        });
      }
    } catch (e) {
      // エラー処理
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('下書き保存に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAutoSaving = false);
      }
    }
  }
  
  // 下書きリストに追加または更新する（ヘルパーメソッド）
  void _addOrUpdateDraftInList(Map<String, dynamic> draft) {
    setState(() {
      // 既存の下書きがあれば更新、なければ追加
      final index = _drafts.indexWhere((d) => (d['id'] ?? d['_id']) == draft['id']);
      if (index != -1) {
        _drafts[index] = draft;
      } else {
        _drafts.insert(0, draft);
        // 最大5件に制限
        if (_drafts.length > 5) {
          _drafts = _drafts.take(5).toList();
        }
      }
    });
  }
  
  // 下書きを選択
  void _loadDraft(Map<String, dynamic> draft) {
    setState(() {
      _messageController.text = draft['originalText'] ?? draft['original_text'] ?? '';
      _reasonController.text = draft['reason'] ?? '';
      _currentDraftId = draft['id'] ?? draft['_id'];
      _errorMessage = null;
    });
  }

  // デバッグ用テストボタン
  void _testApiDebug() async {
    print('🧪 [DEBUG] 現在の状態チェック開始');
    print('🧪 [DEBUG] _drafts.length: ${_drafts.length}');
    print('🧪 [DEBUG] _isDraftsLoading: $_isDraftsLoading');
    print('🧪 [DEBUG] _hasInitialLoad: $_hasInitialLoad');
    print('🧪 [DEBUG] _currentDraftId: $_currentDraftId');
    print('🧪 [DEBUG] _drafts内容: ${_drafts.map((d) {
      final text = d['originalText'] ?? '';
      final truncatedText = text.length > 20 ? text.substring(0, 20) + '...' : text;
      return {
        'id': d['id'], 
        'text': truncatedText,
        'createdAt': d['createdAt']
      };
    }).toList()}');
    
    print('🧪 [DEBUG] APIテスト開始');
    try {
      final response = await _apiService.getDrafts();
      print('🧪 [DEBUG] API レスポンス全体: $response');
      print('🧪 [DEBUG] レスポンスタイプ: ${response.runtimeType}');
      if (response != null && response["data"] != null) {
        print('🧪 [DEBUG] response["data"]["messages"]: ${response["data"]["messages"]}');
        if (response["data"]["messages"] != null) {
          print('🧪 [DEBUG] messages の長さ: ${response["data"]["messages"].length}');
          if (response["data"]["messages"] is List) {
            print('🧪 [DEBUG] 各メッセージの詳細:');
            for (int i = 0; i < (response["data"]["messages"] as List).length; i++) {
              final msg = (response["data"]["messages"] as List)[i];
              final msgText = msg["originalText"] ?? "";
              final truncatedMsg = msgText.length > 30 ? msgText.substring(0, 30) + '...' : msgText;
              print('🧪 [DEBUG]   $i: id=${msg["id"]}, text=$truncatedMsg');
            }
          }
        }
      } else {
        print('🧪 [DEBUG] レスポンスまたはdataがnull');
      }
    } catch (e) {
      print('🧪 [DEBUG] API エラー: $e');
      print('🧪 [DEBUG] エラータイプ: ${e.runtimeType}');
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _messageController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _transformTone() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. メッセージ作成
      final messageResponse = await _apiService.createMessage(
        originalText: _messageController.text.trim(),
        recipientEmail: widget.recipientEmail,
        reason: _reasonController.text.trim(),
      );

      final messageId = messageResponse['data']['id'];
      
      // DraftListView を即座にリフレッシュ
      _refreshDraftList?.call();
      
      // 下書きが作成されたので一覧を更新
      await _loadDrafts();

      // 2. トーン変換
      final toneResponse = await _apiService.transformTones(
        messageId: messageId,
        originalText: _messageController.text.trim(),
      );

      // 3. トーン選択画面に遷移
      if (mounted) {
        // APIレスポンスから実際の変換結果を取得
        final variations = toneResponse['data']['variations'];
        Map<String, dynamic> toneVariations = {};
        
        if (variations is Map<String, dynamic>) {
          toneVariations = variations;
        } else if (variations is List && variations.length >= 3) {
          // APIから実際の変換結果を使用（型安全な変換）
          toneVariations = {
            'gentle': _extractText(variations[0]),
            'constructive': _extractText(variations[1]), 
            'casual': _extractText(variations[2])
          };
        } else {
          // フォールバック
          toneVariations = {
            'gentle': '変換エラーが発生しました',
            'constructive': '変換エラーが発生しました',
            'casual': '変換エラーが発生しました'
          };
        }
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ToneSelectionScreen(
              messageId: messageId,
              originalText: _messageController.text.trim(),
              toneVariations: toneVariations,
              recipientName: widget.recipientName,
              recipientEmail: widget.recipientEmail,
            ),
          ),
        );
      }
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

  String _extractText(dynamic data) {
    if (data is String) {
      return data;
    } else if (data is Map<String, dynamic>) {
      // JSONオブジェクトの場合、textフィールドを探す
      return data['text'] ?? data['content'] ?? data['message'] ?? data.toString();
    } else {
      return data?.toString() ?? '変換エラー';
    }
  }

  String _formatErrorMessage(String error) {
    if (error.contains('network')) {
      return 'ネットワークエラーが発生しました。接続を確認してください。';
    } else if (error.contains('unauthorized')) {
      return '認証エラーが発生しました。再ログインしてください。';
    } else if (error.contains('friend')) {
      return 'メッセージを送るには友達になる必要があります。';
    }
    return 'エラーが発生しました。もう一度お試しください。';
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '';
    
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final diff = now.difference(dateTime);
      
      if (diff.inMinutes < 1) {
        return 'たった今';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes}分前';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}時間前';
      } else if (diff.inDays == 1) {
        return '昨日 ${DateFormat('HH:mm').format(dateTime)}';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}日前 ${DateFormat('HH:mm').format(dateTime)}';
      } else {
        return DateFormat('MM/dd HH:mm').format(dateTime);
      }
    } catch (e) {
      return '';
    }
  }

  
  // デバッグ用: 強制的に下書き一覧を表示
  void _debugShowDrafts() {
    print('🔧 デバッグ: 現在の下書き状態');
    print('🔧 _drafts.length: ${_drafts.length}');
    print('🔧 _drafts.isEmpty: ${_drafts.isEmpty}');
    print('🔧 _isDraftsLoading: $_isDraftsLoading');
    print('🔧 _drafts内容: $_drafts');
    
    if (_drafts.isEmpty) {
      // テスト用の下書きを追加
      setState(() {
        _drafts = [
          {
            'id': 'test_${DateTime.now().millisecondsSinceEpoch}',
            'originalText': 'テスト下書きメッセージ',
            'createdAt': DateTime.now().toIso8601String(),
          }
        ];
      });
      print('🔧 テスト用下書きを追加しました: ${_drafts.length}件');
    }
  }
  
  // デバッグ用: 直接APIテスト
  Future<void> _debugApiTest() async {
    print('🔧 直接APIテスト開始');
    try {
      final response = await _apiService.getDrafts();
      print('🔧 API テスト成功: $response');
    } catch (e) {
      print('🔧 API テスト失敗: $e');
      if (e is DioException) {
        print('🔧 Dio エラー: ${e.message}');
        print('🔧 Status Code: ${e.response?.statusCode}');
        print('🔧 Response: ${e.response?.data}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YanwariDesignSystem.backgroundPrimary,
      body: PageContainer(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back,
                      color: YanwariDesignSystem.textPrimary,
                    ),
                  ),
                  const Expanded(
                    child: PageTitle(title: 'メッセージ作成'),
                  ),
                ],
              ),
              
              // 送信先情報
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
                margin: EdgeInsets.only(bottom: YanwariDesignSystem.spacingLg),
                decoration: BoxDecoration(
                  color: YanwariDesignSystem.primaryColorLight,
                  borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusLg),
                  border: Border.all(
                    color: YanwariDesignSystem.primaryColor,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: YanwariDesignSystem.secondaryColor,
                      child: Text(
                        widget.recipientName.isNotEmpty 
                          ? widget.recipientName.substring(0, 1).toUpperCase()
                          : '?',
                        style: YanwariDesignSystem.bodyMd.copyWith(
                          color: YanwariDesignSystem.textInverse,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: YanwariDesignSystem.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '送信先',
                            style: YanwariDesignSystem.caption.copyWith(
                              color: YanwariDesignSystem.textSecondary,
                            ),
                          ),
                          Text(
                            widget.recipientName,
                            style: YanwariDesignSystem.bodyMd.copyWith(
                              fontWeight: FontWeight.bold,
                              color: YanwariDesignSystem.textPrimary,
                            ),
                          ),
                          Text(
                            widget.recipientEmail,
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

              // メッセージ本文入力エリア
              Text(
                '送りたいメッセージ',
                style: YanwariDesignSystem.bodyMd.copyWith(
                  fontWeight: FontWeight.bold,
                  color: YanwariDesignSystem.textPrimary,
                ),
              ),
              SizedBox(height: YanwariDesignSystem.spacingSm),
              
              Container(
                decoration: BoxDecoration(
                  color: YanwariDesignSystem.neutralColor,
                  borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusLg),
                  border: Border.all(
                    color: YanwariDesignSystem.borderColor,
                    width: 1,
                  ),
                  boxShadow: [YanwariDesignSystem.shadowSm],
                ),
                child: TextFormField(
                  controller: _messageController,
                  maxLines: 4,
                  maxLength: 300,
                  style: YanwariDesignSystem.bodyMd,
                  decoration: InputDecoration(
                    hintText: '伝えたい内容を入力してください...\n例：明日の会議を延期してください',
                    hintStyle: YanwariDesignSystem.bodySm.copyWith(
                      color: YanwariDesignSystem.textTertiary,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
                    counterText: '',
                  ),
                  validator: (value) {
                    if ((value == null || value.trim().isEmpty) && _reasonController.text.trim().isEmpty) {
                      return 'メッセージまたは理由を入力してください';
                    }
                    return null;
                  },
                ),
              ),

              SizedBox(height: YanwariDesignSystem.spacingLg),

              // 理由・背景入力エリア
              Text(
                '理由や背景（任意）',
                style: YanwariDesignSystem.bodyMd.copyWith(
                  fontWeight: FontWeight.bold,
                  color: YanwariDesignSystem.textPrimary,
                ),
              ),
              SizedBox(height: YanwariDesignSystem.spacingSm),
              
              Container(
                decoration: BoxDecoration(
                  color: YanwariDesignSystem.neutralColor,
                  borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusLg),
                  border: Border.all(
                    color: YanwariDesignSystem.borderColor,
                    width: 1,
                  ),
                  boxShadow: [YanwariDesignSystem.shadowSm],
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 3,
                      maxLength: 200,
                      style: YanwariDesignSystem.bodyMd,
                      decoration: InputDecoration(
                        hintText: '理由や背景を入力してください...\n例：準備が間に合わないため',
                        hintStyle: YanwariDesignSystem.bodySm.copyWith(
                          color: YanwariDesignSystem.textTertiary,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
                        counterText: '',
                      ),
                    ),
                    
                  ],
                ),
              ),

              SizedBox(height: YanwariDesignSystem.spacingLg),

              // 操作ボタンエリア
              Container(
                padding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
                decoration: BoxDecoration(
                  color: YanwariDesignSystem.grayColorLight,
                  borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusLg),
                ),
                child: Column(
                  children: [
                    // 下書き保存ボタン
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_messageController.text.trim().isNotEmpty || _reasonController.text.trim().isNotEmpty) && !_isAutoSaving ? _saveDraft : null,
                        style: YanwariDesignSystem.primaryButtonStyle.copyWith(
                          padding: MaterialStateProperty.all(
                            EdgeInsets.symmetric(
                              vertical: YanwariDesignSystem.spacingMd,
                            ),
                          ),
                        ),
                        child: _isAutoSaving
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
                                  const Text('保存中...'),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _currentDraftId != null ? Icons.edit_outlined : Icons.save_outlined,
                                    color: YanwariDesignSystem.textInverse,
                                  ),
                                  SizedBox(width: YanwariDesignSystem.spacingSm),
                                  Text(_currentDraftId != null ? '下書き更新' : '下書き保存'),
                                ],
                              ),
                      ),
                    ),
                    
                    SizedBox(height: YanwariDesignSystem.spacingSm),
                    
                    // 文字数カウンター
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'メッセージ: ${_messageController.text.length}/300',
                              style: YanwariDesignSystem.caption.copyWith(
                                color: _messageController.text.length > 270
                                    ? YanwariDesignSystem.errorColor
                                    : YanwariDesignSystem.textSecondary,
                              ),
                            ),
                            Text(
                              '理由: ${_reasonController.text.length}/200',
                              style: YanwariDesignSystem.caption.copyWith(
                                color: _reasonController.text.length > 180
                                    ? YanwariDesignSystem.errorColor
                                    : YanwariDesignSystem.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: YanwariDesignSystem.spacingXl),

              // 説明テキスト
              Container(
                padding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
                decoration: BoxDecoration(
                  color: YanwariDesignSystem.primaryColorLight,
                  borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_fix_high,
                          size: 20,
                          color: YanwariDesignSystem.secondaryColor,
                        ),
                        SizedBox(width: YanwariDesignSystem.spacingSm),
                        Text(
                          'やんわり変換について',
                          style: YanwariDesignSystem.bodyMd.copyWith(
                            fontWeight: FontWeight.bold,
                            color: YanwariDesignSystem.secondaryColorDark,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: YanwariDesignSystem.spacingSm),
                    Text(
                      'AIがあなたのメッセージを3つの異なるトーンで変換します：\n• 💝 優しめ - 丁寧で温かい表現\n• 🏗️ 建設的 - 明確で協力的な表現\n• 🎯 カジュアル - フレンドリーで親しみやすい表現',
                      style: YanwariDesignSystem.bodySm.copyWith(
                        color: YanwariDesignSystem.secondaryColorDark,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: YanwariDesignSystem.spacingXl),
              
              // エラーメッセージ
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
                  margin: EdgeInsets.only(bottom: YanwariDesignSystem.spacingMd),
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
                      ),
                      SizedBox(width: YanwariDesignSystem.spacingSm),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: YanwariDesignSystem.bodyMd.copyWith(
                            color: YanwariDesignSystem.errorColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // 変換ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _transformTone,
                  style: YanwariDesignSystem.primaryButtonStyle.copyWith(
                    padding: MaterialStateProperty.all(
                      EdgeInsets.symmetric(
                        vertical: YanwariDesignSystem.spacingMd,
                      ),
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
                            const Text('変換中...'),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_fix_high,
                              color: YanwariDesignSystem.textInverse,
                            ),
                            SizedBox(width: YanwariDesignSystem.spacingSm),
                            const Text('やんわり変換'),
                          ],
                        ),
                ),
              ),
              
              // 下書き一覧（スクロール可能な新しいコンポーネント）
              SizedBox(height: YanwariDesignSystem.spacingLg),
              DraftListView(
                currentDraftId: _currentDraftId,
                onDraftSelected: _loadDraft,
                onRefreshCallbackSet: (refreshCallback) {
                  _refreshDraftList = refreshCallback;
                },
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}