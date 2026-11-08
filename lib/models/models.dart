// lib/models/models.dart

class CategoryModel {
  final int id;
  final String name;
  final String iconUrl;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconUrl,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      iconUrl: json['iconUrl'] ?? '',
    );
  }
}

class FoodItemModel {
  final int id;
  final int restaurantId;
  final int categoryId;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final bool isAvailable;
  final bool isBestSeller;

  FoodItemModel({
    required this.id,
    required this.restaurantId,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.isAvailable = true,
    this.isBestSeller = false,
  });

  factory FoodItemModel.fromJson(Map<String, dynamic> json) {
    return FoodItemModel(
      id: json['id'] ?? 0,
      restaurantId: json['restaurantId'] ?? 0,
      categoryId: json['categoryId'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'] ?? '',
      isAvailable: json['isAvailable'] ?? true,
      isBestSeller: json['isBestSeller'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'isBestSeller': isBestSeller,
    };
  }
}

class RestaurantModel {
  final int id;
  final String name;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final double rating;
  final int totalReviews;
  final String openTime;
  final String closeTime;
  final double distanceKm;
  final int estimatedDeliveryMinutes;
  final double deliveryFee;
  final List<FoodItemModel> menuItems;

  RestaurantModel({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    this.rating = 4.8,
    this.totalReviews = 100,
    this.openTime = '07:00',
    this.closeTime = '22:00',
    this.distanceKm = 1.5,
    this.estimatedDeliveryMinutes = 20,
    this.deliveryFee = 15000,
    this.menuItems = const [],
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    var rawMenu = json['menuItems'] as List? ?? [];
    return RestaurantModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 10.7769,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 106.7009,
      imageUrl: json['imageUrl'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      totalReviews: json['totalReviews'] ?? 100,
      openTime: json['openTime'] ?? '07:00',
      closeTime: json['closeTime'] ?? '22:00',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 1.5,
      estimatedDeliveryMinutes: json['estimatedDeliveryMinutes'] ?? 20,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 15000,
      menuItems: rawMenu.map((m) => FoodItemModel.fromJson(m)).toList(),
    );
  }
}

class CartItemModel {
  final FoodItemModel foodItem;
  final int restaurantId;
  final String restaurantName;
  int quantity;
  String? note;
  String size;
  String sweetness;
  String ice;
  List<String> toppings;

  CartItemModel({
    required this.foodItem,
    required this.restaurantId,
    required this.restaurantName,
    this.quantity = 1,
    this.note,
    this.size = 'Vừa (M)',
    this.sweetness = '100% Đường',
    this.ice = 'Bình thường',
    this.toppings = const [],
  });

  double get unitPrice {
    double base = foodItem.price;
    if (size == 'Lớn (L)') base += 10000;
    base += toppings.length * 8000;
    return base;
  }

  double get totalPrice => unitPrice * quantity;
}

enum OrderStatusEnum {
  pending,
  confirmed,
  cooking,
  delivering,
  completed,
  cancelled
}

class OrderModel {
  final int id;
  final int restaurantId;
  final String restaurantName;
  final String restaurantImage;
  final double restaurantLat;
  final double restaurantLng;
  final double totalAmount;
  final double shippingFee;
  final String status;
  final String paymentMethod;
  final bool isPaid;
  final String deliveryAddress;
  final double deliveryLat;
  final double deliveryLng;
  final String driverName;
  final String driverPhone;
  final DateTime createdAt;
  final List<CartItemModel> items;

  OrderModel({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantImage,
    required this.restaurantLat,
    required this.restaurantLng,
    required this.totalAmount,
    required this.shippingFee,
    required this.status,
    required this.paymentMethod,
    required this.isPaid,
    required this.deliveryAddress,
    required this.deliveryLat,
    required this.deliveryLng,
    this.driverName = 'Nguyễn Văn Tài (Shipper)',
    this.driverPhone = '0987654321',
    required this.createdAt,
    this.items = const [],
  });
}

class TrackingNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String type; // 'order', 'location', 'arrived', 'completed'

  TrackingNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
  });
}

class UserModel {
  final int id;
  final String fullName;
  final String phoneNumber;
  final String email;
  final String role; // 'Customer', 'Driver', 'RestaurantOwner', 'Admin'
  final String? avatarUrl;
  final String? address;

  UserModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    this.role = 'Customer',
    this.avatarUrl,
    this.address,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'Customer',
      avatarUrl: json['avatarUrl'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'role': role,
      'avatarUrl': avatarUrl,
      'address': address,
    };
  }
}

class AuthResponseModel {
  final String token;
  final UserModel user;

  AuthResponseModel({
    required this.token,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      token: json['token'] ?? '',
      user: UserModel.fromJson(json['user'] ?? {}),
    );
  }
}

class ReviewModel {
  final int id;
  final int restaurantId;
  final String userName;
  final String userAvatar;
  final int rating; // 1 to 5 stars
  final String comment;
  final List<String> tags;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.restaurantId,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.comment,
    this.tags = const [],
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? 0,
      restaurantId: json['restaurantId'] ?? 0,
      userName: json['userName'] ?? 'Khách hàng',
      userAvatar: json['userAvatar'] ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      rating: json['rating'] ?? 5,
      comment: json['comment'] ?? '',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'userName': userName,
      'userAvatar': userAvatar,
      'rating': rating,
      'comment': comment,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
