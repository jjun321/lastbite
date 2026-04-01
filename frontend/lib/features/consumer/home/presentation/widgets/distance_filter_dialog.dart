import 'package:flutter/material.dart';

/// 주변 반경 조절 다이얼로그
/// 0m, 500m, 1km, 3km 중 하나를 선택할 수 있는 슬라이더 다이얼로그.
/// 선택된 거리 값(미터)을 반환한다.

class DistanceFilterDialog extends StatefulWidget {
  /// 현재 선택된 거리 (미터 단위)
  final int currentDistance;

  const DistanceFilterDialog({
    super.key,
    required this.currentDistance,
  });

  /// 다이얼로그를 표시하고 선택된 거리(미터)를 반환
  static Future<int?> show(BuildContext context, {required int currentDistance}) {
    return showDialog<int>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => DistanceFilterDialog(
        currentDistance: currentDistance,
      ),
    );
  }

  @override
  State<DistanceFilterDialog> createState() => _DistanceFilterDialogState();
}

class _DistanceFilterDialogState extends State<DistanceFilterDialog> {
  /// 슬라이더 위치 (0~3: 0m, 500m, 1km, 3km)
  late double _sliderValue;

  /// 거리 옵션 목록 (미터 단위)
  static const List<int> _distanceOptions = [0, 500, 1000, 3000];

  /// 표시 텍스트 매핑
  static const Map<int, String> _distanceLabels = {
    0: '0m',
    500: '500m',
    1000: '1km',
    3000: '3km',
  };

  @override
  void initState() {
    super.initState();
    // 현재 거리에 해당하는 슬라이더 인덱스를 찾는다
    final index = _distanceOptions.indexOf(widget.currentDistance);
    _sliderValue = (index >= 0) ? index.toDouble() : 0;
  }

  /// 현재 슬라이더 위치에 해당하는 거리 (미터)
  int get _selectedDistance => _distanceOptions[_sliderValue.round()];

  /// 현재 거리의 표시 텍스트
  String get _selectedLabel => _distanceLabels[_selectedDistance] ?? '0m';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF5F3EE),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// ─── 닫기 버튼 ───
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(
                  Icons.close,
                  size: 22,
                  color: Color(0xFF999999),
                ),
              ),
            ),

            /// ─── 제목 ───
            const Text(
              '주변 반경 조절',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF555555),
              ),
            ),

            const SizedBox(height: 8),

            /// ─── 현재 선택 거리 ───
            Text(
              _selectedLabel,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Color(0xFF222222),
              ),
            ),

            const SizedBox(height: 20),

            /// ─── 슬라이더 ───
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF4CAF50),
                inactiveTrackColor: const Color(0xFFD0D0D0),
                thumbColor: const Color(0xFF4CAF50),
                overlayColor: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 10,
                ),
              ),
              child: Slider(
                value: _sliderValue,
                min: 0,
                max: (_distanceOptions.length - 1).toDouble(),
                divisions: _distanceOptions.length - 1,
                onChanged: (value) {
                  setState(() {
                    _sliderValue = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 20),

            /// ─── 확인 버튼 ───
            SizedBox(
              width: 140,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(_selectedDistance);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FA75A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
