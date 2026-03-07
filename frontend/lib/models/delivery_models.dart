import 'shop_model.dart';

enum DeliveryType {
  homeDelivery,
  shopPickup,
}

enum DeliveryAvailability {
  available,
  pickupOnly,
  notDeliverable,
}

class DeliveryEvaluation {
  final Shop shop;
  final double distanceKm;
  final DeliveryAvailability availability;

  const DeliveryEvaluation({
    required this.shop,
    required this.distanceKm,
    required this.availability,
  });

  bool get canDeliverHome => availability == DeliveryAvailability.available;

  bool get canPickup =>
      availability == DeliveryAvailability.available ||
      availability == DeliveryAvailability.pickupOnly;

  String get label {
    switch (availability) {
      case DeliveryAvailability.available:
        return 'Delivery Available';
      case DeliveryAvailability.pickupOnly:
        return 'Pickup Only';
      case DeliveryAvailability.notDeliverable:
        return 'Not Deliverable';
    }
  }
}

class DeliveryQuote {
  final DeliveryEvaluation evaluation;
  final DeliveryType selectedType;
  final double orderSubtotal;
  final double deliveryFee;
  final bool freeDeliveryApplied;
  final Duration eta;

  const DeliveryQuote({
    required this.evaluation,
    required this.selectedType,
    required this.orderSubtotal,
    required this.deliveryFee,
    required this.freeDeliveryApplied,
    required this.eta,
  });

  double get finalAmount => orderSubtotal + deliveryFee;
}
