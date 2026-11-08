// lib/widgets/location_picker_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../providers/restaurant_provider.dart';

class LocationPickerSheet extends StatefulWidget {
  const LocationPickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LocationPickerSheet(),
    );
  }

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  final _searchController = TextEditingController();
  final _houseDetailController = TextEditingController();
  bool _isLocatingGps = false;

  // Danh sách các địa điểm mẫu phổ biến với toạ độ thực tế tại TP.HCM
  final List<Map<String, dynamic>> _presetLocations = [
    {
      "name": "Phố Đi Bộ Nguyễn Huệ, Bến Nghé, Quận 1",
      "subtitle": "Khu vực trung tâm TP.HCM",
      "lat": 10.773996,
      "lng": 106.704245,
      "tag": "Trung tâm",
      "icon": Icons.star,
    },
    {
      "name": "Landmark 81, Vinhomes Central Park, Bình Thạnh",
      "subtitle": "208 Nguyễn Hữu Cảnh, Phường 22",
      "lat": 10.7950,
      "lng": 106.7219,
      "tag": "Chung cư",
      "icon": Icons.apartment,
    },
    {
      "name": "Hồ Con Rùa, Phường Võ Thị Sáu, Quận 3",
      "subtitle": "Khu vực ăn vặt & cà phê",
      "lat": 10.7828,
      "lng": 106.6958,
      "tag": "Cà phê",
      "icon": Icons.local_cafe,
    },
    {
      "name": "Đại học Bách Khoa TP.HCM, Quận 10",
      "subtitle": "268 Lý Thường Kiệt, Phường 14",
      "lat": 10.7721,
      "lng": 106.6578,
      "tag": "Trường học",
      "icon": Icons.school,
    },
    {
      "name": "Khu Đô Thị Sala, Thủ Thiêm, TP. Thủ Đức",
      "subtitle": "10 Mai Chí Thọ, An Lợi Đông",
      "lat": 10.7680,
      "lng": 106.7230,
      "tag": "Khu dân cư",
      "icon": Icons.home_work,
    },
    {
      "name": "Sân Bay Quốc Tế Tân Sơn Nhất, Tân Bình",
      "subtitle": "Đường Trường Sơn, Phường 2",
      "lat": 10.8185,
      "lng": 106.6588,
      "tag": "Sân bay",
      "icon": Icons.flight,
    },
    {
      "name": "Chợ Bến Thành, Phường Bến Thành, Quận 1",
      "subtitle": "Đường Lê Lợi, Phường Bến Thành",
      "lat": 10.7725,
      "lng": 106.6980,
      "tag": "Mua sắm",
      "icon": Icons.storefront,
    },
  ];

  List<Map<String, dynamic>> _filteredLocations = [];

  @override
  void initState() {
    super.initState();
    _filteredLocations = _presetLocations;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _houseDetailController.dispose();
    super.dispose();
  }

  void _filterLocations(String query) {
    if (query.trim().isEmpty) {
      setState(() => _filteredLocations = _presetLocations);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _filteredLocations = _presetLocations.where((loc) {
        final name = (loc['name'] as String).toLowerCase();
        final sub = (loc['subtitle'] as String).toLowerCase();
        final tag = (loc['tag'] as String).toLowerCase();
        return name.contains(q) || sub.contains(q) || tag.contains(q);
      }).toList();
    });
  }

  void _selectLocation(String address, double lat, double lng) {
    final locProvider = context.read<LocationProvider>();
    final restProvider = context.read<RestaurantProvider>();

    String finalAddress = address;
    final detail = _houseDetailController.text.trim();
    if (detail.isNotEmpty && !finalAddress.toLowerCase().contains(detail.toLowerCase())) {
      finalAddress = "$detail, $finalAddress";
    }

    locProvider.setCustomAddress(finalAddress, lat, lng);
    restProvider.fetchData(lat: lat, lng: lng);

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFFEA580C),
        content: Text("📍 Đã chọn vị trí: $finalAddress\nKhoảng cách các quán ăn đã được tính lại!"),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _applyHouseDetail() {
    final detail = _houseDetailController.text.trim();
    if (detail.isEmpty) return;

    final locProvider = context.read<LocationProvider>();
    final restProvider = context.read<RestaurantProvider>();

    String current = locProvider.address;
    if (!current.toLowerCase().contains(detail.toLowerCase())) {
      current = "$detail, $current";
    }

    locProvider.setCustomAddress(current, locProvider.latitude, locProvider.longitude);
    restProvider.fetchData(lat: locProvider.latitude, lng: locProvider.longitude);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFF16A34A),
        content: Text("📍 Đã cập nhật số nhà & chi tiết:\n$current"),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _useCurrentGps() async {
    setState(() => _isLocatingGps = true);
    final locProvider = context.read<LocationProvider>();
    final restProvider = context.read<RestaurantProvider>();

    await locProvider.initLocation();

    if (!mounted) return;
    setState(() => _isLocatingGps = false);

    final detail = _houseDetailController.text.trim();
    if (detail.isNotEmpty && !locProvider.address.toLowerCase().contains(detail.toLowerCase())) {
      final combined = "$detail, ${locProvider.address}";
      locProvider.setCustomAddress(combined, locProvider.latitude, locProvider.longitude);
    }

    restProvider.fetchData(lat: locProvider.latitude, lng: locProvider.longitude);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFF16A34A),
        content: Text("📡 Đã lấy vị trí GPS & số nhà: ${locProvider.address}"),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thanh kéo
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Tiêu đề
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on, color: Color(0xFFEA580C), size: 24),
                    SizedBox(width: 8),
                    Text(
                      "Chọn Vị Trí Giao Hàng",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Ô tìm kiếm địa chỉ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterLocations,
                decoration: InputDecoration(
                  hintText: "Nhập địa chỉ, toà nhà, tên đường...",
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _filterLocations('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Nút Sử dụng GPS hiện tại
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: GestureDetector(
              onTap: _isLocatingGps ? null : _useCurrentGps,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDBA74)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEA580C),
                        shape: BoxShape.circle,
                      ),
                      child: _isLocatingGps
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Sử dụng vị trí GPS hiện tại",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9A3412),
                            ),
                          ),
                          Text(
                            _isLocatingGps ? "Đang quét tín hiệu vệ tinh GPS..." : "Định vị tức thời bằng cảm biến GPS điện thoại",
                            style: const TextStyle(fontSize: 12, color: Color(0xFFC2410C)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFEA580C)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Thẻ nhập số nhà / tầng / phòng chi tiết
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.home_work_outlined, color: Color(0xFFEA580C), size: 18),
                      SizedBox(width: 6),
                      Text(
                        "Số nhà / Tòa nhà / Số phòng cụ thể:",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _houseDetailController,
                          decoration: InputDecoration(
                            hintText: "Ví dụ: Số 24/5A, Lầu 3, Chung cư...",
                            hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _applyHouseDetail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA580C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: const Text("Cập nhật", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Tiêu đề danh sách địa điểm gợi ý
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              "Địa điểm phổ biến (Có toạ độ thực tế):",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
            ),
          ),
          const SizedBox(height: 8),

          // Danh sách cuộn các địa điểm
          Expanded(
            child: _filteredLocations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_off, size: 40, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(
                          "Không tìm thấy '${_searchController.text}'",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () {
                            _selectLocation(
                              _searchController.text.trim(),
                              10.7769,
                              106.7009,
                            );
                          },
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text("Dùng địa chỉ này"),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C)),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    itemCount: _filteredLocations.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _filteredLocations[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(item['icon'] as IconData, color: const Color(0xFFEA580C), size: 20),
                        ),
                        title: Text(
                          item['name'] as String,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          item['subtitle'] as String,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item['tag'] as String,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                          ),
                        ),
                        onTap: () {
                          _selectLocation(
                            item['name'] as String,
                            (item['lat'] as num).toDouble(),
                            (item['lng'] as num).toDouble(),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

