import 'package:flutter/material.dart';
import 'package:frontend/features/owner/dashboard/data/owner_dashboard_service.dart';
import 'package:frontend/features/owner/dashboard/presentation/widgets/owner_bottom_nav_bar.dart';
import 'package:frontend/features/owner/mypage/presentation/pages/owner_mypage.dart';
import 'package:frontend/features/owner/sales/presentation/pages/owner_sales_page.dart';
import 'package:frontend/features/owner/order_manage/presentation/pages/owner_order_management_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  final int initialTabIndex;

  const OwnerDashboardScreen({Key? key, this.initialTabIndex = 0}) : super(key: key);

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  late int _currentTabIndex = widget.initialTabIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: IndexedStack(
          index: _currentTabIndex,
          children: const [
            _OwnerDashboardHome(),           // 0: 홈
            OwnerSalesPage(),                // 1: 판매설정
            OwnerOrderManagementScreen(initialHistoryMode: false), // 2: 주문관리
            OwnerMyPage(),                   // 3: 마이페이지
          ],
        ),
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
}

/// --- 탭 0: 홈 대시보드 콘텐츠 ---
class _OwnerDashboardHome extends StatefulWidget {
  const _OwnerDashboardHome();

  @override
  State<_OwnerDashboardHome> createState() => _OwnerDashboardHomeState();
}

class _OwnerDashboardHomeState extends State<_OwnerDashboardHome> {
  OwnerDashboardData? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await OwnerDashboardService.fetch();
    if (!mounted) return;
    setState(() {
      _data = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4FA55B)));
    }

    return RefreshIndicator(
      color: const Color(0xFF4FA55B),
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSalesCard(_data?.storeName ?? '우리 매장', _data?.totalSales ?? '0'),
            const SizedBox(height: 24),
            _buildOrderStatButtons(context),
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '우리 매장 상품 판매 현황',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF181C2E)),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildRankingSection('인기 상품', _data?.bestSellers ?? [], isBest: true)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildRankingSection('비인기 상품', _data?.worstSellers ?? [], isBest: false)),
                ],
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesCard(String storeName, String totalSales) => Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
    padding: const EdgeInsets.symmetric(vertical: 30),
    decoration: BoxDecoration(
      color: const Color(0xFF4FA55B),
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF4FA55B).withOpacity(0.3),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$storeName 매출', style: const TextStyle(fontSize: 18, color: Colors.white)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(totalSales, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(width: 4),
            const Text('원', style: TextStyle(fontSize: 20, color: Colors.white)),
          ],
        ),
      ],
    ),
  );

  Widget _buildOrderStatButtons(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OwnerOrderManagementScreen(initialHistoryMode: false)),
            ).then((_) => _load()),
            child: _buildStatButton('들어온 주문', (_data?.incomingCount ?? 0).toString()),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OwnerOrderManagementScreen(initialHistoryMode: true)),
            ).then((_) => _load()),
            child: _buildStatButton('판매완료 주문', (_data?.completedCount ?? 0).toString()),
          ),
        ),
      ],
    ),
  );

  Widget _buildStatButton(String label, String count) => Container(
    height: 80,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFF0F0F0)),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2)),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B6E82))),
        const SizedBox(height: 6),
        Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E))),
      ],
    ),
  );

  Widget _buildRankingSection(String title, List<String> items, {required bool isBest}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF181C2E))),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: items.isEmpty
            ? const SizedBox(
            height: 80,
            child: Center(child: Text('데이터 없음', style: TextStyle(fontSize: 12, color: Colors.grey)))
        )
            : Column(
          children: List.generate(items.length, (index) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Text(
                        '${index + 1}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isBest ? const Color(0xFF4FA55B) : Colors.orangeAccent
                        )
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(
                            items[index],
                            style: const TextStyle(fontSize: 13, color: Color(0xFF1E1E1E)),
                            overflow: TextOverflow.ellipsis
                        )
                    ),
                  ],
                ),
              ),
              if (index != items.length - 1) const Divider(height: 1, color: Color(0xFFF5F5F5)),
            ],
          )),
        ),
      ),
    ],
  );
}