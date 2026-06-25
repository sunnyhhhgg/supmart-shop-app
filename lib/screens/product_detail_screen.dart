import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/config_service.dart';

/// 商品详情页 — 与PC端 ShopProductDetail.vue 完全对应
class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Product _product;
  int _quantity = 1;
  bool _isBuying = false;
  bool _loadingDetail = false;
  int _activeInfoTab = 0; // 0=商品详情, 1=商品参数, 2=购买记录
  final Map<String, TextEditingController> _paramControllers = {};
  final Map<String, bool> _resolvingLink = {};
  Timer? _linkTimer;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _quantity = (_product.minBuy > 0) ? _product.minBuy : 1;
    // 如果初始数量超过最大限制，调整
    if (_quantity > _product.maxBuy && _product.maxBuy > 0) {
      _quantity = _product.maxBuy;
    }
    // 加载完整详情（goods-detail 返回更完整的数据，含 buy_params）
    _loadFullDetail();
  }

  @override
  void dispose() {
    _linkTimer?.cancel();
    for (final c in _paramControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadFullDetail() async {
    setState(() => _loadingDetail = true);
    try {
      final detail = await ApiService.getProductDetail(_product.id);
      if (detail != null && mounted) {
        setState(() {
          _product = detail;
          _quantity = (_product.minBuy > 0) ? _product.minBuy : 1;
          if (_quantity > _product.maxBuy && _product.maxBuy > 0) {
            _quantity = _product.maxBuy;
          }
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingDetail = false);
  }

  // ==================== 数量控制 ====================
  int get _minQty => (_product.minBuy > 0) ? _product.minBuy : 1;
  int get _maxQty => (_product.maxBuy > 0) ? _product.maxBuy : 999;
  int get _step => (_product.buyRate > 1) ? _product.buyRate : 1;

  void _decrement() {
    final step = _step;
    if (_quantity - step >= _minQty) {
      setState(() => _quantity -= step);
    } else {
      setState(() => _quantity = _minQty);
    }
  }

  void _increment() {
    final step = _step;
    if (_quantity + step <= _maxQty) {
      setState(() => _quantity += step);
    } else {
      setState(() => _quantity = _maxQty);
    }
  }

  void _snapQty() {
    if (_quantity > _maxQty && _maxQty > 0) _quantity = _maxQty;
    if (_quantity < _minQty) _quantity = _minQty;
    final step = _step;
    if (step > 1) {
      final remainder = _quantity % step;
      if (remainder != 0) {
        _quantity -= remainder;
        if (_quantity < _minQty) _quantity = _minQty;
        if (_quantity > _maxQty && _maxQty > 0) _quantity = _maxQty;
      }
    }
    setState(() {});
  }

  bool _validateQty() {
    final step = _step;
    if (step > 1 && _quantity % step != 0) {
      _showToast(false, '下单数量必须是 $step 的整数倍');
      return false;
    }
    if (_quantity > _maxQty && _maxQty > 0) {
      _quantity = _maxQty;
      _showToast(false, '下单数量不能超过最大限制 $_maxQty');
      return false;
    }
    if (_quantity < _minQty) {
      _quantity = _minQty;
      _showToast(false, '下单数量不能少于最小限制 $_minQty');
      return false;
    }
    return true;
  }

  // ==================== Toast ====================
  bool _toastVisible = false;
  bool _toastSuccess = false;
  String _toastMessage = '';
  String _toastOrderId = '';
  Timer? _toastTimer;

  void _showToast(bool success, String message, {String? orderId}) {
    _toastTimer?.cancel();
    setState(() {
      _toastVisible = true;
      _toastSuccess = success;
      _toastMessage = message;
      _toastOrderId = orderId ?? '';
    });
    _toastTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _toastVisible = false);
    });
  }

  void _dismissToast() {
    _toastTimer?.cancel();
    setState(() => _toastVisible = false);
  }

  // ==================== 购买 ====================
  Future<void> _buy() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      _showToast(false, '请先登录后再购买');
      return;
    }
    if (_product.isCardCode) {
      // 卡密商品检查
    }
    setState(() => _isBuying = true);
    try {
      if (!_validateQty()) {
        setState(() => _isBuying = false);
        return;
      }
      // 收集 buy_params
      final Map<String, dynamic> collected = {};
      for (final param in _product.buyParams) {
        final ctrl = _paramControllers[param.key];
        if (ctrl != null && ctrl.text.trim().isNotEmpty) {
          collected[param.key] = ctrl.text.trim();
        }
      }
      final result = await ApiService.placeOrder(
        productId: _product.id,
        quantity: _quantity,
        buyParams: collected.isNotEmpty ? collected : null,
      );
      if (mounted) {
        if (result['code'] == 0) {
          _showToast(true, '购买成功！', orderId: result['data']?['order_id']?.toString() ?? '');
          auth.refreshBalance();
        } else {
          _showToast(false, result['message'] ?? '购买失败');
        }
      }
    } catch (e) {
      if (mounted) _showToast(false, '网络错误: $e');
    }
    if (mounted) setState(() => _isBuying = false);
  }

  // ==================== 链接解析 (type=61) ====================
  void _onLinkInput(BuyParam param, String value) {
    _linkTimer?.cancel();
    _linkTimer = Timer(const Duration(milliseconds: 1200), () => _resolveLink(param, value));
  }

  Future<void> _resolveLink(BuyParam param, String value) async {
    if (value.isEmpty) return;
    final key = param.key;
    setState(() => _resolvingLink[key] = true);
    try {
      final resolved = await ApiService.resolveLink(_product.id, value);
      if (resolved != null && mounted) {
        final ctrl = _paramControllers[key];
        if (ctrl != null) {
          ctrl.text = resolved;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _resolvingLink[key] = false);
  }

  // ==================== 构建UI ====================
  Color get _primaryColor => _parseColor(ConfigService.primaryColor);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('商品详情', style: TextStyle(fontSize: 16, color: Colors.white)),
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== 图片展示 =====
                _buildImageGallery(),
                // ===== 商品信息 =====
                _buildProductInfo(),
                // ===== 购买参数 =====
                if (_product.buyParams.isNotEmpty)
                  _buildBuyParamsSection(),
                // ===== 数量选择 =====
                _buildQuantitySection(),
                // ===== 底部占位 =====
                const SizedBox(height: 80),
              ],
            ),
          ),
          // ===== Toast =====
          if (_toastVisible)
            _buildToastOverlay(),
        ],
      ),
      // ===== 底部购买栏 =====
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ==================== 图片画廊 ====================
  Widget _buildImageGallery() {
    final imageUrls = _product.imageUrls;
    if (imageUrls.isEmpty) {
      return Container(
        width: double.infinity,
        height: 300,
        color: const Color(0xFF151515),
        child: Center(
          child: Icon(Icons.image_outlined, size: 64, color: _primaryColor.withOpacity(0.2)),
        ),
      );
    }
    return Container(
      width: double.infinity,
      color: const Color(0xFF0F0F0F),
      child: Column(
        children: [
          SizedBox(
            height: 300,
            child: PageView.builder(
              itemCount: imageUrls.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrls[i],
                    fit: BoxFit.contain,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.white.withOpacity(0.03),
                      child: Center(
                        child: Icon(Icons.broken_image, color: Colors.white.withOpacity(0.2), size: 48),
                      ),
                    ),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Center(child: CircularProgressIndicator(strokeWidth: 2, color: _primaryColor));
                    },
                  ),
                ),
              ),
            ),
          ),
          // 图片指示器
          if (imageUrls.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(imageUrls.length, (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == 0 ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == 0 ? _primaryColor : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                )),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== 商品信息 ====================
  Widget _buildProductInfo() {
    final p = _product;
    final priceText = p.priceText;
    final origPriceText = p.originalPriceText;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 名称 + 标签
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(p.name,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              if (p.tag != null && p.tag!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(p.tag!, style: TextStyle(color: _primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text('ID: ${p.id}', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
          if (p.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(p.description, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
          ],

          // 价格
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF151515),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('¥$priceText',
                      style: TextStyle(color: _primaryColor, fontSize: 28, fontWeight: FontWeight.bold)),
                    if (origPriceText.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('¥$origPriceText',
                          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14, decoration: TextDecoration.lineThrough)),
                      ),
                    ],
                    if (p.commissionRate != null && p.commissionRate! > 0) ...[
                      const Spacer(),
                      Text('返佣 ${p.commissionRate!.toStringAsFixed(1)}%',
                        style: TextStyle(color: _primaryColor.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _infoChip('库存: ${p.stock == -1 ? "充足" : p.stock}', Icons.inventory_2),
                    const SizedBox(width: 8),
                    _infoChip('已售: ${p.salesCount}', Icons.trending_up),
                    if (p.unit.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _infoChip('单位: ${p.unit}', Icons.square_foot),
                    ],
                  ],
                ),
                if (p.avgCompletionHours != null && p.avgCompletionHours! > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.white.withOpacity(0.4)),
                      const SizedBox(width: 4),
                      Text('约 ${p.avgCompletionHours!.toStringAsFixed(1)}h 完成',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String text, IconData icon) {
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

  // ==================== 购买参数 (buy_params) ====================
  Widget _buildBuyParamsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16),
          ..._product.buyParams.map((param) {
            _paramControllers.putIfAbsent(param.key, () => TextEditingController(text: param.defaultValue ?? ''));
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildBuyParamField(param),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBuyParamField(BuyParam param) {
    final ctrl = _paramControllers[param.key]!;
    final type = param.type;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(param.name, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        _buildParamInput(param, ctrl, type),
      ],
    );
  }

  Widget _buildParamInput(BuyParam param, TextEditingController ctrl, int type) {
    // 1=普通文本, 21=QQ/手机号 → 文本输入
    if (type == 1 || type == 21) {
      return _buildTextField(ctrl, param.description.isNotEmpty ? param.description : '请输入${param.name}');
    }
    // 2=多行文本
    if (type == 2) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: ctrl,
          maxLines: 3,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: param.description.isNotEmpty ? param.description : '请输入',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      );
    }
    // 3=数字类型（有选项 -> 下拉；无选项 -> 数字输入）
    if (type == 3) {
      final options = _splitConfig(param.typeConfig);
      if (options.isNotEmpty) {
        return _buildDropdown(ctrl, options, '请选择');
      }
      return _buildNumberField(ctrl, param);
    }
    // 4=图片链接
    if (type == 4) {
      return _buildTextField(ctrl, param.description.isNotEmpty ? param.description : '请输入图片链接');
    }
    // 5=累计下拉单选
    if (type == 5) {
      final options = _splitConfig(param.typeConfig);
      if (options.isNotEmpty) {
        return _buildDropdown(ctrl, options, '请选择');
      }
      return _buildTextField(ctrl, param.description.isNotEmpty ? param.description : '请输入');
    }
    // 6=通用ID提取
    if (type == 6) {
      return _buildTextField(ctrl, param.description.isNotEmpty ? param.description : '请输入ID');
    }
    // 7=累计乘收费
    if (type == 7) {
      final options = _splitConfig(param.typeConfig);
      if (options.isNotEmpty) {
        return _buildDropdown(ctrl, options, '请选择');
      }
      return _buildNumberField(ctrl, param);
    }
    // 8=单项选择
    if (type == 8) {
      return _buildDropdown(ctrl, _splitConfig(param.typeConfig), '请选择');
    }
    // 9=多项选择
    if (type == 9) {
      final options = _splitConfig(param.typeConfig);
      if (options.isNotEmpty) {
        return _buildMultiSelect(param, options);
      }
      return _buildTextField(ctrl, param.description.isNotEmpty ? param.description : '请输入');
    }
    // 61=链接提取
    if (type == 61) {
      return _buildLinkField(param, ctrl);
    }
    // 默认回退
    return _buildTextField(ctrl, param.description.isNotEmpty ? param.description : '请输入');
  }

  Widget _buildTextField(TextEditingController ctrl, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildNumberField(TextEditingController ctrl, BuyParam param) {
    final min = param.verify?['min'] ?? 0;
    final max = param.verify?['max'];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: param.description.isNotEmpty ? param.description : '请输入数字',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDropdown(TextEditingController ctrl, List<String> options, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: ctrl.text.isNotEmpty && options.contains(ctrl.text) ? ctrl.text : null,
        dropdownColor: const Color(0xFF1A1A1A),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        icon: Icon(Icons.arrow_drop_down, color: Colors.white.withOpacity(0.4)),
        isExpanded: true,
        items: options.map((opt) => DropdownMenuItem(
          value: opt,
          child: Text(opt, style: const TextStyle(color: Colors.white)),
        )).toList(),
        onChanged: (v) {
          if (v != null) ctrl.text = v;
        },
      ),
    );
  }

  Widget _buildMultiSelect(BuyParam param, List<String> options) {
    final key = param.key;
    final selected = _getMultiSelected(param);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: options.map((opt) {
          final isSelected = selected.contains(opt);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  selected.remove(opt);
                } else {
                  selected.add(opt);
                }
                _paramControllers[key]?.text = selected.join(',');
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? _primaryColor.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? _primaryColor.withOpacity(0.3) : Colors.white.withOpacity(0.06),
                ),
              ),
              margin: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 20,
                    color: isSelected ? _primaryColor : Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(width: 8),
                  Text(opt, style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  )),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Set<String> _getMultiSelected(BuyParam param) {
    final ctrl = _paramControllers[param.key];
    if (ctrl == null || ctrl.text.isEmpty) return {};
    return ctrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
  }

  Widget _buildLinkField(BuyParam param, TextEditingController ctrl) {
    final key = param.key;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          TextField(
            controller: ctrl,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: param.description.isNotEmpty ? param.description : '请输入链接',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            onChanged: (v) => _onLinkInput(param, v),
            onEditingComplete: () => _resolveLink(param, ctrl.text),
          ),
          if (_resolvingLink[key] == true)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: _primaryColor),
              ),
            ),
        ],
      ),
    );
  }

  List<String> _splitConfig(String? config) {
    if (config == null || config.isEmpty) return [];
    return config.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  // ==================== 数量选择 ====================
  Widget _buildQuantitySection() {
    final step = _step;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16),
          Text('购买数量', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _qtyBtn(Icons.remove, _decrement),
                    SizedBox(
                      width: 56,
                      child: TextField(
                        controller: TextEditingController(text: '$_quantity'),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onSubmitted: (v) {
                          final parsed = int.tryParse(v);
                          if (parsed != null) {
                            setState(() => _quantity = parsed);
                            _snapQty();
                          } else {
                            _snapQty();
                          }
                        },
                      ),
                    ),
                    _qtyBtn(Icons.add, _increment),
                  ],
                ),
              ),
              if (_maxQty > 0 && _maxQty < 999) ...[
                const SizedBox(width: 8),
                Text('限购 $_maxQty', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
              ],
              if (step > 1) ...[
                const SizedBox(width: 8),
                Text('倍数 $step', style: TextStyle(color: _primaryColor.withOpacity(0.7), fontSize: 12)),
              ],
            ],
          ),
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

  // ==================== 底部购买栏 ====================
  Widget _buildBottomBar() {
    final p = _product;
    final total = p.displayPrice * _quantity;
    final auth = context.watch<AuthProvider>();
    final isLoggedIn = auth.isLoggedIn;

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
                  Text('¥${total.toStringAsFixed(7).replaceAll(RegExp(r'\.?0+$'), '')}',
                    style: TextStyle(color: _primaryColor, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            SizedBox(
              width: 160,
              height: 48,
              child: ElevatedButton(
                onPressed: _isBuying || _product.isOpen == false ? null : _buy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _product.isOpen ? _primaryColor : Colors.grey[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey[800],
                ),
                child: _isBuying
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        _product.isOpen ? '立即购买' : '商品已下架',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Toast覆盖层 ====================
  Widget _buildToastOverlay() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _toastSuccess ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _toastSuccess ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _toastSuccess ? Icons.check_circle : Icons.error,
                color: Colors.white, size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _toastSuccess ? '购买成功！' : '购买失败',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    if (_toastOrderId.isNotEmpty)
                      Text('订单号: $_toastOrderId',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                    if (!_toastSuccess && _toastMessage.isNotEmpty)
                      Text(_toastMessage,
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _dismissToast,
                child: Icon(Icons.close, color: Colors.white.withOpacity(0.6), size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}
