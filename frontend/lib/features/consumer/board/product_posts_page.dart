import 'package:flutter/material.dart';
import 'data/post_model.dart';
import 'data/post_service.dart';

/// 특정 상품에 대한 모든 제보 목록을 보여주는 전체 화면 페이지
class ProductPostsPage extends StatefulWidget {
  final int productId;
  final String productName;

  const ProductPostsPage({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<ProductPostsPage> createState() => _ProductPostsPageState();
}

class _ProductPostsPageState extends State<ProductPostsPage> {
  List<PostModel> _posts = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _loading = true);
    final posts = await PostService.fetchPosts(
      productId: widget.productId,
      sort: 'latest',
    );
    if (mounted) {
      setState(() {
        _posts = posts;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── AppBar 스타일 상단 영역 ──
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 14.0,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 20,
                        color: Color(0xFF181C2E),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.productName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF181C2E),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE4E4E4)),
            // ── 본문 영역 ──
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _posts.isEmpty
                      ? const Center(
                          child: Text(
                            '해당 상품에 대한 제보가 없습니다.',
                            style: TextStyle(
                              color: Color(0xFF9C9BA6),
                              fontSize: 14,
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadPosts,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 29,
                              vertical: 16,
                            ),
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
                  // 날짜
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      color: Color(0xFF9C9BA6),
                      fontSize: 12,
                      fontFamily: 'Sen',
                    ),
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
