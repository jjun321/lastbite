import 'package:flutter/material.dart';
import 'package:frontend/features/consumer/home/presentation/pages/home_tab_page.dart';
import 'package:frontend/features/consumer/home/presentation/widgets/bottom_nav_bar.dart';
import 'package:frontend/features/consumer/mypage/presentation/pages/consumer_mypage.dart';
import 'package:frontend/features/consumer/order/presentation/pages/order_history_page.dart';
import 'package:frontend/features/consumer/board/board_navigation.dart';
import 'package:frontend/features/consumer/board/report_board_page.dart';

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
    const ReportBoardPage(),
    const OrderHistoryPage(),
    const ConsumerMyPage(),
  ];

  @override
  void initState() {
    super.initState();
    BoardNavigation.requestedTabIndex.addListener(_onExternalTabRequest);
  }

  @override
  void dispose() {
    BoardNavigation.requestedTabIndex.removeListener(_onExternalTabRequest);
    super.dispose();
  }

  void _onExternalTabRequest() {
    final next = BoardNavigation.requestedTabIndex.value;
    if (!mounted || next == _currentTabIndex) return;
    if (next < 0 || next >= _tabPages.length) return;
    setState(() => _currentTabIndex = next);
  }

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
          // 외부 호출(매장정보 카드 탭 등)과 값이 어긋나지 않도록 동기화한다.
          BoardNavigation.requestedTabIndex.value = index;
        },
      ),
    );
  }
}
