import 'package:cloud_firestore/cloud_firestore.dart';

class PrayerAttendance {
  final String? id;
  final String userId;
  final DateTime date;
  final bool isPrayed;
  final DateTime createdAt;
  final DateTime updatedAt;

  PrayerAttendance({
    this.id,
    required this.userId,
    required this.date,
    required this.isPrayed,
    required this.createdAt,
    required this.updatedAt,
  });

  // 날짜만 비교하기 위한 키 생성
  String get dateKey =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  // Firestore에서 데이터를 가져올 때 사용
  factory PrayerAttendance.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PrayerAttendance(
      id: doc.id,
      userId: data['userId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      isPrayed: data['isPrayed'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Firestore에 저장할 때 사용
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'isPrayed': isPrayed,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // 복사 생성자
  PrayerAttendance copyWith({
    String? id,
    String? userId,
    DateTime? date,
    bool? isPrayed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PrayerAttendance(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      isPrayed: isPrayed ?? this.isPrayed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'PrayerAttendance(id: $id, userId: $userId, date: $date, isPrayed: $isPrayed)';
  }
}
