import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/config_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final primaryColor = _parseColor(ConfigService.primaryColor);
    final appName = ConfigService.appName;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('个人中心', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 用户信息卡片
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor.withOpacity(0.15), const Color(0xFF151515)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryColor.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        auth.username.isNotEmpty ? auth.username[0].toUpperCase() : 'U',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(auth.username, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('余额: ', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                            Text('¥${auth.balance.toStringAsFixed(2)}',
                              style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.white.withOpacity(0.4), size: 20),
                    onPressed: () => auth.refreshBalance(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 菜单列表
            _buildMenuCard([
              _menuItem(Icons.receipt_long, '我的订单', Colors.blue, () {
                // 切换到订单Tab
                try {
                  final homeState = context.findAncestorStateOfType<HomeScreenState>();
                  homeState?.switchToTab(1);
                } catch (_) {}
              }),
              _menuItem(Icons.wallet, '余额充值', Colors.green, () {
                _showComingSoon(context, '充值功能');
              }),
            ]),

            const SizedBox(height: 16),

            // 关于
            _buildMenuCard([
              _menuItem(Icons.info_outline, '关于 $appName', Colors.grey, () {
                _showAbout(context, appName);
              }),
              _menuItem(Icons.logout, '退出登录', Colors.red, () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF1A1A1A),
                    title: const Text('确认退出', style: TextStyle(color: Colors.white)),
                    content: const Text('确定要退出登录吗？', style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确认', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }
              }),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> items) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(children: items),
    );
  }

  Widget _menuItem(IconData icon, String label, Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14))),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.2), size: 20),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature 即将开放'),
        backgroundColor: const Color(0xFF1A1A1A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAbout(BuildContext context, String appName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(appName, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('版本: ${ConfigService.config?.version ?? "1.0.0"}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('域名: ${ConfigService.baseUrl}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            if ((ConfigService.config?.updateLog ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('更新日志:', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 4),
              Text(ConfigService.config!.updateLog, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}

// HomeScreen 的 Tab 切换接口
extension _HomeScreenStateFinder on BuildContext {
  // 通过查找StatefulElement找到_HomeScreenState
}
