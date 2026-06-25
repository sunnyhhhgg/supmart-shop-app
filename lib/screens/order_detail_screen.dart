import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/config_service.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final primaryColor = _parseColor(ConfigService.primaryColor);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('订单详情', style: TextStyle(fontSize: 16)),
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 状态卡片
            _buildStatusCard(primaryColor),
            const SizedBox(height: 12),
            // 商品信息
            _buildSection('商品信息', [
              _infoRow('商品名称', order.productName),
              _infoRow('单价', '¥${order.price.toStringAsFixed(2)}'),
              _infoRow('数量', '${order.quantity}'),
              _infoRow('总金额', '¥${order.totalAmount.toStringAsFixed(2)}', valueColor: primaryColor),
            ]),
            const SizedBox(height: 12),
            // 订单信息
            _buildSection('订单信息', [
              _infoRow('订单号', order.orderNo),
              _infoRow('下单时间', _formatTime(order.createdAt)),
              if (order.status == '2' || order.status == '3')
                _infoRow('完成时间', _formatTime(order.updatedAt)),
            ]),
            // 卡密信息
            if (order.cardInfo.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildSection('卡密信息', [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.15)),
                  ),
                  child: SelectableText(
                    order.cardInfo,
                    style: TextStyle(color: Colors.green.shade300, fontSize: 13, height: 1.5),
                  ),
                ),
              ]),
            ],
            // 退款信息
            if (order.refundAmount > 0) ...[
              const SizedBox(height: 12),
              _buildSection('退款信息', [
                _infoRow('退款金额', '¥${order.refundAmount.toStringAsFixed(2)}', valueColor: Colors.orange),
                _infoRow('退款数量', '${order.refundQuantity}'),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _statusColor(order.status).withOpacity(0.2),
            const Color(0xFF151515),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _statusColor(order.status).withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _statusColor(order.status).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_statusIcon(order.status), color: _statusColor(order.status), size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.statusText, style: TextStyle(color: _statusColor(order.status), fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('订单金额: ¥${order.totalAmount.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: valueColor ?? Colors.white.withOpacity(0.85), fontSize: 13)),
          ),
        ],
      ),
    );
  }

  String _formatTime(int timestamp) {
    if (timestamp == 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} ${_pad(dt.hour)}:${_pad(dt.minute)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  IconData _statusIcon(String status) {
    switch (status) {
      case '0': return Icons.hourglass_empty;
      case '1': return Icons.sync;
      case '2': case '3': return Icons.check_circle;
      case '-1': return Icons.replay;
      case '-2': return Icons.cancel;
      default: return Icons.help_outline;
    }
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
