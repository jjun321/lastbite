import 'package:flutter/material.dart';

/// 커스텀 PNG 아이콘을 사용하는 하단 네비게이션 바.
/// 선택된 탭: 초록색 아이콘 (원본 색상),
/// 미선택 탭: 흰색(투명도 적용) 아이콘
///
/// ColorFiltered를 사용하여 PNG 아이콘의 색상을 동적으로 변경한다.

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _buildNavItem(
                index: 0,
                iconPath: 'assets/images/icon_home.png',
                label: '홈',
              ),
              _buildNavItem(
                index: 1,
                iconPath: 'assets/images/icon_board.png',
                label: '제보게시판',
              ),
              _buildNavItem(
                index: 2,
                iconPath: 'assets/images/icon_order.png',
                label: '주문내역',
              ),
              _buildNavItem(
                index: 3,
                iconPath: 'assets/images/icon_mypage.png',
                label: '마이페이지',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String iconPath,
    required String label,
  }) {
    final bool isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// 아이콘: 선택 시 원본 색상, 미선택 시 밝은 회색
            SizedBox(
              width: 24,
              height: 24,
              child: isSelected
                  ? Image.asset(iconPath, width: 24, height: 24)
                  : ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Color(0xFFBDBDBD),
                        BlendMode.srcIn,
                      ),
                      child: Image.asset(iconPath, width: 24, height: 24),
                    ),
            ),
            const SizedBox(height: 4),

            /// 라벨
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFBDBDBD),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
