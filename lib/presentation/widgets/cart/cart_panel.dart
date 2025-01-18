import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sales_management/data/models/cart.dart';
import 'package:sales_management/presentation/blocs/cart/cart_bloc.dart';
import 'package:sales_management/presentation/blocs/cart/cart_event.dart';
import 'package:sales_management/presentation/blocs/cart/cart_state.dart';
import 'package:sales_management/core/localization/app_strings.dart';
import 'package:provider/provider.dart';

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
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        // Nếu kéo xuống với khoảng cách đủ lớn
        if (details.primaryDelta! > 10) {
          onClose();
        }
      },
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Backdrop với animation
            GestureDetector(
              onTap: onClose,
              child: Container(
                color: Colors.black54,
              ),
            ),

            // Panel với animation trượt từ dưới lên
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: screenHeight * 0.68, // Chiếm 60% màn hình
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: screenHeight, end: 0),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, value),
                    child: child,
                  );
                },
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      _buildHandle(),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CartLoaded state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          Icon(
            Icons.shopping_cart,
            color: Theme.of(context).primaryColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppStrings.cart} (${state.allCarts.length})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (state.activeCart.items.isNotEmpty)
                  Text(
                    '${state.activeCart.items.values.fold(0, (sum, item) => sum + item.quantity)} sản phẩm',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClose,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, CartLoaded state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<CartBloc>().add(const CreateNewCart());
              },
              icon: const Icon(Icons.add_shopping_cart, size: 20),
              label: const Text(AppStrings.addToCart),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          if (state.allCarts.isNotEmpty) ...[
            const SizedBox(width: 12),
            IconButton.filled(
              onPressed: () => _showClearCartsDialog(context),
              icon: const Icon(Icons.delete_sweep),
              tooltip: AppStrings.clearCart,
              style: IconButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red,
              ),
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
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.cartEmpty,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: state.allCarts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
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
    final itemCount =
        cart.items.values.fold(0, (sum, item) => sum + item.quantity);

    return Dismissible(
      key: Key(cart.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        final result = await _showDeleteCartDialog(context);
        if (result == true) {
          if (context.mounted) {
            // Xóa giỏ hàng
            context.read<CartBloc>().add(DeleteCart(cart.id));
            // Nếu không còn giỏ hàng nào, đóng panel
            if (state.allCarts.length <= 1) {
              onClose();
            }
          }
        }
        return result;
      },
      background: Container(
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).primaryColor.withOpacity(0.05)
              : Colors.white,
          border: Border.all(
            color:
                isActive ? Theme.of(context).primaryColor : Colors.grey[200]!,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (!isActive) {
                context.read<CartBloc>().add(SwitchCart(cart.id));
              }
            },
            onDoubleTap: () {
              onClose();
              Navigator.pushNamed(context, '/cart');
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Theme.of(context).primaryColor.withOpacity(0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.shopping_cart,
                          color: isActive
                              ? Theme.of(context).primaryColor
                              : Colors.grey[600],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AppStrings.cart} #${cart.id.substring(0, 8)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? Theme.of(context).primaryColor
                                    : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$itemCount sản phẩm · ${NumberFormat.currency(symbol: '₫', decimalDigits: 0).format(cart.total)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isActive && itemCount > 0)
                        ElevatedButton(
                          onPressed: () {
                            onClose();
                            Navigator.pushNamed(context, '/cart');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: const Text('Xem giỏ hàng'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
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
