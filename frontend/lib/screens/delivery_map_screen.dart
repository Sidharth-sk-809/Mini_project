import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../models/order_models.dart';
import '../services/order_service.dart';

class DeliveryMapScreen extends StatelessWidget {
  final String orderId;
  final String shopOrderId;

  const DeliveryMapScreen({
    super.key,
    required this.orderId,
    required this.shopOrderId,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<CustomerOrder>>(
      valueListenable: OrderService.orders,
      builder: (context, _, __) {
        final order = OrderService.byId(orderId);
        final shopOrder = order?.shopOrders.where((s) => s.id == shopOrderId).firstOrNull;

        if (order == null || shopOrder == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Delivery Map')),
            body: const Center(child: Text('Delivery task not found')),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundColor,
            title: Text('Demo Delivery Map', style: AppStyles.heading3),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pickup → ${shopOrder.shopName}', style: AppStyles.bodyMedium),
                Text('Drop → ${order.deliveryAddress}', style: AppStyles.bodyMedium),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 280,
                  decoration: AppStyles.cardDecoration,
                  child: CustomPaint(
                    painter: _DemoRoutePainter(),
                    child: const SizedBox.expand(),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Delivery Status: ${_deliveryStatusText(shopOrder.deliveryJobStatus)}',
                  style: AppStyles.heading3,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
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
                    if (shopOrder.deliveryJobStatus == DeliveryJobStatus.pickedUp)
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _deliveryStatusText(DeliveryJobStatus status) {
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

class _DemoRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.accentGreen
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final routePath = Path()
      ..moveTo(size.width * 0.2, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.35,
        size.width * 0.8,
        size.height * 0.2,
      );

    canvas.drawPath(routePath, linePaint);

    final shopPoint = Offset(size.width * 0.2, size.height * 0.75);
    final customerPoint = Offset(size.width * 0.8, size.height * 0.2);

    final shopPaint = Paint()..color = Colors.orange;
    final customerPaint = Paint()..color = Colors.blue;

    canvas.drawCircle(shopPoint, 10, shopPaint);
    canvas.drawCircle(customerPoint, 10, customerPaint);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(
      text: 'Shop',
      style: AppStyles.bodySmall.copyWith(color: Colors.orange.shade800),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(shopPoint.dx - 12, shopPoint.dy + 14));

    textPainter.text = TextSpan(
      text: 'Customer',
      style: AppStyles.bodySmall.copyWith(color: Colors.blue.shade800),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(customerPoint.dx - 22, customerPoint.dy - 30));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

extension _FirstOrNullExt<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
