import 'package:flutter/material.dart';
import 'package:frontend/features/store/data/models/product_model.dart';
import 'package:frontend/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:frontend/features/store/data/repositories/product_repository_impl.dart';
import 'package:frontend/features/order/data/repositories/order_repository_impl.dart';
import 'package:frontend/features/order/data/models/order_model.dart';
import 'package:frontend/features/consumer/order/presentation/widgets/cart_reset_dialog.dart';
import 'package:frontend/features/consumer/board/data/post_model.dart';
import 'package:frontend/features/consumer/board/data/post_service.dart';
import 'package:frontend/features/consumer/board/product_posts_page.dart';
import 'cart_page.dart';

class OrderScreen extends StatefulWidget {
  final int storeId;
  final String storeName;

  const OrderScreen({
    Key? key,
    required this.storeId,
    required this.storeName,
  }) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _productRepo = ProductRepositoryImpl();
  final _cartRepo = CartRepositoryImpl();
  final _orderRepo = OrderRepositoryImpl();

  List<ProductModel> _products = [];
  bool _isLoading = true;
  String? _error;

  // 현재 매장에서 소비자가 주문한 상품별 누적 수량 (productId → count)
  Map<int, int> _orderCountByProductId = {};

  // 정렬 상태
  String _currentSort = 'default';
  static const _sortOptions = <String, String>{
    'default': '등록순',
    'price_asc': '최저가순',
    'hotdeal': '핫딜순',
    'latest': '최신순',
    'ordered': '주문이력순',
  };

  // 제보 카드 인라인 토글 상태
  // key: productId, value: 최신 제보 1건 (null이면 로딩 중 또는 없음)
  final Set<int> _expandedProductIds = {};
  final Map<int, PostModel?> _latestPostCache = {};
  final Set<int> _loadingPostIds = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // 상품 목록과 주문 내역을 병렬로 가져온다.
      // 주문 내역 조회는 비로그인/실패 시 빈 리스트로 대체해 상품 노출은 막지 않는다.
      final productsFuture = _productRepo.getStoreProducts(
        widget.storeId,
        sort: _currentSort == 'default' ? null : _currentSort,
      );
      final ordersFuture = _orderRepo.getOrders().catchError(
        (_) => <OrderModel>[],
      );

      final products = await productsFuture;
      final orders = await ordersFuture;

      // 현재 매장의 주문만 대상으로 productId 기준 누적 수량 계산
      final Map<int, int> countMap = {};
      for (final order in orders) {
        if (order.storeId != widget.storeId) continue;
        for (final item in order.items) {
          countMap[item.productId] =
              (countMap[item.productId] ?? 0) + item.quantity;
        }
      }

      // 주문 횟수 desc 로 안정 정렬 — 같은 카운트면 백엔드 정렬 순서 유지
      final sorted = List<ProductModel>.from(products);
      sorted.sort((a, b) {
        final ca = countMap[a.productId] ?? 0;
        final cb = countMap[b.productId] ?? 0;
        return cb.compareTo(ca);
      });

      if (mounted) {
        setState(() {
          _orderCountByProductId = countMap;
          _products = sorted;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // 특정 상품의 최신 제보 1건 로드
  Future<void> _loadLatestPost(int productId) async {
    if (_latestPostCache.containsKey(productId)) return; // 이미 로드됨

    setState(() => _loadingPostIds.add(productId));

    try {
      final posts = await PostService.fetchPosts(
        productId: productId,
        sort: 'latest',
        size: 1,
      );
      if (mounted) {
        setState(() {
          _latestPostCache[productId] = posts.isNotEmpty ? posts.first : null;
          _loadingPostIds.remove(productId);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _latestPostCache[productId] = null;
          _loadingPostIds.remove(productId);
        });
      }
    }
  }

  // 제보 토글
  void _toggleReport(int productId) {
    setState(() {
      if (_expandedProductIds.contains(productId)) {
        _expandedProductIds.remove(productId);
      } else {
        _expandedProductIds.add(productId);
        _loadLatestPost(productId);
      }
    });
  }

  // 장바구니 담기 핵심 로직
  Future<void> _addToCart(ProductModel item) async {
    final result = await _cartRepo.addCartItem(
      productId: item.productId,
      quantity: 1,
      storeId: widget.storeId,
    );

    if (result == AddCartResult.success) {
      _showSnackBar('${item.productName}이(가) 장바구니에 담겼습니다.', const Color(0xFF4FA55B));
    }
    else if (result == AddCartResult.differentStore) {
      _showResetDialog(item);
    }
    else {
      _showSnackBar('장바구니 담기 실패. 다시 시도해주세요.', Colors.red);
    }
  }

  void _showResetDialog(ProductModel item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CartResetDialog(
        onConfirm: () async {
          Navigator.pop(context);
          await _cartRepo.clearCart();
          await _addToCart(item);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _showSnackBar(String message, Color bgColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 1),
          backgroundColor: bgColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 45, height: 45,
                      decoration: const BoxDecoration(
                        color: Color(0xFFECF0F4), shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          size: 18, color: Color(0xFF181C2E)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(widget.storeName,
                      style: const TextStyle(
                          fontFamily: 'Sen', fontSize: 17, color: Color(0xFF181C2E))),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CartScreen())),
                    child: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF1E1E1E)),
                  ),
                ],
              ),
            ),

            // 정렬 드롭다운
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Text(
                    '정렬',
                    style: TextStyle(
                      fontFamily: 'Sen',
                      fontSize: 13,
                      color: Color(0xFF6B6E82),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE4E4E4)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _currentSort,
                        isDense: true,
                        style: const TextStyle(
                          fontFamily: 'Sen',
                          fontSize: 13,
                          color: Color(0xFF32343E),
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                        items: _sortOptions.entries
                            .map((e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null && value != _currentSort) {
                            setState(() => _currentSort = value);
                            _loadProducts();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 상품 목록 — 2열 + 인라인 제보 카드
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('상품을 불러오지 못했습니다.'),
                              TextButton(
                                onPressed: _loadProducts,
                                child: const Text('다시 시도'),
                              ),
                            ],
                          ),
                        )
                      : _products.isEmpty
                          ? const Center(child: Text('등록된 상품이 없습니다.'))
                          : _buildProductList(),
            ),

            // 하단 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const CartScreen())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FA55B),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('선택 완료',
                    style: TextStyle(color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 2열 그리드 + 인라인 제보 카드를 지원하는 커스텀 레이아웃
  Widget _buildProductList() {
    final List<Widget> rows = [];

    for (int i = 0; i < _products.length; i += 2) {
      final left = _products[i];
      final right = (i + 1 < _products.length) ? _products[i + 1] : null;

      // 상품 카드 행 (2열)
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildMenuItem(left)),
                const SizedBox(width: 15),
                Expanded(
                  child: right != null
                      ? _buildMenuItem(right)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      );

      // 왼쪽 카드의 인라인 제보
      if (_expandedProductIds.contains(left.productId)) {
        rows.add(_buildInlineReport(left));
      }

      // 오른쪽 카드의 인라인 제보
      if (right != null && _expandedProductIds.contains(right.productId)) {
        rows.add(_buildInlineReport(right));
      }

      rows.add(const SizedBox(height: 15));
    }

    return ListView(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      children: rows,
    );
  }

  /// 인라인 제보 카드 (스크린샷 2번 대응)
  Widget _buildInlineReport(ProductModel product) {
    final isLoading = _loadingPostIds.contains(product.productId);
    final post = _latestPostCache[product.productId];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : post == null
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F8FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      '아직 제보된 내용이 없습니다.',
                      style: TextStyle(
                        color: Color(0xFF9C9BA6),
                        fontSize: 13,
                        fontFamily: 'Sen',
                      ),
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: () {
                    // 제보 카드 탭 → 해당 상품 전체 제보 페이지로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductPostsPage(
                          productId: product.productId,
                          productName: product.productName,
                        ),
                      ),
                    );
                  },
                  child: _buildPostCard(post),
                ),
    );
  }

  /// 제보 카드 UI (report_board_page.dart 스타일)
  Widget _buildPostCard(PostModel post) {
    String formattedDate = '';
    try {
      final dt = DateTime.parse(post.regDt);
      formattedDate =
          '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}.';
    } catch (_) {
      formattedDate = post.regDt;
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      child: Stack(
        children: [
          // 배경 카드
          Padding(
            padding: const EdgeInsets.only(left: 53),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8FA),
                borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(height: 4),
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
                  const SizedBox(height: 6),
                  // 내용
                  if (post.content != null && post.content!.isNotEmpty)
                    Text(
                      post.content!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF747783),
                        fontSize: 12,
                        fontFamily: 'Sen',
                        height: 1.4,
                      ),
                    ),
                  // 이미지
                  if (post.imgUrl != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        post.imgUrl!,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 70, height: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFFC4C4C4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // 유저 아바타
          Positioned(
            left: 0,
            top: 2,
            child: Container(
              width: 40,
              height: 40,
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
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(ProductModel item) {
    // HOT DEAL 기준: 이 매장에서 소비자가 이전에 주문한 적이 있는 상품
    // (주문이 많을수록 _loadProducts 에서 상단으로 정렬됨)
    final bool isHotDeal = (_orderCountByProductId[item.productId] ?? 0) > 0;
    final bool isExpanded = _expandedProductIds.contains(item.productId);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
        border: isHotDeal
            ? Border.all(color: const Color(0xFFE53935), width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // HOT DEAL 배지 + 상품 이미지
          Stack(
            children: [
              Container(
                height: 100,
                width: double.infinity,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFC4C4C4),
                  borderRadius: BorderRadius.circular(5),
                  image: item.imgUrl != null
                      ? DecorationImage(image: NetworkImage(item.imgUrl!), fit: BoxFit.cover)
                      : null,
                ),
              ),
              // HOT DEAL 배지
              if (isHotDeal)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'HOT DEAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // 이름 및 추가 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.productName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _addToCart(item),
                  child: Container(
                    width: 28, height: 28,
                    decoration: const BoxDecoration(
                        color: Color(0xFF11A94D), shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),

          // 가격 정보
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4, right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item.productDisPrice ?? 0}원',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      Text('${item.productOriPrice ?? 0}원',
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFFA0A5BA),
                              decoration: TextDecoration.lineThrough)),
                      const SizedBox(width: 4),
                      Text('${item.discountRate}%',
                          style: const TextStyle(
                              fontSize: 16, color: Color(0xFFFF7622),
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // "제보 내용 열기/닫기" 토글 버튼
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
            child: GestureDetector(
              onTap: () => _toggleReport(item.productId),
              child: Container(
                width: double.infinity,
                height: 30,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFCACCDA)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    isExpanded ? '제보 내용 닫기' : '제보 내용 열기',
                    style: const TextStyle(
                      fontFamily: 'Sen',
                      fontSize: 11,
                      color: Color(0xFF6B6E82),
                    ),
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