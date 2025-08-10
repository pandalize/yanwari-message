// ダッシュボード情報のデータモデル

/// 活動統計
class ActivityStats {
  final PeriodStats today;
  final PeriodStats thisMonth;
  final TotalStats total;

  ActivityStats({
    required this.today,
    required this.thisMonth,
    required this.total,
  });

  factory ActivityStats.fromJson(Map<String, dynamic> json) {
    return ActivityStats(
      today: PeriodStats.fromJson(json['today'] ?? {}),
      thisMonth: PeriodStats.fromJson(json['thisMonth'] ?? {}),
      total: TotalStats.fromJson(json['total'] ?? {}),
    );
  }
}

/// 期間別統計（今日・今月）
class PeriodStats {
  final int messagesSent;
  final int messagesReceived;
  final int messagesRead;

  PeriodStats({
    required this.messagesSent,
    required this.messagesReceived,
    required this.messagesRead,
  });

  factory PeriodStats.fromJson(Map<String, dynamic> json) {
    return PeriodStats(
      messagesSent: json['messagesSent'] ?? 0,
      messagesReceived: json['messagesReceived'] ?? 0,
      messagesRead: json['messagesRead'] ?? 0,
    );
  }
}

/// 全期間統計
class TotalStats {
  final int messagesSent;
  final int messagesReceived;
  final int friends;

  TotalStats({
    required this.messagesSent,
    required this.messagesReceived,
    required this.friends,
  });

  factory TotalStats.fromJson(Map<String, dynamic> json) {
    return TotalStats(
      messagesSent: json['messagesSent'] ?? 0,
      messagesReceived: json['messagesReceived'] ?? 0,
      friends: json['friends'] ?? 0,
    );
  }
}

/// 最近のメッセージ
class RecentMessage {
  final String id;
  final String type; // 'sent' or 'received'
  final String? senderName;
  final String? senderEmail;
  final String? recipientName;
  final String? recipientEmail;
  final String text;
  final DateTime sentAt;
  final DateTime? readAt;
  final bool isRead;

  RecentMessage({
    required this.id,
    required this.type,
    this.senderName,
    this.senderEmail,
    this.recipientName,
    this.recipientEmail,
    required this.text,
    required this.sentAt,
    this.readAt,
    required this.isRead,
  });

  factory RecentMessage.fromJson(Map<String, dynamic> json) {
    return RecentMessage(
      id: json['id'] ?? '',
      type: json['type'] ?? 'sent',
      senderName: json['senderName'],
      senderEmail: json['senderEmail'],
      recipientName: json['recipientName'],
      recipientEmail: json['recipientEmail'],
      text: json['text'] ?? '',
      sentAt: DateTime.parse(json['sentAt']),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      isRead: json['isRead'] ?? false,
    );
  }

  // 表示用の名前を取得
  String get displayName {
    if (type == 'sent') {
      return recipientName ?? recipientEmail ?? '送信先不明';
    } else {
      return senderName ?? senderEmail ?? '送信者不明';
    }
  }

  // 表示用のプレフィックスを取得
  String get displayPrefix {
    return type == 'sent' ? 'へ' : 'から';
  }
}

/// ダッシュボード情報
class DashboardData {
  final ActivityStats activityStats;
  final List<RecentMessage> recentMessages;
  final int pendingMessages; // 未読メッセージ数
  final int scheduledMessages; // スケジュール済みメッセージ数

  DashboardData({
    required this.activityStats,
    required this.recentMessages,
    required this.pendingMessages,
    required this.scheduledMessages,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      activityStats: ActivityStats.fromJson(json['activityStats'] ?? {}),
      recentMessages: (json['recentMessages'] as List<dynamic>?)
          ?.map((item) => RecentMessage.fromJson(item))
          .toList() ?? [],
      pendingMessages: json['pendingMessages'] ?? 0,
      scheduledMessages: json['scheduledMessages'] ?? 0,
    );
  }
}

/// 送信状況情報
class DeliveryStatus {
  final String messageId;
  final String status;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final String recipientName;
  final String text;
  final String? errorMessage;

  DeliveryStatus({
    required this.messageId,
    required this.status,
    this.sentAt,
    this.deliveredAt,
    this.readAt,
    required this.recipientName,
    required this.text,
    this.errorMessage,
  });

  factory DeliveryStatus.fromJson(Map<String, dynamic> json) {
    return DeliveryStatus(
      messageId: json['messageId'] ?? '',
      status: json['status'] ?? '',
      sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt']) : null,
      deliveredAt: json['deliveredAt'] != null ? DateTime.parse(json['deliveredAt']) : null,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      recipientName: json['recipientName'] ?? '受信者不明',
      text: json['text'] ?? '',
      errorMessage: json['errorMessage'],
    );
  }

  // ステータスの日本語表示
  String get statusText {
    const statusMap = {
      'draft': '下書き',
      'processing': '処理中',
      'scheduled': '予約中',
      'sent': '送信済み',
      'delivered': '配信済み',
      'read': '既読',
      'failed': '失敗',
    };
    return statusMap[status] ?? status;
  }

  // ステータスの色を取得
  String get statusColor {
    switch (status) {
      case 'sent':
        return '#38a169'; // green
      case 'delivered':
        return '#3182ce'; // blue
      case 'read':
        return '#22c35e'; // success green
      case 'scheduled':
        return '#d69e2e'; // orange
      case 'failed':
        return '#e53e3e'; // red
      default:
        return '#4a5568'; // gray
    }
  }
}

/// 送信状況一覧レスポンス
class DeliveryStatusResponse {
  final List<DeliveryStatus> statuses;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  DeliveryStatusResponse({
    required this.statuses,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory DeliveryStatusResponse.fromJson(Map<String, dynamic> json) {
    return DeliveryStatusResponse(
      statuses: (json['statuses'] as List<dynamic>?)
          ?.map((item) => DeliveryStatus.fromJson(item))
          .toList() ?? [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}