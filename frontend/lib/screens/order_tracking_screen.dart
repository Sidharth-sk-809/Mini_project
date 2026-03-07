import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../models/order_models.dart';
import '../services/order_service.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;

  const OrderTrackingScreen({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<CustomerOrder>>(
      valueListenable: OrderService.orders,
      builder: (context, _, __) {
        final order = OrderService.byId(orderId);

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundColor,
            elevation: 0,
            title: Text('Order Tracking', style: AppStyles.heading3),
          ),
          body: order == null
              ? Center(
                  child: Text('Order not found', style: AppStyles.bodyMedium),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummary(order),
                      const SizedBox(height: 16),
                      ...order.shopOrders.map(
                        (shopOrder) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildShopCard(context, order, shopOrder),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildSummary(CustomerOrder order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Combined Order Summary', style: AppStyles.heading3),
          const SizedBox(height: 8),
          Text('Order ID: ${order.id}', style: AppStyles.bodySmall),
          Text('Address: ${order.deliveryAddress}', style: AppStyles.bodySmall),
          const SizedBox(height: 8),
          Text('Products: ₹${order.productTotal.toStringAsFixed(2)}', style: AppStyles.bodyMedium),
          Text('Delivery: ₹${order.deliveryTotal.toStringAsFixed(2)}', style: AppStyles.bodyMedium),
          Text(
            'Total: ₹${order.grandTotal.toStringAsFixed(2)}',
            style: AppStyles.heading3.copyWith(color: AppColors.accentGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildShopCard(
    BuildContext context,
    CustomerOrder order,
    ShopOrder shopOrder,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(shopOrder.shopName, style: AppStyles.heading3),
          const SizedBox(height: 6),
          Text('Status: ${_statusLabel(shopOrder.status)}', style: AppStyles.bodyMedium),
          Text(
            'Delivery Status: ${_deliveryStatusLabel(shopOrder.deliveryJobStatus)}',
            style: AppStyles.bodyMedium,
          ),
          Text(
            'Estimated delivery: ${shopOrder.quote.eta.inMinutes} mins',
            style: AppStyles.bodySmall,
          ),
          if (shopOrder.assignedDeliveryName != null)
            Text(
              'Delivery assigned: ${shopOrder.assignedDeliveryName} (${shopOrder.deliveryPartnerPhone})',
              style: AppStyles.bodySmall,
            )
          else
            Text(
              'Delivery assigned: Pending',
              style: AppStyles.bodySmall,
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              if (shopOrder.canCancelBeforeDispatch)
                _actionButton(
                  label: 'Cancel Before Dispatch',
                  color: Colors.redAccent,
                  onTap: () {
                    OrderService.cancelBeforeDispatch(order.id, shopOrder.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Shop order cancelled')),
                    );
                  },
                ),
              if (shopOrder.status != OrderStatus.delivered &&
                  shopOrder.status != OrderStatus.cancelled)
                _actionButton(
                  label: 'Advance Status',
                  color: AppColors.accentGreen,
                  onTap: () {
                    OrderService.advanceShopOrder(order.id, shopOrder.id);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: AppStyles.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return 'Placed';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.packed:
        return 'Packed';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _deliveryStatusLabel(DeliveryJobStatus status) {
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
