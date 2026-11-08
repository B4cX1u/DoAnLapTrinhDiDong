// lib/providers/cart_provider.dart
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItemModel> _items = [];
  int? _restaurantId;
  String _restaurantName = '';
  String? _appliedVoucher;
  double _discountAmount = 0.0;
  final double _shippingFee = 15000.0;

  List<CartItemModel> get items => _items;
  int? get restaurantId => _restaurantId;
  String get restaurantName => _restaurantName;
  String? get appliedVoucher => _appliedVoucher;
  double get discountAmount => _discountAmount;
  double get shippingFee => _items.isEmpty ? 0.0 : _shippingFee;

  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get totalAmount {
    if (_items.isEmpty) return 0.0;
    double total = subtotal + shippingFee - _discountAmount;
    return total > 0 ? total : 0.0;
  }

  /// Thêm món vào giỏ hàng (Kiểm tra nếu khác quán ăn thì cảnh báo/xóa giỏ cũ)
  bool addToCart(CartItemModel newItem) {
    if (_restaurantId != null && _restaurantId != newItem.restaurantId && _items.isNotEmpty) {
      return false; // Báo hiệu giỏ hàng đang chứa món của quán khác
    }

    _restaurantId = newItem.restaurantId;
    _restaurantName = newItem.restaurantName;

    // Kiểm tra xem đã có món cùng ID, cùng Size, Topping chưa
    int existingIndex = _items.indexWhere((item) =>
        item.foodItem.id == newItem.foodItem.id &&
        item.size == newItem.size &&
        listEquals(item.toppings, newItem.toppings));

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += newItem.quantity;
    } else {
      _items.add(newItem);
    }

    notifyListeners();
    return true;
  }

  void forceAddToCart(CartItemModel newItem) {
    _items.clear();
    _restaurantId = newItem.restaurantId;
    _restaurantName = newItem.restaurantName;
    _items.add(newItem);
    notifyListeners();
  }

  void incrementQuantity(int index) {
    if (index >= 0 && index < _items.length) {
      _items[index].quantity++;
      notifyListeners();
    }
  }

  void decrementQuantity(int index) {
    if (index >= 0 && index < _items.length) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
        if (_items.isEmpty) {
          _restaurantId = null;
          _restaurantName = '';
        }
      }
      notifyListeners();
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      if (_items.isEmpty) {
        _restaurantId = null;
        _restaurantName = '';
      }
      notifyListeners();
    }
  }

  bool applyVoucher(String code) {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode == "GIAM20K" && subtotal >= 50000) {
      _appliedVoucher = cleanCode;
      _discountAmount = 20000.0;
      notifyListeners();
      return true;
    } else if (cleanCode == "FREESHIP") {
      _appliedVoucher = cleanCode;
      _discountAmount = _shippingFee;
      notifyListeners();
      return true;
    }
    return false;
  }

  void removeVoucher() {
    _appliedVoucher = null;
    _discountAmount = 0.0;
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _restaurantId = null;
    _restaurantName = '';
    _appliedVoucher = null;
    _discountAmount = 0.0;
    notifyListeners();
  }
}
