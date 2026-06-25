/// 商品分类
class Category {
  final int id;
  final String name;
  final int sort;

  Category({
    required this.id,
    required this.name,
    required this.sort,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      sort: json['sort'] ?? 0,
    );
  }
}
