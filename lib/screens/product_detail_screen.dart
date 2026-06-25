import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/config_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  bool _isBuying = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final primaryColor = _parseColor(ConfigService.primaryColor);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('商品详情', style: TextStyle(fontSize: 16)),
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 商品图片
            Container(
              width: double.infinity,
              height: 300,
              color: const Color(0xFF151515),
              child: p.image.isNotEmpty
                  ? Image.network(p.image, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(p.name, primaryColor))
                  : _buildPlaceholder(p.name, primaryColor),
            ),
            // 基本信息
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('¥${p.price.toStringAsFixed(2)}',
                        style: TextStyle(color: primaryColor, fontSize: 24, fontWeight: FontWeight.bold)),
                      if (p.originalPrice != null && p.originalPrice! > p.price)
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Text('¥${p.originalPrice!.toStringAsFixed(2)}',
                            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14, decoration: TextDecoration.lineThrough)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfoChip('已售 ${p.salesCount}', Icons.trending_up),
                      const SizedBox(width: 8),
                      _buildInfoChip('库存 ${p.stock}', Icons.inventory_2),
                      if (p.minBuy > 1 || p.maxBuy < 999) ...[
                        const SizedBox(width: 8),
                        _buildInfoChip('${p.minBuy}-${p.maxBuy}${p.unit}', Icons.swap_horiz),
                      ],
                    ],
                  ),
                  if (p.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 12),
                    Text('商品说明', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(p.description, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                  ],
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 12),
                  Text('购买数量', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                  const SizedBox(height: 8),
                  _buildQuantitySelector(p),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(primaryColor),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withOpacity(0.4)),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5))),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector(Product p) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qtyBtn(Icons.remove, () {
            if (_quantity > p.minBuy) setState(() => _quantity--);
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('$_quantity', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          _qtyBtn(Icons.add, () {
            if (_quantity < p.maxBuy) setState(() => _quantity++);
          }),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Icon(icon, color: Colors.white.withOpacity(0.6), size: 20),
      ),
    );
  }

  Widget _buildBottomBar(Color primaryColor) {
    final p = widget.product;
    final total = (p.price * _quantity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('合计', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                  Text('¥${total.toStringAsFixed(2)}',
                    style: TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            SizedBox(
              width: 160,
              height: 48,
              child: ElevatedButton(
                onPressed: _isBuying ? null : _buy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isBuying
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('立即购买', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _buy() async {
    final p = widget.product;
    setState(() => _isBuying = true);
    try {
      final result = await ApiService.placeOrder(productId: p.id, quantity: _quantity);
      if (mounted) {
        if (result['code'] == 0) {
          _showSuccess('下单成功！');
          // 刷新余额
          context.read<AuthProvider>().refreshBalance();
        } else {
          _showError(result['message'] ?? '下单失败');
        }
      }
    } catch (e) {
      if (mounted) _showError('网络错误: $e');
    }
    if (mounted) setState(() => _isBuying = false);
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green.shade700, behavior: SnackBarBehavior.floating),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade800, behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildPlaceholder(String name, Color color) {
    return Container(
      color: color.withOpacity(0.1),
      child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'P',
        style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: color.withOpacity(0.2)))),
    );
  }

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}
