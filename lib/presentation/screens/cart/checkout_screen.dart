// lib/presentation/screens/cart/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_management/data/models/cart.dart';
import 'package:sales_management/presentation/blocs/cart/cart_event.dart';
import 'package:sales_management/presentation/blocs/cart/cart_state.dart';
import 'package:sales_management/presentation/blocs/product/product_bloc.dart';
import 'package:sales_management/presentation/blocs/product/product_event.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/order_repository.dart';
import 'package:intl/intl.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _notesController = TextEditingController();
  bool _isProcessing = false;

  Future<void> _processCheckout(BuildContext context, Cart cart) async {
    setState(() => _isProcessing = true);

    try {
      final orderRepository = context.read<OrderRepository>();
      final productRepository = context.read<ProductRepository>();
      final productBloc = context.read<ProductBloc>();

      // Create order
      await orderRepository.createOrder(
        cart,
        notes: _notesController.text,
      );

      // Update product quantities
      for (final item in cart.items.values) {
        final product = await productRepository.getProductById(item.productId);
        await productRepository.updateProductQuantity(
          item.productId,
          product.quantity - item.quantity,
        );
      }

      // Clear cart
      if (!mounted) return;
      context.read<CartBloc>().add(ClearAllCarts());

      // Reload products
      productBloc.add(const LoadProducts());

      // Navigate back to home
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order completed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is CartLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Summary
                  const Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.activeCart.items.length,
                      itemBuilder: (context, index) {
                        final item =
                            state.activeCart.items.values.elementAt(index);
                        return FutureBuilder(
                          future: context
                              .read<ProductRepository>()
                              .getProductById(item.productId),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const SizedBox.shrink();
                            }
                            final product = snapshot.data!;
                            return ListTile(
                              title: Text(product.name),
                              subtitle: Text(
                                '${item.quantity} x ${NumberFormat.currency(symbol: '\$').format(item.price)}',
                              ),
                              trailing: Text(
                                NumberFormat.currency(symbol: '\$')
                                    .format(item.quantity * item.price),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Total
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            NumberFormat.currency(symbol: '\$')
                                .format(state.activeCart.total),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Notes
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Order Notes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Checkout Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isProcessing
                          ? null
                          : () => _processCheckout(context, state.activeCart),
                      child: _isProcessing
                          ? const CircularProgressIndicator()
                          : const Text('Complete Order'),
                    ),
                  ),
                ],
              ),
            );
          }
          return const Center(child: Text('Cart is empty'));
        },
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
