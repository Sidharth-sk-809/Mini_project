import 'shop_model.dart';

class Product {
  final String id;
  final String name;
  final String subtitle;
  final double price;
  final String image;
  final double rating;
  final int reviewCount;
  final String seller;
  final String vendor;
  final String description;
  final String shopId;
  final int stock;
  final double shopDistanceKm;
  final bool deliveryAvailable;
  final String shopType;
  int quantity;

  Product({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.price,
    required this.image,
    required this.rating,
    required this.reviewCount,
    required this.seller,
    required this.vendor,
    required this.description,
    required this.shopId,
    required this.stock,
    this.shopDistanceKm = 0,
    this.deliveryAvailable = true,
    this.shopType = '',
    this.quantity = 1,
  });

  Product copyWith({
    String? id,
    String? name,
    String? subtitle,
    double? price,
    String? image,
    double? rating,
    int? reviewCount,
    String? seller,
    String? vendor,
    String? description,
    String? shopId,
    int? stock,
    double? shopDistanceKm,
    bool? deliveryAvailable,
    String? shopType,
    int? quantity,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      price: price ?? this.price,
      image: image ?? this.image,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      seller: seller ?? this.seller,
      vendor: vendor ?? this.vendor,
      description: description ?? this.description,
      shopId: shopId ?? this.shopId,
      stock: stock ?? this.stock,
      shopDistanceKm: shopDistanceKm ?? this.shopDistanceKm,
      deliveryAvailable: deliveryAvailable ?? this.deliveryAvailable,
      shopType: shopType ?? this.shopType,
      quantity: quantity ?? this.quantity,
    );
  }

  double get safePrice {
    try {
      return price;
    } catch (_) {
      return 0;
    }
  }

  double get safeDistanceKm {
    try {
      return shopDistanceKm;
    } catch (_) {
      return 0;
    }
  }

  bool get safeDeliveryAvailable {
    try {
      return deliveryAvailable;
    } catch (_) {
      return false;
    }
  }
}

class DemoShop {
  final String id;
  final String name;
  final String type;
  final int distanceKm;
  final bool deliveryAvailable;
  final List<String> productNames;

  const DemoShop({
    required this.id,
    required this.name,
    required this.type,
    required this.distanceKm,
    required this.deliveryAvailable,
    required this.productNames,
  });
}

class DummyData {
  static const GeoPoint userDeliveryLocation = GeoPoint(
    latitude: 9.9816,
    longitude: 76.2999,
  );

  static const String savedAddress = 'Edappally, Kochi';

  static const List<int> rangesKm = [2, 5, 10];

  static List<String> categories = [
    'All',
    'Stationary',
    'Fruits',
    'Medicine',
    'Vegetables',
  ];

  static List<DemoShop> demoShops = [
    DemoShop(
      id: 'green_basket',
      name: 'Green Basket',
      type: 'Vegetable Shop',
      distanceKm: 2,
      deliveryAvailable: true,
      productNames: ['Potato', 'Tomato', 'Carrot', 'Cabbage'],
    ),
    DemoShop(
      id: 'paper_point',
      name: 'Paper Point',
      type: 'Stationary Shop',
      distanceKm: 2,
      deliveryAvailable: true,
      productNames: ['Scale', 'Book', 'Pen', 'Paper', 'Pencil'],
    ),
    DemoShop(
      id: 'fresh_farm_market',
      name: 'Fresh Farm Market',
      type: 'Vegetable Shop',
      distanceKm: 5,
      deliveryAvailable: true,
      productNames: ['Potato', 'Tomato', 'Carrot', 'Cabbage'],
    ),
    DemoShop(
      id: 'study_world',
      name: 'Study World',
      type: 'Stationary Shop',
      distanceKm: 5,
      deliveryAvailable: true,
      productNames: ['Scale', 'Book', 'Pen', 'Paper', 'Pencil'],
    ),
    DemoShop(
      id: 'medico_hub',
      name: 'Medico Hub',
      type: 'Medicine Shop',
      distanceKm: 5,
      deliveryAvailable: true,
      productNames: ['Paracetamol', 'Cough Syrup', 'Bandage'],
    ),
    DemoShop(
      id: 'city_veggies',
      name: 'City Veggies',
      type: 'Vegetable Shop',
      distanceKm: 10,
      deliveryAvailable: false,
      productNames: ['Potato', 'Tomato', 'Carrot', 'Cabbage'],
    ),
    DemoShop(
      id: 'smart_stationers',
      name: 'Smart Stationers',
      type: 'Stationary Shop',
      distanceKm: 10,
      deliveryAvailable: false,
      productNames: ['Scale', 'Book', 'Pen', 'Paper', 'Pencil'],
    ),
    DemoShop(
      id: 'pipemaster_tools',
      name: 'PipeMaster Tools',
      type: 'Plumbing Tools',
      distanceKm: 10,
      deliveryAvailable: false,
      productNames: ['Pipe', 'Tap', 'Wrench', 'Hammer'],
    ),
    DemoShop(
      id: 'bake_house_delight',
      name: 'Bake House Delight',
      type: 'Bakery',
      distanceKm: 10,
      deliveryAvailable: true,
      productNames: ['Bread', 'Bun', 'Cake'],
    ),
  ];

  static final Map<String, String> _assetByProductName = {
    'Potato': 'assets/products/Potato.png',
    'Tomato': 'assets/products/Tomato.png',
    'Carrot': 'assets/products/Carrot.png',
    'Cabbage': 'assets/products/Cabbage.png',
    'Pen': 'assets/products/Pen.png',
    'Pencil': 'assets/products/Pencil.png',
    'Book': 'assets/products/Notebook.png',
    'Hammer': 'assets/products/Hammer.png',
    'Paracetamol': 'assets/products/Paracetamol.png',
    'Cough Syrup': 'assets/products/Cough Syrup.png',
    'Bandage': 'assets/products/Bandage.png',
    'Bun': 'assets/products/Bun.png',
  };


  static final Map<String, String> _normalizedAssetByProductName =
      _assetByProductName.map((key, value) => MapEntry(_normalize(key), value));

  static String resolveProductImagePath(String productName) {
    final image = _normalizedAssetByProductName[_normalize(productName)];
    if (image != null && image.isNotEmpty) {
      return image;
    }
    return 'assets/products/placeholder.png';
  }

  static final Map<String, double> _basePriceByProduct = {
    'Potato': 42,
    'Tomato': 58,
    'Carrot': 70,
    'Cabbage': 48,
    'Pen': 15,
    'Pencil': 12,
    'Book': 38,
    'Hammer': 260,
    'Paracetamol': 45,
    'Cough Syrup': 95,
    'Bandage': 30,
    'Bun': 28,
  };

  static final Map<String, double> _shopMultiplier = {
    'green_basket': 1.00,
    'paper_point': 1.00,
    'fresh_farm_market': 1.08,
    'study_world': 1.06,
    'medico_hub': 1.12,
    'city_veggies': 1.15,
    'smart_stationers': 1.14,
    'pipemaster_tools': 1.20,
    'bake_house_delight': 1.09,
  };

  static List<Product> products = _buildProducts();

  static List<Shop> shops = demoShops
      .map(
        (shop) => Shop(
          id: shop.id,
          name: shop.name,
          location: GeoPoint(
            latitude: userDeliveryLocation.latitude + (shop.distanceKm * 0.002),
            longitude: userDeliveryLocation.longitude + (shop.distanceKm * 0.0015),
          ),
          deliveryRadiusKm: shop.deliveryAvailable ? 5.0 : 0,
          maxServiceDistanceKm: shop.distanceKm.toDouble(),
          baseDeliveryFee:
              shop.deliveryAvailable ? 20.0 + shop.distanceKm.toDouble() : 0.0,
          perKmFee: shop.deliveryAvailable ? 8 : 0,
          freeDeliveryAbove: 700,
          supportsPickup: true,
        ),
      )
      .toList();

  static Shop? shopById(String shopId) {
    for (final shop in shops) {
      if (shop.id == shopId) {
        return shop;
      }
    }
    return null;
  }

  static DemoShop? demoShopById(String shopId) {
    for (final shop in demoShops) {
      if (shop.id == shopId) {
        return shop;
      }
    }
    return null;
  }

  static List<DemoShop> shopsWithinRange(int rangeKm) {
    return demoShops.where((shop) => shop.distanceKm <= rangeKm).toList();
  }

  static List<Product> productsWithinRange(int rangeKm) {
    final allowedShopIds = shopsWithinRange(rangeKm).map((shop) => shop.id).toSet();
    return products.where((product) => allowedShopIds.contains(product.shopId)).toList();
  }

  static List<Product> productsByCategory(String category, int rangeKm) {
    final inRange = productsWithinRange(rangeKm);
    if (category == 'All') {
      return inRange;
    }

    return inRange.where((product) {
      if (category == 'Stationary') {
        return product.shopType == 'Stationary Shop';
      }
      if (category == 'Medicine') {
        return product.shopType == 'Medicine Shop';
      }
      if (category == 'Vegetables') {
        return product.shopType == 'Vegetable Shop';
      }
      if (category == 'Fruits') {
        return product.name == 'Tomato';
      }
      return true;
    }).toList();
  }

  static List<String> matchingCatalogProducts(String query) {
    final q = _normalize(query);
    if (q.isEmpty) {
      return [];
    }

    final names = _assetByProductName.keys
        .where((name) => _normalize(name).contains(q))
        .toList()
      ..sort();

    return names;
  }

  static List<Product> smartProductSearch(String query, int rangeKm) {
    final matchingNames = matchingCatalogProducts(query).toSet();
    if (matchingNames.isEmpty) {
      return [];
    }

    final unique = <String>{};
    final results = <Product>[];

    for (final product in productsWithinRange(rangeKm)) {
      if (!matchingNames.contains(product.name)) {
        continue;
      }

      final key = '${product.shopId}-${product.name}';
      if (unique.add(key)) {
        results.add(product);
      }
    }

    results.sort((a, b) {
      final byName = a.name.compareTo(b.name);
      if (byName != 0) {
        return byName;
      }
      return a.price.compareTo(b.price);
    });

    return results;
  }

  static List<DemoShop> smartShopSearch(String query, int rangeKm) {
    final q = _normalize(query);
    if (q.isEmpty) {
      return [];
    }

    final seenShopIds = <String>{};
    return shopsWithinRange(rangeKm)
        .where((shop) => _normalize(shop.name).contains(q))
        .where((shop) => seenShopIds.add(shop.id))
        .toList();
  }

  static List<Product> productsForShop(String shopId, int rangeKm) {
    final list = productsWithinRange(rangeKm)
        .where((product) => product.shopId == shopId)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }


static void applyRemoteBootstrap(Map<String, dynamic> payload) {
  final rawCategories = payload['categories'];
  if (rawCategories is List) {
    categories = rawCategories.map((e) => e.toString()).toList();
    if (!categories.contains('All')) {
      categories.insert(0, 'All');
    }
  }

  final rawShops = payload['shops'];
  if (rawShops is List) {
    demoShops = rawShops
        .whereType<Map<String, dynamic>>()
        .map(
          (shop) => DemoShop(
            id: (shop['id'] ?? '').toString(),
            name: (shop['name'] ?? '').toString(),
            type: (shop['type'] ?? '').toString(),
            distanceKm: _toInt(shop['distance_km']),
            deliveryAvailable: _toBool(shop['delivery_available']),
            productNames: (shop['product_names'] is List)
                ? (shop['product_names'] as List)
                    .map((e) => e.toString())
                    .toList()
                : <String>[],
          ),
        )
        .where((shop) => shop.id.isNotEmpty && shop.name.isNotEmpty)
        .toList();
  }

  final rawProducts = payload['products'];
  if (rawProducts is List) {
    products = rawProducts
        .whereType<Map<String, dynamic>>()
        .map(
          (product) => Product(
            id: (product['id'] ?? '').toString(),
            name: (product['name'] ?? '').toString(),
            subtitle: (product['subtitle'] ?? '').toString(),
            price: _toDouble(product['price']),
            image: resolveProductImagePath((product['name'] ?? '').toString()),
            rating: _toDouble(product['rating']),
            reviewCount: _toInt(product['review_count']),
            seller: (product['seller'] ?? '').toString(),
            vendor: (product['vendor'] ?? 'Neamet').toString(),
            description: (product['description'] ?? '').toString(),
            shopId: (product['shop_id'] ?? '').toString(),
            stock: _toInt(product['stock']),
            shopDistanceKm: _toDouble(product['shop_distance_km']),
            deliveryAvailable: _toBool(product['delivery_available']),
            shopType: (product['shop_type'] ?? '').toString(),
          ),
        )
        .where((product) =>
            product.id.isNotEmpty &&
            product.shopId.isNotEmpty)
        .toList();
  }

  shops = demoShops
      .map(
        (shop) => Shop(
          id: shop.id,
          name: shop.name,
          location: GeoPoint(
            latitude: userDeliveryLocation.latitude + (shop.distanceKm * 0.002),
            longitude: userDeliveryLocation.longitude + (shop.distanceKm * 0.0015),
          ),
          deliveryRadiusKm: shop.deliveryAvailable ? 5.0 : 0,
          maxServiceDistanceKm: shop.distanceKm.toDouble(),
          baseDeliveryFee:
              shop.deliveryAvailable ? 20.0 + shop.distanceKm.toDouble() : 0.0,
          perKmFee: shop.deliveryAvailable ? 8 : 0,
          freeDeliveryAbove: 700,
          supportsPickup: true,
        ),
      )
      .toList();
}

static int _toInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.round();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

static double _toDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

static bool _toBool(Object? value) {
  if (value is bool) {
    return value;
  }
  final normalized = (value?.toString() ?? '').toLowerCase();
  return normalized == 'true' || normalized == '1';
}

  static List<Product> _buildProducts() {
    final result = <Product>[];
    var idCounter = 1;

    for (final shop in demoShops) {
      for (final productName in shop.productNames) {
        final imagePath = resolveProductImagePath(productName);

        final basePrice = _basePriceByProduct[productName] ?? 50;
        final multiplier = _shopMultiplier[shop.id] ?? 1.0;
        final finalPrice = (basePrice * multiplier).roundToDouble();

        result.add(
          Product(
            id: 'P$idCounter',
            name: productName,
            subtitle: shop.type,
            price: finalPrice,
            image: imagePath,
            rating: 4.0 + ((idCounter % 10) / 10),
            reviewCount: 40 + (idCounter * 7),
            seller: shop.name,
            vendor: 'Neamet',
            description: '$productName from ${shop.name}',
            shopId: shop.id,
            stock: 8 + (idCounter % 12),
            shopDistanceKm: shop.distanceKm.toDouble(),
            deliveryAvailable: shop.deliveryAvailable,
            shopType: shop.type,
          ),
        );

        idCounter++;
      }
    }

    return result;
  }

  static String _normalize(String value) => value.trim().toLowerCase();
}
