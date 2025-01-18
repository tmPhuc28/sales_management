// lib/presentation/screens/order/order_details_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sales_management/core/localization/app_strings.dart';
import 'package:sales_management/presentation/widgets/custom_app_bar.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/product_repository.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late Future<Map<String, dynamic>> _orderDetailsFuture;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  void _loadOrderDetails() {
    _orderDetailsFuture =
        context.read<OrderRepository>().getOrderDetails(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: AppStrings.orderDetails),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _orderDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(AppStrings.loading),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('${AppStrings.error}: ${snapshot.error}'),
            );
          }

          final orderData = snapshot.data!;
          final order = orderData['order'];
          final items = orderData['items'] as List<Map<String, dynamic>>;
          final createdAt = DateTime.parse(order['created_at']);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderInfo(order, createdAt),
                const SizedBox(height: 24),
                _buildItemsList(items),
                const SizedBox(height: 24),
                _buildOrderSummary(order),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderInfo(Map<String, dynamic> order, DateTime createdAt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppStrings.orders}: #${order['id'].substring(0, 8)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${AppStrings.orderDate}: ${DateFormat('dd/MM/yyyy HH:mm').format(createdAt)}',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${AppStrings.orderStatus}: ${_getStatusText(order['status'])}',
              style: TextStyle(
                color: _getStatusColor(order['status']),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (order['notes'] != null && order['notes'].isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${AppStrings.notes}: ${order['notes']}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(List<Map<String, dynamic>> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.orderItems,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return FutureBuilder(
                  future: context
                      .read<ProductRepository>()
                      .getProductById(item['product_id']),
                  builder: (context, productSnapshot) {
                    if (!productSnapshot.hasData) {
                      return const SizedBox.shrink();
                    }
                    final product = productSnapshot.data!;
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Text(
                        '${item['quantity']} x ${NumberFormat.currency(symbol: '₫').format(item['price'])}',
                      ),
                      trailing: Text(
                        NumberFormat.currency(symbol: '₫').format(
                          item['quantity'] * item['price'],
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(Map<String, dynamic> order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  AppStrings.totalAmount,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  NumberFormat.currency(symbol: '₫')
                      .format(order['total_amount']),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return AppStrings.orderPending;
      case 'processing':
        return AppStrings.orderProcessing;
      case 'completed':
        return AppStrings.orderCompleted;
      case 'cancelled':
        return AppStrings.orderCancelled;
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
