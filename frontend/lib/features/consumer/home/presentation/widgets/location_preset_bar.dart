import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// '위치 프리셋 ▼' 드롭다운과 우측 액션 버튼을 표시한다.
/// - 리스트 모드: 필터 아이콘 (거리 필터 선택 시 뱃지 표시)
/// - 지도 모드: 'AI 추천가게' 버튼

class LocationPresetBar extends StatelessWidget {
  final bool isListView;
  final VoidCallback? onPresetTap;
  final VoidCallback? onFilterTap;
  final VoidCallback? onAiRecommendTap;
  final bool isAiActive;
  final bool isLoadingLocation;
  final Position? currentPosition;
  final int filterDistance;

  const LocationPresetBar({
    super.key,
    required this.isListView,
    this.onPresetTap,
    this.onFilterTap,
    this.onAiRecommendTap,
    this.isAiActive = false,
    this.isLoadingLocation = false,
    this.currentPosition,
    this.filterDistance = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// 위치 프리셋 드롭다운
          GestureDetector(
            onTap: onPresetTap,
            child: Row(
              children: [
                if (isLoadingLocation)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF4CAF50),
                    ),
                  )
                else
                  const Icon(
                    Icons.my_location,
                    size: 18,
                    color: Color(0xFF4CAF50),
                  ),
                const SizedBox(width: 6),
                Text(
                  currentPosition != null ? '현재 위치' : '위치 프리셋',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_drop_down,
                  size: 22,
                  color: Color(0xFF333333),
                ),
              ],
            ),
          ),

          /// 우측 액션 버튼
          if (isListView)
            /// 리스트 모드 → 필터 아이콘
            GestureDetector(
              onTap: onFilterTap,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.tune,
                    size: 24,
                    color: Color(0xFF333333),
                  ),
                  // 필터가 활성화되어 있으면 뱃지 표시
                  if (filterDistance > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            )
          else
            /// 지도 모드 → AI 추천가게 버튼
            GestureDetector(
              onTap: onAiRecommendTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// AI 활성 상태 표시 점
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF5350),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'AI 추천가게',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
