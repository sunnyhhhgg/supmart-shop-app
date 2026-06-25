import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../models/product.dart';
import '../services/config_service.dart';
import 'product_detail_screen.dart';
import 'order_list_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;

  /// 切换到指定Tab (供profile_screen调用)
  void switchToTab(int index) {
    setState(() => _currentTab = index);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildShopTab(),
      const OrderListScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: tabs[_currentTab],
      bottomNavigationBar: _buildBottomNav(),
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

  Widget _buildShopTab() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text(ConfigService.appName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => context.read<ProductProvider>().loadAll(),
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading && provider.products.isEmpty) {
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
                  ElevatedButton(
                    onPressed: () => provider.loadAll(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }
          return Column(
            children: [
              // 分类栏
              _buildCategoryBar(provider),
              // 商品列表
              Expanded(child: _buildProductGrid(provider)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryBar(ProductProvider provider) {
    final categories = provider.categories;
    return Container(
      height: 44,
      color: const Color(0xFF0F0F0F),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _buildCategoryChip('全部', 0, provider.selectedCategoryId == 0, () => provider.selectCategory(0)),
          ...categories.map((c) => _buildCategoryChip(
            c.name, c.id, provider.selectedCategoryId == c.id, () => provider.selectCategory(c.id),
          )),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, int id, bool selected, VoidCallback onTap) {
    final primaryColor = _parseColor(ConfigService.primaryColor);
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

  Widget _buildProductGrid(ProductProvider provider) {
    if (provider.products.isEmpty) {
      return Center(
        child: Text('暂无商品', style: TextStyle(color: Colors.white.withOpacity(0.4))),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.68,
      ),
      itemCount: provider.products.length,
      itemBuilder: (_, i) => _buildProductCard(provider.products[i]),
    );
  }

  Widget _buildProductCard(Product product) {
    final primaryColor = _parseColor(ConfigService.primaryColor);
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
            // 商品图片
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
            // 信息
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

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}
