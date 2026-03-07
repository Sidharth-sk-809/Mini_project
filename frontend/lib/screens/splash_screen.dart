import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.shopping_basket_outlined,
                color: AppColors.accentGreen,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Neamet',
              style: AppStyles.heading1.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Smart Marketplace',
              style: AppStyles.bodyMedium.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
