import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/gratitude.dart';
import '../models/prayer.dart';
import '../models/year_prayer_item.dart';

const uuid = Uuid();

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Prayer>>? _prayersStream;
  Stream<List<Gratitude>>? _gratitudesStream;

  // 기도제목 관련
  Stream<List<Prayer>> getPrayersStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    _prayersStream ??= _firestore
        .collection('prayers')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Prayer.fromFirestore(doc)).toList());
    return _prayersStream!;
  }

  // 감사 관련 메서드
  CollectionReference get _gratitudesRef => _firestore.collection('gratitudes');

  // 감사 추가
  Future<String> addGratitude(Gratitude gratitude) async {
    try {
      debugPrint('FirestoreService.addGratitude: 저장 시작');
      // Firestore는 오프라인 지속성을 지원하므로 타임아웃 없이 실행
      // 로컬에 먼저 저장되고 나중에 서버와 동기화됨
      // add()가 완료되면 로컬 저장이 완료된 것이므로 성공으로 간주
      final docRef = await _gratitudesRef.add(gratitude.toFirestore());

      // DocumentReference가 반환되면 저장 성공
      if (docRef.id.isNotEmpty) {
        debugPrint('FirestoreService.addGratitude 성공: ${docRef.id}');
        return docRef.id;
      } else {
        throw Exception('Document ID가 비어있습니다');
      }
    } catch (e) {
      debugPrint('FirestoreService.addGratitude 에러: $e');
      rethrow;
    }
  }

  // 감사 수정
  Future<void> updateGratitude(Gratitude gratitude) async {
    if (gratitude.id == null) {
      throw Exception('Gratitude ID is null');
    }
    try {
      debugPrint('FirestoreService.updateGratitude: 업데이트 시작 - ${gratitude.id}');
      // Firestore는 오프라인 지속성을 지원하므로 타임아웃 없이 실행
      // update()가 완료되면 로컬 저장이 완료된 것이므로 성공으로 간주
      await _gratitudesRef.doc(gratitude.id).update(gratitude.toFirestore());
      debugPrint('FirestoreService.updateGratitude 성공: ${gratitude.id}');
    } catch (e) {
      debugPrint('FirestoreService.updateGratitude 에러: $e');
      rethrow;
    }
  }

  // 감사 삭제
  Future<void> deleteGratitude(String id) async {
    await _gratitudesRef.doc(id).delete();
  }

  // 감사 목록 조회 (스트림)
  Stream<List<Gratitude>> getGratitudesStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    _gratitudesStream ??= _gratitudesRef
        .where('userId', isEqualTo: uid)
        .snapshots(includeMetadataChanges: false) // 메타데이터 변경 무시로 성능 향상
        .map((snapshot) {
      // 빈 스냅샷이면 즉시 빈 배열 반환
      if (snapshot.docs.isEmpty) {
        return <Gratitude>[];
      }
      // 클라이언트 측에서 정렬 (인덱스 없이도 작동)
      final gratitudes =
          snapshot.docs.map((doc) => Gratitude.fromFirestore(doc)).toList();
      gratitudes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return gratitudes;
    }).handleError((error) {
      // 에러 발생 시 빈 배열 반환
      debugPrint('FirestoreService.getGratitudesStream: 에러 발생 - $error');
      return <Gratitude>[];
    });
    return _gratitudesStream!;
  }

  // 기간별 감사 목록 조회 (스트림)
  Stream<List<Gratitude>> getGratitudesByDateRangeStream(
      DateTimeRange dateRange) {
    return _gratitudesRef
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start))
        .where('createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end))
        .orderBy('createdAt', descending: true)
        .snapshots(includeMetadataChanges: false)
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return <Gratitude>[];
      }
      return snapshot.docs.map((doc) => Gratitude.fromFirestore(doc)).toList();
    }).handleError((error) {
      return <Gratitude>[];
    });
  }

  // 감사 단일 조회
  Future<Gratitude?> getGratitude(String id) async {
    final doc = await _gratitudesRef.doc(id).get();
    if (doc.exists) {
      return Gratitude.fromFirestore(doc);
    }
    return null;
  }

  // 기도제목 관련 메서드
  CollectionReference get _prayersRef => _firestore.collection('prayers');

  // 기도제목 추가
  Future<String> addPrayer(Prayer prayer) async {
    try {
      debugPrint('FirestoreService.addPrayer: 저장 시작');
      final dataToSave = prayer.toFirestore();
      debugPrint('FirestoreService.addPrayer: 저장할 데이터 = $dataToSave');

      // Firestore는 오프라인 지속성을 지원하므로 타임아웃 없이 실행
      // 로컬에 먼저 저장되고 나중에 서버와 동기화됨
      // add()가 완료되면 로컬 저장이 완료된 것이므로 성공으로 간주
      final docRef = await _prayersRef
          .add(dataToSave)
          .timeout(const Duration(seconds: 10));

      // DocumentReference가 반환되면 저장 성공
      if (docRef.id.isNotEmpty) {
        debugPrint('FirestoreService.addPrayer 성공: ${docRef.id}');
        return docRef.id;
      } else {
        throw Exception('Document ID가 비어있습니다');
      }
    } catch (e) {
      debugPrint('FirestoreService.addPrayer 에러: $e');
      rethrow;
    }
  }

  // 기도제목 수정
  Future<void> updatePrayer(Prayer prayer) async {
    if (prayer.id == null) {
      throw Exception('Prayer ID is null');
    }
    try {
      debugPrint('FirestoreService.updatePrayer: 업데이트 시작 - ${prayer.id}');
      // Firestore는 오프라인 지속성을 지원하므로 타임아웃 없이 실행
      // update()가 완료되면 로컬 저장이 완료된 것이므로 성공으로 간주
      await _prayersRef
          .doc(prayer.id)
          .update(prayer.toFirestore())
          .timeout(const Duration(seconds: 10));
      debugPrint('FirestoreService.updatePrayer 성공: ${prayer.id}');
    } catch (e) {
      debugPrint('FirestoreService.updatePrayer 에러: $e');
      rethrow;
    }
  }

  // 기도제목 삭제
  Future<void> deletePrayer(String id) async {
    await _prayersRef.doc(id).delete();
  }

  // 상태별 기도제목 조회
  Stream<List<Prayer>> getPrayersByStatusStream(PrayerStatus status) {
    String statusString = status == PrayerStatus.ongoing
        ? 'ongoing'
        : status == PrayerStatus.answered
            ? 'answered'
            : 'pending';
    return _prayersRef
        .where('status', isEqualTo: statusString)
        .snapshots(includeMetadataChanges: false) // 메타데이터 변경 무시로 성능 향상
        .map((snapshot) {
      // 빈 스냅샷이면 즉시 빈 배열 반환
      if (snapshot.docs.isEmpty) {
        return <Prayer>[];
      }
      final prayers =
          snapshot.docs.map((doc) => Prayer.fromFirestore(doc)).toList();
      // 클라이언트 측에서 정렬 (인덱스 없이도 작동)
      prayers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return prayers;
    }).handleError((error) {
      // 에러 발생 시 빈 배열 반환
      return <Prayer>[];
    });
  }

  // 기간별 기도제목 목록 조회 (스트림)
  Stream<List<Prayer>> getPrayersByDateRangeStream(DateTimeRange dateRange) {
    return _prayersRef
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start))
        .where('createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end))
        .orderBy('createdAt', descending: true)
        .snapshots(includeMetadataChanges: false)
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return <Prayer>[];
      }
      return snapshot.docs.map((doc) => Prayer.fromFirestore(doc)).toList();
    }).handleError((error) {
      return <Prayer>[];
    });
  }

  // 기도제목 단일 조회
  Future<Prayer?> getPrayer(String id) async {
    final doc = await _prayersRef.doc(id).get();
    if (doc.exists) {
      return Prayer.fromFirestore(doc);
    }
    return null;
  }

  // 특정 날짜 이후의 감사 목록 조회
  Future<List<Gratitude>> getGratitudesSince(DateTime date) async {
    final snapshot = await _gratitudesRef
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(date))
        .get();
    return snapshot.docs.map((doc) => Gratitude.fromFirestore(doc)).toList();
  }

  // 특정 날짜 이후의 기도제목 목록 조회
  Future<List<Prayer>> getPrayersSince(DateTime date) async {
    final snapshot = await _prayersRef
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(date))
        .get();
    return snapshot.docs.map((doc) => Prayer.fromFirestore(doc)).toList();
  }

  // 올해의 기도제목 체크리스트 관련 메서드
  CollectionReference _getYearPrayerItemsRef(String userId, int year) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('yearPrayers')
        .doc(year.toString())
        .collection('items');
  }

  // 년도별 아이템 목록 조회 (스트림)
  Stream<List<YearPrayerItem>> getYearPrayerItemsStream(
      String userId, int year) {
    return _getYearPrayerItemsRef(userId, year)
        .snapshots(includeMetadataChanges: false)
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return <YearPrayerItem>[];
      }
      final items = snapshot.docs
          .map((doc) => YearPrayerItem.fromFirestore(doc))
          .toList();
      items.sort((a, b) => a.order.compareTo(b.order));
      return items;
    }).handleError((error) {
      debugPrint('FirestoreService.getYearPrayerItemsStream: 에러 발생 - $error');
      return <YearPrayerItem>[];
    });
  }

  // 올해의 기도제목 아이템 추가
  Future<String> addYearPrayerItem(YearPrayerItem item) async {
    try {
      debugPrint('FirestoreService.addYearPrayerItem: 저장 시작');
      final docId = uuid.v4();
      await _getYearPrayerItemsRef(item.userId, item.year)
          .doc(docId)
          .set(item.toFirestore());
      debugPrint('FirestoreService.addYearPrayerItem 성공: $docId');
      return docId;
    } catch (e) {
      debugPrint('FirestoreService.addYearPrayerItem 에러: $e');
      rethrow;
    }
  }

  // 올해의 기도제목 아이템 수정
  Future<void> updateYearPrayerItem(YearPrayerItem item) async {
    if (item.id == null) {
      throw Exception('YearPrayerItem ID is null');
    }
    try {
      debugPrint('FirestoreService.updateYearPrayerItem: 업데이트 시작 - ${item.id}');
      await _getYearPrayerItemsRef(item.userId, item.year)
          .doc(item.id)
          .update(item.toFirestore());
      debugPrint('FirestoreService.updateYearPrayerItem 성공: ${item.id}');
    } catch (e) {
      debugPrint('FirestoreService.updateYearPrayerItem 에러: $e');
      rethrow;
    }
  }

  // 올해의 기도제목 아이템 삭제
  Future<void> deleteYearPrayerItem(String userId, int year, String id) async {
    await _getYearPrayerItemsRef(userId, year).doc(id).delete();
  }

  // 올해의 기도제목 아이템 순서 재정렬
  Future<void> reorderYearPrayerItems(String userId, int year) async {
    final ref = _getYearPrayerItemsRef(userId, year);
    final snapshot = await ref.get();
    final items =
        snapshot.docs.map((doc) => YearPrayerItem.fromFirestore(doc)).toList();
    items.sort((a, b) => a.order.compareTo(b.order));

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.order != i + 1) {
        final updated = item.copyWith(
          order: i + 1,
          updatedAt: DateTime.now(),
        );
        await ref.doc(updated.id).update(updated.toFirestore());
      }
    }
  }
}
