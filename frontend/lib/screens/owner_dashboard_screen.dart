import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import 'owner_order_management_screen.dart';

// 점주 대시보드 페이지

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {

  @override
  Widget build(BuildContext context) {
    // 1. 들어온 주문 수: 수락X, 취소X 인 상태
    final int incomingCount = orderList.where((o) => !o.isAccepted && !o.isCancelled).length;

    // 2. 판매완료 주문 수: 수락O 또는 취소O 인 상태 (주문 내역으로 넘어간 모든 주문)
    final int completedCount = orderList.where((o) => o.isAccepted || o.isCancelled).length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 상단 매출 카드 (가게 이름 및 매출액 데이터 연결)
              _buildSalesCard(myStoreStats.storeName, myStoreStats.totalSales),

              const SizedBox(height: 24),

              // 2. 주문 상태 버튼 세트 (실시간 계산된 count 전달)
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

              // 4. 베스트 & 워스트 셀러 섹션 (mock_data 리스트 연결)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildRankingSection('인기 상품', myStoreStats.bestSellers)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildRankingSection('비인기 상품', myStoreStats.worstSellers)),
                  ],
                ),
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. 매출 카드 위젯 ---
  Widget _buildSalesCard(String storeName, String totalSales) {
    return Container(
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
            style: const TextStyle(fontFamily: 'Sen', fontSize: 20, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            '$totalSales원',
            style: const TextStyle(fontFamily: 'Sen', fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // --- 2. 주문 상태 버튼 세트 ---
  Widget _buildOrderStatButtons(BuildContext context, int incoming, int completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OwnerOrderManagementScreen(initialHistoryMode: false),
                  ),
                );
                setState(() {});
              },
              child: _buildStatButton('들어온 주문 수', incoming.toString()),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OwnerOrderManagementScreen(initialHistoryMode: true),
                  ),
                );
                setState(() {});
              },
              child: _buildStatButton('판매완료 주문 수', completed.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatButton(String label, String count) {
    return Container(
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
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF6B6E82)),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: const TextStyle(fontFamily: 'Sen', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E)),
          ),
        ],
      ),
    );
  }

  // --- 4. 랭킹 섹션 ---
  Widget _buildRankingSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontFamily: 'Sen', fontSize: 16, color: Color(0xFF181C2E))),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10)),
          child: Column(
            children: List.generate(items.length, (index) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Text('${index + 1}위', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 8),
                        const Text('|', style: TextStyle(color: Color(0xFFCACCDA))),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(
                                items[index],
                                style: const TextStyle(fontSize: 12, color: Color(0xFF6B6E82)),
                                overflow: TextOverflow.ellipsis
                            )
                        ),
                      ],
                    ),
                  ),
                  if (index != items.length - 1) const Divider(height: 1, color: Color(0xFFEEF2F6)),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}