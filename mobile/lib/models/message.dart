class Message {
  final String id;
  final String senderId;
  final String recipientId;
  final String recipientEmail;
  final String originalText;
  final ToneVariations? variations;
  final String? selectedTone;
  final String? finalText;
  final DateTime? scheduledAt;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime? sentAt;
  final DateTime? readAt;

  Message({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.recipientEmail,
    required this.originalText,
    this.variations,
    this.selectedTone,
    this.finalText,
    this.scheduledAt,
    required this.status,
    required this.createdAt,
    this.sentAt,
    this.readAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      senderId: json['sender_id'] ?? '',
      recipientId: json['recipient_id'] ?? '',
      recipientEmail: json['recipient_email'] ?? '',
      originalText: json['original_text'] ?? '',
      variations: json['variations'] != null 
          ? ToneVariations.fromJson(json['variations'])
          : null,
      selectedTone: json['selected_tone'],
      finalText: json['final_text'],
      scheduledAt: json['scheduled_at'] != null 
          ? DateTime.parse(json['scheduled_at'])
          : null,
      status: MessageStatus.fromString(json['status'] ?? 'draft'),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      sentAt: json['sent_at'] != null 
          ? DateTime.parse(json['sent_at'])
          : null,
      readAt: json['read_at'] != null 
          ? DateTime.parse(json['read_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'recipient_id': recipientId,
      'recipient_email': recipientEmail,
      'original_text': originalText,
      'variations': variations?.toJson(),
      'selected_tone': selectedTone,
      'final_text': finalText,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'status': status.toString(),
      'created_at': createdAt.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }
}

class ToneVariations {
  final String gentle;
  final String constructive;
  final String casual;

  ToneVariations({
    required this.gentle,
    required this.constructive,
    required this.casual,
  });

  factory ToneVariations.fromJson(Map<String, dynamic> json) {
    return ToneVariations(
      gentle: json['gentle'] ?? '',
      constructive: json['constructive'] ?? '',
      casual: json['casual'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gentle': gentle,
      'constructive': constructive,
      'casual': casual,
    };
  }

  String getToneText(String tone) {
    switch (tone) {
      case 'gentle':
        return gentle;
      case 'constructive':
        return constructive;
      case 'casual':
        return casual;
      default:
        return gentle;
    }
  }
}

enum MessageStatus {
  draft,
  processing,
  scheduled,
  sent,
  delivered,
  read;

  static MessageStatus fromString(String status) {
    switch (status) {
      case 'draft':
        return MessageStatus.draft;
      case 'processing':
        return MessageStatus.processing;
      case 'scheduled':
        return MessageStatus.scheduled;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      default:
        return MessageStatus.draft;
    }
  }

  @override
  String toString() {
    return name;
  }

  String get displayName {
    switch (this) {
      case MessageStatus.draft:
        return '下書き';
      case MessageStatus.processing:
        return '処理中';
      case MessageStatus.scheduled:
        return '送信予定';
      case MessageStatus.sent:
        return '送信済み';
      case MessageStatus.delivered:
        return '配信済み';
      case MessageStatus.read:
        return '既読';
    }
  }
}