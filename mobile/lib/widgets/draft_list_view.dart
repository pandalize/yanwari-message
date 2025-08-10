import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/design_system.dart';

class DraftListView extends StatefulWidget {
  final Function(Map<String, dynamic>) onDraftSelected;
  final String? currentDraftId;
  final Function(VoidCallback)? onRefreshCallbackSet;

  const DraftListView({
    Key? key,
    required this.onDraftSelected,
    this.currentDraftId,
    this.onRefreshCallbackSet,
  }) : super(key: key);

  @override
  State<DraftListView> createState() => _DraftListViewState();
}

class _DraftListViewState extends State<DraftListView> {
  late ApiService _apiService;
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _drafts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 10;
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    // 親にリフレッシュコールバックを提供
    widget.onRefreshCallbackSet?.call(refreshDrafts);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _apiService = ApiService(context.read<AuthService>());
    _loadDrafts();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMoreDrafts();
      }
    }
  }
  
  Future<void> _loadDrafts({bool refresh = false}) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      if (refresh) {
        _drafts.clear();
        _currentPage = 1;
        _hasMore = true;
      }
    });
    
    try {
      print('📋 [DraftListView] ページ${_currentPage}の下書きを取得中...');
      
      // APIにページネーション情報を送信 (FlutterのgetDraftsは現在パラメータをサポートしていない)
      final response = await _apiService.getDrafts();
      
      if (response != null && response['data'] != null) {
        final draftsData = response['data'] as Map<String, dynamic>;
        final allDrafts = (draftsData['messages'] as List<dynamic>?)
            ?.where((d) => d is Map<String, dynamic>)
            .map((d) => d as Map<String, dynamic>)
            .toList() ?? [];
        
        final pagination = draftsData['pagination'] as Map<String, dynamic>?;
        final total = pagination?['total'] as int? ?? allDrafts.length;
        
        print('📋 [DraftListView] 取得: ${allDrafts.length}件, 総数: $total');
        
        if (refresh || _currentPage == 1) {
          // 初回または更新の場合は全て置き換え
          _drafts = List.from(allDrafts);
        } else {
          // ページネーションの場合は追加（現在のAPIは全件返すので、この部分は将来の拡張用）
          for (final newDraft in allDrafts) {
            final newId = newDraft['id'] ?? newDraft['_id'];
            if (newId != null && !_drafts.any((draft) => (draft['id'] ?? draft['_id']) == newId)) {
              _drafts.add(newDraft);
            }
          }
        }
        
        // 更新日時で降順ソート（更新されたものが一番上に）
        _drafts.sort((a, b) {
          try {
            // updatedAt を優先、なければ createdAt を使用
            final aUpdated = a['updatedAt'] ?? a['updated_at'] ?? a['createdAt'] ?? a['created_at'] ?? '';
            final bUpdated = b['updatedAt'] ?? b['updated_at'] ?? b['createdAt'] ?? b['created_at'] ?? '';
            final aDate = DateTime.parse(aUpdated.toString());
            final bDate = DateTime.parse(bUpdated.toString());
            return bDate.compareTo(aDate);
          } catch (e) {
            return 0;
          }
        });
        
        setState(() {
          // 現在のAPIは全件返すため、追加データなしとする
          _hasMore = false;
        });
      }
    } catch (e) {
      print('❌ [DraftListView] 下書き読み込みエラー: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _loadMoreDrafts() async {
    if (!_hasMore) return;
    
    _currentPage++;
    print('📋 [DraftListView] 次ページ${_currentPage}を読み込み中...');
    await _loadDrafts();
  }
  
  Future<void> _refreshDrafts() async {
    print('🔄 [DraftListView] 下書きリストをリフレッシュ');
    await _loadDrafts(refresh: true);
  }
  
  // 外部から呼び出せるリフレッシュメソッド
  Future<void> refreshDrafts() async {
    await _refreshDrafts();
  }
  
  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return '';
    
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}日前';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}時間前';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}分前';
      } else {
        return 'たった今';
      }
    } catch (e) {
      return '';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 300, // 最大高さを設定
      ),
      decoration: BoxDecoration(
        color: YanwariDesignSystem.neutralColor,
        borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusLg),
        border: Border.all(
          color: YanwariDesignSystem.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Container(
            padding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
            decoration: BoxDecoration(
              color: YanwariDesignSystem.primaryColorLight,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(YanwariDesignSystem.radiusLg),
                topRight: Radius.circular(YanwariDesignSystem.radiusLg),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.edit_note,
                  size: 20,
                  color: YanwariDesignSystem.primaryColor,
                ),
                SizedBox(width: YanwariDesignSystem.spacingSm),
                Expanded(
                  child: Text(
                    '下書き一覧 (${_drafts.length}件)',
                    style: YanwariDesignSystem.bodyMd.copyWith(
                      fontWeight: FontWeight.bold,
                      color: YanwariDesignSystem.primaryColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    size: 20,
                    color: YanwariDesignSystem.primaryColor,
                  ),
                  onPressed: _refreshDrafts,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          
          // 下書きリスト（スクロール可能）
          Expanded(
            child: _drafts.isEmpty && !_isLoading
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(YanwariDesignSystem.spacingLg),
                      child: Text(
                        'まだ下書きはありません',
                        style: YanwariDesignSystem.bodySm.copyWith(
                          color: YanwariDesignSystem.textSecondary,
                        ),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshDrafts,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(
                        horizontal: YanwariDesignSystem.spacingMd,
                        vertical: YanwariDesignSystem.spacingSm,
                      ),
                      itemCount: _drafts.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        // ローディングインジケーター
                        if (index >= _drafts.length) {
                          return _isLoading
                              ? Container(
                                  padding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
                                  alignment: Alignment.center,
                                  child: const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : const SizedBox.shrink();
                        }
                        
                        final draft = _drafts[index];
                        final text = draft['originalText'] ?? draft['original_text'] ?? '';
                        final reason = draft['reason'] ?? '';
                        
                        // メッセージと理由を個別に処理
                        final hasText = text.isNotEmpty;
                        final hasReason = reason.isNotEmpty;
                        final truncatedText = hasText 
                            ? (text.length > 40 ? '${text.substring(0, 40)}...' : text)
                            : '';
                        final truncatedReason = hasReason 
                            ? (reason.length > 35 ? '${reason.substring(0, 35)}...' : reason)
                            : '';
                        
                        final isSelected = widget.currentDraftId == (draft['id'] ?? draft['_id']);
                        // 更新日時を表示（なければ作成日時）
                        final updatedAt = draft['updatedAt'] ?? draft['updated_at'] ?? draft['createdAt'] ?? draft['created_at'];
                        final timeAgo = _formatDateTime(updatedAt);
                        
                        return Container(
                          margin: EdgeInsets.only(bottom: YanwariDesignSystem.spacingSm),
                          child: Material(
                            color: isSelected 
                                ? YanwariDesignSystem.primaryColorLight 
                                : YanwariDesignSystem.backgroundPrimary,
                            borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusMd),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusMd),
                              onTap: () => widget.onDraftSelected(draft),
                              child: Container(
                                padding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
                                decoration: BoxDecoration(
                                  border: isSelected
                                      ? Border.all(
                                          color: YanwariDesignSystem.primaryColor,
                                          width: 2,
                                        )
                                      : Border.all(
                                          color: YanwariDesignSystem.borderColor,
                                          width: 1,
                                        ),
                                  borderRadius: BorderRadius.circular(YanwariDesignSystem.radiusMd),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // メッセージ本文
                                    if (hasText) ...[
                                      Text(
                                        truncatedText,
                                        style: YanwariDesignSystem.bodySm.copyWith(
                                          color: isSelected 
                                              ? YanwariDesignSystem.primaryColor 
                                              : YanwariDesignSystem.textPrimary,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (hasReason) SizedBox(height: YanwariDesignSystem.spacingXs),
                                    ],
                                    // 理由・背景
                                    if (hasReason) ...[
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: YanwariDesignSystem.secondaryColor.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '理由',
                                              style: YanwariDesignSystem.caption.copyWith(
                                                color: YanwariDesignSystem.secondaryColorDark,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: YanwariDesignSystem.spacingXs),
                                          Expanded(
                                            child: Text(
                                              truncatedReason,
                                              style: YanwariDesignSystem.bodySm.copyWith(
                                                color: isSelected 
                                                    ? YanwariDesignSystem.primaryColor 
                                                    : YanwariDesignSystem.textSecondary,
                                                fontWeight: FontWeight.normal,
                                                fontSize: 13,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    // 空の場合
                                    if (!hasText && !hasReason) ...[
                                      Text(
                                        '(空の下書き)',
                                        style: YanwariDesignSystem.bodySm.copyWith(
                                          color: YanwariDesignSystem.textTertiary,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                    if (timeAgo.isNotEmpty) ...[
                                      SizedBox(height: YanwariDesignSystem.spacingXs),
                                      Text(
                                        timeAgo,
                                        style: YanwariDesignSystem.caption.copyWith(
                                          color: YanwariDesignSystem.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}