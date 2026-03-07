import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';

class FavoritesService {
  FavoritesService._();

  static const String _key = 'favorite_product_ids';

  static final ValueNotifier<Set<String>> favoriteIds =
      ValueNotifier<Set<String>>({});

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_key) ?? [];
    favoriteIds.value = stored.toSet();
  }

  static bool isFavorite(String productId) =>
      favoriteIds.value.contains(productId);

  static Future<void> toggle(String productId) async {
    final current = Set<String>.from(favoriteIds.value);
    if (current.contains(productId)) {
      current.remove(productId);
    } else {
      current.add(productId);
    }
    favoriteIds.value = current;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, current.toList());
  }

  static List<Product> favoritedProducts() {
    final ids = favoriteIds.value;
    return DummyData.products.where((p) => ids.contains(p.id)).toList();
  }
}
