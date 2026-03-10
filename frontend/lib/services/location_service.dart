import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  LocationService._();

  static final ValueNotifier<String> currentLocation =
      ValueNotifier<String>('Edappally, Kochi');

  /// Indicates whether a GPS fetch is in progress.
  static final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  static void setLocation(String location) {
    final trimmed = location.trim();
    if (trimmed.isNotEmpty) {
      currentLocation.value = trimmed;
    }
  }

  /// Requests permission, gets the device's current GPS coordinates, then
  /// reverse-geocodes them into a human-readable suburb/city string.
  /// Returns the resolved address, or null if the user denied permission or
  /// an error occurred.
  static Future<String?> fetchGpsLocation() async {
    isLoading.value = true;
    try {
      // 1. Check / request permission.
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      // 2. Make sure location services are enabled on the device.
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // 3. Get position.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 10));

      // 4. Reverse-geocode to a readable address.
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) return null;

      final p = placemarks.first;
      // Build a short, friendly label: "Suburb, City" or fallback combos.
      final parts = [
        if ((p.subLocality ?? '').isNotEmpty) p.subLocality,
        if ((p.locality ?? '').isNotEmpty) p.locality,
      ];
      final address = parts.isNotEmpty
          ? parts.join(', ')
          : (p.administrativeArea ?? 'Unknown location');

      currentLocation.value = address;
      return address;
    } catch (_) {
      return null;
    } finally {
      isLoading.value = false;
    }
  }
}
