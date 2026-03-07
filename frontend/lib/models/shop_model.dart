class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint({
    required this.latitude,
    required this.longitude,
  });
}

class Shop {
  final String id;
  final String name;
  final GeoPoint location;
  final double deliveryRadiusKm;
  final double maxServiceDistanceKm;
  final double baseDeliveryFee;
  final double perKmFee;
  final double freeDeliveryAbove;
  final bool supportsPickup;

  const Shop({
    required this.id,
    required this.name,
    required this.location,
    required this.deliveryRadiusKm,
    required this.maxServiceDistanceKm,
    required this.baseDeliveryFee,
    required this.perKmFee,
    required this.freeDeliveryAbove,
    this.supportsPickup = true,
  });
}
