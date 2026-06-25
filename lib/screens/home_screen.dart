import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/config_service.dart';
import '../models/product.dart';
import '../models/banner.dart';
import 'product_detail_screen.dart';
import 'order_list_screen.dart';
import 'profile_screen.dart';
import 'announcements_screen.dart';
import 'chat_screen.dart';

/// 首页 — 底部3Tab导航 (商城/订单/我的)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  int _unreadCount = 0;
  Timer? _chatPollTimer;

  void switchToTab(int index) {
    setState(() => _currentTab = index);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadAll();
      _startChatPolling();
    });
  }

  @override
  void dispose() {
    _chatPollTimer?.cancel();
    super.dispose();
  }

  void _startChatPolling() {
    _chatPollTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!context.mounted) return;
      final auth = context.read<AuthProvider>();
      if (auth.isLoggedIn) {
        try {
          final count = await ApiService.getUnreadNoticeCount();
          if (mounted) setState(() => _unreadCount = count);
        } catch (_) {}
      }
    });
  }

  void _openChat() {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChatScreen(userId: 0, userName: auth.username),
    )).then((_) {
      setState(() => _unreadCount = 0);
    });
  }

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const _ShopTab(),
      const OrderListScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _currentTab, children: tabs),
          // 浮动聊天按钮
          if (context.watch<AuthProvider>().isLoggedIn)
            Positioned(
              right: 16,
              bottom: 80,
              child: _buildChatButton(),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildChatButton() {
    final primaryColor = _parseColor(ConfigService.primaryColor);
    return GestureDetector(
      onTap: _openChat,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, primaryColor.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Center(
              child: Icon(Icons.chat_bubble_outline, color: Colors.white, size: 24),
            ),
            if (_unreadCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _unreadCount > 99 ? '99+' : '$_unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final primaryColor = _parseColor(ConfigService.primaryColor);
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
        color: const Color(0xFF0F0F0F),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.white.withOpacity(0.35),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store_outlined), activeIcon: Icon(Icons.store), label: '商城'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: '订单'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}

// ==================== 商城Tab (含轮播图+搜索+分类+商品) ====================
class _ShopTab extends StatefulWidget {
  const _ShopTab();
  @override
  State<_ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<_ShopTab> {
  List<BannerItem> _banners = [];
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBanners() async {
    try {
      _banners = await ApiService.getBanners();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _doSearch(String keyword) {
    context.read<ProductProvider>().searchProducts(keyword);
  }

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _parseColor(ConfigService.primaryColor);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text(ConfigService.appName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign_outlined, size: 20),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsScreen())),
            tooltip: '公告',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () {
              context.read<ProductProvider>().loadAll();
              _loadBanners();
            },
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading && provider.products.isEmpty && _banners.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.products.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 48, color: Colors.white.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  Text(provider.error!, style: TextStyle(color: Colors.white.withOpacity(0.5))),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => provider.loadAll(), child: const Text('重试')),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              provider.loadAll();
              _loadBanners();
            },
            child: CustomScrollView(
              slivers: [
                // 搜索栏
                SliverToBoxAdapter(child: _buildSearchBar(primaryColor)),
                // 轮播图
                if (_banners.isNotEmpty)
                  SliverToBoxAdapter(child: _buildBannerCarousel(primaryColor)),
                // 分类栏
                SliverToBoxAdapter(child: _buildCategoryBar(provider, primaryColor)),
                // 商品列表
                if (provider.products.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        provider.searchKeyword != null ? '未找到"${provider.searchKeyword}"相关商品' : '暂无商品',
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.68,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _buildProductCard(provider.products[i], primaryColor),
                        childCount: provider.products.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      color: const Color(0xFF0F0F0F),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(fontSize: 14, color: Colors.white),
        decoration: InputDecoration(
          hintText: '搜索商品名称...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.4), size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.4), size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    _doSearch('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white.withOpacity(0.06),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: (v) => _doSearch(v),
        onChanged: (v) => setState(() {}),
      ),
    );
  }

  Widget _buildBannerCarousel(Color primaryColor) {
    return Container(
      height: 160,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: PageView.builder(
        itemCount: _banners.length,
        onPageChanged: (_) => setState(() {}),
        itemBuilder: (_, i) {
          final b = _banners[i];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: primaryColor.withOpacity(0.1),
            ),
            clipBehavior: Clip.antiAlias,
            child: b.imageUrl.isNotEmpty
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(b.imageUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _bannerPlaceholder(b.title ?? '轮播图', primaryColor),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Center(child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor));
                        },
                      ),
                      if (b.title != null && b.title!.isNotEmpty)
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter, end: Alignment.topCenter,
                                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                              ),
                            ),
                            child: Text(b.title!, style: const TextStyle(color: Colors.white, fontSize: 13)),
                          ),
                        ),
                    ],
                  )
                : _bannerPlaceholder(b.title ?? '轮播图', primaryColor),
          );
        },
      ),
    );
  }

  Widget _bannerPlaceholder(String text, Color color) {
    return Container(
      color: color.withOpacity(0.08),
      child: Center(
        child: Icon(Icons.image, size: 40, color: color.withOpacity(0.2)),
      ),
    );
  }

  Widget _buildCategoryBar(ProductProvider provider, Color primaryColor) {
    final categories = provider.categories;
    return Container(
      height: 44,
      color: const Color(0xFF0F0F0F),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _buildCategoryChip('全部', 0, provider.selectedCategoryId == 0,
              () => provider.selectCategory(0), primaryColor),
          ...categories.map((c) => _buildCategoryChip(
            c.name, c.id, provider.selectedCategoryId == c.id,
            () => provider.selectCategory(c.id), primaryColor,
          )),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, int id, bool selected, VoidCallback onTap, Color primaryColor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? primaryColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? primaryColor.withOpacity(0.4) : Colors.transparent),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? primaryColor : Colors.white.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product, Color primaryColor) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: product.image.isNotEmpty
                    ? Image.network(product.image, fit: BoxFit.cover, width: double.infinity,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(product.name, primaryColor))
                    : _buildPlaceholder(product.name, primaryColor),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Row(
                      children: [
                        Text('¥${product.price.toStringAsFixed(2)}',
                          style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
                        if (product.originalPrice != null && product.originalPrice! > product.price)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Text('¥${product.originalPrice!.toStringAsFixed(2)}',
                              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11, decoration: TextDecoration.lineThrough)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String name, Color color) {
    return Container(
      color: color.withOpacity(0.1),
      child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'P',
        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color.withOpacity(0.3)))),
    );
  }
}
