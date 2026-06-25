import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  List<Category> _categories = [];
  int _selectedCategoryId = 0;
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  List<Category> get categories => _categories;
  int get selectedCategoryId => _selectedCategoryId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 加载分类和商品
  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadCategories(),
        _loadProducts(categoryId: _selectedCategoryId),
      ]);
    } catch (e) {
      _error = '加载失败: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 切换分类
  Future<void> selectCategory(int categoryId) async {
    _selectedCategoryId = categoryId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    await _loadProducts(categoryId: categoryId);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadCategories() async {
    _categories = await ApiService.getCategories();
  }

  Future<void> _loadProducts({int? categoryId}) async {
    _products = await ApiService.getProducts(categoryId: categoryId);
  }
}
