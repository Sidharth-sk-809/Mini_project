import 'package:flutter/foundation.dart';
import '../models/product_model.dart';

class CartService {
  CartService._();

  static final ValueNotifier<List<Product>> cartItems = ValueNotifier<List<Product>>(
    [
      DummyData.products.first.copyWith(quantity: 1),
      DummyData.products[4].copyWith(quantity: 1),
      DummyData.products[1].copyWith(quantity: 1),
    ],
  );

  static void addProduct(Product product) {
    final items = List<Product>.from(cartItems.value);
    final index = items.indexWhere((item) => item.id == product.id);

    if (index >= 0) {
      final current = items[index];
      if (current.quantity < current.stock) {
        items[index] = current.copyWith(quantity: current.quantity + 1);
      }
    } else {
      items.add(product.copyWith(quantity: 1));
    }

    cartItems.value = items;
  }

  static void removeProduct(String productId) {
    final items = List<Product>.from(cartItems.value)
      ..removeWhere((item) => item.id == productId);
    cartItems.value = items;
  }

  static void setQuantity(String productId, int quantity) {
    if (quantity < 1) {
      removeProduct(productId);
      return;
    }

    final items = List<Product>.from(cartItems.value);
    final index = items.indexWhere((item) => item.id == productId);

    if (index >= 0) {
      final product = items[index];
      final safeQuantity = quantity > product.stock ? product.stock : quantity;
      items[index] = product.copyWith(quantity: safeQuantity);
      cartItems.value = items;
    }
  }

  static void clear() {
    cartItems.value = [];
  }

  static int get totalUnits =>
      cartItems.value.fold(0, (sum, item) => sum + item.quantity);

  static Map<String, List<Product>> groupedByShop() {
    final map = <String, List<Product>>{};
    for (final item in cartItems.value) {
      map.putIfAbsent(item.shopId, () => []).add(item);
    }
    return map;
  }
}
