import 'package:flutter/foundation.dart';

class LocationService {
  LocationService._();

  static final ValueNotifier<String> currentLocation =
      ValueNotifier<String>('Edappally, Kochi');

  static void setLocation(String location) {
    final trimmed = location.trim();
    if (trimmed.isNotEmpty) {
      currentLocation.value = trimmed;
    }
  }

  static void setGpsLocation() {
    currentLocation.value = 'Edappally, Kochi';
  }
}
