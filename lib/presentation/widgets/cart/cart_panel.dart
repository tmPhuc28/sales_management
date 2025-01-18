// lib/presentation/widgets/cart/cart_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sales_management/data/models/cart.dart';
import 'package:sales_management/data/repositories/product_repository.dart';
import 'package:sales_management/presentation/blocs/cart/cart_bloc.dart';
import 'package:sales_management/presentation/blocs/cart/cart_event.dart';
import 'package:sales_management/core/localization/app_strings.dart';
import 'package:sales_management/presentation/blocs/cart/cart_state.dart';

class CartPanel extends StatelessWidget {
  final VoidCallback onClose;
  final CartState cartState;

  const CartPanel({
    super.key,
    required this.onClose,
    required this.cartState,
  });

  @override
  Widget build(BuildContext context) {
    if (cartState is! CartLoaded) return const SizedBox.shrink();
    final state = cartState as CartLoaded;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Backdrop with animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            color: Colors.black54,
            child: GestureDetector(
              onTap: onClose,
              child: const SizedBox.expand(),
            ),
          ),

          // Panel with sliding animation
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            right: 0,
            top: 0,
            bottom: 0,
            width: 320,
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 8,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  _buildHeader(context, state),
                  _buildActionButtons(context, state),
                  Expanded(
                    child: state.allCarts.isEmpty
                        ? _buildEmptyState()
                        : _buildCartList(context, state),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CartLoaded state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shopping_cart,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${AppStrings.cart} (${state.allCarts.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClose,
            tooltip: AppStrings.close,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, CartLoaded state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<CartBloc>().add(const CreateNewCart());
              },
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: const Text(AppStrings.addToCart),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (state.allCarts.isNotEmpty) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _showClearCartsDialog(context),
              icon: const Icon(Icons.delete_sweep),
              tooltip: AppStrings.clearCart,
              color: Colors.red,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.cartEmpty,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thêm sản phẩm vào giỏ hàng để tiếp tục',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCartList(BuildContext context, CartLoaded state) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.allCarts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final cart = state.allCarts.values.elementAt(index);
        final isActive = cart.id == state.activeCart.id;
        return _buildCartItem(context, cart, isActive, state);
      },
    );
  }

  Widget _buildCartItem(
      BuildContext context,
      Cart cart,
      bool isActive,
      CartLoaded state,
      ) {
    final itemCount = cart.items.values.fold(0, (sum, item) => sum + item.quantity);

    return Dismissible(
      key: Key(cart.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => _showDeleteCartDialog(context),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (!isActive) {
            context.read<CartBloc>().add(SwitchCart(cart.id));
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
            border: Border.all(
              color: isActive ? Theme.of(context).primaryColor : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Cart icon with count
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Theme.of(context).primaryColor.withOpacity(0.2)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shopping_cart,
                          size: 16,
                          color: isActive
                              ? Theme.of(context).primaryColor
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          itemCount.toString(),
                          style: TextStyle(
                            color: isActive
                                ? Theme.of(context).primaryColor
                                : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Cart info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AppStrings.cart} #${cart.id.substring(0, 8)}',
                          style: TextStyle(
                            fontWeight: isActive ? FontWeight.bold : null,
                            color: isActive ? Theme.of(context).primaryColor : null,
                          ),
                        ),
                        Text(
                          NumberFormat.currency(symbol: '₫').format(cart.total),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // View cart button for active cart
                  if (isActive && itemCount > 0)
                    TextButton.icon(
                      onPressed: () {
                        onClose();
                        Navigator.pushNamed(context, '/cart');
                      },
                      icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                      label: const Text('Xem'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteCartDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.clearCart),
        content: const Text('Bạn có chắc muốn xóa giỏ hàng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearCartsDialog(BuildContext context) async {
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<CartBloc>().add(ClearAllCarts());
    }
  }
}