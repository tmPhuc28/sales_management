// lib/presentation/widgets/cart/cart_list_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_management/presentation/blocs/cart/cart_event.dart';
import 'package:sales_management/presentation/blocs/cart/cart_state.dart';
import '../../blocs/cart/cart_bloc.dart';

class CartListWidget extends StatelessWidget {
  const CartListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        if (state is CartLoaded) {
          return Container(
            height: 100,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                // Header with Add Cart button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Shopping Carts',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => _confirmDeleteAllCarts(context),
                            child: const Text('Clear All'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_shopping_cart),
                            onPressed: () {
                              context
                                  .read<CartBloc>()
                                  .add(const CreateNewCart());
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Cart List
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    itemCount: state.allCarts.length,
                    itemBuilder: (context, index) {
                      final cart = state.allCarts.values.elementAt(index);
                      final isActive = cart.id == state.activeCart.id;
                      final totalItems = cart.items.values
                          .fold(0, (sum, item) => sum + item.quantity);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: InkWell(
                          onTap: () {
                            context.read<CartBloc>().add(SwitchCart(cart.id));
                            // Navigate to CartScreen when tapped
                            Navigator.pushNamed(context, '/cart');
                          },
                          child: Container(
                            width: 60,
                            decoration: BoxDecoration(
                              color: isActive ? Colors.blue : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_cart,
                                  color: isActive
                                      ? Colors.white
                                      : Colors.grey[600],
                                  size: 28,
                                ),
                                if (totalItems > 0)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        totalItems.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Future<void> _confirmDeleteAllCarts(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Carts'),
        content:
            const Text('Are you sure you want to delete all shopping carts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      context.read<CartBloc>().add(ClearAllCarts());
    }
  }
}
