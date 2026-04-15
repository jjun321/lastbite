import 'package:flutter/material.dart';
import 'package:frontend/features/consumer/home/presentation/pages/home_tab_page.dart';
import 'package:frontend/features/consumer/home/presentation/widgets/bottom_nav_bar.dart';
import 'package:frontend/features/consumer/mypage/presentation/pages/consumer_mypage.dart';
import 'package:frontend/features/consumer/order/presentation/pages/order_history_page.dart';

/// 소비자 홈 화면의 최상위 Shell
/// 하단 네비게이션 바를 포함하고, 탭 전환을 관리

class ConsumerHomePage extends StatefulWidget {
  const ConsumerHomePage({super.key});

  @override
  State<ConsumerHomePage> createState() => _ConsumerHomePageState();
}

class _ConsumerHomePageState extends State<ConsumerHomePage> {
  int _currentTabIndex = 0;

  /// 4개 탭 페이지
  late final List<Widget> _tabPages = [
    const HomeTabPage(),
    _buildPlaceholderPage('제보게시판', Icons.chat_bubble_outline),
    const OrderHistoryPage(),
    const ConsumerMyPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: IndexedStack(index: _currentTabIndex, children: _tabPages),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
      ),
    );
  }

  /// 미구현 탭용 placeholder 페이지
  static Widget _buildPlaceholderPage(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: const Color(0xFFBDBDBD)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '준비 중입니다',
            style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }
}
