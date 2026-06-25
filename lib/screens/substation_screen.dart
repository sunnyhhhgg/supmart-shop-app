import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/substation_info.dart';

/// 分站管理
class SubstationScreen extends StatefulWidget {
  const SubstationScreen({super.key});

  @override
  State<SubstationScreen> createState() => _SubstationScreenState();
}

class _SubstationScreenState extends State<SubstationScreen> {
  SubstationInfo? _substation;
  bool _loading = true;
  bool _buying = false;
  List<Map<String, dynamic>> _domains = [];
  Map<String, dynamic>? _vipPrices;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _substation = await ApiService.getSubstation();
      _domains = await ApiService.getShopUrlList();
      _vipPrices = await ApiService.getVipMoney(type: 'substation');
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _buySubstation() async {
    setState(() => _buying = true);
    try {
      final result = await ApiService.buySubstation();
      if (result['code'] == 0) {
        _showMsg('分站购买成功！', isError: false);
        _load();
      } else {
        _showMsg(result['message'] ?? '购买失败');
      }
    } catch (e) {
      _showMsg('购买失败: $e');
    }
    setState(() => _buying = false);
  }

  void _showMsg(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red[800] : Colors.green[800],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('分站管理')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_substation == null || !_substation!.exists)
                    _buildNoSubstation(theme)
                  else ...[
                    _buildInfoCard(theme),
                    const SizedBox(height: 16),
                    _buildDomainsSection(theme),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildNoSubstation(ThemeData theme) {
    double? price;
    try {
      if (_vipPrices != null && _vipPrices!['substation_price'] != null) {
        price = (_vipPrices!['substation_price'] as num).toDouble();
      }
    } catch (_) {}
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 60),
        Icon(Icons.dns_outlined, size: 64, color: Colors.grey[600]),
        const SizedBox(height: 16),
        const Text('您还没有分站', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          price != null ? '开通分站仅需 ¥${price.toStringAsFixed(0)}' : '开通专属分站，搭建自己的商城',
          style: TextStyle(fontSize: 14, color: Colors.grey[400]),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: 200,
          height: 46,
          child: ElevatedButton.icon(
            icon: _buying
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.shopping_cart),
            label: Text(_buying ? '购买中...' : '立即开通分站'),
            onPressed: _buying ? null : _buySubstation,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    final s = _substation!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dns, color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 8),
              Text('分站信息', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
            ],
          ),
          const Divider(height: 24),
          _infoRow('站点名称', s.name.isNotEmpty ? s.name : '未设置'),
          _infoRow('绑定域名', s.domain.isNotEmpty ? s.domain : '未绑定'),
          _infoRow('联系QQ', s.qq.isNotEmpty ? s.qq : '未设置'),
          _infoRow('联系微信', s.wx.isNotEmpty ? s.wx : '未设置'),
          if (s.level.isNotEmpty) _infoRow('等级', s.level),
        ],
      ),
    );
  }

  Widget _buildDomainsSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.language, color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 8),
              Text('域名列表', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
            ],
          ),
          const Divider(height: 20),
          if (_domains.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('暂无已绑定的域名', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            )
          else
            ...List.generate(_domains.length, (i) {
              final d = _domains[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.link, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        d['domain']?.toString() ?? d['url']?.toString() ?? '',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      d['type']?.toString() == '1' ? '主域名' : '别名',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
