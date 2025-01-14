// lib/presentation/screens/order/order_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/repositories/order_repository.dart';
import 'package:provider/provider.dart';

class OrderListScreen extends StatelessWidget {
  const OrderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Orders'),
            floating: true,
            snap: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: FutureBuilder<List<Map<String, dynamic>>>(
              future: context.read<OrderRepository>().getAllOrders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(child: Text('Error: ${snapshot.error}')),
                  );
                }

                final orders = snapshot.data ?? [];
                if (orders.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('No orders found')),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final order = orders[index];
                      return OrderCard(order: order);
                    },
                    childCount: orders.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final orderDate = DateTime.parse(order['created_at']);
    final orderItems = order['items'] as List<Map<String, dynamic>>;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/order-details',
            arguments: {'orderId': order['id']},
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order ID and Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${order['id'].toString().substring(0, 8)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('MMM dd, yyyy HH:mm').format(orderDate),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Order Summary
              Row(
                children: [
                  _buildSummaryItem(
                    Icons.shopping_basket,
                    '${orderItems.length} items',
                    Colors.blue,
                  ),
                  const SizedBox(width: 24),
                  _buildSummaryItem(
                    Icons.attach_money,
                    NumberFormat.currency(symbol: '\$')
                        .format(order['total_amount']),
                    Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // View Details Button
              Row(
                children: [
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('View Details'),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/order-details',
                        arguments: {'orderId': order['id']},
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
