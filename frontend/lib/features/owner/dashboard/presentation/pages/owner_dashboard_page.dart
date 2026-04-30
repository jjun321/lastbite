import 'package:flutter/material.dart';
import 'package:frontend/data/mock_data.dart';
import 'package:frontend/data/models.dart';
import 'package:frontend/features/owner/dashboard/data/owner_dashboard_service.dart';
import 'package:frontend/features/owner/order_manage/presentation/pages/owner_order_detail_page.dart';
import 'package:frontend/features/owner/order_manage/presentation/pages/owner_order_management_screen.dart';
import 'package:frontend/features/owner/dashboard/presentation/widgets/owner_bottom_nav_bar.dart';
import 'package:frontend/features/owner/mypage/presentation/pages/owner_mypage.dart';
import 'package:frontend/features/owner/sales/presentation/pages/owner_sales_page.dart';

// 점주 대시보드 페이지
class OwnerDashboardScreen extends StatefulWidget {
  final int initialTabIndex;

  const OwnerDashboardScreen({Key? key, this.initialTabIndex = 0})
    : super(key: key);

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
            // 홈 탭 내용을 분리된 위젯으로 호출
            _OwnerDashboardHome(), // 0: 홈
            OwnerSalesPage(), // 1: 판매설정
            _NotificationPlaceholder(), // 2: 주문알림
            OwnerMyPage(), // 3: 마이페이지
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

class _NotificationPlaceholder extends StatefulWidget {
  const _NotificationPlaceholder();

  @override
  State<_NotificationPlaceholder> createState() =>
      _NotificationPlaceholderState();
}

class _NotificationPlaceholderState extends State<_NotificationPlaceholder> {
  bool isHistoryMode = false;

  void _showConfirmDialog({
    required BuildContext context,
    required String title,
    required Color actionColor,
    required Order order,
    required bool toAccepted,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFFF1F3E8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Container(
          width: 323,
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF676C5A),
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (toAccepted) {
                            order.isAccepted = true;
                            order.isCancelled = false;
                          } else {
                            order.isAccepted = false;
                            order.isCancelled = true;
                          }
                          isHistoryMode = true;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 37,
                        decoration: BoxDecoration(
                          color: actionColor,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '예',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 37,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: const Color(0xFFB3BA9F)),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '아니오',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Color(0xFFB3BA9F),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Order> displayList = isHistoryMode
        ? orderList.where((o) => o.isAccepted || o.isCancelled).toList()
        : orderList.where((o) => !o.isAccepted && !o.isCancelled).toList();

    return Column(
      children: [
        _buildTabButtons(),
        Expanded(
          child: displayList.isEmpty
              ? const Center(
                  child: Text(
                    '주문이 없습니다.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    return _buildOrderCard(displayList[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTabButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: _buildTabItem(
              "들어온 주문",
              !isHistoryMode,
              () => setState(() => isHistoryMode = false),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildTabItem(
              "주문 내역",
              isHistoryMode,
              () => setState(() => isHistoryMode = true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEAFBF0) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? const Color(0xFF4FA55B) : const Color(0xFFE4E4E4),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF4FA55B) : const Color(0xFF1E1E1E),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OwnerOrderDetailScreen(order: order),
          ),
        ).then((_) {
          setState(() {}); // 상세에서 돌아오면 상태 반영
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.transparent,
          border: Border(top: BorderSide(color: Color(0xFFEEF2F6))),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF98A8B8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.representativeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF181C2E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${order.totalCountString} | ${order.price}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF181C2E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '픽업: ${order.pickupTime}',
                              style: const TextStyle(
                                color: Color(0xFF6B6E82),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            order.orderNo,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B6E82),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (order.isCancelled)
                            const Text(
                              '취소됨',
                              style: TextStyle(
                                color: Color(0xFFD63030),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            )
                          else if (order.isAccepted)
                            const Text(
                              '수락됨',
                              style: TextStyle(
                                color: Color(0xFF4FA55B),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildActionButton(
                  order.isAccepted && !order.isCancelled ? '수락됨' : '주문 수락',
                  order.isAccepted && !order.isCancelled
                      ? const Color(0xFFB3BA9F)
                      : const Color(0xFF4FA55B),
                  () {
                    if (order.isAccepted && !order.isCancelled) return;
                    _showConfirmDialog(
                      context: context,
                      title: '이 주문을 수락하시겠습니까?',
                      actionColor: const Color(0xFF4FA55B),
                      order: order,
                      toAccepted: true,
                    );
                  },
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  order.isCancelled ? '취소됨' : '주문 취소',
                  order.isCancelled
                      ? const Color(0xFFB3BA9F)
                      : const Color(0xFFD63030),
                  () {
                    if (order.isCancelled) return;
                    _showConfirmDialog(
                      context: context,
                      title: '이 주문을 취소하시겠습니까?',
                      actionColor: const Color(0xFFD63030),
                      order: order,
                      toAccepted: false,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

/// --- 홈 탭 콘텐츠 위젯 ---
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
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4FA55B)),
      );
    }

    final storeName = _data?.storeName ?? '';
    final totalSales = _data?.totalSales ?? '0';
    final incomingCount = _data?.incomingCount ?? 0;
    final completedCount = _data?.completedCount ?? 0;
    final bestSellers = _data?.bestSellers ?? const <String>[];
    final worstSellers = _data?.worstSellers ?? const <String>[];

    return RefreshIndicator(
      color: const Color(0xFF4FA55B),
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 상단 매출 카드
            _buildSalesCard(storeName, totalSales),

            const SizedBox(height: 24),

            // 2. 주문 상태 버튼 세트
            _buildOrderStatButtons(context, incomingCount, completedCount),

            const SizedBox(height: 32),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '우리 매장에서 팔린 할인상품들이에요',
                style: TextStyle(
                  fontFamily: 'Sen',
                  fontSize: 16,
                  color: Color(0xFF181C2E),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 4. 베스트 & 워스트 셀러 섹션
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildRankingSection('인기 상품', bestSellers),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildRankingSection('비인기 상품', worstSellers),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // 매출 카드 위젯
  Widget _buildSalesCard(String storeName, String totalSales) => Container(
    width: double.infinity,
    height: 160,
    margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
    decoration: BoxDecoration(
      color: const Color(0xFF4FA55B),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$storeName 매출',
          style: const TextStyle(
            fontFamily: 'Sen',
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$totalSales원',
          style: const TextStyle(
            fontFamily: 'Sen',
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );

  // 주문 상태 버튼 세트
  Widget _buildOrderStatButtons(
    BuildContext context,
    int incoming,
    int completed,
  ) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const OwnerOrderManagementScreen(initialHistoryMode: false),
              ),
            ),
            child: _buildStatButton('들어온 주문 수', incoming.toString()),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: GestureDetector(
            onTap: () async => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const OwnerOrderManagementScreen(initialHistoryMode: true),
              ),
            ),
            child: _buildStatButton('판매완료 주문 수', completed.toString()),
          ),
        ),
      ],
    ),
  );

  Widget _buildStatButton(String label, String count) => Container(
    height: 70,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE4E4E4)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: Color(0xFF6B6E82),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          count,
          style: const TextStyle(
            fontFamily: 'Sen',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E1E1E),
          ),
        ),
      ],
    ),
  );

  // 랭킹 섹션
  Widget _buildRankingSection(String title, List<String> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontFamily: 'Sen',
          fontSize: 16,
          color: Color(0xFF181C2E),
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10), // 배경
          border: Border.all(color: const Color(0xFFF0F0F0)), // 테두리
        ),
        child: Column(
          children: List.generate(
            items.length,
            (index) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        '${index + 1}위',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '|',
                        style: TextStyle(color: Color(0xFFCACCDA)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          items[index],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B6E82),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index != items.length - 1)
                  const Divider(height: 1, color: Color(0xFFEEF2F6)),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
