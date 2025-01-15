// lib/presentation/widgets/product_grid.dart
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:sales_management/data/models/product.dart';
import 'package:sales_management/presentation/blocs/cart/cart_bloc.dart';
import 'package:sales_management/presentation/blocs/cart/cart_event.dart';
import 'package:sales_management/presentation/widgets/product/product_card.dart';

class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final bool isEditable;

  const ProductGrid({
    super.key,
    required this.products,
    this.isEditable = false,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.6,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        if (isEditable) {
          return GestureDetector(
            onTap: () => Navigator.pushNamed(
              context,
              '/add-product',
              arguments: product,
            ),
            child: ProductCard(product: product),
          );
        }
        return GestureDetector(
          onDoubleTap: product.quantity > 0
              ? () => context.read<CartBloc>().add(AddToCart(product))
              : null,
          child: ProductCard(product: product),
        );
      },
    );
  }
}