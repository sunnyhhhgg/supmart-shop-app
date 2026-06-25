import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/substation_info.dart';

/// 分站管理 — 含3版本选择/购买/信息展示/域名列表
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
  List<Map<String, dynamic>> _versions = [];
  int _selectedLevel = 1;
  double _singlePrice = 0;

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
      final vipData = await ApiService.getVipMoney(type: 'substation');
      // vipData 已经是 data 层级: { substation_versions, substation_price, ... }
      final versions = vipData['substation_versions'];
      if (versions is List && versions.isNotEmpty) {
        _versions = versions.cast<Map<String, dynamic>>();
      }
      if (vipData['substation_price'] is num) {
        _singlePrice = (vipData['substation_price'] as num).toDouble();
      }
    } catch (_) {}
    if (_versions.isEmpty && _singlePrice > 0) {
      // Fallback: 生成默认3版本
      _versions = [
        {'level': 1, 'name': '普及版', 'price': _singlePrice, 'features': ['基础功能', '绑定域名']},
        {'level': 2, 'name': '专业版', 'price': _singlePrice * 2, 'features': ['基础功能', '绑定域名', '更多商品']},
        {'level': 3, 'name': '旗舰版', 'price': _singlePrice * 3, 'features': ['全部功能', '绑定域名', '自定义模板']},
      ];
    } else if (_versions.isEmpty) {
      _versions = [
        {'level': 1, 'name': '普及版', 'price': 99.0, 'features': ['基础商品展示', '单域名绑定', '订单管理', '客服支持', '商品搜索', '分类浏览', '在线下单']},
        {'level': 2, 'name': '专业版', 'price': 199.0, 'features': ['全部普及版功能', '多域名绑定', '数据统计', 'API接口', '自定义LOGO', '自定义主题', '优先客服响应', '批量商品上架']},
        {'level': 3, 'name': '旗舰版', 'price': 399.0, 'features': ['全部专业版功能', '无限域名绑定', '优先客服', '自定义模板', '独立管理后台', '专属API密钥', '商品审核', '佣金结算', '会员等级管理', '自定义支付接口']},
      ];
    }
    if (_versions.isNotEmpty) {
      _selectedLevel = (_versions.first['level'] as num).toInt();
    }
    setState(() => _loading = false);
  }

  Future<void> _buySubstation() async {
    setState(() => _buying = true);
    try {
      final result = await ApiService.buyFz(level: _selectedLevel);
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

  // ==================== 未开通: 版本选择 ====================
  Widget _buildNoSubstation(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Center(
          child: Text('选择一个版本开通您的分站',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text('开通专属分站，搭建自己的商城',
            style: TextStyle(fontSize: 13, color: Colors.grey[400])),
        ),
        const SizedBox(height: 24),
        // 三个版本卡片
        ...List.generate(_versions.length, (i) {
          final v = _versions[i];
          final level = (v['level'] as num).toInt();
          final name = v['name'] as String? ?? '版本${level}';
          final price = (v['price'] as num).toDouble();
          final features = (v['features'] as List?)?.cast<String>() ?? [];
          final isSelected = _selectedLevel == level;
          final isRecommended = level == 2;

          // 获取颜色主题
          final cardColors = [
            const Color(0xFF06B6D4), // 青色 - 普及版
            theme.colorScheme.primary, // 主题色 - 专业版
            const Color(0xFFF59E0B), // 琥珀色 - 旗舰版
          ];
          final color = cardColors[(level - 1) % cardColors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedLevel = level),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.08) : const Color(0xFF151515),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? color.withOpacity(0.6) : Colors.white.withOpacity(0.06),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Stack(
                  children: [
                    if (isRecommended)
                      Positioned(
                        top: 0, left: 0, right: 0,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 头部: 图标 + 名称 + 推荐标签 + 选择圈
                          Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  level == 1 ? Icons.person_outline :
                                  level == 2 ? Icons.star_outline : Icons.diamond_outlined,
                                  color: color, size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(name,
                                          style: const TextStyle(
                                            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                        if (isRecommended) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text('推荐', style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text('¥${price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                                  ],
                                ),
                              ),
                              Container(
                                width: 22, height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? color : Colors.grey[600]!,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? Center(child: Container(
                                        width: 12, height: 12,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle, color: color,
                                        ),
                                      ))
                                    : null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // 功能列表
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: features.map((f) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check, size: 14, color: Colors.green[400]),
                                  const SizedBox(width: 3),
                                  Text(f, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        // 购买按钮
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: _buying ? null : _buySubstation,
            child: _buying
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(
                    '立即开通 - ${_getSelectedName()} ¥${_getSelectedPrice().toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }

  String _getSelectedName() {
    for (final v in _versions) {
      if ((v['level'] as num).toInt() == _selectedLevel) return v['name'] as String? ?? '';
    }
    return '';
  }

  double _getSelectedPrice() {
    for (final v in _versions) {
      if ((v['level'] as num).toInt() == _selectedLevel) return (v['price'] as num).toDouble();
    }
    return 0;
  }

  // ==================== 已开通: 信息卡片 ====================
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

  // ==================== 域名列表 ====================
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
