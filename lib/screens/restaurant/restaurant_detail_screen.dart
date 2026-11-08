// lib/screens/restaurant/restaurant_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/review_bottom_sheet.dart';
import '../cart/cart_screen.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final RestaurantModel restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  late List<ReviewModel> _reviews;

  @override
  void initState() {
    super.initState();
    _reviews = [
      ReviewModel(
        id: 1,
        restaurantId: widget.restaurant.id,
        userName: "Nguyễn Hải Đăng",
        userAvatar: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150",
        rating: 5,
        comment: "Món ăn ngon đậm đà, giao đến nơi còn bốc khói nghi ngút. Rất hài lòng!",
        tags: ["Món ăn nóng hổi 🍲", "Đúng định lượng 👍"],
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      ReviewModel(
        id: 2,
        restaurantId: widget.restaurant.id,
        userName: "Trần Mai Phương",
        userAvatar: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150",
        rating: 5,
        comment: "Giao siêu tốc trong 15 phút, tài xế cực kỳ lịch sự và chu đáo.",
        tags: ["Giao siêu tốc ⚡", "Tài xế thân thiện 😊"],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ReviewModel(
        id: 3,
        restaurantId: widget.restaurant.id,
        userName: "Lê Hoàng Phúc",
        userAvatar: "https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150",
        rating: 4,
        comment: "Đóng gói kỹ càng, sạch sẽ. Hương vị rất vừa miệng, lần sau sẽ ủng hộ tiếp.",
        tags: ["Đóng gói cẩn thận 📦", "Hương vị chuẩn vị 😋"],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  void _openReviewSheet() {
    ReviewBottomSheet.show(
      context,
      restaurantId: widget.restaurant.id,
      restaurantName: widget.restaurant.name,
      onReviewSubmitted: (newReview) {
        setState(() {
          _reviews.insert(0, newReview);
        });
      },
    );
  }

  void _showFoodCustomizationSheet(FoodItemModel food) {
    String selectedSize = 'Vừa (M)';
    String selectedSweetness = '100% Ngọt';
    String selectedIce = 'Bình thường';
    List<String> selectedToppings = [];
    int quantity = 1;
    final noteController = TextEditingController();

    final availableToppings = widget.restaurant.id == 2
        ? ["Trân châu đen (+8k)", "Pudding trứng (+8k)", "Thạch củ năng (+8k)"]
        : ["Thêm trứng ốp la (+10k)", "Thêm chả cua (+10k)", "Thêm tép mỡ giòn (+5k)"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            double currentUnitPrice = food.price;
            if (selectedSize == 'Lớn (L)') currentUnitPrice += 10000;
            currentUnitPrice += selectedToppings.length * 8000;
            double currentTotal = currentUnitPrice * quantity;

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Thanh kéo handle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        // Ảnh và thông tin món
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                food.imageUrl,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 90,
                                  height: 90,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.fastfood, color: Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    food.name,
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currencyFormat.format(food.price),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFEA580C),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    food.description,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 32),

                        // 1. Chọn Size
                        const Text(
                          "Chọn Size (Kích cỡ)",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildChoiceChip(
                              label: "Vừa (M) - Tiêu chuẩn",
                              isSelected: selectedSize == 'Vừa (M)',
                              onSelected: () => setModalState(() => selectedSize = 'Vừa (M)'),
                            ),
                            const SizedBox(width: 10),
                            _buildChoiceChip(
                              label: "Lớn (L) (+10.000đ)",
                              isSelected: selectedSize == 'Lớn (L)',
                              onSelected: () => setModalState(() => selectedSize = 'Lớn (L)'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // 2. Tùy chỉnh (Đường & Đá nếu là đồ uống)
                        if (food.categoryId == 3) ...[
                          const Text(
                            "Độ ngọt & Lượng đá",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: ["100% Ngọt", "70% Ngọt", "50% Ngọt", "Không đường"].map((opt) {
                              return _buildChoiceChip(
                                label: opt,
                                isSelected: selectedSweetness == opt,
                                onSelected: () => setModalState(() => selectedSweetness = opt),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: ["Bình thường", "Ít đá", "Không đá"].map((opt) {
                              return _buildChoiceChip(
                                label: opt,
                                isSelected: selectedIce == opt,
                                onSelected: () => setModalState(() => selectedIce = opt),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // 3. Topping thêm
                        const Text(
                          "Món thêm / Topping",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...availableToppings.map((top) {
                          final isChecked = selectedToppings.contains(top);
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(top, style: const TextStyle(fontSize: 14)),
                            value: isChecked,
                            activeColor: const Color(0xFFEA580C),
                            onChanged: (val) {
                              setModalState(() {
                                if (val == true) {
                                  selectedToppings.add(top);
                                } else {
                                  selectedToppings.remove(top);
                                }
                              });
                            },
                          );
                        }),

                        const SizedBox(height: 12),

                        // Ghi chú cho quán
                        const Text(
                          "Ghi chú cho quán",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: noteController,
                          decoration: InputDecoration(
                            hintText: "Ví dụ: Không lấy hành, nước mắm ngọt...",
                            hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // Thanh footer: Số lượng & Nút Thêm vào giỏ
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Bộ đếm số lượng
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 18),
                                onPressed: () {
                                  if (quantity > 1) {
                                    setModalState(() => quantity--);
                                  }
                                },
                              ),
                              Text(
                                "$quantity",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 18),
                                onPressed: () => setModalState(() => quantity++),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Nút thêm vào giỏ
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final cartItem = CartItemModel(
                                foodItem: food,
                                restaurantId: widget.restaurant.id,
                                restaurantName: widget.restaurant.name,
                                quantity: quantity,
                                size: selectedSize,
                                sweetness: selectedSweetness,
                                ice: selectedIce,
                                toppings: selectedToppings,
                                note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                              );

                              final cartProvider = context.read<CartProvider>();
                              bool success = cartProvider.addToCart(cartItem);

                              Navigator.pop(ctx);

                              if (!success) {
                                // Cảnh báo giỏ hàng đã có món quán khác
                                _showConflictRestaurantDialog(cartItem);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Đã thêm '${food.name}' vào giỏ hàng!"),
                                    duration: const Duration(seconds: 1),
                                    backgroundColor: const Color(0xFFEA580C),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEA580C),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              "Thêm • ${currencyFormat.format(currentTotal)}",
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showConflictRestaurantDialog(CartItemModel newItem) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Tạo giỏ hàng mới?"),
        content: const Text(
          "Giỏ hàng hiện tại đang có món của quán khác. Bạn có muốn xóa giỏ cũ để đặt món của quán này?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CartProvider>().forceAddToCart(newItem);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Đã làm mới giỏ hàng và thêm món mới!")),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C)),
            child: const Text("Đồng ý", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFEDD5) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFEA580C) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFFEA580C) : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();
    final isCurrentRestaurantInCart = cart.restaurantId == widget.restaurant.id && cart.items.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Ảnh bìa SliverAppBar
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: const Color(0xFFEA580C),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        widget.restaurant.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.4),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Thông tin Quán ăn
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.restaurant.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.restaurant.description,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                "${widget.restaurant.rating} (${widget.restaurant.totalReviews}+ đánh giá)",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.near_me, color: Color(0xFFEA580C), size: 18),
                              const SizedBox(width: 4),
                              Text(
                                "${widget.restaurant.distanceKm} km • ${widget.restaurant.estimatedDeliveryMinutes} phút",
                                style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: Colors.grey, size: 18),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.restaurant.address,
                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Text(
                    "Thực đơn của quán",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
              ),

              // Danh sách món ăn
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, isCurrentRestaurantInCart ? 90 : 30),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final food = widget.restaurant.menuItems[index];
                      return GestureDetector(
                        onTap: () => _showFoodCustomizationSheet(food),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  food.imageUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.fastfood, color: Colors.grey),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (food.isBestSeller)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        margin: const EdgeInsets.only(bottom: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          "🔥 Bán chạy",
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                                        ),
                                      ),
                                    Text(
                                      food.name,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      food.description,
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      currencyFormat.format(food.price),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFEA580C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Nút Yêu thích & Nút + chọn món
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      favoritesProvider.isFavorite(food.id)
                                          ? Icons.favorite
                                          : Icons.favorite_border_rounded,
                                      color: favoritesProvider.isFavorite(food.id)
                                          ? Colors.red
                                          : Colors.grey,
                                      size: 22,
                                    ),
                                    onPressed: () {
                                      favoritesProvider.toggleFavorite(food);
                                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            favoritesProvider.isFavorite(food.id)
                                                ? "Đã thêm '${food.name}' vào yêu thích ❤️"
                                                : "Đã bỏ yêu thích '${food.name}'",
                                          ),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFEDD5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.add, color: Color(0xFFEA580C), size: 20),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: widget.restaurant.menuItems.length,
                  ),
                ),
              ),

              // Tiêu đề phần Đánh giá & Nhận xét
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Đánh giá từ khách hàng ⭐",
                              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${widget.restaurant.rating} / 5.0 (${widget.restaurant.totalReviews + _reviews.length} đánh giá)",
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _openReviewSheet,
                        icon: const Icon(Icons.rate_review_outlined, size: 15),
                        label: const Text("Viết đánh giá"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFECE5),
                          foregroundColor: const Color(0xFFEA580C),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Danh sách thẻ đánh giá
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, isCurrentRestaurantInCart ? 90 : 30),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final review = _reviews[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundImage: NetworkImage(review.userAvatar),
                                  backgroundColor: Colors.grey[200],
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        review.userName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateFormat('dd/MM/yyyy HH:mm').format(review.createdAt),
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: List.generate(
                                    5,
                                    (starIdx) => Icon(
                                      starIdx < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                      size: 16,
                                      color: starIdx < review.rating ? Colors.amber : Colors.grey[300],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              review.comment,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.3),
                            ),
                            if (review.tags.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: review.tags.map((t) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    t,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                                  ),
                                )).toList(),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                    childCount: _reviews.length,
                  ),
                ),
              ),
            ],
          ),

          // Thanh giỏ hàng trôi nổi dưới màn hình (Floating Cart Bar)
          if (isCurrentRestaurantInCart)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA580C),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEA580C).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${cart.totalQuantity}",
                          style: const TextStyle(color: Color(0xFFEA580C), fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Xem giỏ hàng",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            currencyFormat.format(cart.totalAmount),
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
