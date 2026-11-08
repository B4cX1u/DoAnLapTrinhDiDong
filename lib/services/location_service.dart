// lib/services/location_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Tọa độ mặc định (Trung tâm Quận 1, TP. Hồ Chí Minh) khi thiết bị chưa cấp quyền hoặc chạy máy ảo
  static const double defaultLatitude = 10.7769;
  static const double defaultLongitude = 106.7009;
  static const String defaultAddress = "135 Nguyễn Huệ, Phường Bến Nghé, Quận 1, TP.HCM";

  // Danh sách các quận/khu vực tại TP.HCM dùng để fallback khi offline hoặc chưa lấy được API
  static final List<Map<String, dynamic>> _tphcmDistricts = [
    {"name": "Bình Thạnh", "lat": 10.8040, "lng": 106.6975},
    {"name": "Gò Vấp", "lat": 10.8387, "lng": 106.6653},
    {"name": "Quận 1", "lat": 10.7769, "lng": 106.7009},
    {"name": "Quận 3", "lat": 10.7844, "lng": 106.6843},
    {"name": "Phú Nhuận", "lat": 10.7992, "lng": 106.6803},
    {"name": "Tân Bình", "lat": 10.8015, "lng": 106.6528},
    {"name": "Quận 10", "lat": 10.7716, "lng": 106.6675},
    {"name": "Quận 5", "lat": 10.7554, "lng": 106.6669},
    {"name": "TP. Thủ Đức", "lat": 10.8494, "lng": 106.7717},
    {"name": "Quận 7", "lat": 10.7340, "lng": 106.7218},
    {"name": "Quận 4", "lat": 10.7610, "lng": 106.7042},
    {"name": "Tân Phú", "lat": 10.7900, "lng": 106.6280},
    {"name": "Quận 12", "lat": 10.8672, "lng": 106.6412},
    {"name": "Quận 6", "lat": 10.7480, "lng": 106.6352},
    {"name": "Quận 8", "lat": 10.7240, "lng": 106.6285},
    {"name": "Bình Tân", "lat": 10.7652, "lng": 106.6038},
  ];

  /// Lấy vị trí GPS hiện tại của người dùng qua thư viện Geolocator
  static Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// Dịch tọa độ GPS (lat, lng) sang tên đường & địa chỉ thực tế qua cụm đa nguồn (BigDataCloud + Photon + OSM)
  static Future<String> getAddressFromCoordinates(double lat, double lng) async {
    // 1. Thử nguồn 1: BigDataCloud (Siêu tốc <300ms, hỗ trợ tiếng Việt cực chuẩn, CDN toàn cầu)
    try {
      final uri = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lng&localityLanguage=vi',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Tìm tên đường trong informative
        String road = '';
        final informative = data['localityInfo']?['informative'] as List?;
        if (informative != null) {
          for (var item in informative) {
            final desc = (item['description'] ?? '').toString().toLowerCase();
            final name = (item['name'] ?? '').toString().trim();
            if (desc.contains('road') || desc.contains('street') || desc.contains('thoroughfare') || name.startsWith('Đường')) {
              road = name;
              break;
            }
          }
        }

        final ward = (data['locality'] ?? '').toString().trim();
        final district = (data['city'] ?? '').toString().trim();
        final city = (data['principalSubdivision'] ?? 'TP.HCM').toString().trim();

        final parts = [road, ward, district, city].where((p) => p.isNotEmpty).toList();
        if (parts.length >= 2) {
          return parts.join(', ');
        }
      }
    } catch (_) {}

    // 2. Thử nguồn 2: Photon by Komoot (Dữ liệu OpenStreetMap toàn cầu phản hồi nhanh)
    try {
      final uri = Uri.parse('https://photon.komoot.io/reverse?lat=$lat&lon=$lng');
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final features = data['features'] as List?;
        if (features != null && features.isNotEmpty) {
          final props = features[0]['properties'] as Map<String, dynamic>?;
          if (props != null) {
            final house = (props['housenumber'] ?? '').toString().trim();
            final street = (props['street'] ?? props['name'] ?? '').toString().trim();
            final district = (props['district'] ?? props['suburb'] ?? '').toString().trim();
            final city = (props['city'] ?? 'TP.HCM').toString().trim();

            String streetPart = '';
            if (house.isNotEmpty && street.isNotEmpty) {
              streetPart = "Số $house, $street";
            } else if (street.isNotEmpty) {
              streetPart = street;
            }

            final parts = [streetPart, district, city].where((p) => p.isNotEmpty).toList();
            if (parts.length >= 2) {
              return parts.join(', ');
            }
          }
        }
      }
    } catch (_) {}

    // 3. Thử nguồn 3: OpenStreetMap Nominatim gốc (Timeout 5s)
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
      );
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'FoodDeliveryMobileApp/2.0 (student.project@hcm.edu.vn)',
          'Accept-Language': 'vi,en;q=0.9',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final addr = data['address'] as Map<String, dynamic>?;

        if (addr != null) {
          final houseNumber = (addr['house_number'] ?? addr['house_name'] ?? '').toString().trim();
          final building = (addr['building'] ?? addr['amenity'] ?? addr['shop'] ?? '').toString().trim();
          final road = (addr['road'] ?? addr['pedestrian'] ?? addr['footway'] ?? addr['hamlet'] ?? '').toString().trim();
          final ward = (addr['suburb'] ?? addr['quarter'] ?? addr['neighbourhood'] ?? '').toString().trim();
          final district = (addr['city_district'] ?? addr['district'] ?? addr['county'] ?? '').toString().trim();
          final city = (addr['city'] ?? addr['state'] ?? 'TP.HCM').toString().trim();

          String streetPart = '';
          if (houseNumber.isNotEmpty && road.isNotEmpty) {
            streetPart = "Số $houseNumber, $road";
          } else if (houseNumber.isNotEmpty) {
            streetPart = "Số $houseNumber";
          } else if (road.isNotEmpty) {
            streetPart = road;
          }

          if (building.isNotEmpty && streetPart.isNotEmpty && !streetPart.contains(building)) {
            streetPart = "$building, $streetPart";
          } else if (building.isNotEmpty && streetPart.isEmpty) {
            streetPart = building;
          }

          final parts = [streetPart, ward, district, city].where((p) => p.trim().isNotEmpty).toList();
          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }

        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          final segments = displayName.split(',').map((s) => s.trim()).toList();
          if (segments.length > 3) {
            return segments.take(3).join(', ');
          }
          return displayName;
        }
      }
    } catch (_) {}

    // 4. Fallback cuối cùng: Tự động tính toán và gắn tên quận/khu vực gần nhất tại TP.HCM
    return _getFallbackDistrictAddress(lat, lng);
  }

  static String _getFallbackDistrictAddress(double lat, double lng) {
    Map<String, dynamic>? closest;
    double minDistance = double.infinity;

    for (var d in _tphcmDistricts) {
      double dist = calculateDistanceInKm(lat, lng, d['lat'], d['lng']);
      if (dist < minDistance) {
        minDistance = dist;
        closest = d;
      }
    }

    if (closest != null) {
      return "Khu vực ${closest['name']}, TP. Hồ Chí Minh";
    }

    return defaultAddress;
  }

  /// Tính khoảng cách giữa 2 tọa độ (trả về km)
  static double calculateDistanceInKm(
      double startLat, double startLng, double endLat, double endLng) {
    double distanceInMeters = Geolocator.distanceBetween(
      startLat,
      startLng,
      endLat,
      endLng,
    );
    return double.parse((distanceInMeters / 1000).toStringAsFixed(1));
  }
}
