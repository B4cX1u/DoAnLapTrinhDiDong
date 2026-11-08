// lib/screens/payment/vnpay_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../order/order_tracking_screen.dart';

class VnPayPaymentScreen extends StatefulWidget {
  final double amount;
  final int restaurantId;
  final String restaurantName;
  final List<CartItemModel> items;
  final String deliveryAddress;
  final double deliveryLat;
  final double deliveryLng;
  final double shippingFee;

  const VnPayPaymentScreen({
    super.key,
    required this.amount,
    required this.restaurantId,
    required this.restaurantName,
    required this.items,
    required this.deliveryAddress,
    required this.deliveryLat,
    required this.deliveryLng,
    required this.shippingFee,
  });

  @override
  State<VnPayPaymentScreen> createState() => _VnPayPaymentScreenState();
}

class _VnPayPaymentScreenState extends State<VnPayPaymentScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  int selectedBankIndex = 0;
  bool isProcessing = false;
  bool isPaymentSuccess = false;
  OrderModel? createdOrder;

  final List<Map<String, String>> banks = [
    {"name": "NCB (Quốc Dân)", "code": "NCB", "icon": "🏦"},
    {"name": "Vietcombank", "code": "VCB", "icon": "💳"},
    {"name": "VietinBank", "code": "CTG", "icon": "🏛️"},
    {"name": "BIDV", "code": "BIDV", "icon": "🪙"},
    {"name": "Agribank", "code": "VBA", "icon": "🌾"},
    {"name": "MB Bank", "code": "MB", "icon": "⭐"},
  ];

  void _processPayment() async {
    setState(() => isProcessing = true);

    // Mô phỏng độ trễ giao dịch ngân hàng VNPay
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final orderProvider = context.read<OrderProvider>();
    final cart = context.read<CartProvider>();

    final order = await orderProvider.placeOrder(
      restaurantId: widget.restaurantId,
      restaurantName: widget.restaurantName,
      restaurantImage: widget.items.first.foodItem.imageUrl,
      restaurantLat: 10.7761,
      restaurantLng: 106.7027,
      deliveryAddress: widget.deliveryAddress,
      deliveryLat: widget.deliveryLat,
      deliveryLng: widget.deliveryLng,
      paymentMethod: 'VNPAY',
      isPaid: true,
      totalAmount: widget.amount,
      shippingFee: widget.shippingFee,
      items: widget.items,
    );

    cart.clearCart();

    setState(() {
      isProcessing = false;
      isPaymentSuccess = true;
      createdOrder = order;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isPaymentSuccess && createdOrder != null) {
      return _buildSuccessScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Cổng Thanh Toán VNPay", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF005BAA), // Màu xanh đặc trưng VNPay
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Thẻ thông tin đơn hàng VNPay
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF005BAA),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "VNPAY SANDBOX",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      "Mã GD: #928374",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text("Số tiền cần thanh toán:", style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                Text(
                  currencyFormat.format(widget.amount),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF005BAA),
                  ),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Đơn vị thụ hưởng:", style: TextStyle(fontSize: 13, color: Colors.grey)),
                    Text(widget.restaurantName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Nội dung:", style: TextStyle(fontSize: 13, color: Colors.grey)),
                    Text("Thanh toan don hang FoodDelivery", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Chọn ngân hàng thanh toán
          const Text(
            "Chọn ngân hàng thanh toán nội địa",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: banks.length,
            itemBuilder: (context, index) {
              final bank = banks[index];
              final isSelected = selectedBankIndex == index;

              return GestureDetector(
                onTap: () => setState(() => selectedBankIndex = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF005BAA) : const Color(0xFFE2E8F0),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(bank["icon"]!, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              bank["code"]!,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              bank["name"]!,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: Color(0xFF005BAA), size: 18),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // 3. Thông tin thẻ Sandbox mẫu
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF0284C7), size: 18),
                    SizedBox(width: 6),
                    Text(
                      "Thông tin thẻ test VNPay Sandbox:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0369A1)),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text("• Số thẻ: 9704198526191432198", style: TextStyle(fontSize: 12, color: Color(0xFF0369A1))),
                Text("• Tên chủ thẻ: NGUYEN VAN A", style: TextStyle(fontSize: 12, color: Color(0xFF0369A1))),
                Text("• Ngày phát hành: 07/15 • Mã OTP: 123456", style: TextStyle(fontSize: 12, color: Color(0xFF0369A1))),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Nút Xác nhận thanh toán
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005BAA),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: isProcessing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text("Đang kết nối cổng VNPay...", style: TextStyle(color: Colors.white)),
                      ],
                    )
                  : const Text(
                      "⚡ Xác Nhận Thanh Toán VNPay",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
            const Spacer(),
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, size: 80, color: Color(0xFF16A34A)),
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                "Thanh Toán Thành Công!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                "Cổng VNPay đã ghi nhận giao dịch của bạn.\nQuán ăn đã bắt đầu làm món!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 24),

            // Card chi tiết giao dịch
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Mã đơn hàng", style: TextStyle(color: Colors.grey)),
                      Text("#${createdOrder!.id}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Phương thức", style: TextStyle(color: Colors.grey)),
                      const Text("VNPay Sandbox (00)", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF005BAA))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Tổng số tiền", style: TextStyle(color: Colors.grey)),
                      Text(currencyFormat.format(createdOrder!.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEA580C))),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Nút theo dõi đơn hàng trên bản đồ
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderTrackingScreen(order: createdOrder!),
                    ),
                  );
                },
                icon: const Icon(Icons.map, color: Colors.white),
                label: const Text(
                  "Theo Dõi Đơn Hàng Trên Bản Đồ",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
  }
}
