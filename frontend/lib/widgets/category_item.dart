import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';

class CategoryItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;

  const CategoryItem({
    Key? key,
    required this.label,
    required this.icon,
    required this.isActive,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isActive ? AppColors.accentGreen : AppColors.lightGray,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : AppColors.textDark,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppStyles.bodySmall.copyWith(
            color: isActive ? AppColors.accentGreen : AppColors.textDark,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
