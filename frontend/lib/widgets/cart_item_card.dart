import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../models/product_model.dart';

class CartItemCard extends StatefulWidget {
  final Product item;
  final VoidCallback? onDelete;
  final ValueChanged<int>? onQuantityChanged;

  const CartItemCard({
    Key? key,
    required this.item,
    this.onDelete,
    this.onQuantityChanged,
  }) : super(key: key);

  @override
  State<CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<CartItemCard> {
  late int quantity;

  @override
  void initState() {
    super.initState();
    quantity = widget.item.quantity;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: AppStyles.cardDecoration,
      child: Stack(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  widget.item.image,
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    width: 100,
                    height: 100,
                    color: AppColors.lightGray,
                    child: Icon(
                      Icons.image_not_supported,
                      color: Color(0xFFB0B0B0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.item.name,
                      style: AppStyles.bodyLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.item.subtitle,
                      style: AppStyles.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${widget.item.price.toStringAsFixed(0)}',
                      style: AppStyles.heading3.copyWith(
                        color: AppColors.accentGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: widget.onDelete,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (quantity > 1) {
                        setState(() {
                          quantity--;
                          widget.item.quantity = quantity;
                        });
                        widget.onQuantityChanged?.call(quantity);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Icon(
                        Icons.remove,
                        size: 16,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Text(
                    '$quantity',
                    style: AppStyles.label,
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        quantity++;
                        widget.item.quantity = quantity;
                      });
                      widget.onQuantityChanged?.call(quantity);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Icon(
                        Icons.add,
                        size: 16,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
