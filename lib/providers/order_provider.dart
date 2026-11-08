// lib/providers/order_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class OrderProvider extends ChangeNotifier {
  final List<OrderModel> _orders = [];
  OrderModel? _currentTrackingOrder;
  Timer? _statusSimulationTimer;

  // Quản lý thông báo theo dõi vị trí
  final List<TrackingNotification> _notifications = [];
  TrackingNotification? _latestNotification;
  bool _isLocationNotificationEnabled = true;
  int _unreadNotificationCount = 0;

  // Dữ liệu vị trí tài xế thời gian thực
  double _driverProgress = 0.2; // 0.0 (tại quán) -> 1.0 (tại nhà khách)
  double _distanceToCustomerKm = 1.8;
  int _etaMinutes = 15;

  List<OrderModel> get orders => _orders;
  OrderModel? get currentTrackingOrder => _currentTrackingOrder;
  List<TrackingNotification> get notifications => List.unmodifiable(_notifications);
  TrackingNotification? get latestNotification => _latestNotification;
  bool get isLocationNotificationEnabled => _isLocationNotificationEnabled;
  int get unreadNotificationCount => _unreadNotificationCount;
  double get driverProgress => _driverProgress;
  double get distanceToCustomerKm => _distanceToCustomerKm;
  int get etaMinutes => _etaMinutes;

  void toggleLocationNotification(bool enabled) {
    _isLocationNotificationEnabled = enabled;
    notifyListeners();
  }

  void dismissLatestNotification() {
    _latestNotification = null;
    notifyListeners();
  }

  void markNotificationsAsRead() {
    _unreadNotificationCount = 0;
    notifyListeners();
  }

  void _pushNotification(String title, String message, String type) {
    if (!_isLocationNotificationEnabled) return;

    final notif = TrackingNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: type,
    );

    _notifications.insert(0, notif);
    _latestNotification = notif;
    _unreadNotificationCount++;
    notifyListeners();
  }

  /// Cho phép người dùng bấm thủ công để yêu cầu cập nhật vị trí GPS tài xế
  void pingDriverLocation() {
    if (_currentTrackingOrder == null) return;
    _pushNotification(
      "📍 Tọa độ GPS Shipper",
      "Tài xế đang ở gần ${_currentTrackingOrder!.deliveryAddress} (Cách ${_distanceToCustomerKm.toStringAsFixed(1)} km - ETA $_etaMinutes phút)",
      "location",
    );
  }

  Future<OrderModel> placeOrder({
    required int restaurantId,
    required String restaurantName,
    required String restaurantImage,
    required double restaurantLat,
    required double restaurantLng,
    required String deliveryAddress,
    required double deliveryLat,
    required double deliveryLng,
    required String paymentMethod,
    required bool isPaid,
    required double totalAmount,
    required double shippingFee,
    required List<CartItemModel> items,
  }) async {
    int orderId = await ApiService.createOrder(
      restaurantId: restaurantId,
      deliveryAddress: deliveryAddress,
      deliveryLat: deliveryLat,
      deliveryLng: deliveryLng,
      paymentMethod: paymentMethod,
      items: items,
    );

    final newOrder = OrderModel(
      id: orderId,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      restaurantImage: restaurantImage,
      restaurantLat: restaurantLat,
      restaurantLng: restaurantLng,
      totalAmount: totalAmount,
      shippingFee: shippingFee,
      status: isPaid ? 'Quán đang chuẩn bị món' : 'Chờ xác nhận',
      paymentMethod: paymentMethod,
      isPaid: isPaid,
      deliveryAddress: deliveryAddress,
      deliveryLat: deliveryLat,
      deliveryLng: deliveryLng,
      createdAt: DateTime.now(),
      items: List.from(items),
    );

    _orders.insert(0, newOrder);
    _currentTrackingOrder = newOrder;
    _driverProgress = 0.15;
    _distanceToCustomerKm = 2.0;
    _etaMinutes = 18;

    // Gửi thông báo đầu tiên khi tạo đơn
    _pushNotification(
      "🔔 Đơn hàng #$orderId đã tạo",
      "Đơn hàng của bạn đã gửi đến $restaurantName. Hệ thống đang kích hoạt GPS theo dõi hành trình.",
      "order",
    );

    notifyListeners();
    _startTrackingSimulation();

    return newOrder;
  }

  void setTrackingOrder(OrderModel order) {
    _currentTrackingOrder = order;
    notifyListeners();
  }

  void _startTrackingSimulation() {
    _statusSimulationTimer?.cancel();
    int step = 0;

    _statusSimulationTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (_currentTrackingOrder == null) {
        timer.cancel();
        return;
      }

      step++;
      String nextStatus;

      if (step == 1) {
        nextStatus = 'Quán đang nấu món';
        _driverProgress = 0.25;
        _distanceToCustomerKm = 1.8;
        _etaMinutes = 15;
        _pushNotification(
          "👨‍🍳 Quán đang nấu món",
          "Bếp của ${_currentTrackingOrder!.restaurantName} đã nhận đơn và đang chuẩn bị món nóng hổi.",
          "status",
        );
      } else if (step == 2) {
        nextStatus = 'Tài xế đang giao đến bạn';
        _driverProgress = 0.50;
        _distanceToCustomerKm = 1.2;
        _etaMinutes = 9;
        _pushNotification(
          "🛵 Shipper đã nhận món",
          "Tài xế Nguyễn Văn Tài đã lấy món từ quán và bắt đầu di chuyển trên lộ trình VietMap GL (Cách bạn 1.2 km).",
          "location",
        );
      } else if (step == 3) {
        nextStatus = 'Tài xế đang giao đến bạn';
        _driverProgress = 0.85;
        _distanceToCustomerKm = 0.3;
        _etaMinutes = 2;
        _pushNotification(
          "📍 Shipper sắp đến nơi!",
          "Tài xế đang cách bạn 300m (khoảng 2 phút nữa). Vui lòng để ý điện thoại hoặc ra sảnh nhận món!",
          "location",
        );
      } else if (step == 4) {
        nextStatus = 'Giao hàng thành công';
        _driverProgress = 1.0;
        _distanceToCustomerKm = 0.0;
        _etaMinutes = 0;
        _pushNotification(
          "🎉 Đã giao hàng thành công",
          "Đơn hàng đã được giao an toàn tận tay bạn. Chúc bạn có một bữa ăn ngon miệng!",
          "completed",
        );
        timer.cancel();
      } else {
        timer.cancel();
        return;
      }

      final updatedOrder = OrderModel(
        id: _currentTrackingOrder!.id,
        restaurantId: _currentTrackingOrder!.restaurantId,
        restaurantName: _currentTrackingOrder!.restaurantName,
        restaurantImage: _currentTrackingOrder!.restaurantImage,
        restaurantLat: _currentTrackingOrder!.restaurantLat,
        restaurantLng: _currentTrackingOrder!.restaurantLng,
        totalAmount: _currentTrackingOrder!.totalAmount,
        shippingFee: _currentTrackingOrder!.shippingFee,
        status: nextStatus,
        paymentMethod: _currentTrackingOrder!.paymentMethod,
        isPaid: true,
        deliveryAddress: _currentTrackingOrder!.deliveryAddress,
        deliveryLat: _currentTrackingOrder!.deliveryLat,
        deliveryLng: _currentTrackingOrder!.deliveryLng,
        createdAt: _currentTrackingOrder!.createdAt,
        items: _currentTrackingOrder!.items,
      );

      _currentTrackingOrder = updatedOrder;

      int idx = _orders.indexWhere((o) => o.id == updatedOrder.id);
      if (idx >= 0) {
        _orders[idx] = updatedOrder;
      }

      notifyListeners();
    });
  }

  @override
  void dispose() {
    _statusSimulationTimer?.cancel();
    super.dispose();
  }
}
