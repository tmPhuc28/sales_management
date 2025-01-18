// lib/presentation/screens/cart/cart_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sales_management/data/models/cart.dart';
import 'package:sales_management/presentation/blocs/cart/cart_event.dart';
import 'package:sales_management/presentation/blocs/cart/cart_state.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/models/product.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_strings.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Future<void> _confirmDeleteCart(BuildContext context) async {
    final state = context.read<CartBloc>().state;
    if (state is! CartLoaded) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.clearCart),
        content: const Text(AppStrings.confirmClearCart),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              AppStrings.delete,
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<CartBloc>().add(DeleteCart(state.activeCart.id));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.cart),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDeleteCart(context),
          ),
        ],
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is CartLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CartLoaded) {
            if (state.activeCart.items.isEmpty) {
              return const Center(
                child: Text(AppStrings.cartEmpty),
              );
            }
            return CartItemList(cart: state.activeCart);
          }
          return const Center(child: Text('Đã xảy ra lỗi'));
        },
      ),
      bottomNavigationBar: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is CartLoaded) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        AppStrings.orderTotal,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        NumberFormat.currency(symbol: '₫').format(
                          state.activeCart.total,
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: state.activeCart.items.isEmpty
                              ? null
                              : () {
                            Navigator.pushNamed(context, '/checkout');
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(AppStrings.checkout),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class CartItemList extends StatelessWidget {
  final Cart cart;

  const CartItemList({super.key, required this.cart});

  @override
  Widget build(BuildContext context) {
    final productRepository = context.read<ProductRepository>();

    return ListView.builder(
      itemCount: cart.items.length,
      itemBuilder: (context, index) {
        final item = cart.items.values.elementAt(index);
        return FutureBuilder<Product>(
          future: productRepository.getProductById(item.productId),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final product = snapshot.data!;
              return Slidable(
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (context) {
                        context.read<CartBloc>().add(
                              RemoveFromCart(item.productId,
                                  quantity: item.quantity),
                            );
                      },
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Xóa',
                    ),
                  ],
                ),
                child: CartItemTile(
                  product: product,
                  quantity: item.quantity,
                  onIncrement: product.quantity > item.quantity
                      ? () {
                          context.read<CartBloc>().add(AddToCart(product));
                        }
                      : null,
                  onDecrement: () {
                    context.read<CartBloc>().add(RemoveFromCart(product.id));
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}

class CartItemTile extends StatelessWidget {
  final Product product;
  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback onDecrement;

  const CartItemTile({
    super.key,
    required this.product,
    required this.quantity,
    this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: product.imagePath != null
          ? SizedBox(
              width: 48,
              height: 48,
              child: Image.file(
                File(product.imagePath!),
                fit: BoxFit.cover,
              ),
            )
          : const Icon(Icons.image, size: 48),
      title: Text(product.name),
      subtitle: Text(
        NumberFormat.currency(symbol: '\$').format(product.sellingPrice),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: onDecrement,
          ),
          Text(
            quantity.toString(),
            style: const TextStyle(fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }
}
