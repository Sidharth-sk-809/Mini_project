import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../models/delivery_models.dart';
import '../models/product_model.dart';
import '../models/shop_model.dart';
import '../services/cart_service.dart';
import '../services/delivery_service.dart';
import '../services/location_service.dart';
import '../services/order_service.dart';
import '../widgets/cart_item_card.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Map<String, DeliveryType> selectedDeliveryTypes = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: ValueListenableBuilder<List<Product>>(
        valueListenable: CartService.cartItems,
        builder: (context, items, _) {
          final groupedItems = _groupedByShop(items);
          _syncSelectedTypes(groupedItems);

          final quoteByShop = _buildQuotes(groupedItems);
          final subtotal = _subtotal(items);
          final deliveryTotal = _deliveryTotal(quoteByShop);
          final total = subtotal + deliveryTotal;

          return Column(
            children: [
              _buildHeader(),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text('Cart is empty', style: AppStyles.bodyLarge),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            _buildGroupedCart(groupedItems, quoteByShop),
                            const SizedBox(height: 24),
                            _buildPricingSummary(subtotal, deliveryTotal, total),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
              ),
              _buildBottomButton(
                context: context,
                groupedItems: groupedItems,
                quoteByShop: quoteByShop,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowColor,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.arrow_back, color: AppColors.textDark),
              ),
            ),
            const SizedBox(width: 16),
            Text('Your Cart', style: AppStyles.heading2),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedCart(
    Map<String, List<Product>> groupedItems,
    Map<String, DeliveryQuote> quoteByShop,
  ) {
    return Column(
      children: groupedItems.entries.map((entry) {
        final shop = DummyData.shopById(entry.key);
        final quote = quoteByShop[entry.key];

        if (shop == null || quote == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Container(
            decoration: AppStyles.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '${shop.name} • ${quote.evaluation.label}',
                    style: AppStyles.heading3,
                  ),
                ),
                _buildDeliveryTypeSelector(shop, quote.evaluation),
                const SizedBox(height: 8),
                ...entry.value.map(
                  (item) => CartItemCard(
                    item: item,
                    onDelete: () => CartService.removeProduct(item.id),
                    onQuantityChanged: (newQuantity) {
                      CartService.setQuantity(item.id, newQuantity);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(
                    'Delivery: ₹${quote.deliveryFee.toStringAsFixed(2)} (${quote.selectedType == DeliveryType.homeDelivery ? 'Home Delivery' : 'Shop Pickup'})',
                    style: AppStyles.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDeliveryTypeSelector(Shop shop, DeliveryEvaluation evaluation) {
    final shopId = shop.id;
    final selectedType = selectedDeliveryTypes[shopId] ?? DeliveryType.homeDelivery;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            label: const Text('Home Delivery'),
            selected: selectedType == DeliveryType.homeDelivery,
            onSelected: evaluation.canDeliverHome
                ? (_) {
                    setState(() {
                      selectedDeliveryTypes[shopId] = DeliveryType.homeDelivery;
                    });
                  }
                : null,
          ),
          ChoiceChip(
            label: const Text('Shop Pickup'),
            selected: selectedType == DeliveryType.shopPickup,
            onSelected: evaluation.canPickup
                ? (_) {
                    setState(() {
                      selectedDeliveryTypes[shopId] = DeliveryType.shopPickup;
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSummary(double subtotal, double deliveryTotal, double total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppStyles.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Product Total', style: AppStyles.bodyMedium),
                Text('₹${subtotal.toStringAsFixed(2)}', style: AppStyles.bodyMedium),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Delivery Charge', style: AppStyles.bodyMedium),
                Text('₹${deliveryTotal.toStringAsFixed(2)}', style: AppStyles.bodyMedium),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: AppColors.borderColor, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: AppStyles.heading3.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${total.toStringAsFixed(2)}',
                  style: AppStyles.heading3.copyWith(
                    color: AppColors.accentGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton({
    required BuildContext context,
    required Map<String, List<Product>> groupedItems,
    required Map<String, DeliveryQuote> quoteByShop,
  }) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: Container(
            decoration: AppStyles.accentCardDecoration,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: groupedItems.isEmpty
                    ? null
                    : () async {
                        final stockIssue = _validateStock(CartService.cartItems.value);
                        if (stockIssue != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(stockIssue)),
                          );
                          return;
                        }

                        final hasBlockedShop = quoteByShop.values.any(
                          (quote) =>
                              quote.evaluation.availability ==
                                  DeliveryAvailability.notDeliverable &&
                              quote.selectedType == DeliveryType.homeDelivery,
                        );

                        if (hasBlockedShop) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('One or more shops are not deliverable for selected mode'),
                            ),
                          );
                          return;
                        }

                        final order = await OrderService.createOrder(
                          groupedItems: groupedItems,
                          selectedTypes: selectedDeliveryTypes,
                          userLocation: DummyData.userDeliveryLocation,
                          deliveryAddress: LocationService.currentLocation.value,
                        );

                        CartService.clear();
                        Navigator.pushNamed(
                          context,
                          '/order_tracking',
                          arguments: order.id,
                        );
                      },
                child: Center(
                  child: Text(
                    'Proceed To Checkout',
                    style: AppStyles.heading3.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, List<Product>> _groupedByShop(List<Product> items) {
    final grouped = <String, List<Product>>{};

    for (final item in items) {
      grouped.putIfAbsent(item.shopId, () => []).add(item);
    }

    return grouped;
  }

  void _syncSelectedTypes(Map<String, List<Product>> groupedItems) {
    selectedDeliveryTypes.removeWhere((shopId, _) => !groupedItems.containsKey(shopId));

    groupedItems.forEach((shopId, _) {
      final shop = DummyData.shopById(shopId);
      if (shop == null) {
        return;
      }

      final evaluation = DeliveryService.evaluate(
        shop: shop,
        userLocation: DummyData.userDeliveryLocation,
      );

      if (!selectedDeliveryTypes.containsKey(shopId)) {
        selectedDeliveryTypes[shopId] =
            evaluation.canDeliverHome ? DeliveryType.homeDelivery : DeliveryType.shopPickup;
      }

      if (!evaluation.canDeliverHome && selectedDeliveryTypes[shopId] == DeliveryType.homeDelivery) {
        selectedDeliveryTypes[shopId] = DeliveryType.shopPickup;
      }
    });
  }

  Map<String, DeliveryQuote> _buildQuotes(Map<String, List<Product>> groupedItems) {
    final quoteByShop = <String, DeliveryQuote>{};

    groupedItems.forEach((shopId, items) {
      final shop = DummyData.shopById(shopId);
      if (shop == null) {
        return;
      }

      final selectedType = selectedDeliveryTypes[shopId] ?? DeliveryType.homeDelivery;

      quoteByShop[shopId] = DeliveryService.createQuote(
        shop: shop,
        items: items,
        deliveryType: selectedType,
        userLocation: DummyData.userDeliveryLocation,
      );
    });

    return quoteByShop;
  }

  double _subtotal(List<Product> items) {
    return items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  double _deliveryTotal(Map<String, DeliveryQuote> quoteByShop) {
    return quoteByShop.values.fold(0.0, (sum, quote) => sum + quote.deliveryFee);
  }

  String? _validateStock(List<Product> items) {
    for (final item in items) {
      if (item.quantity > item.stock) {
        return 'Insufficient stock for ${item.name}';
      }
    }
    return null;
  }
}
