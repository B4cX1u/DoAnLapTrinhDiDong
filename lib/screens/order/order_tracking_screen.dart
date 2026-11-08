// lib/screens/order/order_tracking_screen.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/order_provider.dart';
import '../../widgets/review_bottom_sheet.dart';

class OrderTrackingScreen extends StatefulWidget {
  final OrderModel order;

  const OrderTrackingScreen({super.key, required this.order});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  void _showNotificationHistorySheet(BuildContext context, OrderProvider orderProvider) {
    orderProvider.markNotificationsAsRead();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications_active, color: Color(0xFFEA580C)),
                  const SizedBox(width: 8),
                  const Text(
                    "Thông Báo Vị Trí & Hành Trình",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Nút bật tắt thông báo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Nhận thông báo khi tài xế di chuyển",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Switch(
                      value: orderProvider.isLocationNotificationEnabled,
                      activeThumbColor: const Color(0xFFEA580C),
                      onChanged: (val) {
                        orderProvider.toggleLocationNotification(val);
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                "Nhật ký theo dõi:",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: orderProvider.notifications.isEmpty
                    ? const Center(
                        child: Text("Chưa có thông báo vị trí nào.", style: TextStyle(color: Colors.grey)),
                      )
                    : ListView.separated(
                        itemCount: orderProvider.notifications.length,
                        separatorBuilder: (_, _) => const Divider(height: 16),
                        itemBuilder: (context, idx) {
                          final n = orderProvider.notifications[idx];
                          final timeStr = DateFormat('HH:mm:ss').format(n.timestamp);

                          IconData icon = Icons.info_outline;
                          Color color = Colors.blue;
                          if (n.type == 'location') {
                            icon = Icons.near_me;
                            color = const Color(0xFFEA580C);
                          } else if (n.type == 'status') {
                            icon = Icons.restaurant;
                            color = Colors.amber;
                          } else if (n.type == 'completed') {
                            icon = Icons.check_circle;
                            color = Colors.green;
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: color, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        Text(timeStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(n.message, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final activeOrder = orderProvider.currentTrackingOrder ?? widget.order;
    final latestNotif = orderProvider.latestNotification;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          "Theo dõi đơn #${activeOrder.id}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          // Nút chuông thông báo vị trí có badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 26),
                onPressed: () => _showNotificationHistorySheet(context, orderProvider),
              ),
              if (orderProvider.unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "${orderProvider.unreadNotificationCount}",
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. BANNER THÔNG BÁO VỊ TRÍ TỨC THỜI (In-App Notification Toast)
          if (latestNotif != null)
            Dismissible(
              key: Key(latestNotif.id),
              onDismissed: (_) => orderProvider.dismissLatestNotification(),
              child: Container(
                margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEA580C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.near_me, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            latestNotif.title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Text(
                            latestNotif.message,
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white60, size: 18),
                      onPressed: () => orderProvider.dismissLatestNotification(),
                    ),
                  ],
                ),
              ),
            ),

          // 2. KHU VỰC BẢN ĐỒ VIETMAP / MÔ PHỎNG LỘ TRÌNH GPS
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                // Bản đồ Vector Canvas vẽ lộ trình Quán -> Shipper -> Nhà
                Container(
                  color: const Color(0xFFE2E8F0),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: MapRoutePainter(progress: orderProvider.driverProgress),
                  ),
                ),

                // Badge Vietmap Logo & Nút định vị
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map, color: Color(0xFFEA580C), size: 16),
                        SizedBox(width: 6),
                        Text(
                          "VietMap GL • GPS Live Tracking",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                  ),
                ),

                // Nút Ping / Bấm cập nhật vị trí GPS thủ công
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () {
                      orderProvider.pingDriverLocation();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("📍 Đang ping tín hiệu GPS vệ tinh của Shipper..."),
                          duration: Duration(seconds: 1),
                          backgroundColor: Color(0xFF0F172A),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.gps_fixed, color: Color(0xFF0284C7), size: 16),
                          SizedBox(width: 4),
                          Text(
                            "Ping GPS",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Badge Ước lượng thời gian ETA & Khoảng cách thực tế
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, color: Color(0xFFEA580C), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Khoảng cách & Thời gian giao",
                                style: TextStyle(fontSize: 10.5, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                activeOrder.status == 'Giao hàng thành công'
                                    ? "Đã giao đến nhà"
                                    : "Cách ${orderProvider.distanceToCustomerKm.toStringAsFixed(1)} km • Còn ${orderProvider.etaMinutes} phút",
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEDD5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            activeOrder.status,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. CHI TIẾT ĐƠN HÀNG & TÀI XẾ
          Expanded(
            flex: 6,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Thẻ tài xế
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: Color(0xFFFFEDD5),
                          child: Icon(Icons.delivery_dining, color: Color(0xFFEA580C), size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeOrder.driverName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const Text(
                                "Honda Wave • 59-P1 839.22",
                                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        // Nút gọi điện
                        IconButton(
                          icon: const Icon(Icons.phone, color: Color(0xFF059669)),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Đang gọi tài xế: ${activeOrder.driverPhone}")),
                            );
                          },
                        ),
                        // Nút nhắn tin nhanh
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF0284C7)),
                          onPressed: () => _showQuickChatDialog(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tiến trình đơn hàng (Timeline)
                  const Text("Trạng thái đơn hàng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  _buildTimelineStep("Đã nhận đơn & Xác nhận VNPay", true, isCompleted: true),
                  _buildTimelineStep(
                    "Quán đang chuẩn bị món",
                    true,
                    isCompleted: activeOrder.status != 'Chờ xác nhận',
                  ),
                  _buildTimelineStep(
                    "Tài xế đang giao đến bạn",
                    true,
                    isCompleted: activeOrder.status == 'Tài xế đang giao đến bạn' || activeOrder.status == 'Giao hàng thành công',
                  ),
                  _buildTimelineStep(
                    "Giao hàng thành công",
                    false,
                    isCompleted: activeOrder.status == 'Giao hàng thành công',
                  ),

                  const Divider(height: 32),

                  // Tóm tắt các món trong đơn
                  const Text("Danh sách món ăn", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  ...activeOrder.items.map((it) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${it.quantity}x ${it.foodItem.name}", style: const TextStyle(fontSize: 13)),
                            Text(currencyFormat.format(it.totalPrice), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Tổng đã thanh toán", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        currencyFormat.format(activeOrder.totalAmount),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Nút Đánh giá đơn hàng khi giao hàng thành công
                  if (activeOrder.status == 'Giao hàng thành công')
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ReviewBottomSheet.show(
                            context,
                            restaurantId: activeOrder.restaurantId,
                            restaurantName: activeOrder.restaurantName,
                          );
                        },
                        icon: const Icon(Icons.star_rate_rounded, color: Colors.white, size: 22),
                        label: const Text(
                          "Đánh Giá Món Ăn & Shipper ⭐",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(String title, bool showLine, {required bool isCompleted}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFFEA580C) : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            if (showLine)
              Container(
                width: 2,
                height: 24,
                color: isCompleted ? const Color(0xFFEA580C) : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
              color: isCompleted ? const Color(0xFF0F172A) : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  void _showQuickChatDialog(BuildContext context) {
    final templates = [
      "Tôi đang xuống sảnh nhận món nhé!",
      "Nhà tôi có em bé đang ngủ, vui lòng đừng bấm chuông.",
      "Giao tại phòng bảo vệ giúp tôi nhé.",
      "Cho thêm nhiều ớt giúp tôi nha tài xế!",
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Nhắn tin nhanh cho tài xế", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...templates.map((txt) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.chat_bubble_outline, color: Color(0xFFEA580C), size: 20),
                  title: Text(txt, style: const TextStyle(fontSize: 14)),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Đã gửi tin nhắn: '$txt'")),
                    );
                  },
                )),
          ],
        ),
      ),
    );
  }
}

/// Custom Painter vẽ bản đồ đường đi và tọa độ shipper di chuyển động
class MapRoutePainter extends CustomPainter {
  final double progress;

  MapRoutePainter({this.progress = 0.3});

  @override
  void paint(Canvas canvas, Size size) {
    final startPt = Offset(size.width * 0.2, size.height * 0.25); // Điểm A: Quán ăn
    final endPt = Offset(size.width * 0.8, size.height * 0.75);   // Điểm C: Nhà bạn

    // Đường đi bản đồ
    final streetPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(startPt.dx, startPt.dy);
    path.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.5,
      size.width * 0.55,
      size.height * 0.45,
    );
    path.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.4,
      endPt.dx,
      endPt.dy,
    );

    canvas.drawPath(path, streetPaint);

    // Đường kẻ định hướng
    final routePaint = Paint()
      ..color = const Color(0xFFEA580C)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, routePaint);

    // Tính tọa độ động của Shipper theo progress (0.0 -> 1.0)
    final clampedP = progress.clamp(0.0, 1.0);
    // Ước lượng vị trí trên đường cong
    final driverX = ui.lerpDouble(startPt.dx, endPt.dx, clampedP)!;
    final driverY = ui.lerpDouble(startPt.dy, endPt.dy, clampedP)! + (clampedP < 0.5 ? -15 : 15) * (1.0 - (clampedP - 0.5).abs() * 2);
    final driverPt = Offset(driverX, driverY);

    // Điểm A: Quán ăn 🏪
    _drawMarker(canvas, startPt, "🏪 Quán Ăn", Colors.deepOrange);

    // Điểm B: Tài xế Shipper đang di chuyển 🛵
    _drawMarker(canvas, driverPt, "🛵 Shipper (${(clampedP * 100).toInt()}%)", const Color(0xFF0284C7));

    // Điểm C: Khách hàng 🏠
    _drawMarker(canvas, endPt, "🏠 Bạn", const Color(0xFF16A34A));
  }

  void _drawMarker(Canvas canvas, Offset offset, String label, Color color) {
    // Vòng tròn hào quang
    final glowPaint = Paint()..color = color.withValues(alpha: 0.25);
    canvas.drawCircle(offset, 18, glowPaint);

    // Điểm marker
    final markerPaint = Paint()..color = color;
    canvas.drawCircle(offset, 9, markerPaint);

    final whiteCenter = Paint()..color = Colors.white;
    canvas.drawCircle(offset, 4, whiteCenter);

    // Nhãn chữ
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.white.withValues(alpha: 0.9),
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(offset.dx - textPainter.width / 2, offset.dy + 14));
  }

  @override
  bool shouldRepaint(covariant MapRoutePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
