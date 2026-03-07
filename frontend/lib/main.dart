import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants/colors.dart';
import 'models/product_model.dart';
import 'models/user_role.dart';
import 'screens/cart_screen.dart';
import 'screens/delivery_dashboard_screen.dart';
import 'screens/delivery_map_screen.dart';
import 'screens/delivery_order_view_screen.dart';
import 'screens/delivery_route_plan_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/order_tracking_screen.dart';
import 'screens/product_details_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/session_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GroceryApp());
}

class GroceryApp extends StatelessWidget {
  const GroceryApp({super.key});

  static final Future<void> _bootstrapFuture = _initialize();

  static Future<void> _initialize() async {
    await SessionService.load();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grocery App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accentGreen,
          brightness: Brightness.light,
        ),
        fontFamily: GoogleFonts.poppins().fontFamily,
        scaffoldBackgroundColor: AppColors.backgroundColor,
      ),
      home: AppBootstrap(bootstrapFuture: _bootstrapFuture),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/delivery_dashboard': (context) => const DeliveryDashboardScreen(),
        '/product_details': (context) {
          final product = ModalRoute.of(context)!.settings.arguments as Product;
          return ProductDetailsScreen(product: product);
        },
        '/cart': (context) => const CartScreen(),
        '/order_tracking': (context) {
          final orderId = ModalRoute.of(context)!.settings.arguments as String;
          return OrderTrackingScreen(orderId: orderId);
        },
        '/delivery_map': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
          return DeliveryMapScreen(
            orderId: args['orderId']!,
            shopOrderId: args['shopOrderId']!,
          );
        },
        '/delivery_order_view': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return DeliveryOrderViewScreen(
            orderId: args['orderId'] as String,
            canAccept: (args['canAccept'] as bool?) ?? false,
          );
        },
        '/delivery_route_plan': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
          return DeliveryRoutePlanScreen(orderId: args['orderId']!);
        },
      },
    );
  }
}

class AppBootstrap extends StatefulWidget {
  final Future<void> bootstrapFuture;

  const AppBootstrap({super.key, required this.bootstrapFuture});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    unawaited(_finishSplash());
  }

  Future<void> _finishSplash() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashScreen();
    }

    return FutureBuilder<void>(
      future: widget.bootstrapFuture,
      builder: (context, snapshot) {
        if (!SessionService.isLoggedIn) {
          return const LoginScreen();
        }

        return FutureBuilder<UserRole>(
          future: AuthService.getCurrentUserRole(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            if (roleSnapshot.hasError) {
              unawaited(AuthService.signOut());
              return const LoginScreen();
            }

            final role = roleSnapshot.data ?? SessionService.role;
            if (role == null) {
              return const LoginScreen();
            }

            return role == UserRole.deliveryPerson
                ? const DeliveryDashboardScreen()
                : const HomeScreen();
          },
        );
      },
    );
  }
}
