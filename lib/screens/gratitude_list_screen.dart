import 'package:flutter/material.dart';
import '../models/gratitude.dart';
import '../services/firestore_service.dart';
import '../widgets/gratitude_card.dart';
import '../widgets/empty_state.dart';
import '../utils/date_range_picker_dialog.dart';
import 'gratitude_form_screen.dart';

class GratitudeListScreen extends StatefulWidget {
  const GratitudeListScreen({super.key});

  @override
  State<GratitudeListScreen> createState() => _GratitudeListScreenState();
}

class _GratitudeListScreenState extends State<GratitudeListScreen> {
  late DateTimeRange _dateRange;

  @override
  void initState() {
    super.initState();
    // 탭 이동할 때마다 오늘 날짜로 초기화
    _dateRange = DateTimeRange(
      start: DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day),
      end: DateTime(DateTime.now().year, DateTime.now().month,
          DateTime.now().day, 23, 59, 59, 999, 999),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('감사'),
        backgroundColor: Colors.purple[100],
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
                debugPrint(
                    'Selected date range: start=${picked.start}, end=${picked.end}');
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Gratitude>>(
        stream: firestoreService.getGratitudesStream(),
        builder: (context, snapshot) {
          debugPrint(
              'Gratitude snapshot: connectionState=${snapshot.connectionState}, hasData=${snapshot.hasData}, dataLength=${snapshot.data?.length}, hasError=${snapshot.hasError}');
          if (snapshot.hasError) {
            debugPrint('Gratitude snapshot error: ${snapshot.error}');
          }
          if (snapshot.data != null) {
            debugPrint(
                'Gratitude snapshot data: ${snapshot.data!.map((g) => g.title).toList()}');
          }
          // 데이터 필터링
          final allGratitudes = snapshot.data ?? [];
          final gratitudes = allGratitudes.where((gratitude) {
            return gratitude.createdAt.isAfter(
                    _dateRange.start.subtract(const Duration(seconds: 1))) &&
                gratitude.createdAt
                    .isBefore(_dateRange.end.add(const Duration(seconds: 1)));
          }).toList();

          // 연결 상태 확인
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

          // 데이터가 있고 필터링 후 항목이 있으면 표시
          if (snapshot.hasData && gratitudes.isNotEmpty) {
            return ListView.builder(
              itemCount: gratitudes.length,
              itemBuilder: (context, index) {
                final gratitude = gratitudes[index];
                return GratitudeCard(
                  gratitude: gratitude,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GratitudeFormScreen(
                          gratitude: gratitude,
                        ),
                      ),
                    );
                  },
                  onDelete: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('삭제 확인'),
                        content: const Text('이 감사를 삭제하시겠습니까?'),
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

                    if (confirm == true && gratitude.id != null) {
                      await firestoreService.deleteGratitude(gratitude.id!);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('감사가 삭제되었습니다')),
                        );
                      }
                    }
                  },
                );
              },
            );
          }

          // 데이터가 없을 때 빈 상태 표시 (연결 상태와 관계없이)
          if (gratitudes.isEmpty) {
            // 연결이 완료되었거나 데이터가 있는 경우 빈 상태 표시
            // hasData가 true이면 빈 배열을 받았다는 의미이므로 즉시 표시
            if (snapshot.hasData ||
                snapshot.connectionState == ConnectionState.active ||
                snapshot.connectionState == ConnectionState.done) {
              return const EmptyState(
                icon: Icons.favorite_border,
                message: '아직 작성한 감사가 없습니다',
                subMessage: '오른쪽 아래 버튼을 눌러 감사를 작성해보세요',
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
              builder: (context) => const GratitudeFormScreen(),
            ),
          );
          // 저장 성공/실패 메시지 표시
          if (result == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('감사가 저장되었습니다'),
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
        backgroundColor: Colors.purple[300],
      ),
    );
  }
}
