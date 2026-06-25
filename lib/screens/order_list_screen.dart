import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../services/config_service.dart';
import 'order_detail_screen.dart';
import '../models/order.dart' as order_model;

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final List<_StatusTab> _tabs = [
    _StatusTab('全部', null),
    _StatusTab('待处理', 0),
    _StatusTab('已完成', 2),
    _StatusTab('已退款', -1),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrders(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _parseColor(ConfigService.primaryColor);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('我的订单', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 状态Tab
          _buildStatusTabs(primaryColor),
          // 订单列表
          Expanded(child: _buildOrderList(primaryColor)),
        ],
      ),
    );
  }

  Widget _buildStatusTabs(Color primaryColor) {
    return Consumer<OrderProvider>(
      builder: (_, provider, __) {
        return Container(
          height: 44,
          color: const Color(0xFF0F0F0F),
          child: Row(
            children: _tabs.map((tab) {
              final selected = provider.statusFilter == tab.status;
              return Expanded(
                child: GestureDetector(
                  onTap: () => provider.setStatusFilter(tab.status),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: selected ? primaryColor : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 14,
                        color: selected ? primaryColor : Colors.white.withOpacity(0.5),
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildOrderList(Color primaryColor) {
    return Consumer<OrderProvider>(
      builder: (_, provider, __) {
        if (provider.isLoading && provider.orders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long, size: 48, color: Colors.white.withOpacity(0.2)),
                const SizedBox(height: 12),
                Text('暂无订单', style: TextStyle(color: Colors.white.withOpacity(0.4))),
              ],
            ),
          );
        }
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification && notification.metrics.pixels >= notification.metrics.maxScrollExtent - 100) {
              if (provider.hasMore && !provider.isLoading) {
                provider.loadOrders();
              }
            }
            return false;
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: provider.orders.length + (provider.isLoading ? 1 : 0),
            itemBuilder: (_, i) {
              if (i >= provider.orders.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                );
              }
              final order = provider.orders[i];
              return _buildOrderCard(order, primaryColor);
            },
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(order_model.Order order, Color primaryColor) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(order.productName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor(order.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(order.statusText, style: TextStyle(fontSize: 11, color: _statusColor(order.status))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('订单号: ${order.orderNo}', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.35))),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${order.quantity}${order.productName}',
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
                Text('¥${order.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            if (order.refundAmount > 0) ...[
              const SizedBox(height: 4),
              Text('已退款 ¥${order.refundAmount.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 12, color: Colors.orange.withOpacity(0.8))),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case '0': return Colors.orange;
      case '1': return Colors.blue;
      case '2': case '3': return Colors.green;
      case '-1': return Colors.red;
      case '-2': return Colors.grey;
      default: return Colors.white;
    }
  }

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}

class _StatusTab {
  final String label;
  final int? status;
  const _StatusTab(this.label, this.status);
}
