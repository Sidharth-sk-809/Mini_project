import 'dart:math';
import '../models/delivery_models.dart';
import '../models/product_model.dart';
import '../models/shop_model.dart';

class DeliveryService {
  const DeliveryService._();

  static DeliveryEvaluation evaluate({
    required Shop shop,
    required GeoPoint userLocation,
  }) {
    final distanceKm = _distanceKm(shop.location, userLocation);

    if (distanceKm <= shop.deliveryRadiusKm) {
      return DeliveryEvaluation(
        shop: shop,
        distanceKm: distanceKm,
        availability: DeliveryAvailability.available,
      );
    }

    if (shop.supportsPickup && distanceKm <= shop.maxServiceDistanceKm) {
      return DeliveryEvaluation(
        shop: shop,
        distanceKm: distanceKm,
        availability: DeliveryAvailability.pickupOnly,
      );
    }

    return DeliveryEvaluation(
      shop: shop,
      distanceKm: distanceKm,
      availability: DeliveryAvailability.notDeliverable,
    );
  }

  static DeliveryQuote createQuote({
    required Shop shop,
    required List<Product> items,
    required DeliveryType deliveryType,
    required GeoPoint userLocation,
  }) {
    final evaluation = evaluate(shop: shop, userLocation: userLocation);
    final subtotal = items.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );

    double fee = 0;
    var freeDeliveryApplied = false;

    if (deliveryType == DeliveryType.homeDelivery && evaluation.canDeliverHome) {
      if (subtotal >= shop.freeDeliveryAbove) {
        freeDeliveryApplied = true;
      } else {
        fee = shop.baseDeliveryFee + (evaluation.distanceKm * shop.perKmFee);
      }
    }

    final etaMinutes = deliveryType == DeliveryType.shopPickup
        ? 20
        : (25 + (evaluation.distanceKm * 8)).round();

    return DeliveryQuote(
      evaluation: evaluation,
      selectedType: deliveryType,
      orderSubtotal: subtotal,
      deliveryFee: fee,
      freeDeliveryApplied: freeDeliveryApplied,
      eta: Duration(minutes: etaMinutes),
    );
  }

  static double _distanceKm(GeoPoint a, GeoPoint b) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLon = _degToRad(b.longitude - a.longitude);

    final haversine = pow(sin(dLat / 2), 2) +
        cos(_degToRad(a.latitude)) *
            cos(_degToRad(b.latitude)) *
            pow(sin(dLon / 2), 2);

    final arc = 2 * atan2(sqrt(haversine), sqrt(1 - haversine));
    return earthRadiusKm * arc;
  }

  static double _degToRad(double degree) => degree * pi / 180;
}
