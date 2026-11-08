// lib/providers/favorites_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class FavoritesProvider extends ChangeNotifier {
  static const String _storageKey = 'saved_favorite_foods';
  final List<FoodItemModel> _favorites = [];

  List<FoodItemModel> get favorites => List.unmodifiable(_favorites);
  int get count => _favorites.length;

  bool isFavorite(int foodId) {
    return _favorites.any((f) => f.id == foodId);
  }

  Future<void> loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawData = prefs.getString(_storageKey);
      if (rawData != null && rawData.isNotEmpty) {
        final List list = jsonDecode(rawData);
        _favorites.clear();
        for (var item in list) {
          _favorites.add(FoodItemModel.fromJson(item));
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  Future<void> toggleFavorite(FoodItemModel food) async {
    final index = _favorites.indexWhere((f) => f.id == food.id);
    if (index >= 0) {
      _favorites.removeAt(index);
    } else {
      _favorites.add(food);
    }
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> removeFavorite(int foodId) async {
    _favorites.removeWhere((f) => f.id == foodId);
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> clearFavorites() async {
    _favorites.clear();
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(_favorites.map((f) => f.toJson()).toList());
      await prefs.setString(_storageKey, data);
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }
}

