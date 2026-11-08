// lib/providers/location_provider.dart
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  Position? _currentPosition;
  String _address = LocationService.defaultAddress;
  bool _isLoading = false;

  Position? get currentPosition => _currentPosition;
  String get address => _address;
  bool get isLoading => _isLoading;

  double get latitude => _currentPosition?.latitude ?? LocationService.defaultLatitude;
  double get longitude => _currentPosition?.longitude ?? LocationService.defaultLongitude;

  LocationProvider() {
    initLocation();
  }

  Future<void> initLocation() async {
    _isLoading = true;
    notifyListeners();

    try {
      final pos = await LocationService.getCurrentPosition();
      if (pos != null) {
        _currentPosition = pos;
        _address = await LocationService.getAddressFromCoordinates(pos.latitude, pos.longitude);
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  void setCustomAddress(String newAddress, double lat, double lng) {
    _address = newAddress;
    _currentPosition = Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 10,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
    notifyListeners();
  }
}
