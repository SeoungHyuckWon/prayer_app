import 'package:flutter/material.dart';
import '../models/prayer.dart';
import '../services/firestore_service.dart';
import '../widgets/prayer_card.dart';
import '../widgets/empty_state.dart';
import '../utils/date_range_picker_dialog.dart';
import 'prayer_form_screen.dart';

class PrayerListScreen extends StatefulWidget {
  const PrayerListScreen({super.key});

  @override
  State<PrayerListScreen> createState() => _PrayerListScreenState();
}

class _PrayerListScreenState extends State<PrayerListScreen> {
  PrayerStatus? _selectedStatus;
  DateTimeRange _dateRange = DateTimeRange(
    start:
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    end: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day,
        23, 59, 59, 999, 999),
  );

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('기도제목'),
        backgroundColor: Colors.blue[100],
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await CustomDateRangePickerDialog.show(
                context,
                _dateRange,
              );
              if (picked != null) {
                setState(() {
                  _dateRange = picked;
                });
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<String>(
                onSelected: (String newValue) {
                  debugPrint('Selected: $newValue');
                  setState(() {
                    switch (newValue) {
                      case 'all':
                        _selectedStatus = null;
                        break;
                      case 'ongoing':
                        _selectedStatus = PrayerStatus.ongoing;
                        break;
                      case 'answered':
                        _selectedStatus = PrayerStatus.answered;
                        break;
                      case 'pending':
                        _selectedStatus = PrayerStatus.pending;
                        break;
                    }
                    debugPrint('Status set to: $_selectedStatus');
                  });
                },
                color: Colors.grey[200],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedStatus == null
                          ? '전체'
                          : _selectedStatus == PrayerStatus.ongoing
                              ? PrayerStatus.ongoing.displayName
                              : _selectedStatus == PrayerStatus.answered
                                  ? PrayerStatus.answered.displayName
                                  : PrayerStatus.pending.displayName,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'all',
                    child: const Text('전체'),
                  ),
                  PopupMenuItem<String>(
                    value: 'ongoing',
                    child: const Text('진행중'),
                  ),
                  PopupMenuItem<String>(
                    value: 'answered',
                    child: const Text('응답받음'),
                  ),
                  PopupMenuItem<String>(
                    value: 'pending',
                    child: const Text('보류'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Prayer>>(
        stream: firestoreService.getPrayersStream(),
        builder: (context, snapshot) {
          debugPrint(
              'Prayer snapshot: connectionState=${snapshot.connectionState}, hasData=${snapshot.hasData}, dataLength=${snapshot.data?.length}');
          // 데이터 필터링
          final allPrayers = snapshot.data ?? [];
          final dateFilteredPrayers = allPrayers.where((prayer) {
            return prayer.createdAt.isAfter(
                    _dateRange.start.subtract(const Duration(seconds: 1))) &&
                prayer.createdAt
                    .isBefore(_dateRange.end.add(const Duration(seconds: 1)));
          }).toList();
          final prayers = _selectedStatus == null
              ? dateFilteredPrayers
              : dateFilteredPrayers
                  .where((prayer) => prayer.status == _selectedStatus)
                  .toList();

          // 데이터가 있고 필터링 후 항목이 있으면 표시
          if (snapshot.hasData && prayers.isNotEmpty) {
            return ListView.builder(
              itemCount: prayers.length,
              itemBuilder: (context, index) {
                final prayer = prayers[index];
                return PrayerCard(
                  prayer: prayer,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PrayerFormScreen(
                          prayer: prayer,
                        ),
                      ),
                    );
                  },
                  onDelete: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('삭제 확인'),
                        content: const Text('이 기도제목을 삭제하시겠습니까?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('삭제',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && prayer.id != null) {
                      await firestoreService.deletePrayer(prayer.id!);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('기도제목이 삭제되었습니다')),
                        );
                      }
                    }
                  },
                );
              },
            );
          }

          // 연결 상태 확인 (데이터가 없을 때만)
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // 연결이 없거나 none 상태일 때 (네트워크 오류 등)
          if (snapshot.connectionState == ConnectionState.none) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    '연결할 수 없습니다',
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '인터넷 연결을 확인해주세요',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    '오류가 발생했습니다',
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // 데이터가 없을 때 빈 상태 표시 (연결 상태와 관계없이)
          if (prayers.isEmpty) {
            // 연결이 완료되었거나 데이터가 있는 경우 빈 상태 표시
            // hasData가 true이면 빈 배열을 받았다는 의미이므로 즉시 표시
            if (snapshot.hasData ||
                snapshot.connectionState == ConnectionState.active ||
                snapshot.connectionState == ConnectionState.done) {
              String emptyMessage = _selectedStatus == null
                  ? '아직 작성한 기도제목이 없습니다'
                  : _selectedStatus == PrayerStatus.ongoing
                      ? '진행중인 기도제목이 없습니다'
                      : _selectedStatus == PrayerStatus.answered
                          ? '응답받은 기도제목이 없습니다'
                          : '보류된 기도제목이 없습니다';

              return EmptyState(
                icon: Icons.volunteer_activism,
                message: emptyMessage,
                subMessage: _selectedStatus == null
                    ? '오른쪽 아래 버튼을 눌러 기도제목을 작성해보세요'
                    : null,
              );
            }
          }

          // 기본 로딩 상태 (예외 상황)
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const PrayerFormScreen(),
            ),
          );
          // 저장 성공 시 성공 메시지 표시
          if (result == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('기도제목이 저장되었습니다'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          } else if (result == false && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('저장에 실패했습니다'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue[300],
      ),
    );
  }
}
