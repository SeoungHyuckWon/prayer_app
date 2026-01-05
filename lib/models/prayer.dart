import 'package:cloud_firestore/cloud_firestore.dart';

enum PrayerStatus {
  ongoing, // 진행중
  answered, // 응답받음
  pending, // 보류
}

extension PrayerStatusExtension on PrayerStatus {
  String get displayName {
    switch (this) {
      case PrayerStatus.ongoing:
        return '진행중';
      case PrayerStatus.answered:
        return '응답받음';
      case PrayerStatus.pending:
        return '보류';
    }
  }
}

class Prayer {
  final String? id;
  final String userId;
  final String title;
  final String content;
  final PrayerStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? answeredAt;

  Prayer({
    this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.answeredAt,
  });

  // Firestore에서 데이터를 가져올 때 사용
  factory Prayer.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Prayer(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      status: _statusFromString(data['status'] ?? 'ongoing'),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      answeredAt: data['answeredAt'] != null
          ? (data['answeredAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Firestore에 저장할 때 사용
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'content': content,
      'status': _statusToString(status),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'answeredAt': answeredAt != null ? Timestamp.fromDate(answeredAt!) : null,
    };
  }

  // 복사 생성자
  Prayer copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    PrayerStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? answeredAt,
  }) {
    return Prayer(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      answeredAt: answeredAt ?? this.answeredAt,
    );
  }

  static PrayerStatus _statusFromString(String status) {
    switch (status) {
      case 'ongoing':
        return PrayerStatus.ongoing;
      case 'answered':
        return PrayerStatus.answered;
      case 'pending':
        return PrayerStatus.pending;
      default:
        return PrayerStatus.ongoing;
    }
  }

  static String _statusToString(PrayerStatus status) {
    switch (status) {
      case PrayerStatus.ongoing:
        return 'ongoing';
      case PrayerStatus.answered:
        return 'answered';
      case PrayerStatus.pending:
        return 'pending';
    }
  }
}
