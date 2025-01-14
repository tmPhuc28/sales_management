// lib/presentation/screens/order/order_details_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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
  double? _orderProfit;

  @override
  void initState() {
    super.initState();
    _calculateProfit();
  }

  Future<void> _calculateProfit() async {
    try {
      final orderRepo = context.read<OrderRepository>();
      final productRepo = context.read<ProductRepository>();
      final orderData = await orderRepo.getOrderDetails(widget.orderId);

      double profit = 0;
      for (var item in orderData['items']) {
        try {
          final product = await productRepo.getProductById(item['product_id']);
          profit += (item['price'] - product.costPrice) * item['quantity'];
        } catch (e) {
          // Handle deleted products
          continue;
        }
      }

      if (mounted) {
        setState(() {
          _orderProfit = profit;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.orderId.substring(0, 8)}'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: context.read<OrderRepository>().getOrderDetails(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final orderData = snapshot.data!;
          final order = orderData['order'];
          final items = orderData['items'] as List<Map<String, dynamic>>;
          final orderDate = DateTime.parse(order['created_at']);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Information',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(
                          'Date',
                          DateFormat('MMM dd, yyyy HH:mm').format(orderDate),
                        ),
                        _buildInfoRow(
                          'Status',
                          order['status'],
                        ),
                        _buildInfoRow(
                          'Total Amount',
                          NumberFormat.currency(symbol: '\$')
                              .format(order['total_amount']),
                          valueColor: Colors.green,
                        ),
                        if (_orderProfit != null)
                          _buildInfoRow(
                            'Profit',
                            NumberFormat.currency(symbol: '\$')
                                .format(_orderProfit),
                            valueColor:
                                _orderProfit! >= 0 ? Colors.blue : Colors.red,
                          ),
                        if (order['notes'] != null && order['notes'].isNotEmpty)
                          _buildInfoRow('Notes', order['notes']),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Order Items',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => OrderItemCard(item: items[index]),
                    childCount: items.length,
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class OrderItemCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const OrderItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder(
          future: context
              .read<ProductRepository>()
              .getProductById(item['product_id']),
          builder: (context, snapshot) {
            final productName =
                snapshot.hasData ? snapshot.data!.name : 'Deleted Product';

            return Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item['quantity']} x ${NumberFormat.currency(symbol: '\$').format(item['price'])}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  NumberFormat.currency(symbol: '\$')
                      .format(item['quantity'] * item['price']),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
