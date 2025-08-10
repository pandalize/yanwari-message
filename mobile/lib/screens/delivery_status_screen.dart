import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/dashboard.dart';
import '../utils/design_system.dart';

/// 送信状況画面
class DeliveryStatusScreen extends StatefulWidget {
  const DeliveryStatusScreen({super.key});

  @override
  State<DeliveryStatusScreen> createState() => _DeliveryStatusScreenState();
}

class _DeliveryStatusScreenState extends State<DeliveryStatusScreen> {
  DeliveryStatusResponse? _deliveryData;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  static const int _limit = 20;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadDeliveryStatuses();
  }

  /// 送信状況を読み込み
  Future<void> _loadDeliveryStatuses({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      final apiService = ApiService(authService);
      
      final response = await apiService.getDeliveryStatuses(page: page, limit: _limit);
      final deliveryData = DeliveryStatusResponse.fromJson(response['data']);
      
      setState(() {
        _deliveryData = deliveryData;
        _currentPage = page;
      });
    } catch (e) {
      print('送信状況読み込みエラー: $e');
      setState(() {
        _error = '送信状況の読み込みに失敗しました';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// フィルタリングされた送信状況一覧
  List<DeliveryStatus> get filteredStatuses {
    if (_deliveryData == null) return [];
    
    if (_statusFilter == 'all') {
      return _deliveryData!.statuses;
    }
    
    return _deliveryData!.statuses
        .where((status) => status.status == _statusFilter)
        .toList();
  }

  /// ステータス統計
  Map<String, int> get statusSummary {
    if (_deliveryData == null) return {};
    
    final statuses = _deliveryData!.statuses;
    return {
      'sent': statuses.where((s) => s.status == 'sent').length,
      'delivered': statuses.where((s) => s.status == 'delivered').length,
      'read': statuses.where((s) => s.status == 'read').length,
      'scheduled': statuses.where((s) => s.status == 'scheduled').length,
    };
  }

  /// ページ移動
  void _goToPage(int page) {
    if (page >= 1 && _deliveryData != null && page <= _deliveryData!.totalPages) {
      _loadDeliveryStatuses(page: page);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YanwariDesignSystem.backgroundPrimary,
      appBar: AppBar(
        title: const Text('送信状況'),
        backgroundColor: YanwariDesignSystem.primaryColor,
        foregroundColor: YanwariDesignSystem.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _loadDeliveryStatuses(page: _currentPage),
            icon: const Icon(Icons.refresh),
            tooltip: '更新',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadDeliveryStatuses(page: _currentPage),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _deliveryData == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('送信状況を読み込み中...'),
          ],
        ),
      );
    }

    if (_error != null && _deliveryData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: YanwariDesignSystem.errorColor,
            ),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDeliveryStatuses,
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 統計サマリー
        if (_deliveryData != null) ...[
          Container(
            padding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
            child: _buildStatusSummary(),
          ),
          
          // フィルター
          Container(
            padding: EdgeInsets.symmetric(horizontal: YanwariDesignSystem.spacingMd),
            child: _buildFilterBar(),
          ),
        ],

        // メッセージ一覧
        Expanded(
          child: filteredStatuses.isEmpty
              ? _buildEmptyState()
              : _buildMessageList(),
        ),

        // ページネーション
        if (_deliveryData != null && _deliveryData!.totalPages > 1)
          _buildPagination(),
      ],
    );
  }

  /// ステータスサマリーカード
  Widget _buildStatusSummary() {
    final summary = statusSummary;
    
    return Row(
      children: [
        Expanded(child: _buildSummaryCard('送信済み', summary['sent'] ?? 0, YanwariDesignSystem.successColor)),
        const SizedBox(width: 8),
        Expanded(child: _buildSummaryCard('配信済み', summary['delivered'] ?? 0, YanwariDesignSystem.secondaryColor)),
        const SizedBox(width: 8),
        Expanded(child: _buildSummaryCard('既読', summary['read'] ?? 0, Colors.green)),
        const SizedBox(width: 8),
        Expanded(child: _buildSummaryCard('予約中', summary['scheduled'] ?? 0, Colors.orange)),
      ],
    );
  }

  Widget _buildSummaryCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// フィルターバー
  Widget _buildFilterBar() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _statusFilter,
            decoration: const InputDecoration(
              labelText: 'フィルター',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('すべて')),
              DropdownMenuItem(value: 'sent', child: Text('送信済み')),
              DropdownMenuItem(value: 'delivered', child: Text('配信済み')),
              DropdownMenuItem(value: 'read', child: Text('既読')),
              DropdownMenuItem(value: 'scheduled', child: Text('予約中')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _statusFilter = value;
                });
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => _loadDeliveryStatuses(page: _currentPage),
          icon: const Icon(Icons.refresh),
          tooltip: '更新',
        ),
      ],
    );
  }

  /// 空の状態
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mail_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '該当する送信メッセージがありません',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// メッセージリスト
  Widget _buildMessageList() {
    return ListView.builder(
      padding: EdgeInsets.all(YanwariDesignSystem.spacingMd),
      itemCount: filteredStatuses.length,
      itemBuilder: (context, index) {
        final status = filteredStatuses[index];
        return _buildMessageStatusCard(status);
      },
    );
  }

  /// メッセージステータスカード
  Widget _buildMessageStatusCard(DeliveryStatus status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Row(
            children: [
              Expanded(
                child: Text(
                  status.recipientName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(int.parse('0xFF${status.statusColor.substring(1)}')).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(int.parse('0xFF${status.statusColor.substring(1)}')),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // メッセージ内容プレビュー
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              status.text.length > 100 ? '${status.text.substring(0, 100)}...' : status.text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // ステータスタイムライン
          _buildStatusTimeline(status),
          
          // エラーメッセージ
          if (status.errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[600], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status.errorMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// ステータスタイムライン
  Widget _buildStatusTimeline(DeliveryStatus status) {
    return Row(
      children: [
        _buildTimelineStep(
          label: '送信',
          time: status.sentAt,
          isActive: status.sentAt != null,
        ),
        const Expanded(child: Divider()),
        _buildTimelineStep(
          label: '配信',
          time: status.deliveredAt,
          isActive: status.deliveredAt != null,
        ),
        const Expanded(child: Divider()),
        _buildTimelineStep(
          label: '既読',
          time: status.readAt,
          isActive: status.readAt != null,
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required String label,
    DateTime? time,
    required bool isActive,
  }) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? YanwariDesignSystem.successColor : Colors.grey[300],
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
          child: isActive
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isActive ? YanwariDesignSystem.textPrimary : Colors.grey[600],
          ),
        ),
        if (time != null) ...[
          const SizedBox(height: 2),
          Text(
            '${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  /// ページネーション
  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('$_currentPage / ${_deliveryData!.totalPages}'),
          IconButton(
            onPressed: _currentPage < _deliveryData!.totalPages ? () => _goToPage(_currentPage + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}