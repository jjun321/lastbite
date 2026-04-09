import 'package:flutter/material.dart';
import 'report_form_page.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';

class ReportBoardPage extends StatefulWidget {
  const ReportBoardPage({super.key});

  @override
  State<ReportBoardPage> createState() => _ReportBoardPageState();
}

class _ReportBoardPageState extends State<ReportBoardPage> {
  void _handleRefresh() {
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('내 주변 정보를 새로고침했습니다.')),
    );
  }

  void _openReportSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ReportFormPage(),
    );
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
                    color: Color(0xFF181C2E)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 29.0, vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('내 주변 찾기',
                          style: TextStyle(fontSize: 16, fontFamily: 'Sen')),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _handleRefresh,
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.refresh, size: 22, color: Color(0xFF1E1E1E)),
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: _openReportSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E3E5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('제보하기',
                          style: TextStyle(color: Color(0xFF32343E), fontSize: 14, fontFamily: 'Sen')),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 29),
                itemCount: reportList.length,
                itemBuilder: (context, index) {
                  final report = reportList[index];
                  return _buildListItem(report);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(CommunityReport report) {
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
                  Text(report.date,
                      style: const TextStyle(color: Color(0xFF9C9BA6), fontSize: 12, fontFamily: 'Sen')),
                  const SizedBox(height: 10),
                  Text(report.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF32343E), fontFamily: 'Sen')),
                  const SizedBox(height: 5),
                  Text(report.storeName,
                      style: const TextStyle(color: Color(0xFF747783), fontSize: 12, fontFamily: 'Sen')),
                  const SizedBox(height: 8),
                  Text(
                    report.content,
                    maxLines: 3, // 최대 3줄까지만 허용
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF747783), fontSize: 12, fontFamily: 'Sen', height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  // 이미지 영역
                  Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                          color: const Color(0xFFC4C4C4),
                          borderRadius: BorderRadius.circular(10))),
                ],
              ),
            ),
          ),
          // 유저 프로필 아이콘 (변함 없음)
          Positioned(
            left: 0,
            top: 2,
            child: Container(
                width: 43,
                height: 43,
                decoration: const BoxDecoration(
                    color: Color(0xFF98A8B8), shape: BoxShape.circle)),
          ),
        ],
      ),
    );
  }
}