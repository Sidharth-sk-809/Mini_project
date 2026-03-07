import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../models/product_model.dart';
import '../services/cart_service.dart';
import '../services/delivery_service.dart';
import '../widgets/product_card.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildProductImage(),
                  _buildProductInfo(),
                  _buildDeliveryAvailability(),
                  _buildTabBar(),
                  _buildTabContent(),
                  const SizedBox(height: 24),
                  _buildYouMightAlsoLike(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _buildAddToCartButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            Text('Details', style: AppStyles.heading3),
            Container(
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
              child: Icon(Icons.favorite_outline, color: AppColors.textDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Image.asset(
          widget.product.image,
          height: 280,
          width: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            height: 280,
            color: AppColors.lightGray,
            child: const Icon(Icons.image_not_supported, color: Color(0xFFB0B0B0), size: 40),
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.product.name, style: AppStyles.heading2),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_half, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.product.rating}',
                      style: AppStyles.label.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('(${widget.product.reviewCount} Reviews)', style: AppStyles.bodySmall),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: 'Seller: ', style: AppStyles.bodySmall),
                    TextSpan(
                      text: widget.product.seller,
                      style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: 'Vendor: ', style: AppStyles.bodySmall),
                    TextSpan(
                      text: widget.product.vendor,
                      style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${widget.product.price.toStringAsFixed(0)}',
            style: AppStyles.heading3.copyWith(color: AppColors.accentGreen),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDeliveryAvailability() {
    final shop = DummyData.shopById(widget.product.shopId);
    if (shop == null) {
      return const SizedBox.shrink();
    }

    final evaluation = DeliveryService.evaluate(
      shop: shop,
      userLocation: DummyData.userDeliveryLocation,
    );

    final labelColor = evaluation.canDeliverHome
        ? AppColors.accentGreen
        : evaluation.canPickup
            ? Colors.orange
            : Colors.redAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: AppStyles.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delivery Availability', style: AppStyles.heading3),
            const SizedBox(height: 8),
            Text(
              evaluation.label,
              style: AppStyles.bodyLarge.copyWith(color: labelColor),
            ),
            Text(
              'Distance from shop: ${evaluation.distanceKm.toStringAsFixed(1)} km',
              style: AppStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _buildTabButton('Details', 0),
            _buildTabButton('Support', 1),
            _buildTabButton('Ratings', 2),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isActive = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.accentGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppStyles.bodyMedium.copyWith(
              color: isActive ? Colors.white : AppColors.textDark,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (selectedTab == 0) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description', style: AppStyles.heading3),
            const SizedBox(height: 12),
            Text(
              widget.product.description,
              style: AppStyles.bodyMedium,
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      );
    }

    if (selectedTab == 1) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Support', style: AppStyles.heading3),
            const SizedBox(height: 12),
            Text(
              'Contact support for delivery, pickup and tracking help.',
              style: AppStyles.bodyMedium,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ratings', style: AppStyles.heading3),
          const SizedBox(height: 12),
          Text(
            'This product has a rating of ${widget.product.rating} stars based on ${widget.product.reviewCount} reviews.',
            style: AppStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildYouMightAlsoLike() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('You Might Also Like', style: AppStyles.heading3),
              Text(
                'View All',
                style: AppStyles.bodyMedium.copyWith(color: AppColors.accentGreen),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: DummyData.products.length > 3 ? 3 : DummyData.products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, index) {
              return SizedBox(
                width: 160,
                child: ProductCard(
                  product: DummyData.products[index],
                  onTap: () {
                    Navigator.pushReplacementNamed(
                      context,
                      '/product_details',
                      arguments: DummyData.products[index],
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddToCartButton() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: DecoratedBox(
            decoration: AppStyles.accentCardDecoration,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  CartService.addProduct(widget.product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${widget.product.name} added to cart'),
                      duration: const Duration(milliseconds: 900),
                    ),
                  );
                },
                child: Center(
                  child: Text(
                    'Add To Cart',
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
}
