// lib/screens/favorites/favorites_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorites_provider.dart';
import '../cart/cart_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();
    final cart = context.watch<CartProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final items = favoritesProvider.favorites;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Món Ăn Yêu Thích ❤️",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              tooltip: "Xóa tất cả",
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.grey),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text("Xóa danh sách yêu thích?"),
                    content: const Text("Bạn có chắc chắn muốn bỏ lưu tất cả các món ăn này không?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          favoritesProvider.clearFavorites();
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Đã xóa tất cả món yêu thích")),
                          );
                        },
                        child: const Text("Xóa hết"),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFECE5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        size: 64,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Chưa có món ăn yêu thích",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Nhấn vào biểu tượng trái tim ❤️ ở bất kỳ món ăn nào để lưu lại danh sách các món bạn mê nhất nhé!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.explore_outlined, color: Colors.white),
                      label: const Text(
                        "Khám phá thực đơn ngay",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEA580C),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                ListView.builder(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, cart.items.isNotEmpty ? 90 : 20),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final food = items[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Ảnh món
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  food.imageUrl,
                                  width: 85,
                                  height: 85,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 85,
                                    height: 85,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.fastfood, color: Colors.grey),
                                  ),
                                ),
                              ),
                              if (food.isBestSeller)
                                Positioned(
                                  top: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEA580C),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      "HOT",
                                      style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 14),

                          // Thông tin món
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  food.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  food.description,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      currencyFormat.format(food.price),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFEA580C),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        final success = cart.addToCart(CartItemModel(
                                          foodItem: food,
                                          restaurantId: food.restaurantId,
                                          restaurantName: "Quán Ăn Yêu Thích",
                                          quantity: 1,
                                        ));
                                        if (!success) {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                              title: const Text("Tạo giỏ hàng mới?"),
                                              content: const Text(
                                                "Giỏ hàng hiện tại đang có món của quán khác. Bạn có muốn đổi sang đặt quán này không?",
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx),
                                                  child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
                                                ),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFFEA580C),
                                                    foregroundColor: Colors.white,
                                                  ),
                                                  onPressed: () {
                                                    cart.clearCart();
                                                    cart.addToCart(CartItemModel(
                                                      foodItem: food,
                                                      restaurantId: food.restaurantId,
                                                      restaurantName: "Quán Ăn Yêu Thích",
                                                      quantity: 1,
                                                    ));
                                                    Navigator.pop(ctx);
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text("Đã tạo giỏ hàng mới với '${food.name}'!"),
                                                        action: SnackBarAction(
                                                          label: "Xem giỏ",
                                                          textColor: const Color(0xFFEA580C),
                                                          onPressed: () {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(builder: (_) => const CartScreen()),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: const Text("Tạo giỏ mới"),
                                                ),
                                              ],
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text("Đã thêm '${food.name}' vào giỏ hàng!"),
                                              duration: const Duration(seconds: 2),
                                              action: SnackBarAction(
                                                label: "Xem giỏ",
                                                textColor: const Color(0xFFEA580C),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(builder: (_) => const CartScreen()),
                                                  );
                                                },
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                                      label: const Text("Thêm"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFFECE5),
                                        foregroundColor: const Color(0xFFEA580C),
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Nút bỏ yêu thích
                          IconButton(
                            icon: const Icon(Icons.favorite, color: Colors.red, size: 24),
                            tooltip: "Bỏ yêu thích",
                            onPressed: () {
                              final removedFood = food;
                              favoritesProvider.removeFavorite(food.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Đã bỏ '${food.name}' khỏi danh sách"),
                                  duration: const Duration(seconds: 2),
                                  action: SnackBarAction(
                                    label: "Hoàn tác",
                                    textColor: Colors.amber,
                                    onPressed: () {
                                      favoritesProvider.toggleFavorite(removedFood);
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Floating Cart summary if cart has items
                if (cart.items.isNotEmpty)
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
