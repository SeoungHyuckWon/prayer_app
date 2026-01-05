import 'package:flutter/material.dart';
import 'gratitude_list_screen.dart';
import 'prayer_list_screen.dart';
import 'statistics_screen.dart';
import 'account_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  // 탭 변경 시 새 인스턴스 생성
  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return GratitudeListScreen();
      case 1:
        return PrayerListScreen();
      case 2:
        return StatisticsScreen();
      case 3:
        return AccountScreen();
      default:
        return GratitudeListScreen();
    }
  }

  // 탭 변경 메서드
  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getScreen(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: '감사',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.volunteer_activism),
            label: '기도제목',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: '통계',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '내 계정',
          ),
        ],
        // 아이템이 4개 이상일 때 타입 변경하여 아이콘과 라벨이 모두 보이도록 함
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
