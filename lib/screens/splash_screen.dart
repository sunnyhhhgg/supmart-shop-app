import 'package:flutter/material.dart';
import '../services/config_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _status = '正在加载配置...';
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // 尝试从公共API加载配置
    await ConfigService.loadConfig();
    setState(() => _status = '准备就绪');

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _ready = true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final splashUrl = ConfigService.config?.splashImage ?? '';
    final appName = ConfigService.appName;
    final Color primaryColor = _parseColor(ConfigService.primaryColor);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor, primaryColor.withOpacity(0.8), const Color(0xFF0F0F0F)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (splashUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  splashUrl,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildLogo(appName, primaryColor),
                ),
              )
            else
              _buildLogo(appName, primaryColor),
            const SizedBox(height: 24),
            Text(
              appName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              ConfigService.config?.description ?? '品质购物，值得信赖',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _status,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(String name, Color color) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'S',
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
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
