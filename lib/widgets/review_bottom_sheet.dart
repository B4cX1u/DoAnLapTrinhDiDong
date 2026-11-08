// lib/widgets/review_bottom_sheet.dart
import 'package:flutter/material.dart';
import '../models/models.dart';

class ReviewBottomSheet extends StatefulWidget {
  final int restaurantId;
  final String restaurantName;
  final Function(ReviewModel review)? onReviewSubmitted;

  const ReviewBottomSheet({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    this.onReviewSubmitted,
  });

  static Future<ReviewModel?> show(
    BuildContext context, {
    required int restaurantId,
    required String restaurantName,
    Function(ReviewModel review)? onReviewSubmitted,
  }) {
    return showModalBottomSheet<ReviewModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReviewBottomSheet(
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        onReviewSubmitted: onReviewSubmitted,
      ),
    );
  }

  @override
  State<ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<ReviewBottomSheet> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  final Set<String> _selectedTags = {};

  final List<String> _availableTags = [
    "Món ăn nóng hổi 🍲",
    "Giao siêu tốc ⚡",
    "Đóng gói cẩn thận 📦",
    "Tài xế thân thiện 😊",
    "Đúng định lượng 👍",
    "Hương vị chuẩn vị 😋",
    "Giá cả hợp lý 💰",
  ];

  final Map<int, String> _ratingDescriptions = {
    1: "Rất không hài lòng 😞",
    2: "Chưa hài lòng 😐",
    3: "Bình thường 🙂",
    4: "Hài lòng và ngon miệng 😊",
    5: "Tuyệt vời, cực kỳ hài lòng! 🌟",
  };

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitReview() {
    final comment = _commentController.text.trim();
    final newReview = ReviewModel(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      restaurantId: widget.restaurantId,
      userName: "Bạn (Khách hàng)",
      userAvatar: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150",
      rating: _rating,
      comment: comment.isEmpty ? "Món ăn rất ngon, dịch vụ chu đáo!" : comment,
      tags: _selectedTags.toList(),
      createdAt: DateTime.now(),
    );

    widget.onReviewSubmitted?.call(newReview);
    Navigator.pop(context, newReview);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Cảm ơn bạn đã gửi đánh giá $_rating sao cho ${widget.restaurantName}!",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            const Text(
              "Đánh Giá & Nhận Xét",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            Text(
              widget.restaurantName,
              style: const TextStyle(fontSize: 14, color: Color(0xFFEA580C), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // 5-Star interactive selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _rating = starIndex;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      starIndex <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 40,
                      color: starIndex <= _rating ? Colors.amber : Colors.grey[300],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _ratingDescriptions[_rating] ?? "",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _rating >= 4 ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
              ),
            ),
            const SizedBox(height: 20),

            // Quick Tag Chips
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Bạn thấy trải nghiệm thế nào?",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[700]),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  selectedColor: const Color(0xFFFFECE5),
                  checkmarkColor: const Color(0xFFEA580C),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? const Color(0xFFEA580C) : const Color(0xFF475569),
                  ),
                  backgroundColor: const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFFEA580C) : Colors.transparent,
                    ),
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Comment text area
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Chia sẻ thêm cảm nhận của bạn về món ăn, tốc độ giao hàng, đóng gói...",
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEA580C), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  "Gửi Đánh Giá Ngay",
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

