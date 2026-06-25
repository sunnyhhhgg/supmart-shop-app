/// 系统公告模型
class Announcement {
  final int id;
  final String title;
  final String content;
  final String createdAt;
  final String? status;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.status,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] ?? 0,
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? json['create_time']?.toString() ?? '',
      status: json['status']?.toString(),
    );
  }
}
