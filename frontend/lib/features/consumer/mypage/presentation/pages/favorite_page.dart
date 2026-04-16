import 'package:flutter/material.dart';
import 'package:frontend/features/store/data/models/store_model.dart';
import 'package:frontend/features/consumer/home/presentation/widgets/store_card.dart';
import 'package:frontend/features/consumer/store_detail/presentation/pages/shop_page.dart';
import 'package:frontend/features/consumer/mypage/data/datasources/favorite_api.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  List<StoreModel> _favoriteStores = [];
  bool _isLoading = true;

  final FavoriteRemoteDataSource _api = FavoriteRemoteDataSource();

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);

    final stores = await _api.getFavorites();

    setState(() {
      _favoriteStores = stores;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          '즐겨찾기',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF333333)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favoriteStores.isEmpty
          ? const Center(
              child: Text(
                '찜한 가게가 없습니다.',
                style: TextStyle(fontSize: 16, color: Color(0xFF9E9E9E)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _favoriteStores.length,
              itemBuilder: (context, index) {
                final store = _favoriteStores[index];
                return StoreCard(
                  // 리스트 뷰 — 가게 카드 리스트
                  store: store,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShopPage(storeId: store.storeId),
                      ),
                    ).then((_) => _loadFavorites());
                  },
                );
              },
            ),
    );
  }
}
