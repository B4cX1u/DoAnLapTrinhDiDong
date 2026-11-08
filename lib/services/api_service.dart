// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  /// Danh sách IP ứng viên tự động nhận diện thiết bị:
  /// - 127.0.0.1:5000: Máy thật cắm cáp USB (đã chạy adb reverse)
  /// - 192.168.1.227:5000: Máy thật dùng chung mạng Wi-Fi với máy tính
  /// - 10.0.2.2:5000: Máy ảo Android Emulator mặc định
  /// - localhost:5000: Windows desktop / Web
  static final List<String> candidateUrls = [
    'http://127.0.0.1:5000/api',
    'http://192.168.1.227:5000/api',
    'http://10.0.2.2:5000/api',
    'http://localhost:5000/api',
  ];

  static String _activeBaseUrl = 'http://127.0.0.1:5000/api';
  static bool _hasProbed = false;
  static const Duration timeoutDuration = Duration(seconds: 10);

  static String get baseUrl => _activeBaseUrl;

  /// Tự động dò tìm URL kết nối thành công nhanh nhất giữa máy thật & máy ảo
  static Future<String> getBaseUrl({bool forceRefresh = false}) async {
    if (_hasProbed && !forceRefresh) return _activeBaseUrl;

    try {
      final futures = candidateUrls.map((candidate) async {
        try {
          final res = await http
              .get(Uri.parse('$candidate/categories'))
              .timeout(const Duration(milliseconds: 2500));
          if (res.statusCode == 200) {
            return candidate;
          }
        } catch (_) {}
        return null;
      });

      final results = await Future.wait(futures);
      final found = results.firstWhere((r) => r != null, orElse: () => null);
      if (found != null) {
        _activeBaseUrl = found;
        _hasProbed = true;
        return _activeBaseUrl;
      }
    } catch (_) {}

    _hasProbed = true;
    return _activeBaseUrl;
  }

  /// Lấy danh sách danh mục món ăn
  static Future<List<CategoryModel>> getCategories() async {
    final currentBase = await getBaseUrl();
    try {
      final response = await http
          .get(Uri.parse('$currentBase/categories'))
          .timeout(timeoutDuration);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => CategoryModel.fromJson(e)).toList();
      }
    } catch (_) {}

    // Dữ liệu mẫu phong phú khi chạy offline / chưa bật backend C#
    return [
      CategoryModel(id: 1, name: "Cơm", iconUrl: "https://cdn-icons-png.flaticon.com/512/3170/3170733.png"),
      CategoryModel(id: 2, name: "Bún & Phở", iconUrl: "https://cdn-icons-png.flaticon.com/512/2718/2718224.png"),
      CategoryModel(id: 3, name: "Trà Sữa & Cafe", iconUrl: "https://cdn-icons-png.flaticon.com/512/924/924514.png"),
      CategoryModel(id: 4, name: "Đồ Ăn Nhanh", iconUrl: "https://cdn-icons-png.flaticon.com/512/737/737967.png"),
      CategoryModel(id: 5, name: "Ăn Vặt", iconUrl: "https://cdn-icons-png.flaticon.com/512/3081/3081840.png"),
    ];
  }

  /// Lấy danh sách quán ăn (truyền tọa độ GPS để C# backend tính khoảng cách Haversine)
  static Future<List<RestaurantModel>> getRestaurants({
    double? lat,
    double? lng,
    int? categoryId,
    String? search,
  }) async {
    final currentBase = await getBaseUrl();
    try {
      String query = '?lat=${lat ?? 10.7769}&lng=${lng ?? 106.7009}';
      if (categoryId != null) query += '&categoryId=$categoryId';
      if (search != null && search.isNotEmpty) query += '&search=$search';

      final response = await http
          .get(Uri.parse('$currentBase/restaurants$query'))
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => RestaurantModel.fromJson(e)).toList();
      }
    } catch (_) {}

    // Dữ liệu mẫu chuẩn khi chạy offline
    return _getMockRestaurants(categoryId: categoryId, search: search);
  }

  /// Tạo đơn hàng sang C# Web API
  static Future<int> createOrder({
    required int restaurantId,
    required String deliveryAddress,
    required double deliveryLat,
    required double deliveryLng,
    required String paymentMethod,
    required List<CartItemModel> items,
  }) async {
    final currentBase = await getBaseUrl();
    try {
      final body = jsonEncode({
        "userId": 1,
        "restaurantId": restaurantId,
        "deliveryAddress": deliveryAddress,
        "deliveryLatitude": deliveryLat,
        "deliveryLongitude": deliveryLng,
        "paymentMethod": paymentMethod,
        "items": items.map((i) => {
          "menuItemId": i.foodItem.id,
          "quantity": i.quantity,
          "note": i.note
        }).toList()
      });

      final response = await http
          .post(
            Uri.parse('$currentBase/orders'),
            headers: {"Content-Type": "application/json"},
            body: body,
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id'] ?? DateTime.now().millisecondsSinceEpoch % 10000;
      }
    } catch (_) {}

    // ID đơn hàng ngẫu nhiên nếu offline
    return DateTime.now().millisecondsSinceEpoch % 10000;
  }

  /// Gọi C# API sinh URL thanh toán VNPay có kèm mã hóa HMAC-SHA512
  static Future<String> createVnPayUrl(int orderId) async {
    final currentBase = await getBaseUrl();
    try {
      final response = await http
          .post(
            Uri.parse('$currentBase/payments/create-vnpay-url'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"orderId": orderId}),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['paymentUrl'] ?? '';
      }
    } catch (_) {}

    return 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?orderId=$orderId';
  }

  /// Đăng nhập tài khoản (Gọi C# JWT Auth - 100% xác thực thực tế từ Database)
  static Future<AuthResponseModel> login({
    required String emailOrPhone,
    required String password,
  }) async {
    var currentBase = await getBaseUrl();
    try {
      final response = await http
          .post(
            Uri.parse('$currentBase/auth/login'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "emailOrPhone": emailOrPhone,
              "password": password,
            }),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AuthResponseModel.fromJson(data);
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Tài khoản chưa được đăng ký hoặc sai mật khẩu');
      }
    } on Exception catch (e) {
      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('TimeoutException')) {
        // Thử lại nếu vừa đổi mạng hoặc vừa cắm cáp USB
        final refreshedBase = await getBaseUrl(forceRefresh: true);
        if (refreshedBase != currentBase) {
          return login(emailOrPhone: emailOrPhone, password: password);
        }
        throw Exception('Không thể kết nối đến máy chủ C# API ($currentBase). Vui lòng kiểm tra backend đã chạy.');
      }
      rethrow;
    }
  }

  /// Đăng ký tài khoản mới (Lưu trực tiếp vào C# Database SQLite)
  static Future<AuthResponseModel> register({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String password,
  }) async {
    var currentBase = await getBaseUrl();
    try {
      final response = await http
          .post(
            Uri.parse('$currentBase/auth/register'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "fullName": fullName,
              "phoneNumber": phoneNumber,
              "email": email,
              "password": password,
            }),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return AuthResponseModel.fromJson(data);
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Đăng ký tài khoản không thành công');
      }
    } on Exception catch (e) {
      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('TimeoutException')) {
        // Thử lại nếu vừa đổi mạng hoặc vừa cắm cáp USB
        final refreshedBase = await getBaseUrl(forceRefresh: true);
        if (refreshedBase != currentBase) {
          return register(fullName: fullName, phoneNumber: phoneNumber, email: email, password: password);
        }
        throw Exception('Không thể kết nối đến máy chủ C# API ($currentBase). Vui lòng kiểm tra backend đã chạy.');
      }
      rethrow;
    }
  }

  static List<RestaurantModel> _getMockRestaurants({int? categoryId, String? search}) {
    final list = [
      RestaurantModel(
        id: 1,
        name: "Cơm Tấm Ba Ghiền - Đặng Văn Ngữ",
        description: "Cơm tấm sườn nướng siêu to khổng lồ gia truyền",
        address: "84 Đặng Văn Ngữ, Phú Nhuận, TP.HCM",
        latitude: 10.7925,
        longitude: 106.6715,
        imageUrl: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600",
        rating: 4.9,
        totalReviews: 450,
        distanceKm: 1.2,
        estimatedDeliveryMinutes: 20,
        deliveryFee: 15000,
        menuItems: [
          FoodItemModel(
            id: 1,
            restaurantId: 1,
            categoryId: 1,
            name: "Cơm Tấm Sườn Bì Chả Đặc Biệt",
            description: "Sườn cây nướng mềm mật ong, bì thơm, chả trứng béo ngậy kèm canh nóng",
            price: 65000,
            imageUrl: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500",
            isBestSeller: true,
          ),
          FoodItemModel(
            id: 2,
            restaurantId: 1,
            categoryId: 1,
            name: "Cơm Tấm Sườn Cốt Lết Ốp La",
            description: "Sườn cốt lết dày thịt, 1 trứng ốp la lòng đào tan chảy, mỡ hành tép mỡ giòn",
            price: 55000,
            imageUrl: "https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=500",
          ),
        ],
      ),
      RestaurantModel(
        id: 2,
        name: "Phúc Long Tea & Coffee - Đồng Khởi",
        description: "Đậm vị trà truyền thống, trà đào cam sả và trà sữa Ô Long",
        address: "63 Đồng Khởi, Quận 1, TP.HCM",
        latitude: 10.7761,
        longitude: 106.7027,
        imageUrl: "https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=600",
        rating: 4.8,
        totalReviews: 320,
        distanceKm: 0.8,
        estimatedDeliveryMinutes: 15,
        deliveryFee: 15000,
        menuItems: [
          FoodItemModel(
            id: 3,
            restaurantId: 2,
            categoryId: 3,
            name: "Trà Đào Cam Sả Đặc Biệt",
            description: "Vị trà thanh mát hòa quyện cam vàng mọng, hương sả nồng nàn",
            price: 50000,
            imageUrl: "https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=500",
            isBestSeller: true,
          ),
          FoodItemModel(
            id: 4,
            restaurantId: 2,
            categoryId: 3,
            name: "Trà Sữa Ô Long Phúc Long",
            description: "Hương thơm trà Ô Long rang đậm đà kết hợp với sữa béo thanh tao",
            price: 55000,
            imageUrl: "https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=500",
            isBestSeller: true,
          ),
        ],
      ),
      RestaurantModel(
        id: 3,
        name: "Phở Bò Gia Truyền Hà Nội",
        description: "Nước dùng xương hầm 24 tiếng, bò tái lăn đậm đà chuẩn vị Bắc",
        address: "19 Pasteur, Quận 1, TP.HCM",
        latitude: 10.7715,
        longitude: 106.7001,
        imageUrl: "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=600",
        rating: 4.7,
        totalReviews: 195,
        distanceKm: 1.8,
        estimatedDeliveryMinutes: 25,
        deliveryFee: 18000,
        menuItems: [
          FoodItemModel(
            id: 5,
            restaurantId: 3,
            categoryId: 2,
            name: "Phở Bò Tái Lăn Hà Nội",
            description: "Thịt bò xào lăn tỏi gừng thơm lừng, hành hoa ngập bát",
            price: 60000,
            imageUrl: "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500",
            isBestSeller: true,
          ),
        ],
      ),
      RestaurantModel(
        id: 4,
        name: "Crispy Burger & Fried Chicken",
        description: "Burger bò phô mai tan chảy & gà rán giòn rụm sốt cay Hàn Quốc",
        address: "120 Hai Bà Trưng, Quận 1, TP.HCM",
        latitude: 10.7842,
        longitude: 106.6978,
        imageUrl: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600",
        rating: 4.6,
        totalReviews: 210,
        distanceKm: 2.3,
        estimatedDeliveryMinutes: 25,
        deliveryFee: 20000,
        menuItems: [
          FoodItemModel(
            id: 6,
            restaurantId: 4,
            categoryId: 4,
            name: "Combo Burger Bò Phô Mai + Khoai Tây",
            description: "Burger thịt bò nướng than hoa, phô mai Cheddar kép kèm khoai tây chiên",
            price: 89000,
            imageUrl: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500",
            isBestSeller: true,
          ),
        ],
      ),
      RestaurantModel(
        id: 5,
        name: "Bánh Mì Huỳnh Hoa - Lê Thị Riêng",
        description: "Bánh mì nức tiếng Sài Gòn, ngập tràn 5 loại thịt nguội, pate bơ tươi",
        address: "26 Lê Thị Riêng, Quận 1, TP.HCM",
        latitude: 10.7709,
        longitude: 106.6925,
        imageUrl: "https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=600",
        rating: 4.9,
        totalReviews: 580,
        distanceKm: 0.9,
        estimatedDeliveryMinutes: 15,
        deliveryFee: 15000,
        menuItems: [
          FoodItemModel(
            id: 12,
            restaurantId: 5,
            categoryId: 5,
            name: "Bánh Mì Đặc Biệt Huỳnh Hoa",
            description: "Bánh mì kẹp 5 loại thịt nguội hảo hạng, chả lụa, bơ tươi và pate gan gia truyền",
            price: 68000,
            imageUrl: "https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=500",
            isBestSeller: true,
          ),
          FoodItemModel(
            id: 13,
            restaurantId: 5,
            categoryId: 5,
            name: "Bánh Mì Xíu Mại Trứng Muối",
            description: "Xíu mại thịt heo mềm ngập sốt cà chua và trứng muối bùi bùi",
            price: 55000,
            imageUrl: "https://images.unsplash.com/photo-1509722747041-616f39b57569?w=500",
          ),
        ],
      ),
      RestaurantModel(
        id: 6,
        name: "Highlands Coffee - Phố Đi Bộ Nguyễn Huệ",
        description: "Phindi Hạnh Nhân thơm béo, Freeze Trà Xanh mát lạnh chuẩn vị cà phê Việt",
        address: "135 Nguyễn Huệ, Quận 1, TP.HCM",
        latitude: 10.7735,
        longitude: 106.7038,
        imageUrl: "https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=600",
        rating: 4.8,
        totalReviews: 390,
        distanceKm: 0.3,
        estimatedDeliveryMinutes: 10,
        deliveryFee: 15000,
        menuItems: [
          FoodItemModel(
            id: 14,
            restaurantId: 6,
            categoryId: 3,
            name: "Phindi Hạnh Nhân (Size L)",
            description: "Cà phê phin thế hệ mới kết hợp sốt hạnh nhân thơm béo và sữa tươi",
            price: 49000,
            imageUrl: "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=500",
            isBestSeller: true,
          ),
          FoodItemModel(
            id: 15,
            restaurantId: 6,
            categoryId: 3,
            name: "Freeze Trà Xanh Thạch (Size L)",
            description: "Trà xanh đá xay thơm ngát, thạch trà giòn dai mát lạnh kèm kem whipping",
            price: 59000,
            imageUrl: "https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=500",
            isBestSeller: true,
          ),
        ],
      ),
      RestaurantModel(
        id: 7,
        name: "Katinat Saigon Kafe - Đồng Khởi",
        description: "Trà Sữa Chôm Chôm giòn ngọt, Trà Oolong Tứ Quý Bơ thơm lừng",
        address: "91 Đồng Khởi, Quận 1, TP.HCM",
        latitude: 10.7758,
        longitude: 106.7042,
        imageUrl: "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=600",
        rating: 4.7,
        totalReviews: 340,
        distanceKm: 0.5,
        estimatedDeliveryMinutes: 12,
        deliveryFee: 15000,
        menuItems: [
          FoodItemModel(
            id: 17,
            restaurantId: 7,
            categoryId: 3,
            name: "Trà Sữa Chôm Chôm Katinat",
            description: "Trà sữa đậm đà hòa quyện cùng topping chôm chôm tươi giòn ngọt lịm",
            price: 58000,
            imageUrl: "https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=500",
            isBestSeller: true,
          ),
        ],
      ),
      RestaurantModel(
        id: 8,
        name: "Pizza 4P's - Bến Thành",
        description: "Pizza phô mai Burrata tươi béo ngậy nướng củi thủ công chuẩn phong cách Nhật - Ý",
        address: "8 Thủ Khoa Huân, Quận 1, TP.HCM",
        latitude: 10.7731,
        longitude: 106.6968,
        imageUrl: "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600",
        rating: 4.9,
        totalReviews: 620,
        distanceKm: 1.1,
        estimatedDeliveryMinutes: 22,
        deliveryFee: 18000,
        menuItems: [
          FoodItemModel(
            id: 19,
            restaurantId: 8,
            categoryId: 4,
            name: "Pizza Phô Mai Burrata Parma Ham",
            description: "Phô mai Burrata tươi nguyên quả béo ngậy, thịt nguội Parma Ham trứ danh",
            price: 220000,
            imageUrl: "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500",
            isBestSeller: true,
          ),
          FoodItemModel(
            id: 20,
            restaurantId: 8,
            categoryId: 4,
            name: "Mì Ý Cua Sốt Kem Cà Chua",
            description: "Thịt cua biển tươi ngọt béo ngậy hòa quyện cùng sốt kem cà chua thơm bùi",
            price: 185000,
            imageUrl: "https://images.unsplash.com/photo-1551183053-bf91a1d81141?w=500",
            isBestSeller: true,
          ),
        ],
      ),
      RestaurantModel(
        id: 9,
        name: "Bún Bò Huế Đông Ba - Nguyễn Du",
        description: "Nước dùng ruốc sả thơm nồng cố đô, bắp bò hoa giòn, chả cua Huế hấp",
        address: "110A Nguyễn Du, Quận 1, TP.HCM",
        latitude: 10.7770,
        longitude: 106.6950,
        imageUrl: "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=600",
        rating: 4.8,
        totalReviews: 270,
        distanceKm: 1.4,
        estimatedDeliveryMinutes: 20,
        deliveryFee: 16000,
        menuItems: [
          FoodItemModel(
            id: 21,
            restaurantId: 9,
            categoryId: 2,
            name: "Bún Bò Huế Thập Cẩm Đặc Biệt",
            description: "Bắp bò hoa giòn, nạm bò mềm, giò heo rút xương, chả cua Huế và tiết bò",
            price: 65000,
            imageUrl: "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=500",
            isBestSeller: true,
          ),
        ],
      ),
      RestaurantModel(
        id: 10,
        name: "Gà Rán Jollibee - Vincom Đồng Khởi",
        description: "Gà Giòn Vui Vẻ da vàng giòn rụm, Mì Ý sốt bò bằm cà chua béo ngậy",
        address: "72 Lê Thánh Tôn, Quận 1, TP.HCM",
        latitude: 10.7780,
        longitude: 106.7018,
        imageUrl: "https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=600",
        rating: 4.6,
        totalReviews: 410,
        distanceKm: 0.6,
        estimatedDeliveryMinutes: 15,
        deliveryFee: 15000,
        menuItems: [
          FoodItemModel(
            id: 23,
            restaurantId: 10,
            categoryId: 4,
            name: "Combo 2 Miếng Gà Giòn Vui Vẻ",
            description: "Lớp vỏ bột giòn rụm vàng ươm, thịt gà bên trong mềm mọng nước chấm sốt Gravy",
            price: 75000,
            imageUrl: "https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=500",
            isBestSeller: true,
          ),
          FoodItemModel(
            id: 24,
            restaurantId: 10,
            categoryId: 4,
            name: "Mì Ý Sốt Bò Bằm Jollibee",
            description: "Mì Ý dai ngon ngập tràn sốt cà chua thịt bò bằm béo ngậy kèm xúc xích",
            price: 40000,
            imageUrl: "https://images.unsplash.com/photo-1551183053-bf91a1d81141?w=500",
            isBestSeller: true,
          ),
        ],
      ),
    ];

    if (categoryId != null) {
      return list.where((r) => r.menuItems.any((m) => m.categoryId == categoryId)).toList();
    }
    if (search != null && search.isNotEmpty) {
      final s = search.toLowerCase();
      return list.where((r) => r.name.toLowerCase().contains(s) || r.menuItems.any((m) => m.name.toLowerCase().contains(s))).toList();
    }
    return list;
  }
}
