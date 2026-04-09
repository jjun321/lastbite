import 'package:flutter/material.dart';

class ReportFormPage extends StatelessWidget {
  const ReportFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 1. 상단 핸들 (Drag Indicator)
          const SizedBox(height: 12),
          Container(
            width: 134,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFE4E4E4),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '제보하기',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E1E1E)),
          ),
          const SizedBox(height: 16),

          // 2. 스크롤 본문 (키보드 에러 해결)
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 8,
                  bottom: bottomInset + 20
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 리뷰 작성 필드
                  TextField(
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: '리뷰를 작성해주세요',
                      hintStyle: const TextStyle(color: Color(0xFF8E8E8E), fontSize: 16),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE4E4E4)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF4FA55B)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 매장명 입력 필드 (수정된 부분)
                  const Text('매장명', style: TextStyle(color: Color(0xFF6B6E82), fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    maxLines: 1, // 매장명은 한 줄로 제한
                    decoration: InputDecoration(
                      hintText: '매장 이름을 적어주세요',
                      hintStyle: const TextStyle(color: Color(0xFF8E8E8E), fontSize: 15),
                      filled: true,
                      fillColor: const Color(0xFFF0F5FA), // 피그마 디자인 배경색 유지
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none, // 기본 테두리 없앰
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF4FA55B), width: 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 사진 첨부
                  const Center(
                    child: Text('사진 첨부', style: TextStyle(color: Color(0xFF32343E), fontSize: 14)),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 130,
                      height: 142,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F5FA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_circle, size: 30, color: Color(0xFF1E1E1E)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. 하단 고정 등록 버튼
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FA55B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text(
                  '제보 등록',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}