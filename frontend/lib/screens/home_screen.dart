import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../models/order_models.dart';
import '../models/product_model.dart';
import '../services/cart_service.dart';
import '../services/auth_service.dart';
import '../services/catalog_api_service.dart';
import '../services/favorites_service.dart';
import '../services/location_service.dart';
import '../services/order_service.dart';
import '../services/session_service.dart';
import '../widgets/category_item.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedCategory = 0;
  int selectedRangeKm = 2;
  int selectedBottomTab = 0;
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  String get _userName => SessionService.name?.trim().isNotEmpty == true
      ? SessionService.name!.trim()
      : 'User Name';

  @override
  void initState() {
    super.initState();
    if (!DummyData.rangesKm.contains(selectedRangeKm)) {
      selectedRangeKm = 2;
    }
    LocationService.setLocation(SessionService.location);
    FavoritesService.init();
    OrderService.seedDemoOrdersIfEmpty();
    _syncCatalog();
  }

  Future<void> _syncCatalog() async {
    final synced = await CatalogApiService.syncCatalog(rangeKm: 10);
    if (!mounted || !synced) {
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: selectedBottomTab == 3
                  ? _buildAccountTab()
                  : selectedBottomTab == 1
                      ? _buildFavoritesTab()
                      : selectedBottomTab == 2
                          ? _buildOrdersTab()
                          : Column(
                              children: [
                                _buildSearchBar(),
                                const SizedBox(height: 20),
                                _buildCategories(),
                                const SizedBox(height: 24),
                                if (searchQuery.trim().isEmpty) _buildSpecialOfferCard(),
                                const SizedBox(height: 24),
                                searchQuery.trim().isEmpty
                                    ? _buildPopularItems(context)
                                    : _buildSearchResults(context),
                                const SizedBox(height: 80),
                              ],
                            ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
      floatingActionButton: _buildFloatingCart(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.lightGray,
                  child: Icon(Icons.person_outline, color: AppColors.primaryDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyles.welcomeSmall.copyWith(color: Colors.white70),
                      ),
                      Text(
                        _userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyles.heading3.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(Icons.notifications_outlined, color: AppColors.primaryDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search product or shop...',
          hintStyle: AppStyles.bodyMedium.copyWith(color: const Color(0xFFB0B0B0)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFFB0B0B0)),
          filled: true,
          fillColor: AppColors.cardBackground,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildRangeSelector() {
    return Padding(
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          Text('Range', style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          ...DummyData.rangesKm.map(
            (range) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('$range km'),
                selected: selectedRangeKm == range,
                onSelected: (_) {
                  setState(() {
                    selectedRangeKm = range;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 110,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: DummyData.categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (_, index) {
            const icons = [
              Icons.apps,
              Icons.edit_note,
              Icons.apple,
              Icons.medical_services,
              Icons.eco,
            ];

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedCategory = index;
                });
              },
              child: CategoryItem(
                label: DummyData.categories[index],
                icon: icons[index],
                isActive: selectedCategory == index,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSpecialOfferCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppStyles.cardDecoration,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '35% Discount',
                    style: AppStyles.heading3.copyWith(
                      color: AppColors.accentGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '100% Guaranteed all Fresh Grocery Items',
                    style: AppStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: AppStyles.accentCardDecoration,
                    child: Text(
                      'Shop Now',
                      style: AppStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/products/Potato.png',
                width: 90,
                height: 90,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularItems(BuildContext context) {
    final safeCategoryIndex =
        selectedCategory >= 0 && selectedCategory < DummyData.categories.length
            ? selectedCategory
            : 0;
    final category = DummyData.categories[safeCategoryIndex];
    var products = DummyData.productsByCategory(category, selectedRangeKm);
    if (products.isEmpty) {
      products = DummyData.productsByCategory('All', selectedRangeKm);
    }
    if (products.isEmpty) {
      products = _defaultPopularProducts();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Popular Items', style: AppStyles.heading2),
              Text('View All', style: AppStyles.bodyMedium.copyWith(color: AppColors.accentGreen)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (products.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.50,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: products.length,
            itemBuilder: (_, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                onTap: () => Navigator.pushNamed(context, '/product_details', arguments: product),
                onAddPressed: () {
                  CartService.addProduct(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${product.name} added to cart')),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  List<Product> _defaultPopularProducts() {
    final defaultProducts = DummyData.productsByCategory('All', 2);
    if (defaultProducts.isNotEmpty) {
      return defaultProducts;
    }

    // Last-resort fallback from full catalog to avoid empty popular section.
    return DummyData.products.take(8).toList();
  }

  Widget _buildSearchResults(BuildContext context) {
    final query = searchQuery.trim();
    final productNameMatches = DummyData.matchingCatalogProducts(query);
    final queryMatchesCatalogProduct = productNameMatches.isNotEmpty;

    // Search order:
    // 1) Range is always applied inside helper methods.
    // 2) If query matches catalog products, show product comparison only.
    // 3) If no product match, try shop matching.
    final matchingProducts = queryMatchesCatalogProduct
        ? DummyData.smartProductSearch(query, selectedRangeKm)
        : <Product>[];
    final matchingShops = queryMatchesCatalogProduct
        ? <DemoShop>[]
        : DummyData.smartShopSearch(query, selectedRangeKm);

    final noResults = queryMatchesCatalogProduct
        ? matchingProducts.isEmpty
        : matchingShops.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (queryMatchesCatalogProduct && matchingProducts.isNotEmpty) ...[
            Text('Price Comparison', style: AppStyles.heading3),
            const SizedBox(height: 10),
            ...matchingProducts.map(
              (product) => _buildPriceComparisonTile(context, product),
            ),
            const SizedBox(height: 16),
          ],
          if (!queryMatchesCatalogProduct && matchingShops.isNotEmpty) ...[
            Text('Matching Shops', style: AppStyles.heading3),
            const SizedBox(height: 10),
            ...matchingShops.map((shop) => _buildShopCard(context, shop)),
          ],
          if (noResults)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text('No results found', style: AppStyles.bodyMedium),
            ),
        ],
      ),
    );
  }

  Widget _buildPriceComparisonTile(BuildContext context, Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: AppStyles.cardDecoration,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: () => Navigator.pushNamed(context, '/product_details', arguments: product),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(product.image, width: 44, height: 44, fit: BoxFit.cover),
        ),
        title: Text(product.name, style: AppStyles.bodyLarge),
        subtitle: Text(
          '${product.seller} • ${product.shopDistanceKm.toStringAsFixed(0)} km',
          style: AppStyles.bodySmall,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${product.price.toStringAsFixed(0)}',
              style: AppStyles.bodyLarge.copyWith(color: AppColors.accentGreen),
            ),
            Text(
              product.deliveryAvailable ? 'Delivery' : 'Pickup',
              style: AppStyles.bodySmall.copyWith(
                color: product.deliveryAvailable ? AppColors.accentGreen : Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopCard(BuildContext context, DemoShop shop) {
    final shopProducts = DummyData.productsForShop(shop.id, selectedRangeKm);
    final uniqueNames = shopProducts.map((p) => p.name).toSet().toList()..sort();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.storefront, color: AppColors.primaryDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shop.name, style: AppStyles.bodyLarge),
                    Text('${shop.type} • ${shop.distanceKm} km', style: AppStyles.bodySmall),
                  ],
                ),
              ),
              Text(
                shop.deliveryAvailable ? 'Delivery' : 'Pickup',
                style: AppStyles.bodySmall.copyWith(
                  color: shop.deliveryAvailable ? AppColors.accentGreen : Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (uniqueNames.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Products', style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: uniqueNames
                  .map(
                    (name) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.lightGray,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(name, style: AppStyles.bodySmall),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFavoritesTab() {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: FavoritesService.favoriteIds,
      builder: (context, ids, _) {
        final favorites = FavoritesService.favoritedProducts();
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('My Favourites', style: AppStyles.heading2),
                  if (favorites.isNotEmpty)
                    Text(
                      '${favorites.length} items',
                      style: AppStyles.bodySmall.copyWith(color: AppColors.accentGreen),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (favorites.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Column(
                      children: [
                        Icon(Icons.favorite_border, size: 64, color: AppColors.lightGray),
                        const SizedBox(height: 16),
                        Text('No favourites yet', style: AppStyles.heading3),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the ♡ on any product to save it here',
                          style: AppStyles.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.50,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: favorites.length,
                  itemBuilder: (_, index) {
                    final product = favorites[index];
                    return ProductCard(
                      product: product,
                      onTap: () =>
                          Navigator.pushNamed(context, '/product_details', arguments: product),
                      onAddPressed: () {
                        CartService.addProduct(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${product.name} added to cart')),
                        );
                      },
                    );
                  },
                ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrdersTab() {
    return ValueListenableBuilder<List<CustomerOrder>>(
      valueListenable: OrderService.orders,
      builder: (context, orders, _) {
        final customerOrders = orders
            .where((o) => o.shopOrders.isNotEmpty)
            .toList();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('My Orders', style: AppStyles.heading2),
                  if (customerOrders.isNotEmpty)
                    Text(
                      '${customerOrders.length} orders',
                      style: AppStyles.bodySmall.copyWith(color: AppColors.accentGreen),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (customerOrders.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.lightGray),
                        const SizedBox(height: 16),
                        Text('No orders yet', style: AppStyles.heading3),
                        const SizedBox(height: 8),
                        Text(
                          'Your order history will appear here',
                          style: AppStyles.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...customerOrders.map((order) => _buildOrderCard(context, order)),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, CustomerOrder order) {
    final firstShopOrder = order.shopOrders.first;
    final statusLabel = _orderStatusLabel(firstShopOrder.status);
    final statusColor = _orderStatusColor(firstShopOrder.status);
    final totalItems = order.shopOrders.fold<int>(
      0,
      (sum, so) => sum + so.items.fold<int>(0, (s, i) => s + i.quantity),
    );

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/order_tracking', arguments: order.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: AppStyles.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Order #${order.id.replaceFirst('ORD-', '')}',
                    style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: AppStyles.bodySmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${order.shopOrders.length} shop${order.shopOrders.length > 1 ? 's' : ''} • $totalItems item${totalItems > 1 ? 's' : ''}',
              style: AppStyles.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              order.deliveryAddress,
              style: AppStyles.bodySmall.copyWith(color: AppColors.textDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(order.createdAt),
                  style: AppStyles.bodySmall,
                ),
                Text(
                  '₹${order.grandTotal.toStringAsFixed(0)}',
                  style: AppStyles.bodyLarge.copyWith(
                    color: AppColors.accentGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _orderStatusLabel(OrderStatus status) {
    return switch (status) {
      OrderStatus.placed => 'Placed',
      OrderStatus.confirmed => 'Confirmed',
      OrderStatus.packed => 'Packed',
      OrderStatus.outForDelivery => 'Out for Delivery',
      OrderStatus.delivered => 'Delivered',
      OrderStatus.cancelled => 'Cancelled',
    };
  }

  Color _orderStatusColor(OrderStatus status) {
    return switch (status) {
      OrderStatus.placed => Colors.orange,
      OrderStatus.confirmed => Colors.blue,
      OrderStatus.packed => Colors.purple,
      OrderStatus.outForDelivery => AppColors.accentGreen,
      OrderStatus.delivered => AppColors.accentGreen,
      OrderStatus.cancelled => Colors.red,
    };
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Widget _buildAccountTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ValueListenableBuilder<String>(
        valueListenable: LocationService.currentLocation,
        builder: (context, location, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Account', style: AppStyles.heading2),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: AppStyles.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Location: $location', style: AppStyles.bodyLarge),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _showSetLocationSheet,
                      child: const Text('Set Current Location'),
                    ),
                    const SizedBox(height: 16),
                    _buildRangeSelector(),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _confirmLogout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSetLocationSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Set Current Location', style: AppStyles.heading3),
                const SizedBox(height: 12),
                ValueListenableBuilder<bool>(
                  valueListenable: LocationService.isLoading,
                  builder: (context, loading, _) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.gps_fixed),
                      title: const Text('Use Current GPS Location'),
                      onTap: loading
                          ? null
                          : () async {
                              // Capture before async gap to satisfy context-safety lint.
                              final messenger = ScaffoldMessenger.of(context);
                              Navigator.pop(ctx);
                              final address =
                                  await LocationService.fetchGpsLocation();
                              if (!mounted) return;
                              if (address == null) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Could not get GPS location. Check permissions or use manual entry.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              // Persist to backend + session.
                              await AuthService.updateLocation(address);
                            },
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.edit_location_alt),
                  title: const Text('Enter Location Manually'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showManualLocationDialog();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showManualLocationDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Manual Location'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Ex: Edappally, Kochi'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final loc = controller.text.trim();
                LocationService.setLocation(loc);
                Navigator.pop(context);
                // Fire-and-forget: persist to backend without blocking UI.
                AuthService.updateLocation(loc);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Do you want to logout from this account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    await AuthService.signOut();
    if (!mounted) {
      return;
    }
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomAppBar(
        color: AppColors.cardBackground,
        elevation: 0,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSmallNavItem(Icons.home, 'Home', 0),
              _buildSmallNavItem(Icons.favorite_outline, 'Favorite', 1),
              const SizedBox(width: 40),
              _buildSmallNavItem(Icons.receipt_long_outlined, 'Order', 2),
              _buildSmallNavItem(Icons.account_circle_outlined, 'Account', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallNavItem(IconData icon, String label, int tabIndex) {
    final isActive = selectedBottomTab == tabIndex;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedBottomTab = tabIndex;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? AppColors.accentGreen : const Color(0xFFB0B0B0),
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w400,
              color: isActive ? AppColors.accentGreen : const Color(0xFFB0B0B0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingCart() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/cart'),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.accentGreen,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 28),
            Positioned(
              top: 8,
              right: 8,
              child: ValueListenableBuilder<List<Product>>(
                valueListenable: CartService.cartItems,
                builder: (_, __, ___) {
                  return Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF4757),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${CartService.totalUnits}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
