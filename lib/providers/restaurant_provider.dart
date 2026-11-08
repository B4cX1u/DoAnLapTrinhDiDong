// lib/providers/restaurant_provider.dart
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class RestaurantProvider extends ChangeNotifier {
  List<CategoryModel> _categories = [];
  List<RestaurantModel> _restaurants = [];
  int? _selectedCategoryId;
  String _searchQuery = '';
  bool _isLoading = false;

  List<CategoryModel> get categories => _categories;
  List<RestaurantModel> get restaurants => _restaurants;
  int? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  Future<void> fetchData({double? lat, double? lng}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _categories = await ApiService.getCategories();
      _restaurants = await ApiService.getRestaurants(
        lat: lat,
        lng: lng,
        categoryId: _selectedCategoryId,
        search: _searchQuery,
      );
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  void selectCategory(int? categoryId, {double? lat, double? lng}) {
    if (_selectedCategoryId == categoryId) {
      _selectedCategoryId = null; // Bỏ chọn
    } else {
      _selectedCategoryId = categoryId;
    }
    fetchData(lat: lat, lng: lng);
  }

  void search(String query, {double? lat, double? lng}) {
    _searchQuery = query;
    fetchData(lat: lat, lng: lng);
  }
}
