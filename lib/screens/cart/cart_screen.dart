// lib/screens/cart/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/location_picker_sheet.dart';
import '../auth/login_screen.dart';
import '../order/order_tracking_screen.dart';
import '../payment/vnpay_payment_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final voucherController = TextEditingController();
  String selectedPaymentMethod = 'VNPAY'; // Mặc định là VNPay theo yêu cầu đề bài
  bool isPlacingOrder = false;

  @override
  void dispose() {
    voucherController.dispose();
    super.dispose();
  }

  void _handlePlaceOrder() async {
    final cart = context.read<CartProvider>();
    final loc = context.read<LocationProvider>();
    final orderProvider = context.read<OrderProvider>();
    final auth = context.read<AuthProvider>();

    if (cart.items.isEmpty) return;

    // Yêu cầu đăng nhập trước khi tiến hành thanh toán
    if (!auth.isLoggedIn) {
      final shouldLogin = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Yêu cầu đăng nhập 🔒"),
          content: const Text("Vui lòng đăng nhập để lưu đơn hàng vào tài khoản và nhận ưu đãi từ quán!"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Để sau", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Đăng Nhập Ngay", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (shouldLogin == true && mounted) {
        final loggedIn = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        if (loggedIn != true) return;
      } else {
        return;
      }
    }

    if (selectedPaymentMethod == 'VNPAY') {
      // Mở màn hình thanh toán VNPay
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VnPayPaymentScreen(
            amount: cart.totalAmount,
            restaurantId: cart.restaurantId!,
            restaurantName: cart.restaurantName,
            items: List.from(cart.items),
            deliveryAddress: loc.address,
            deliveryLat: loc.latitude,
            deliveryLng: loc.longitude,
            shippingFee: cart.shippingFee,
          ),
        ),
      );
    } else {
      // Thanh toán Tiền mặt (COD)
      setState(() => isPlacingOrder = true);

      final order = await orderProvider.placeOrder(
        restaurantId: cart.restaurantId!,
        restaurantName: cart.restaurantName,
        restaurantImage: cart.items.first.foodItem.imageUrl,
        restaurantLat: 10.7761,
        restaurantLng: 106.7027,
        deliveryAddress: loc.address,
        deliveryLat: loc.latitude,
        deliveryLng: loc.longitude,
        paymentMethod: 'COD',
        isPaid: false,
        totalAmount: cart.totalAmount,
        shippingFee: cart.shippingFee,
        items: cart.items,
      );

      cart.clearCart();
      setState(() => isPlacingOrder = false);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: order)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final loc = context.watch<LocationProvider>();

    if (cart.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Giỏ hàng của bạn", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
        ),
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEDD5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shopping_bag_outlined, size: 72, color: Color(0xFFEA580C)),
              ),
              const SizedBox(height: 20),
              const Text(
                "Giỏ hàng đang trống",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              const Text(
                "Hãy chọn những món ăn ngon từ danh sách quán nhé!",
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          cart.restaurantName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              cart.clearCart();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Địa chỉ giao hàng
          GestureDetector(
            onTap: () => LocationPickerSheet.show(context),
            child: Container(
              padding: const EdgeInsets.all(14),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, color: Color(0xFFEA580C), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Địa chỉ nhận hàng (Chạm để đổi)",
                          style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          loc.address,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDD5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Đổi vị trí",
                      style: TextStyle(color: Color(0xFFEA580C), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Danh sách món ăn trong giỏ
          Container(
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
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cart.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = cart.items[index];
                return Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.foodItem.imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[200],
                            child: const Icon(Icons.fastfood, color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.foodItem.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              "Size: ${item.size}${item.toppings.isNotEmpty ? " • ${item.toppings.join(', ')}" : ""}",
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                            if (item.note != null && item.note!.isNotEmpty)
                              Text(
                                "Ghi chú: ${item.note}",
                                style: const TextStyle(fontSize: 11, color: Colors.amber, fontStyle: FontStyle.italic),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormat.format(item.unitPrice),
                              style: const TextStyle(
                                color: Color(0xFFEA580C),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Tăng giảm số lượng
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.grey),
                            onPressed: () => cart.decrementQuantity(index),
                          ),
                          Text(
                            "${item.quantity}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 20, color: Color(0xFFEA580C)),
                            onPressed: () => cart.incrementQuantity(index),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // 3. Mã giảm giá (Vouchers)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.confirmation_num_outlined, color: Color(0xFFEA580C), size: 20),
                    SizedBox(width: 8),
                    Text("Mã Giảm Giá / Voucher", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                      label: const Text("GIAM20K (-20k)", style: TextStyle(fontSize: 12)),
                      backgroundColor: cart.appliedVoucher == "GIAM20K" ? const Color(0xFFFFEDD5) : const Color(0xFFF1F5F9),
                      onPressed: () {
                        cart.applyVoucher("GIAM20K");
                      },
                    ),
                    ActionChip(
                      label: const Text("FREESHIP (-15k)", style: TextStyle(fontSize: 12)),
                      backgroundColor: cart.appliedVoucher == "FREESHIP" ? const Color(0xFFFFEDD5) : const Color(0xFFF1F5F9),
                      onPressed: () {
                        cart.applyVoucher("FREESHIP");
                      },
                    ),
                  ],
                ),
                if (cart.appliedVoucher != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        "Đã áp dụng mã: ${cart.appliedVoucher}",
                        style: const TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => cart.removeVoucher(),
                        child: const Text("Hủy bỏ", style: TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Phương thức thanh toán (VNPay / Tiền mặt)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Phương thức thanh toán", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                _buildPaymentOption(
                  value: 'VNPAY',
                  title: "Ví VNPAY / Thẻ ATM / QR",
                  subtitle: "Thanh toán bảo mật trực tuyến qua VNPay",
                  badge: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF005BAA),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      "VNPAY",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ),
                _buildPaymentOption(
                  value: 'COD',
                  title: "Tiền mặt khi nhận hàng (COD)",
                  subtitle: "Thanh toán tiền mặt cho tài xế shipper",
                  badge: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      "TIỀN MẶT",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. Tóm tắt chi phí
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Tạm tính", style: TextStyle(color: Color(0xFF64748B))),
                    Text(currencyFormat.format(cart.subtotal), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Phí giao hàng", style: TextStyle(color: Color(0xFF64748B))),
                    Text(currencyFormat.format(cart.shippingFee), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                if (cart.discountAmount > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Giảm giá Voucher", style: TextStyle(color: Color(0xFF047857))),
                      Text("-${currencyFormat.format(cart.discountAmount)}", style: const TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Tổng thanh toán", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      currencyFormat.format(cart.totalAmount),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Nút Đặt hàng
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isPlacingOrder ? null : _handlePlaceOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: isPlacingOrder
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      selectedPaymentMethod == 'VNPAY' ? "Tiếp Tục Thanh Toán VNPay" : "Đặt Hàng Ngay (COD)",
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required String title,
    required String subtitle,
    required Widget badge,
  }) {
    final isSelected = selectedPaymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => selectedPaymentMethod = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF7ED) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFEA580C) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFFEA580C) : const Color(0xFF94A3B8),
              size: 20,
            ),
            const SizedBox(width: 10),
            badge,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
