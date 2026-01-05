import 'package:cloud_firestore/cloud_firestore.dart';

class YearPrayerItem {
  final String? id; // 문서 ID (order)
  final String userId;
  final int year;
  final int order;
  final String title;
  final bool isAnswered;
  final DateTime createdAt;
  final DateTime updatedAt;

  YearPrayerItem({
    this.id,
    required this.userId,
    required this.year,
    required this.order,
    required this.title,
    required this.isAnswered,
    required this.createdAt,
    required this.updatedAt,
  });

  // Firestore에서 데이터를 가져올 때 사용
  factory YearPrayerItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return YearPrayerItem(
      id: doc.id,
      userId: data['userId'] ?? '',
      year: data['year'] ?? DateTime.now().year,
      order: data['order'] ?? 1,
      title: data['title'] ?? '',
      isAnswered: data['isAnswered'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Firestore에 저장할 때 사용
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'year': year,
      'order': order,
      'title': title,
      'isAnswered': isAnswered,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // 복사 생성자
  YearPrayerItem copyWith({
    String? id,
    String? userId,
    int? year,
    int? order,
    String? title,
    bool? isAnswered,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return YearPrayerItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      year: year ?? this.year,
      order: order ?? this.order,
      title: title ?? this.title,
      isAnswered: isAnswered ?? this.isAnswered,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
