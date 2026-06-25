import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../models/wallet_record.dart';
import '../services/api_service.dart';

/// 我的钱包 — 资金流水/充值记录/提现记录/发起提现
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final wp = context.read<WalletProvider>();
    wp.loadCapitalFlow(refresh: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的钱包'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                '余额: ¥${auth.balance.toStringAsFixed(2)}',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '资金流水'),
            Tab(text: '充值记录'),
            Tab(text: '提现记录'),
          ],
          onTap: (i) {
            final wp = context.read<WalletProvider>();
            if (i == 0) wp.loadCapitalFlow(refresh: true);
            if (i == 1) wp.loadRechargeRecords(refresh: true);
            if (i == 2) wp.loadWithdrawRecords(refresh: true);
          },
        ),
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wp, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildCapitalFlowList(context, wp),
              _buildRechargeList(context, wp, auth),
              _buildWithdrawList(context, wp, auth),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCapitalFlowList(BuildContext context, WalletProvider wp) {
    if (wp.isLoading && wp.capitalFlows.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (wp.capitalFlows.isEmpty) {
      return _buildEmpty('暂无资金流水');
    }
    return RefreshIndicator(
      onRefresh: () => wp.loadCapitalFlow(refresh: true),
      child: ListView.builder(
        itemCount: wp.capitalFlows.length + (wp.hasMoreCapital ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= wp.capitalFlows.length) {
            wp.loadCapitalFlow();
            return const Center(child: Padding(
              padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ));
          }
          final flow = wp.capitalFlows[index];
          final isPositive = flow.type == 'recharge' || flow.type == 'refund' || flow.type == 'commission' || flow.type == 'admin_recharge';
          return ListTile(
            dense: true,
            leading: Icon(
              isPositive ? Icons.arrow_downward : Icons.arrow_upward,
              color: isPositive ? Colors.green[400] : Colors.red[400],
              size: 20,
            ),
            title: Text(flow.typeText, style: const TextStyle(fontSize: 14)),
            subtitle: Text(
              flow.remark.isNotEmpty ? flow.remark : (flow.createdAt.isNotEmpty ? _fmtTime(flow.createdAt) : ''),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            trailing: Text(
              '${isPositive ? '+' : ''}${flow.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isPositive ? Colors.green[400] : Colors.red[400],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRechargeList(BuildContext context, WalletProvider wp, AuthProvider auth) {
    return _buildListWithAction(
      wp.rechargeRecords,
      wp.isLoading,
      wp.hasMoreRecharge,
      () => wp.loadRechargeRecords(refresh: true),
      () => wp.loadRechargeRecords(),
      '暂无充值记录',
      (item) {
        final r = item as RechargeRecord;
        final isSuccess = r.statusText == '已完成';
        return ListTile(
          dense: true,
          leading: Icon(isSuccess ? Icons.check_circle : Icons.access_time, color: isSuccess ? Colors.green[400] : Colors.orange[400], size: 22),
          title: Text('${r.amount.toStringAsFixed(2)} 元', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          subtitle: Text('${r.statusText}  ${_fmtTime(r.createdAt)}', style: const TextStyle(fontSize: 12)),
          trailing: r.statusText == '待支付' ? TextButton(
            child: const Text('去支付', style: TextStyle(fontSize: 13)),
            onPressed: () => _showRechargeDialog(context, auth),
          ) : null,
        );
      },
      bottomButton: TextButton.icon(
        icon: const Icon(Icons.add_circle_outline, size: 18),
        label: const Text('发起充值'),
        onPressed: () => _showRechargeDialog(context, auth),
      ),
    );
  }

  Widget _buildWithdrawList(BuildContext context, WalletProvider wp, AuthProvider auth) {
    return _buildListWithAction(
      wp.withdrawRecords,
      wp.isLoading,
      wp.hasMoreWithdraw,
      () => wp.loadWithdrawRecords(refresh: true),
      () => wp.loadWithdrawRecords(),
      '暂无提现记录',
      (item) {
        final w = item as WithdrawRecord;
        Color color;
        switch (w.status) {
          case '1': color = Colors.green; break;
          case '2': color = Colors.red; break;
          default: color = Colors.orange;
        }
        return ListTile(
          dense: true,
          leading: Icon(Icons.monetization_on, color: color, size: 22),
          title: Text('${w.amount.toStringAsFixed(2)} 元', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          subtitle: Text('${w.statusText}  ${_fmtTime(w.createdAt)}', style: const TextStyle(fontSize: 12)),
          trailing: Text(w.statusText, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        );
      },
      bottomButton: TextButton.icon(
        icon: const Icon(Icons.send, size: 18),
        label: const Text('发起提现'),
        onPressed: () => _showWithdrawDialog(context, auth),
      ),
    );
  }

  Widget _buildListWithAction<T>(
    List<T> items,
    bool loading,
    bool hasMore,
    Future<void> Function() onRefresh,
    VoidCallback onLoadMore,
    String emptyText,
    Widget Function(T) itemBuilder, {
    Widget? bottomButton,
  }) {
    if (loading && items.isEmpty) return const Center(child: CircularProgressIndicator());
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey[700]),
            const SizedBox(height: 8),
            Text(emptyText, style: TextStyle(color: Colors.grey[500])),
            if (bottomButton != null) ...[const SizedBox(height: 16), bottomButton],
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        itemCount: items.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            onLoadMore();
            return const Center(child: Padding(
              padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ));
          }
          return itemBuilder(items[index]);
        },
      ),
    );
  }

  Widget _buildEmpty(String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox, size: 48, color: Colors.grey[700]),
          const SizedBox(height: 8),
          Text(text, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  void _showRechargeDialog(BuildContext context, AuthProvider auth) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('充值'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('目前不支持在线充值，请联系管理员充值。', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '充值金额',
                border: OutlineInputBorder(),
                prefixText: '¥ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text);
              if (amount == null || amount <= 0) return;
              Navigator.pop(ctx);
              _showSnackBar('请通过后台系统完成充值', isError: false);
            },
            child: const Text('联系管理员'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, AuthProvider auth) {
    final amountCtrl = TextEditingController();
    final accountCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('发起提现'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '提现金额',
                border: OutlineInputBorder(),
                prefixText: '¥ ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: accountCtrl,
              decoration: const InputDecoration(
                labelText: '收款账户',
                border: OutlineInputBorder(),
                hintText: '支付宝/微信账号',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text);
              if (amount == null || amount <= 0) return;
              if (accountCtrl.text.trim().isEmpty) return;
              if (amount > auth.balance) {
                Navigator.pop(ctx);
                _showSnackBar('余额不足');
                return;
              }
              Navigator.pop(ctx);
              try {
                await ApiService.withdraw(amount: amount, account: accountCtrl.text.trim());
                _showSnackBar('提现申请已提交', isError: false);
                auth.refreshBalance();
                context.read<WalletProvider>().loadWithdrawRecords(refresh: true);
              } catch (e) {
                _showSnackBar('提现失败: $e');
              }
            },
            child: const Text('提交'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red[800] : Colors.green[800],
    ));
  }

  String _fmtTime(String t) {
    if (t.isEmpty) return '';
    try {
      return t.substring(0, 16).replaceAll('T', ' ');
    } catch (_) {
      return t;
    }
  }
}
