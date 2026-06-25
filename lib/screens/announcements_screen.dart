import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/announcement.dart';

/// 系统公告列表
class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  List<Announcement> _announcements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _announcements = await ApiService.getAnnouncements();
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('系统公告')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _announcements.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.campaign_outlined, size: 48, color: Colors.grey[700]),
                      const SizedBox(height: 8),
                      Text('暂无公告', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _announcements.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final a = _announcements[index];
                      return ExpansionTile(
                        title: Text(a.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                        subtitle: Text(_fmtTime(a.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              a.content,
                              style: const TextStyle(fontSize: 14, height: 1.6),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
    );
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
