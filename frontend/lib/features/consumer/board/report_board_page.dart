import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'data/post_model.dart';
import 'data/post_service.dart';
import 'report_form_page.dart';

// 제보게시판 페이지 — 서버 데이터 연동
class ReportBoardPage extends StatefulWidget {
  const ReportBoardPage({super.key});

  @override
  State<ReportBoardPage> createState() => _ReportBoardPageState();
}

class _ReportBoardPageState extends State<ReportBoardPage> {
  List<PostModel> _posts = [];
  bool _loading = false;
  double? _lat;
  double? _long;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _loading = true);
    try {
      // 위치 권한 확인 후 현재 위치 가져오기
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        _lat = pos.latitude;
        _long = pos.longitude;
      }
    } catch (e) {
      debugPrint('위치 오류: $e');
    }

    final posts = await PostService.fetchPosts(
      lat: _lat,
      long: _long,
      radiusKm: 3,
    );

    if (mounted) {
      setState(() {
        _posts = posts;
        _loading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await _loadPosts();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('내 주변 정보를 새로고침했습니다.')));
    }
  }

  void _openReportSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReportFormPage(userLat: _lat, userLong: _long),
    );
    // 제보 등록 후 목록 갱신
    _loadPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 28),
            const Center(
              child: Text(
                '커뮤니티',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF181C2E),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 29.0,
                vertical: 24.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        '내 주변 찾기',
                        style: TextStyle(fontSize: 16, fontFamily: 'Sen'),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _handleRefresh,
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.refresh,
                            size: 22,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: _openReportSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E3E5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '제보하기',
                        style: TextStyle(
                          color: Color(0xFF32343E),
                          fontSize: 14,
                          fontFamily: 'Sen',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _posts.isEmpty
                  ? const Center(
                      child: Text(
                        '주변에 제보된 내용이 없습니다.',
                        style: TextStyle(
                          color: Color(0xFF9C9BA6),
                          fontSize: 14,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _handleRefresh,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 29),
                        itemCount: _posts.length,
                        itemBuilder: (context, index) {
                          return _buildListItem(_posts[index]);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(PostModel post) {
    // 날짜 포맷: "2026-01-01T12:00:00Z" → "2026.01.01."
    String formattedDate = '';
    try {
      final dt = DateTime.parse(post.regDt);
      formattedDate =
          '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}.';
    } catch (_) {
      formattedDate = post.regDt;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      constraints: const BoxConstraints(minHeight: 180),
      child: Stack(
        children: [
          // 배경 카드 영역
          Padding(
            padding: const EdgeInsets.only(left: 53),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8FA),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 날짜 + 거리
                  Row(
                    children: [
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          color: Color(0xFF9C9BA6),
                          fontSize: 12,
                          fontFamily: 'Sen',
                        ),
                      ),
                      if (post.distanceKm != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${post.distanceKm!.toStringAsFixed(1)}km',
                          style: const TextStyle(
                            color: Color(0xFF4FA55B),
                            fontSize: 12,
                            fontFamily: 'Sen',
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  // 제보 이름 (title)
                  Text(
                    post.postName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF32343E),
                      fontFamily: 'Sen',
                    ),
                  ),
                  const SizedBox(height: 5),
                  // 매장명
                  if (post.storeName != null)
                    Text(
                      post.storeName!,
                      style: const TextStyle(
                        color: Color(0xFF747783),
                        fontSize: 12,
                        fontFamily: 'Sen',
                      ),
                    ),
                  const SizedBox(height: 8),
                  // 내용
                  if (post.content != null && post.content!.isNotEmpty)
                    Text(
                      post.content!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF747783),
                        fontSize: 12,
                        fontFamily: 'Sen',
                        height: 1.4,
                      ),
                    ),
                  // 이미지 영역
                  if (post.imgUrl != null) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        post.imgUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFC4C4C4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC4C4C4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // 유저 아바타 (작성자 이니셜)
          Positioned(
            left: 0,
            top: 2,
            child: Container(
              width: 43,
              height: 43,
              decoration: const BoxDecoration(
                color: Color(0xFF98A8B8),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  post.userName.isNotEmpty
                      ? post.userName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
