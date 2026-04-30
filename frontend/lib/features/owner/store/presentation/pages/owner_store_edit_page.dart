import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:frontend/services/store_service.dart';
import 'package:frontend/services/owner_image_cache.dart';

// 가게 정보 수정 화면
class OwnerStoreEditPage extends StatefulWidget {
  const OwnerStoreEditPage({super.key});

  @override
  State<OwnerStoreEditPage> createState() => _OwnerStoreEditPageState();
}

class _OwnerStoreEditPageState extends State<OwnerStoreEditPage> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _address2Controller = TextEditingController();
  final _descController = TextEditingController();

  TimeOfDay _openTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 22, minute: 0);

  final Set<DateTime> _selectedOffDates = {};
  DateTime _calendarMonth = DateTime.now();

  double? _storeLat;
  double? _storeLong;
  int? _storeId;

  File? _storeImage;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadStore();
    _loadCachedImage();
  }

  // 로컬 캐시에 저장된 매장 이미지 불러오기 (마이페이지·계정관리와 공유)
  Future<void> _loadCachedImage() async {
    final cached = await OwnerImageCache.load();
    if (cached != null && mounted) {
      setState(() => _storeImage = cached);
    }
  }

  Future<void> _loadStore() async {
    final data = await StoreService.getMyStore();
    if (data != null && mounted) {
      setState(() {
        _storeId = data['store_id'];
        _nameController.text = data['store_name'] ?? '';
        _addressController.text = data['store_address'] ?? '';
        _storeLat = data['store_lat'] != null
            ? (data['store_lat'] as num).toDouble()
            : null;
        _storeLong = data['store_long'] != null
            ? (data['store_long'] as num).toDouble()
            : null;

        if (data['open_time'] != null) {
          final parts = (data['open_time'] as String).split(':');
          _openTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
        if (data['close_time'] != null) {
          final parts = (data['close_time'] as String).split(':');
          _closeTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
        if (data['off_dates'] != null) {
          for (final d in data['off_dates'] as List) {
            final parts = d.toString().split('-');
            _selectedOffDates.add(
              DateTime(
                int.parse(parts[0]),
                int.parse(parts[1]),
                int.parse(parts[2]),
              ),
            );
          }
        }
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openMapSearch() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NaverMapSearchSheet(
        onAddressSelected: (address, lat, lng) {
          setState(() {
            _addressController.text = address;
            _storeLat = lat;
            _storeLong = lng;
          });
        },
      ),
    );
  }

  Future<void> _pickTime(bool isOpen) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpen ? _openTime : _closeTime,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null)
      setState(() => isOpen ? _openTime = picked : _closeTime = picked);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file != null) {
      setState(() => _storeImage = File(file.path));
      // 마이페이지·계정관리 프로필 사진과 동일하게 사용하기 위해 로컬 캐시에 저장
      await OwnerImageCache.save(file.path);
    }
  }

  void _toggleDate(DateTime d) {
    final date = DateTime(d.year, d.month, d.day);
    setState(() {
      if (_selectedOffDates.contains(date))
        _selectedOffDates.remove(date);
      else
        _selectedOffDates.add(date);
    });
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (_storeId == null) {
      _showSnack('가게 정보를 불러오지 못했습니다.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final offDates = _selectedOffDates
          .map(
            (d) =>
                '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
          )
          .toList();

      // 백엔드 store_long: DecimalField(max_digits=9, decimal_places=6) 제약
      // → 소수점 6자리로 반올림해서 전송
      double? round6(double? v) =>
          v == null ? null : double.parse(v.toStringAsFixed(6));

      final res = await StoreService.updateStore(
        storeId: _storeId!,
        storeName: _nameController.text.trim(),
        storeAddress:
            '${_addressController.text.trim()} ${_address2Controller.text.trim()}'
                .trim(),
        storeLat: round6(_storeLat),
        storeLong: round6(_storeLong),
        storeDesc: _descController.text.trim(),
        openTime: _fmt(_openTime),
        closeTime: _fmt(_closeTime),
        offDates: offDates,
      );

      if (res['success'] == true) {
        _showSnack('가게 정보가 수정되었습니다.');
        if (mounted) Navigator.pop(context);
      } else {
        _showSnack(res['message'] ?? '저장에 실패했습니다.');
      }
    } catch (e) {
      _showSnack('오류: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── 헤더 ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '가게 정보',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),

            // 본문 영역 — 로딩 여부와 무관하게 항상 텍스트 필드 렌더링
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('가게 이름'),
                    _input(_nameController),
                    const SizedBox(height: 20),
                    _label('가게 주소'),
                    Row(
                      children: [
                        Expanded(
                          child: _input(_addressController, readOnly: true),
                        ),
                        const SizedBox(width: 8),
                        _searchBtn(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _input(_address2Controller, hint: '상세주소 (선택)'),
                    const SizedBox(height: 20),
                    _label('가게 소개'), _input(_descController, maxLines: 3),
                    const SizedBox(height: 20),

                    // 영업 시간
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('영업 시작'),
                              _timeBox(_openTime, () => _pickTime(true)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('영업 종료'),
                              _timeBox(_closeTime, () => _pickTime(false)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: GestureDetector(
                            onTap: () => _pickTime(true),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE0E0E0),
                                ),
                              ),
                              child: const Icon(
                                Icons.access_time_rounded,
                                color: Color(0xFF4FA75A),
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 가게 사진
                    _label('가게 사진'),
                    const SizedBox(height: 8),
                    _imageBox(),
                    const SizedBox(height: 24),

                    // 휴무일 달력
                    _label('휴무일 선택'),
                    const SizedBox(height: 8),
                    _buildCalendar(),
                    const SizedBox(height: 32),

                    // 데이터 로딩 중 표시
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: CircularProgressIndicator(
                            color: Color(0xFF4FA75A),
                          ),
                        ),
                      ),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: (_isSaving || _isLoading) ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4FA75A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                '저장하기',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF333333),
      ),
    ),
  );

  Widget _input(
    TextEditingController ctrl, {
    String hint = '000000',
    int maxLines = 1,
    bool readOnly = false,
  }) => TextField(
    controller: ctrl,
    readOnly: readOnly,
    maxLines: maxLines,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF0F4F0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );

  Widget _searchBtn() => GestureDetector(
    onTap: _openMapSearch,
    child: Container(
      width: 44,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.search_rounded, color: Color(0xFF4FA75A)),
    ),
  );

  Widget _timeBox(TimeOfDay t, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F0),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        _fmt(t),
        style: const TextStyle(fontSize: 15, color: Color(0xFF444444)),
      ),
    ),
  );

  Widget _imageBox() => GestureDetector(
    onTap: _pickImage,
    child: Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: _storeImage != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(_storeImage!, fit: BoxFit.cover),
            )
          : const Icon(
              Icons.add_circle_outline,
              size: 36,
              color: Color(0xFFAAAAAA),
            ),
    ),
  );

  Widget _buildCalendar() {
    final now = DateTime.now();
    final year = _calendarMonth.year;
    final month = _calendarMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    int startWeekday = firstDay.weekday - 1;
    const days = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () =>
                    setState(() => _calendarMonth = DateTime(year, month - 1)),
                child: const Icon(
                  Icons.chevron_left,
                  size: 22,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$year년 $month월',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () =>
                    setState(() => _calendarMonth = DateTime(year, month + 1)),
                child: const Icon(
                  Icons.chevron_right,
                  size: 22,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: days
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (_, idx) {
              if (idx < startWeekday) return const SizedBox();
              final day = idx - startWeekday + 1;
              final date = DateTime(year, month, day);
              final isSelected = _selectedOffDates.contains(date);
              final isPast = date.isBefore(
                DateTime(now.year, now.month, now.day),
              );
              return GestureDetector(
                onTap: isPast ? null : () => _toggleDate(date),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? const Color(0xFF4FA75A)
                        : Colors.transparent,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : isPast
                            ? const Color(0xFFCCCCCC)
                            : const Color(0xFF333333),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

//Naver Map 주소 검색 시트 (공유)
// TODO: 네이버 지도 기반 API 선택 구현
class _NaverMapSearchSheet extends StatefulWidget {
  final Function(String address, double lat, double lng) onAddressSelected;
  const _NaverMapSearchSheet({required this.onAddressSelected});
  @override
  State<_NaverMapSearchSheet> createState() => _NaverMapSearchSheetState();
}

class _NaverMapSearchSheetState extends State<_NaverMapSearchSheet> {
  final _ctrl = TextEditingController();
  NLatLng _center = const NLatLng(37.5665, 126.9780);
  String _selectedAddress = '';
  NaverMapController? _mapCtrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: '주소를 검색하세요',
                      filled: true,
                      fillColor: const Color(0xFFF0F4F0),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () =>
                      setState(() => _selectedAddress = _ctrl.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FA75A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('검색'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: NaverMap(
              options: NaverMapViewOptions(
                initialCameraPosition: NCameraPosition(
                  target: _center,
                  zoom: 15,
                ),
              ),
              onMapReady: (ctrl) => _mapCtrl = ctrl,
              onMapTapped: (point, coord) => setState(() {
                _center = coord;
                _selectedAddress =
                    '위도: ${coord.latitude.toStringAsFixed(5)}, 경도: ${coord.longitude.toStringAsFixed(5)}';
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_selectedAddress.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _selectedAddress,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF555555),
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_selectedAddress.isNotEmpty) {
                        widget.onAddressSelected(
                          _selectedAddress,
                          _center.latitude,
                          _center.longitude,
                        );
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4FA75A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      '이 위치로 설정',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
