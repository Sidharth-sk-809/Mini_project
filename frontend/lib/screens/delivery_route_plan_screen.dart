import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../models/order_models.dart';
import '../services/order_service.dart';

class DeliveryRoutePlanScreen extends StatelessWidget {
  final String orderId;

  const DeliveryRoutePlanScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<CustomerOrder>>(
      valueListenable: OrderService.orders,
      builder: (context, _, __) {
        final order = OrderService.byId(orderId);
        if (order == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Route Plan')),
            body: const Center(child: Text('Order not found')),
          );
        }

        final shopOrders = order.shopOrders.where((s) => s.requiresDelivery).toList();

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundColor,
            title: Text('Route Plan', style: AppStyles.heading3),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: AppStyles.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order #${order.id}', style: AppStyles.heading3),
                      const SizedBox(height: 6),
                      Text('Drop Location: ${order.deliveryAddress}', style: AppStyles.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...shopOrders.map(
                  (shopOrder) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: AppStyles.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(shopOrder.shopName, style: AppStyles.bodyLarge),
                        const SizedBox(height: 6),
                        Text('Pickup → ${shopOrder.shopName}', style: AppStyles.bodySmall),
                        Text('Drop → ${order.deliveryAddress}', style: AppStyles.bodySmall),
                        Text(
                          'Status: ${_statusText(shopOrder.deliveryJobStatus)}',
                          style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (shopOrder.deliveryJobStatus == DeliveryJobStatus.accepted)
                              ElevatedButton(
                                onPressed: () {
                                  OrderService.updateDeliveryStatus(
                                    orderId: order.id,
                                    shopOrderId: shopOrder.id,
                                    status: DeliveryJobStatus.pickedUp,
                                  );
                                },
                                child: const Text('Mark Picked Up'),
                              ),
                            if (shopOrder.deliveryJobStatus == DeliveryJobStatus.pickedUp) ...[
                              ElevatedButton(
                                onPressed: () {
                                  OrderService.updateDeliveryStatus(
                                    orderId: order.id,
                                    shopOrderId: shopOrder.id,
                                    status: DeliveryJobStatus.delivered,
                                  );
                                },
                                child: const Text('Mark Delivered'),
                              ),
                            ],
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/delivery_map',
                                  arguments: {
                                    'orderId': order.id,
                                    'shopOrderId': shopOrder.id,
                                  },
                                );
                              },
                              child: const Text('Open Demo Map'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _statusText(DeliveryJobStatus status) {
    switch (status) {
      case DeliveryJobStatus.available:
        return 'Available';
      case DeliveryJobStatus.accepted:
        return 'Accepted';
      case DeliveryJobStatus.pickedUp:
        return 'Picked Up';
      case DeliveryJobStatus.delivered:
        return 'Delivered';
    }
  }
}
