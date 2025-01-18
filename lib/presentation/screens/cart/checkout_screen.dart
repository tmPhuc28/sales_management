// lib/presentation/screens/cart/checkout_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_management/core/localization/app_strings.dart';
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
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final orderRepository = context.read<OrderRepository>();
      final productRepository = context.read<ProductRepository>();
      final productBloc = context.read<ProductBloc>();

      // Kiểm tra số lượng tồn trước khi tạo đơn hàng
      for (final item in cart.items.values) {
        final product = await productRepository.getProductById(item.productId);
        if (product.quantity < item.quantity) {
          throw Exception(AppStrings.notEnoughStock);
        }
      }

      // Tạo đơn hàng và cập nhật số lượng trong transaction
      await orderRepository.createOrder(
        cart,
        notes: _notesController.text.trim(),
      );

      // Cập nhật số lượng sản phẩm
      for (final item in cart.items.values) {
        final product = await productRepository.getProductById(item.productId);
        await productRepository.updateProductQuantity(
          item.productId,
          product.quantity - item.quantity,
        );
      }

      // Xóa giỏ hàng
      if (!mounted) return;
      context.read<CartBloc>().add(ClearAllCarts());

      // Tải lại danh sách sản phẩm
      productBloc.add(const LoadProducts());

      if (!mounted) return;
      // Quay về trang chủ
      Navigator.of(context).popUntil((route) => route.isFirst);

      // Hiển thị thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.orderSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.error}: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.checkout),
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is CartLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Summary
                  Text(
                    AppStrings.orderSummary,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildOrderItems(state.activeCart),
                  const SizedBox(height: 24),

                  // Ghi chú
                  Text(
                    AppStrings.orderNotes,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: AppStrings.orderNotesHint,
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Total và nút thanh toán
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.totalItems,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                state.activeCart.items.values
                                    .fold(0, (sum, item) => sum + item.quantity)
                                    .toString(),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.totalAmount,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                NumberFormat.currency(symbol: '₫').format(
                                  state.activeCart.total,
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isProcessing
                                  ? null
                                  : () => _processCheckout(
                                        context,
                                        state.activeCart,
                                      ),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _isProcessing
                                  ? const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(AppStrings.processing),
                                      ],
                                    )
                                  : const Text(AppStrings.completeOrder),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return const Center(child: Text(AppStrings.cartEmpty));
        },
      ),
    );
  }

  Widget _buildOrderItems(Cart cart) {
    return Card(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cart.items.length,
        itemBuilder: (context, index) {
          final item = cart.items.values.elementAt(index);
          return FutureBuilder(
            future: context
                .read<ProductRepository>()
                .getProductById(item.productId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 72,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final product = snapshot.data!;
              return ListTile(
                leading: product.imagePath != null
                    ? Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(File(product.imagePath!)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.image),
                      ),
                title: Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppStrings.quantity}: ${item.quantity}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      '${AppStrings.price}: ${NumberFormat.currency(symbol: '₫').format(item.price)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                trailing: Text(
                  NumberFormat.currency(symbol: '₫')
                      .format(item.price * item.quantity),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              );
            },
          );
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
