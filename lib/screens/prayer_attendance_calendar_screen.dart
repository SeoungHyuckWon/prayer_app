import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/firestore_service.dart';
import '../models/prayer_attendance.dart';

class PrayerAttendanceCalendarScreen extends StatefulWidget {
  const PrayerAttendanceCalendarScreen({super.key});

  @override
  State<PrayerAttendanceCalendarScreen> createState() =>
      _PrayerAttendanceCalendarScreenState();
}

class _PrayerAttendanceCalendarScreenState
    extends State<PrayerAttendanceCalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late int _currentYear;
  late String _userId;
  final FirestoreService _firestoreService = FirestoreService();

  // 출석 데이터 저장용 맵
  Map<DateTime, bool> _prayerAttendances = {};

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _currentYear = DateTime.now().year;
    _userId = FirebaseAuth.instance.currentUser!.uid;
    _loadPrayerAttendances();
  }

  // 출석 데이터 로드
  void _loadPrayerAttendances() {
    _firestoreService
        .getPrayerAttendancesByYearStream(_userId, _currentYear)
        .listen(
      (attendances) {
        if (mounted) {
          setState(() {
            _prayerAttendances = {
              for (var attendance in attendances)
                DateTime(attendance.date.year, attendance.date.month,
                    attendance.date.day): attendance.isPrayed
            };
          });
        }
      },
      onError: (error) {
        debugPrint('출석 데이터 로드 에러: $error');
      },
    );
  }

  // 출석 토글
  Future<void> _togglePrayerAttendance(DateTime date) async {
    // 미래 날짜는 변경 불가
    if (date.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('미래 날짜는 기록할 수 없습니다')),
      );
      return;
    }

    final normalizedDate = DateTime(date.year, date.month, date.day);
    final isCurrentlyPrayed = _prayerAttendances[normalizedDate] ?? false;
    final newIsPrayed = !isCurrentlyPrayed;

    try {
      final attendance = PrayerAttendance(
        userId: _userId,
        date: normalizedDate,
        isPrayed: newIsPrayed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.setPrayerAttendance(attendance);

      // 로컬 상태 업데이트
      setState(() {
        _prayerAttendances[normalizedDate] = newIsPrayed;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newIsPrayed ? '기도 기록이 추가되었습니다' : '기도 기록이 제거되었습니다'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기록 저장에 실패했습니다')),
      );
    }
  }

  // 올해 기도 횟수 계산
  Future<int> _getPrayerCountThisYear() async {
    try {
      return await _firestoreService.getPrayerCountThisYear(
          _userId, _currentYear);
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _currentYear--;
                  _focusedDay = DateTime(
                      _currentYear, _focusedDay.month, _focusedDay.day);
                  _selectedDay = DateTime(
                      _currentYear, _selectedDay.month, _selectedDay.day);
                });
                _loadPrayerAttendances();
              },
            ),
            Text('$_currentYear년'),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                setState(() {
                  _currentYear++;
                  _focusedDay = DateTime(
                      _currentYear, _focusedDay.month, _focusedDay.day);
                  _selectedDay = DateTime(
                      _currentYear, _selectedDay.month, _selectedDay.day);
                });
                _loadPrayerAttendances();
              },
            ),
          ],
        ),
        backgroundColor: Colors.blue[100],
      ),
      body: Column(
        children: [
          // 올해 기도 횟수 표시
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: FutureBuilder<int>(
              future: _getPrayerCountThisYear(),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Center(
                  child: Text(
                    '올해 $count번 기도했어요',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                );
              },
            ),
          ),

          // 달력
          TableCalendar(
            firstDay: DateTime(_currentYear, 1, 1),
            lastDay: DateTime(_currentYear, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _togglePrayerAttendance(selectedDay);
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
                _currentYear = focusedDay.year;
              });
              _loadPrayerAttendances();
            },
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
            },
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue[200],
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue[400],
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.green[400],
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                final normalizedDate =
                    DateTime(date.year, date.month, date.day);
                final isPrayed = _prayerAttendances[normalizedDate] ?? false;

                if (isPrayed) {
                  return Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.red[400],
                      shape: BoxShape.circle,
                    ),
                  );
                }
                return null;
              },
            ),
          ),

          // 선택된 날짜 정보
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              '날짜를 선택하여 기도 기록을 토글하세요\n(빨간 점: 기도함, 빈 칸: 미기도)',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
