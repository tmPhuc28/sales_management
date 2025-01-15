// lib/config/routes/app_routes.dart
import 'package:flutter/material.dart';
import 'package:sales_management/presentation/screens/main_screen.dart';
import 'package:sales_management/presentation/screens/order/order_details_screen.dart';
import '../../presentation/screens/product/product_screen.dart';
import '../../presentation/screens/cart/cart_screen.dart';
import '../../presentation/screens/cart/checkout_screen.dart';

class AppRoutes {
  static const String main = '/';
  static const String addProduct = '/add-product';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orderDetails = '/order-details';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case main:
        return MaterialPageRoute(
          builder: (_) => const MainScreen(),
        );
      case addProduct:
        return MaterialPageRoute(
          builder: (_) => const ProductScreen(),
        );
      case cart:
        return MaterialPageRoute(
          builder: (_) => const CartScreen(),
        );
      case checkout:
        return MaterialPageRoute(
          builder: (_) => const CheckoutScreen(),
        );
      case orderDetails:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => OrderDetailsScreen(
            orderId: args['orderId'],
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const MainScreen(),
        );
    }
  }
}
