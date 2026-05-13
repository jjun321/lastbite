import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:frontend/services/store_service.dart';
import 'package:frontend/services/owner_image_cache.dart';
import 'package:frontend/services/naver_geocoding_service.dart';

/// 1. 첫 로그인 시 가게 정보 등록 화면
class OwnerStoreRegisterPage extends StatefulWidget {
  const OwnerStoreRegisterPage({super.key});

  @override
  State<OwnerStoreRegisterPage> createState() => _OwnerStoreRegisterPageState();
}

class _OwnerStoreRegisterPageState extends State<OwnerStoreRegisterPage> {
  final _nameController    = TextEditingController();
  final _addressController = TextEditingController();
  final _address2Controller= TextEditingController();
  final _descController    = TextEditingController();

  TimeOfDay _openTime  = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 22, minute: 0);

  // 휴무일: 선택된 날짜 목록 (월간 복수 선택)
  final Set<DateTime> _selectedOffDates = {};
  DateTime _calendarMonth = DateTime.now();

  double? _storeLat;
  double? _storeLong;

  File? _storeImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _address2Controller.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ── 주소 검색 (NaverMap 팝업) ──
  Future<void> _openMapSearch() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NaverMapSearchSheet(
        onAddressSelected: (address, lat, lng) {
          setState(() {
            _addressController.text = address;
            _storeLat  = lat;
            _storeLong = lng;
          });
        },
      ),
    );
  }

  // ── 시간 선택 ──
  Future<void> _pickTime(bool isOpen) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpen ? _openTime : _closeTime,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isOpen) _openTime  = picked;
        else        _closeTime = picked;
      });
    }
  }

  // ── 이미지 선택 ──
  // 사진은 _save() 시점에 multipart 로 한 번에 전송되므로 여기서는 상태만 갱신.
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;

    setState(() => _storeImage = File(file.path));
    // 마이페이지·계정관리 프로필 사진과 동일하게 사용하기 위해 로컬 캐시에 저장
    await OwnerImageCache.save(file.path);
  }

  // ── 달력 날짜 토글 ──
  void _toggleDate(DateTime d) {
    final date = DateTime(d.year, d.month, d.day);
    setState(() {
      if (_selectedOffDates.contains(date)) _selectedOffDates.remove(date);
      else _selectedOffDates.add(date);
    });
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnack('가게 이름을 입력해주세요.');
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      _showSnack('가게 주소를 입력해주세요.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final offDates = _selectedOffDates
          .map((d) => '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}')
          .toList();

      final res = await StoreService.registerStore(
        storeName:    _nameController.text.trim(),
        storeAddress: '${_addressController.text.trim()} ${_address2Controller.text.trim()}'.trim(),
        storeLat:     _storeLat,
        storeLong:    _storeLong,
        storeDesc:    _descController.text.trim(),
        openTime:     _fmt(_openTime),
        closeTime:    _fmt(_closeTime),
        offDates:     offDates,
        imageFile:    _storeImage,
      );

      if (res['success'] == true) {
        if (mounted) context.go('/owner-dashboard');
      } else {
        _showSnack(res['message'] ?? '저장에 실패했습니다.');
      }
    } catch (e) {
      _showSnack('오류가 발생했습니다: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── 헤더 ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: const Center(
                child: Text('가게 정보',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF222222))),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('가게 이름'),
                    _input(_nameController, hint: '000000'),
                    const SizedBox(height: 20),

                    _label('가게 주소'),
                    Row(children: [
                      Expanded(child: _input(_addressController, hint: '000000', readOnly: true)),
                      const SizedBox(width: 8),
                      _searchBtn(),
                    ]),
                    const SizedBox(height: 8),
                    _input(_address2Controller, hint: '상세주소 (선택)'),
                    const SizedBox(height: 20),

                    _label('가게 소개'),
                    _input(_descController, hint: '000000', maxLines: 3),
                    const SizedBox(height: 20),

                    // ── 영업 시간 ──
                    Row(children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('영업 시작'),
                          _timeBox(_openTime, () => _pickTime(true)),
                        ],
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('영업 종료'),
                          _timeBox(_closeTime, () => _pickTime(false)),
                        ],
                      )),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: GestureDetector(
                          onTap: () => _pickTime(true),
                          child: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE0E0E0)),
                            ),
                            child: const Icon(Icons.access_time_rounded, color: Color(0xFF4FA75A), size: 22),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // ── 가게 사진 ──
                    _label('가게 사진'),
                    const SizedBox(height: 8),
                    _imageBox(),
                    const SizedBox(height: 24),

                    // ── 휴무일 달력 ──
                    _label('휴무일 선택'),
                    const SizedBox(height: 8),
                    _buildCalendar(),
                    const SizedBox(height: 32),

                    // ── 저장 버튼 ──
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4FA75A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('저장하기', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
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

  // ── UI 헬퍼 위젯들 ──

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
  );

  Widget _input(TextEditingController ctrl, {String hint = '', int maxLines = 1, bool readOnly = false}) => TextField(
    controller: ctrl,
    readOnly: readOnly,
    maxLines: maxLines,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF0F4F0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    ),
  );

  Widget _searchBtn() => GestureDetector(
    onTap: _openMapSearch,
    child: Container(
      width: 44, height: 50,
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
      child: Text(_fmt(t), style: const TextStyle(fontSize: 15, color: Color(0xFF444444))),
    ),
  );

  Widget _imageBox() => GestureDetector(
    onTap: _pickImage,
    child: Container(
      width: 120, height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: _storeImage != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(_storeImage!, fit: BoxFit.cover))
          : const Icon(Icons.add_circle_outline, size: 36, color: Color(0xFFAAAAAA)),
    ),
  );

  // ── 달력 (한달 복수 날짜 선택) ──
  Widget _buildCalendar() {
    final now = DateTime.now();
    final year  = _calendarMonth.year;
    final month = _calendarMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // 시작 요일 (월=0 기준)
    int startWeekday = firstDay.weekday - 1; // 1(Mon)→0

    const days = ['MO','TU','WE','TH','FR','SA','SU'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // 월 네비게이션
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          GestureDetector(
            onTap: () => setState(() => _calendarMonth = DateTime(year, month-1)),
            child: const Icon(Icons.chevron_left, size: 22, color: Color(0xFF666666)),
          ),
          const SizedBox(width: 8),
          Text('$year년 ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Text('${month}월', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _calendarMonth = DateTime(year, month+1)),
            child: const Icon(Icons.chevron_right, size: 22, color: Color(0xFF666666)),
          ),
        ]),
        const SizedBox(height: 12),
        // 요일 헤더
        Row(children: days.map((d) => Expanded(
          child: Center(child: Text(d, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF888888))))
        )).toList()),
        const SizedBox(height: 8),
        // 날짜 그리드
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, childAspectRatio: 1,
          ),
          itemCount: startWeekday + daysInMonth,
          itemBuilder: (_, idx) {
            if (idx < startWeekday) return const SizedBox();
            final day = idx - startWeekday + 1;
            final date = DateTime(year, month, day);
            final isSelected = _selectedOffDates.contains(date);
            final isPast = date.isBefore(DateTime(now.year, now.month, now.day));

            return GestureDetector(
              onTap: isPast ? null : () => _toggleDate(date),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? const Color(0xFF4FA75A) : Colors.transparent,
                ),
                child: Center(child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : isPast ? const Color(0xFFCCCCCC) : const Color(0xFF333333),
                  ),
                )),
              ),
            );
          },
        ),
      ]),
    );
  }
}

// ── NaverMap 주소 검색 시트 ──
class _NaverMapSearchSheet extends StatefulWidget {
  final Function(String address, double lat, double lng) onAddressSelected;
  const _NaverMapSearchSheet({required this.onAddressSelected});

  @override
  State<_NaverMapSearchSheet> createState() => _NaverMapSearchSheetState();
}

class _NaverMapSearchSheetState extends State<_NaverMapSearchSheet> {
  final _searchCtrl = TextEditingController();
  NaverMapController? _mapController;
  NLatLng _center = const NLatLng(37.5665, 126.9780); // 기본: 서울시청
  String _selectedAddress = '';
  bool _searching = false;

  Future<void> _onSearch() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() => _searching = true);
    try {
      final result = await NaverGeocodingService.geocode(q);
      if (!mounted) return;
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('주소를 찾을 수 없습니다.')),
        );
        return;
      }
      final lat = result['lat'] as double;
      final lng = result['lng'] as double;
      final address = result['address'] as String;
      final newCenter = NLatLng(lat, lng);
      setState(() {
        _center = newCenter;
        _selectedAddress = address;
      });
      await _mapController?.updateCamera(
        NCameraUpdate.fromCameraPosition(
          NCameraPosition(target: newCenter, zoom: 16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('주소 검색 오류: $e')),
      );
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: [
        // 드래그 핸들
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),

        // 검색창
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onSubmitted: (_) => _onSearch(),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: '주소를 검색하세요',
                  filled: true,
                  fillColor: const Color(0xFFF0F4F0),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _searching ? null : _onSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4FA75A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: _searching
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('검색'),
            ),
          ]),
        ),

        const SizedBox(height: 12),

        // 지도
        Expanded(
          child: NaverMap(
            options: NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: _center,
                zoom: 15,
              ),
            ),
            onMapReady: (ctrl) => _mapController = ctrl,
            onMapTapped: (point, coord) {
              setState(() {
                _center = coord;
                _selectedAddress = '위도: ${coord.latitude.toStringAsFixed(5)}, 경도: ${coord.longitude.toStringAsFixed(5)}';
              });
            },
          ),
        ),

        // 선택 확인 버튼
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            if (_selectedAddress.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_selectedAddress, style: const TextStyle(fontSize: 13, color: Color(0xFF555555))),
              ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedAddress.isNotEmpty) {
                    widget.onAddressSelected(_selectedAddress, _center.latitude, _center.longitude);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FA75A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('이 위치로 설정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
