import 'delivery_models.dart';
import 'product_model.dart';

enum OrderStatus {
  placed,
  confirmed,
  packed,
  outForDelivery,
  delivered,
  cancelled,
}

enum DeliveryJobStatus {
  available,
  accepted,
  pickedUp,
  delivered,
}

class ShopOrder {
  final String id;
  final String shopId;
  final String shopName;
  final List<Product> items;
  final DeliveryQuote quote;
  final String deliveryPartnerPhone;
  OrderStatus status;
  DeliveryJobStatus deliveryJobStatus;
  String? assignedDeliveryUserId;
  String? assignedDeliveryName;
  final DateTime createdAt;

  ShopOrder({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.items,
    required this.quote,
    required this.deliveryPartnerPhone,
    required this.status,
    required this.deliveryJobStatus,
    required this.createdAt,
    this.assignedDeliveryUserId,
    this.assignedDeliveryName,
  });

  bool get canCancelBeforeDispatch =>
      status != OrderStatus.cancelled &&
      status != OrderStatus.outForDelivery &&
      status != OrderStatus.delivered;

  bool get requiresDelivery => quote.selectedType == DeliveryType.homeDelivery;

  double get itemsTotal => items.fold(
        0,
        (sum, item) => sum + (item.price * item.quantity),
      );

  double get deliveryEarning => quote.deliveryFee;
}

class CustomerOrder {
  final String id;
  final List<ShopOrder> shopOrders;
  final DateTime createdAt;
  final String deliveryAddress;

  CustomerOrder({
    required this.id,
    required this.shopOrders,
    required this.createdAt,
    required this.deliveryAddress,
  });

  double get productTotal => shopOrders.fold(0, (sum, order) => sum + order.itemsTotal);

  double get deliveryTotal =>
      shopOrders.fold(0, (sum, order) => sum + order.quote.deliveryFee);

  double get grandTotal => productTotal + deliveryTotal;
}

class DeliveryTask {
  final CustomerOrder customerOrder;
  final ShopOrder shopOrder;

  DeliveryTask({
    required this.customerOrder,
    required this.shopOrder,
  });
}
