import 'package:flutter/material.dart';

/// '리스트'와 '지도' 두 탭을 전환하는 토글 버튼 위젯.
/// 선택된 탭은 초록 배경 + 흰 텍스트, 미선택 탭은 흰 배경 + 회색 텍스트.

class ViewToggle extends StatelessWidget {
  /// true = 리스트 모드, false = 지도 모드
  final bool isListView;
  final ValueChanged<bool> onChanged;

  const ViewToggle({
    super.key,
    required this.isListView,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFF4CAF50), width: 1.2),
      ),
      child: Row(
        children: [
          /// 리스트 탭
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(true),
              child: Container(
                decoration: BoxDecoration(
                  color: isListView
                      ? const Color(0xFF4CAF50)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                alignment: Alignment.center,
                child: Text(
                  '리스트',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isListView ? Colors.white : const Color(0xFF9E9E9E),
                  ),
                ),
              ),
            ),
          ),

          /// 지도 탭
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(false),
              child: Container(
                decoration: BoxDecoration(
                  color: !isListView
                      ? const Color(0xFF4CAF50)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                alignment: Alignment.center,
                child: Text(
                  '지도',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: !isListView ? Colors.white : const Color(0xFF9E9E9E),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
