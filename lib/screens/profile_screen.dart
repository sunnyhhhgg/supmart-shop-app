import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_screen.dart';
import 'secret_key_screen.dart';
import 'substation_screen.dart';
import 'announcements_screen.dart';
import 'wallet_screen.dart';
import 'chat_screen.dart';
import 'login_screen.dart';
import '../providers/auth_provider.dart';

/// 个人中心 — 完整的功能入口列表
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _toPage(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('我的', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async => auth.refreshBalance(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ===== 用户信息卡片 =====
            _buildUserCard(context, auth),
            const SizedBox(height: 16),

            // ===== 核心功能 (9宫格) =====
            _buildGridSection(context, auth, theme),
            const SizedBox(height: 16),

            // ===== 钱包快捷操作 =====
            _buildWalletSection(context, auth),
            const SizedBox(height: 16),

            // ===== 其他功能 =====
            _buildMenuSection(context, auth, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary.withOpacity(0.15), Colors.transparent],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            child: Text(
              (auth.username.isNotEmpty ? auth.username[0] : 'U').toUpperCase(),
              style: TextStyle(fontSize: 26, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(auth.username, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('余额: ', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                    GestureDetector(
                      onTap: () => auth.refreshBalance(),
                      child: Row(
                        children: [
                          Text('¥${auth.balance.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                          const SizedBox(width: 4),
                          Icon(Icons.refresh, size: 14, color: Colors.grey[500]),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[600]),
        ],
      ),
    );
  }

  Widget _buildGridSection(BuildContext context, AuthProvider auth, ThemeData theme) {
    final row1 = [
      _GridItem('我的订单', Icons.receipt_long, theme.colorScheme.primary, () {
        Navigator.popUntil(context, (route) => route.isFirst);
      }),
      _GridItem('我的钱包', Icons.account_balance_wallet, Colors.green, () => _toPage(context, WalletScreen(
        key: ValueKey('wallet_${DateTime.now().millisecondsSinceEpoch}'),
      ))),
      _GridItem('API密钥', Icons.vpn_key, Colors.blue, () => _toPage(context, const SecretKeyScreen())),
    ];
    final row2 = [
      _GridItem('分站管理', Icons.dns, Colors.purple, () => _toPage(context, const SubstationScreen())),
      _GridItem('系统公告', Icons.campaign, Colors.teal, () => _toPage(context, const AnnouncementsScreen())),
      _GridItem('账号设置', Icons.settings, Colors.blueGrey, () => _toPage(context, const SettingsScreen())),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('我的服务', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 16),
          Row(
            children: row1.map((item) {
              return Expanded(
                child: GestureDetector(
                  onTap: item.onTap,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(
                          color: item.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.icon, color: item.color, size: 22),
                      ),
                      const SizedBox(height: 6),
                      Text(item.label,
                        style: TextStyle(fontSize: 11, color: Colors.grey[300]),
                        textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: row2.map((item) {
              return Expanded(
                child: GestureDetector(
                  onTap: item.onTap,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(
                          color: item.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.icon, color: item.color, size: 22),
                      ),
                      const SizedBox(height: 6),
                      Text(item.label,
                        style: TextStyle(fontSize: 11, color: Colors.grey[300]),
                        textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletSection(BuildContext context, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _toPage(context, WalletScreen(
                key: ValueKey('wallet_capital_${DateTime.now().millisecondsSinceEpoch}'),
              )),
              child: _buildWalletAction(Icons.receipt, '资金流水', Colors.blue),
            ),
          ),
          Container(width: 1, height: 32, color: Colors.white.withOpacity(0.06)),
          Expanded(
            child: GestureDetector(
              onTap: () {
                // 充值需要联系管理员
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('请联系管理员充值', style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.orange[800],
                  ),
                );
              },
              child: _buildWalletAction(Icons.add_circle_outline, '充值', Colors.green),
            ),
          ),
          Container(width: 1, height: 32, color: Colors.white.withOpacity(0.06)),
          Expanded(
            child: GestureDetector(
              onTap: () => _toPage(context, WalletScreen(
                key: ValueKey('wallet_withdraw_${DateTime.now().millisecondsSinceEpoch}'),
              )),
              child: _buildWalletAction(Icons.send, '提现', Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletAction(IconData icon, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[300])),
      ],
    );
  }

  Widget _buildMenuSection(BuildContext context, AuthProvider auth, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        children: [
          _menuItem(context, Icons.headset_mic, '在线客服', Colors.blue, () {
            _toPage(context, ChatScreen(userName: auth.username));
          }),
          const Divider(height: 1, indent: 52, color: Colors.white10),
          _menuItem(context, Icons.info_outline, '关于', Colors.grey, () => _showAbout(context)),
          const Divider(height: 1, indent: 52, color: Colors.white10),
          _menuItem(context, Icons.logout, '退出登录', Colors.red[400]!, () => _logout(context, auth)),
        ],
      ),
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[600], size: 18),
      onTap: onTap,
      dense: true,
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('关于'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _aboutRow('应用名称', 'SUPMART'),
            _aboutRow('版本', '1.0.0'),
            _aboutRow('域名', '3003.online'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
        ],
      ),
    );
  }

  Widget _aboutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _logout(BuildContext context, AuthProvider auth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('退出', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      auth.logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}

class _GridItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _GridItem(this.label, this.icon, this.color, this.onTap);
}
