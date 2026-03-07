import 'dart:collection';
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../models/order_models.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../services/session_service.dart';

class DeliveryDashboardScreen extends StatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  State<DeliveryDashboardScreen> createState() => _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen> {
  String get _deliveryUserId => (SessionService.userId?.toString() ?? 'delivery-demo');

  String get _deliveryName => SessionService.name?.trim().isNotEmpty == true
      ? SessionService.name!.trim()
      : 'Delivery Partner';

  @override
  void initState() {
    super.initState();
    OrderService.seedDemoOrdersIfEmpty();
    OrderService.seedDeliveredDemoOrdersFor(
      deliveryUserId: _deliveryUserId,
      deliveryName: _deliveryName,
    );
    OrderService.markPrimaryDemoOrderAvailable();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<CustomerOrder>>(
      valueListenable: OrderService.orders,
      builder: (context, _, __) {
        final available = OrderService.availableDeliveryTasks();
        final mine = OrderService.tasksForDeliveryUser(_deliveryUserId);
        final deliveredCount = mine
            .where((task) => task.shopOrder.deliveryJobStatus == DeliveryJobStatus.delivered)
            .length;

        final availableCountDisplay = available.isEmpty ? 1 : available.length;
        final availableGroups = _groupTasksByOrder(available);
        final mineGroups = _groupTasksByOrder(mine);

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            title: const Text('Delivery Dashboard'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _confirmLogout(context),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: AppStyles.cardDecoration,
                  child: Row(
                    children: [
                      Expanded(
                        child: _statTile(
                          'Available',
                          '$availableCountDisplay',
                          Icons.local_shipping_outlined,
                          isAvailableTile: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _statTile('Delivered', '$deliveredCount', Icons.check_circle_outline)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text('Available Orders', style: AppStyles.heading3),
                const SizedBox(height: 10),
                if (availableGroups.isEmpty)
                  Text('No available orders', style: AppStyles.bodyMedium)
                else
                  ...availableGroups.map(
                    (group) => _buildOrderGroupCard(
                      context: context,
                      order: group.key,
                      tasks: group.value,
                      canAccept: true,
                    ),
                  ),
                const SizedBox(height: 18),
                Text('My Deliveries', style: AppStyles.heading3),
                const SizedBox(height: 10),
                if (mineGroups.isEmpty)
                  Text('No assigned deliveries', style: AppStyles.bodyMedium)
                else
                  ...mineGroups.map(
                    (group) => _buildOrderGroupCard(
                      context: context,
                      order: group.key,
                      tasks: group.value,
                      canAccept: false,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<MapEntry<CustomerOrder, List<DeliveryTask>>> _groupTasksByOrder(List<DeliveryTask> tasks) {
    final map = LinkedHashMap<String, MapEntry<CustomerOrder, List<DeliveryTask>>>();

    for (final task in tasks) {
      final orderId = task.customerOrder.id;
      if (!map.containsKey(orderId)) {
        map[orderId] = MapEntry(task.customerOrder, <DeliveryTask>[]);
      }
      map[orderId]!.value.add(task);
    }

    return map.values.toList();
  }

  Widget _statTile(
    String label,
    String value,
    IconData icon, {
    bool isAvailableTile = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isAvailableTile ? Colors.white : AppColors.lightGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentGreen),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
              Text(label, style: AppStyles.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderGroupCard({
    required BuildContext context,
    required CustomerOrder order,
    required List<DeliveryTask> tasks,
    required bool canAccept,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order #${order.id}', style: AppStyles.bodyLarge),
          const SizedBox(height: 4),
          Text('Drop → ${order.deliveryAddress}', style: AppStyles.bodySmall),
          const SizedBox(height: 10),
          ...tasks.map((task) => _buildShopBlock(context, order, task, canAccept)),
        ],
      ),
    );
  }

  Widget _buildShopBlock(
    BuildContext context,
    CustomerOrder order,
    DeliveryTask task,
    bool canAccept,
  ) {
    final status = task.shopOrder.deliveryJobStatus;
    final isPrimaryDemoOrder = order.id.startsWith('ORD-DEMO-') &&
        !order.id.startsWith('ORD-DEMO-DONE-') &&
        !order.id.startsWith('ORD-DEMO-AVL-');
    final items = task.shopOrder.items.map((i) => i.name).join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPrimaryDemoOrder ? Colors.white : AppColors.lightGray,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  task.shopOrder.shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              isPrimaryDemoOrder
                  ? _customStatusChip(
                      'New Order',
                      fg: const Color(0xFF005BBB),
                      bg: const Color(0xFFEAF4FF),
                    )
                  : _statusChip(status),
            ],
          ),
          const SizedBox(height: 6),
          Text('Products: $items', style: AppStyles.bodySmall),
          Text('Product Cost: ₹${task.shopOrder.itemsTotal.toStringAsFixed(0)}', style: AppStyles.bodySmall),
          Text('Delivery Fee: ₹${task.shopOrder.quote.deliveryFee.toStringAsFixed(0)}', style: AppStyles.bodySmall),
          Text('Pickup → ${task.shopOrder.shopName}', style: AppStyles.bodySmall),
          Text(
            'Earning: ₹${task.shopOrder.deliveryEarning.toStringAsFixed(0)}',
            style: AppStyles.bodyMedium.copyWith(color: AppColors.accentGreen, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (canAccept)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/delivery_order_view',
                    arguments: {
                      'orderId': order.id,
                      'canAccept': true,
                    },
                  );
                },
                child: const Text('View & Accept'),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/delivery_order_view',
                    arguments: {
                      'orderId': order.id,
                      'canAccept': false,
                    },
                  );
                },
                child: const Text('View'),
              ),
            ),
        ],
      ),
    );
  }


Widget _customStatusChip(
  String text, {
  required Color fg,
  required Color bg,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
    child: Text(text, style: AppStyles.bodySmall.copyWith(color: fg, fontWeight: FontWeight.w700)),
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

  Future<void> _confirmLogout(BuildContext context) async {
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
    if (!context.mounted) {
      return;
    }
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
}
