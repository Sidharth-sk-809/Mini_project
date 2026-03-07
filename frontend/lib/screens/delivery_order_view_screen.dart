import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../models/order_models.dart';
import '../services/order_service.dart';
import '../services/session_service.dart';

class DeliveryOrderViewScreen extends StatelessWidget {
  final String orderId;
  final bool canAccept;

  const DeliveryOrderViewScreen({
    super.key,
    required this.orderId,
    required this.canAccept,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<CustomerOrder>>(
      valueListenable: OrderService.orders,
      builder: (context, _, __) {
        final order = OrderService.byId(orderId);
        if (order == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Delivery Order')),
            body: const Center(child: Text('Order not found')),
          );
        }

        final shopOrders = order.shopOrders.where((s) => s.requiresDelivery).toList();

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          body: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      ...shopOrders.map((shopOrder) => _buildShopSection(order, shopOrder)),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              _buildBottomButton(context, order, shopOrders),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            Text('Delivery Order', style: AppStyles.heading2),
          ],
        ),
      ),
    );
  }

  Widget _buildShopSection(CustomerOrder order, ShopOrder shopOrder) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: AppStyles.cardDecoration,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${shopOrder.shopName} • Home Delivery',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.heading3,
                  ),
                ),
                _statusChip(shopOrder.deliveryJobStatus),
              ],
            ),
            const SizedBox(height: 10),
            ...shopOrder.items.map(_buildItemCard),
            const SizedBox(height: 8),
            Text(
              'Delivery: ₹${shopOrder.quote.deliveryFee.toStringAsFixed(2)}',
              style: AppStyles.bodyMedium,
            ),
            Text('Pickup → ${shopOrder.shopName}', style: AppStyles.bodySmall),
            Text('Drop → ${order.deliveryAddress}', style: AppStyles.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              item.image,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppStyles.bodyLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(item.subtitle, style: AppStyles.bodySmall),
                const SizedBox(height: 6),
                Text(
                  '₹${item.price.toStringAsFixed(0)}',
                  style: AppStyles.heading3.copyWith(color: AppColors.accentGreen),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text('x${item.quantity}', style: AppStyles.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(
    BuildContext context,
    CustomerOrder order,
    List<ShopOrder> shopOrders,
  ) {
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
                onTap: () async {
                  if (canAccept) {
                    final uid = SessionService.userId?.toString() ?? 'delivery-demo';
                    final name = SessionService.name?.trim().isNotEmpty == true
                        ? SessionService.name!.trim()
                        : 'Delivery Partner';

                    for (final shopOrder in shopOrders) {
                      if (shopOrder.deliveryJobStatus == DeliveryJobStatus.available) {
                        await OrderService.acceptDeliveryTask(
                          orderId: order.id,
                          shopOrderId: shopOrder.id,
                          deliveryUserId: uid,
                          deliveryName: name,
                        );
                      }
                    }
                  }

                  Navigator.pushNamed(
                    context,
                    '/delivery_route_plan',
                    arguments: {'orderId': order.id},
                  );
                },
                child: Center(
                  child: Text(
                    'Proceed To Route Plan',
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

  Widget _statusChip(DeliveryJobStatus status) {
    Color fg;
    Color bg;
    String text;

    switch (status) {
      case DeliveryJobStatus.available:
        text = 'Available';
        fg = const Color(0xFF005BBB);
        bg = const Color(0xFFEAF4FF);
        break;
      case DeliveryJobStatus.accepted:
        text = 'Accepted';
        fg = const Color(0xFFE68A00);
        bg = const Color(0xFFFFF4E8);
        break;
      case DeliveryJobStatus.pickedUp:
        text = 'Picked Up';
        fg = const Color(0xFF8A4FFF);
        bg = const Color(0xFFF0E9FF);
        break;
      case DeliveryJobStatus.delivered:
        text = 'Delivered';
        fg = AppColors.accentGreen;
        bg = const Color(0xFFE8F9F0);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: AppStyles.bodySmall.copyWith(color: fg, fontWeight: FontWeight.w700)),
    );
  }
}
