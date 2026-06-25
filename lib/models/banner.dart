/// 轮播图模型
class BannerItem {
  final int id;
  final String imageUrl;
  final String? linkUrl;
  final String? title;
  final int sortOrder;

  BannerItem({
    required this.id,
    required this.imageUrl,
    this.linkUrl,
    this.title,
    this.sortOrder = 0,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      id: json['id'] ?? 0,
      imageUrl: json['image_url']?.toString() ?? '',
      linkUrl: json['link_url']?.toString(),
      title: json['title']?.toString(),
      sortOrder: json['sort_order'] ?? 0,
    );
  }
}
