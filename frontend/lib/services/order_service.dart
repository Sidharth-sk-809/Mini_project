import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/delivery_models.dart';
import '../models/order_models.dart';
import '../models/product_model.dart';
import '../models/shop_model.dart';
import '../models/user_role.dart';
import 'api_client.dart';
import 'delivery_service.dart';
import 'session_service.dart';

class OrderService {
  OrderService._();

  static final ValueNotifier<List<CustomerOrder>> orders =
      ValueNotifier<List<CustomerOrder>>([]);

  static Timer? _autoRefreshTimer;

  static void seedDemoOrdersIfEmpty() {
    unawaited(refreshNow());
    _ensureAutoRefresh();
  }

  static void seedDeliveredDemoOrdersFor({
    required String deliveryUserId,
    required String deliveryName,
  }) {
    unawaited(refreshNow());
    _ensureAutoRefresh();
  }

  static void markPrimaryDemoOrderAvailable() {
    // Backend is source of truth now.
    unawaited(refreshNow());
  }

  static void _ensureAutoRefresh() {
    _autoRefreshTimer ??= Timer.periodic(
      const Duration(seconds: 2),
      (_) => unawaited(refreshNow()),
    );
  }

  static Future<void> refreshNow() async {
    _ensureAutoRefresh();
    if (!SessionService.isLoggedIn) {
      orders.value = [];
      return;
    }

    try {
      final isDelivery = SessionService.role == UserRole.deliveryPerson;

      if (isDelivery) {
        final availableJson = await ApiClient.getList('/api/delivery/orders/available', auth: true);
        final mineJson = await ApiClient.getList('/api/delivery/orders/my', auth: true);

        final map = <String, CustomerOrder>{};
        for (final row in [...availableJson, ...mineJson]) {
          if (row is! Map<String, dynamic>) {
            continue;
          }
          final order = _mapOrder(row);
          if (order == null) {
            continue;
          }
          if (!map.containsKey(order.id)) {
            map[order.id] = order;
            continue;
          }
          final existing = map[order.id]!;
          final merged = [...existing.shopOrders, ...order.shopOrders];
          final deduped = <String, ShopOrder>{};
          for (final so in merged) {
            deduped[so.id] = so;
          }
          map[order.id] = CustomerOrder(
            id: existing.id,
            shopOrders: deduped.values.toList(),
            createdAt: existing.createdAt,
            deliveryAddress: existing.deliveryAddress,
          );
        }

        final list = map.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        orders.value = list;
        return;
      }

      final customerJson = await ApiClient.getList('/api/orders/customer', auth: true);
      final list = customerJson
          .whereType<Map<String, dynamic>>()
          .map(_mapOrder)
          .whereType<CustomerOrder>()
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      orders.value = list;
    } catch (_) {
      // Keep last successful state for offline resilience.
    }
  }

  static Future<CustomerOrder> createOrder({
    required Map<String, List<Product>> groupedItems,
    required Map<String, DeliveryType> selectedTypes,
    required GeoPoint userLocation,
    required String deliveryAddress,
  }) async {
    _ensureAutoRefresh();
    final shopOrdersPayload = <Map<String, dynamic>>[];

    groupedItems.forEach((shopId, items) {
      shopOrdersPayload.add({
        'shop_id': shopId,
        'delivery_type': (selectedTypes[shopId] ?? DeliveryType.homeDelivery) ==
                DeliveryType.homeDelivery
            ? 'home_delivery'
            : 'shop_pickup',
        'items': items
            .map((item) => {
                  'product_id': item.id,
                  'quantity': item.quantity,
                })
            .toList(),
      });
    });

    final response = await ApiClient.post(
      '/api/orders',
      auth: true,
      body: {
        'delivery_address': deliveryAddress,
        'shop_orders': shopOrdersPayload,
      },
    );

    final order = _mapOrder(response);
    if (order == null) {
      throw Exception('Invalid order response');
    }

    final current = List<CustomerOrder>.from(orders.value)
      ..removeWhere((o) => o.id == order.id)
      ..insert(0, order);
    orders.value = current;
    return order;
  }

  static Future<bool> acceptDeliveryTask({
    required String orderId,
    required String shopOrderId,
    required String deliveryUserId,
    required String deliveryName,
  }) async {
    try {
      await ApiClient.post('/api/delivery/orders/$shopOrderId/accept', auth: true);
      await refreshNow();
      return true;
    } catch (_) {
      return false;
    }
  }

  static void updateDeliveryStatus({
    required String orderId,
    required String shopOrderId,
    required DeliveryJobStatus status,
  }) {
    final statusValue = switch (status) {
      DeliveryJobStatus.available => 'available',
      DeliveryJobStatus.accepted => 'accepted',
      DeliveryJobStatus.pickedUp => 'picked_up',
      DeliveryJobStatus.delivered => 'delivered',
    };

    unawaited(
      ApiClient.post(
        '/api/delivery/orders/$shopOrderId/status',
        auth: true,
        body: {'status': statusValue},
      ).then((_) => refreshNow()).catchError((_) {}),
    );
  }

  static List<DeliveryTask> availableDeliveryTasks() {
    final tasks = <DeliveryTask>[];
    for (final order in orders.value) {
      for (final shopOrder in order.shopOrders) {
        if (shopOrder.requiresDelivery &&
            shopOrder.deliveryJobStatus == DeliveryJobStatus.available &&
            shopOrder.assignedDeliveryUserId == null &&
            shopOrder.status != OrderStatus.cancelled) {
          tasks.add(DeliveryTask(customerOrder: order, shopOrder: shopOrder));
        }
      }
    }
    return tasks;
  }

  static List<DeliveryTask> tasksForDeliveryUser(String deliveryUserId) {
    final tasks = <DeliveryTask>[];
    for (final order in orders.value) {
      for (final shopOrder in order.shopOrders) {
        if (shopOrder.assignedDeliveryUserId == deliveryUserId &&
            shopOrder.status != OrderStatus.cancelled) {
          tasks.add(DeliveryTask(customerOrder: order, shopOrder: shopOrder));
        }
      }
    }
    return tasks;
  }

  static void advanceShopOrder(String orderId, String shopOrderId) {
    unawaited(
      ApiClient.post('/api/orders/$shopOrderId/advance', auth: true)
          .then((_) => refreshNow())
          .catchError((_) {}),
    );
  }

  static void cancelBeforeDispatch(String orderId, String shopOrderId) {
    unawaited(
      ApiClient.post('/api/orders/$shopOrderId/cancel', auth: true)
          .then((_) => refreshNow())
          .catchError((_) {}),
    );
  }

  static CustomerOrder? byId(String id) {
    for (final order in orders.value) {
      if (order.id == id) {
        return order;
      }
    }
    return null;
  }

  static CustomerOrder? _mapOrder(Map<String, dynamic> data) {
    final orderId = (data['id'] ?? '').toString();
    if (orderId.isEmpty) {
      return null;
    }

    final rawShopOrders = data['shop_orders'];
    if (rawShopOrders is! List) {
      return null;
    }

    final shopOrders = rawShopOrders
        .whereType<Map<String, dynamic>>()
        .map(_mapShopOrder)
        .whereType<ShopOrder>()
        .toList();

    final createdAt = DateTime.tryParse((data['created_at'] ?? '').toString()) ?? DateTime.now();

    return CustomerOrder(
      id: orderId,
      shopOrders: shopOrders,
      createdAt: createdAt,
      deliveryAddress: (data['delivery_address'] ?? 'Edappally, Kochi').toString(),
    );
  }

  static ShopOrder? _mapShopOrder(Map<String, dynamic> data) {
    final shopOrderId = (data['id'] ?? '').toString();
    final shopId = (data['shop_id'] ?? '').toString();
    if (shopOrderId.isEmpty || shopId.isEmpty) {
      return null;
    }

    final rawItems = data['items'];
    final items = <Product>[];
    if (rawItems is List) {
      for (final row in rawItems.whereType<Map<String, dynamic>>()) {
        items.add(
          Product(
            id: (row['product_id'] ?? '${shopOrderId}_${row['product_name']}').toString(),
            name: (row['product_name'] ?? '').toString(),
            subtitle: (row['subtitle'] ?? '').toString(),
            price: _toDouble(row['price']),
            image: DummyData.resolveProductImagePath((row['product_name'] ?? '').toString()),
            rating: 4.2,
            reviewCount: 20,
            seller: (data['shop_name'] ?? '').toString(),
            vendor: 'Neamet',
            description: (row['product_name'] ?? '').toString(),
            shopId: shopId,
            stock: 999,
            quantity: _toInt(row['quantity']),
            shopDistanceKm: _toDouble(data['shop_distance_km']),
            deliveryAvailable: true,
            shopType: '',
          ),
        );
      }
    }

    final shop = DummyData.shopById(shopId) ??
        Shop(
          id: shopId,
          name: (data['shop_name'] ?? '').toString(),
          location: DummyData.userDeliveryLocation,
          deliveryRadiusKm: 5,
          maxServiceDistanceKm: 10,
          baseDeliveryFee: 20,
          perKmFee: 8,
          freeDeliveryAbove: 700,
        );

    final deliveryTypeValue = (data['selected_delivery_type'] ?? 'home_delivery').toString();
    final selectedType = deliveryTypeValue == 'shop_pickup'
        ? DeliveryType.shopPickup
        : DeliveryType.homeDelivery;

    final evaluation = DeliveryService.evaluate(
      shop: shop,
      userLocation: DummyData.userDeliveryLocation,
    );

    final quote = DeliveryQuote(
      evaluation: evaluation,
      selectedType: selectedType,
      orderSubtotal: items.fold(0, (s, item) => s + (item.price * item.quantity)),
      deliveryFee: _toDouble(data['delivery_fee']),
      freeDeliveryApplied: _toDouble(data['delivery_fee']) <= 0,
      eta: Duration(minutes: _toInt(data['eta_minutes']) <= 0 ? 30 : _toInt(data['eta_minutes'])),
    );

    return ShopOrder(
      id: shopOrderId,
      shopId: shopId,
      shopName: (data['shop_name'] ?? '').toString(),
      items: items,
      quote: quote,
      deliveryPartnerPhone: '+91 90000 12345',
      status: _mapOrderStatus((data['status'] ?? '').toString()),
      deliveryJobStatus: _mapDeliveryStatus((data['delivery_job_status'] ?? '').toString()),
      createdAt: DateTime.now(),
      assignedDeliveryUserId: data['assigned_delivery_user_id']?.toString(),
      assignedDeliveryName: data['assigned_delivery_name']?.toString(),
    );
  }

  static OrderStatus _mapOrderStatus(String value) {
    return switch (value) {
      'placed' => OrderStatus.placed,
      'confirmed' => OrderStatus.confirmed,
      'packed' => OrderStatus.packed,
      'out_for_delivery' => OrderStatus.outForDelivery,
      'delivered' => OrderStatus.delivered,
      'cancelled' => OrderStatus.cancelled,
      _ => OrderStatus.placed,
    };
  }

  static DeliveryJobStatus _mapDeliveryStatus(String value) {
    return switch (value) {
      'available' => DeliveryJobStatus.available,
      'accepted' => DeliveryJobStatus.accepted,
      'picked_up' => DeliveryJobStatus.pickedUp,
      'delivered' => DeliveryJobStatus.delivered,
      _ => DeliveryJobStatus.available,
    };
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
