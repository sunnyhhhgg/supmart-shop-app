import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/close_price.dart';

/// 成交价/密价列表
class ClosePriceScreen extends StatefulWidget {
  const ClosePriceScreen({super.key});

  @override
  State<ClosePriceScreen> createState() => _ClosePriceScreenState();
}

class _ClosePriceScreenState extends State<ClosePriceScreen> {
  List<ClosePrice> _prices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _prices = await ApiService.getClosePriceList();
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('成交价')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _prices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.price_change, size: 48, color: Colors.grey[700]),
                      const SizedBox(height: 8),
                      Text('暂无专属成交价', style: TextStyle(color: Colors.grey[500])),
                      const SizedBox(height: 4),
                      Text('请联系管理员设置密价', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _prices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final p = _prices[index];
                      final saving = p.originalPrice - p.closePrice;
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[800]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.productName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Text('原价: ', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                      Text(
                                        '¥${p.originalPrice.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text('成交价: ', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                      Text(
                                        '¥${p.closePrice.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (saving > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '-${saving.toStringAsFixed(1)}',
                                  style: TextStyle(fontSize: 12, color: Colors.green[400], fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
