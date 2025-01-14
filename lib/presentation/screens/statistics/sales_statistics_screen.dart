// lib/presentation/screens/statistics/sales_statistics_screen.dart
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sales_management/data/repositories/order_repository.dart';
import 'package:sales_management/data/repositories/product_repository.dart';
import 'package:sales_management/presentation/widgets/charts/product_chart.dart';
import 'package:sales_management/presentation/widgets/charts/sales_chart.dart';

class SalesStatisticsScreen extends StatefulWidget {
  const SalesStatisticsScreen({super.key});

  @override
  State<SalesStatisticsScreen> createState() => _SalesStatisticsScreenState();
}

class _SalesStatisticsScreenState extends State<SalesStatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: const Text('Statistics'),
              floating: true,
              snap: true,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(100),
                child: Column(
                  children: [
                    // Date Range Selector
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            initialDateRange: DateTimeRange(
                              start: _startDate,
                              end: _endDate,
                            ),
                          );
                          if (picked != null) {
                            setState(() {
                              _startDate = picked.start;
                              _endDate = picked.end;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '${DateFormat('MMM dd, yyyy').format(_startDate)} - '
                                '${DateFormat('MMM dd, yyyy').format(_endDate)}',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Tab Bar
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Sales'),
                        Tab(text: 'Products'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            OverviewTab(startDate: _startDate, endDate: _endDate),
            SalesTab(startDate: _startDate, endDate: _endDate),
            ProductsTab(startDate: _startDate, endDate: _endDate),
          ],
        ),
      ),
    );
  }
}

class OverviewTab extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;

  const OverviewTab({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadOverviewData(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final data = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Statistics Cards
            StatCard(
              title: 'Total Sales',
              value: NumberFormat.currency(symbol: '\$')
                  .format(data['totalSales']),
              icon: Icons.attach_money,
              color: Colors.green.shade700,
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade50,
                  Colors.green.shade100,
                ],
              ),
            ),
            const SizedBox(height: 16),
            StatCard(
              title: 'Total Orders',
              value: data['totalOrders'].toString(),
              icon: Icons.shopping_cart,
              color: Colors.blue.shade700,
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade50,
                  Colors.blue.shade100,
                ],
              ),
            ),
            const SizedBox(height: 16),
            StatCard(
              title: 'Average Order Value',
              value: NumberFormat.currency(symbol: '\$')
                  .format(data['averageOrderValue']),
              icon: Icons.analytics,
              color: Colors.purple.shade700,
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade50,
                  Colors.purple.shade100,
                ],
              ),
            ),
            const SizedBox(height: 16),
            StatCard(
              title: 'Total Profit',
              value: NumberFormat.currency(symbol: '\$')
                  .format(data['totalProfit']),
              icon: Icons.trending_up,
              color: Colors.orange.shade700,
              gradient: LinearGradient(
                colors: [
                  Colors.orange.shade50,
                  Colors.orange.shade100,
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadOverviewData(BuildContext context) async {
    final orderRepo = context.read<OrderRepository>();
    final productRepo = context.read<ProductRepository>();

    // Get basic statistics
    final stats = await orderRepo.getStatistics(startDate, endDate);

    // Calculate total profit
    final orders = await orderRepo.getAllOrders();
    double totalProfit = 0;

    for (var order in orders) {
      final orderDate = DateTime.parse(order['created_at']);
      if (orderDate.isAfter(startDate) && orderDate.isBefore(endDate)) {
        for (var item in order['items']) {
          try {
            final product =
                await productRepo.getProductById(item['product_id']);
            final itemProfit =
                (item['price'] - product.costPrice) * item['quantity'];
            totalProfit += itemProfit;
          } catch (e) {
            continue;
          }
        }
      }
    }

    return {
      'totalSales': stats['totalSales'],
      'totalOrders': stats['totalOrders'],
      'averageOrderValue': stats['averageOrderValue'],
      'totalProfit': totalProfit,
    };
  }
}

class SalesTab extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;

  const SalesTab({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: context.read<OrderRepository>().getDailySales(startDate, endDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final salesData = snapshot.data ?? [];
        if (salesData.isEmpty) {
          return const Center(child: Text('No sales data available'));
        }

        // Convert data to FlSpot for LineChart
        final spots = salesData.map((data) {
          final date = DateTime.parse(data['date']);
          return FlSpot(
            date.millisecondsSinceEpoch.toDouble(),
            data['sales'],
          );
        }).toList();

        // Calculate min and max Y values
        double maxY = spots.map((spot) => spot.y).reduce(max);
        double minY = spots.map((spot) => spot.y).reduce(min);
        // Add 10% padding to max and min values
        final padding = (maxY - minY) * 0.1;
        maxY += padding;
        minY = max(0, minY - padding);

        return SingleChildScrollView(
          child: Column(
            children: [
              SalesChart(
                salesData: spots,
                maxY: maxY,
                minY: minY,
              ),
              const SizedBox(height: 16),
              SalesSummaryCard(
                startDate: startDate,
                endDate: endDate,
              ),
            ],
          ),
        );
      },
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Gradient gradient;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SalesSummaryCard extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;

  const SalesSummaryCard({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: context.read<OrderRepository>().getStatistics(startDate, endDate),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final stats = snapshot.data!;
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatRow(
                  'Total Sales',
                  NumberFormat.currency(symbol: '\$')
                      .format(stats['totalSales']),
                ),
                _buildStatRow(
                  'Total Orders',
                  stats['totalOrders'].toString(),
                ),
                _buildStatRow(
                  'Average Order',
                  NumberFormat.currency(symbol: '\$')
                      .format(stats['averageOrderValue']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class ProductsTab extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;

  const ProductsTab({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getProductsData(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final productsData = snapshot.data ?? [];
        if (productsData.isEmpty) {
          return const Center(child: Text('No products data available'));
        }

        // Calculate total sales for percentage
        final totalSales = productsData
            .map((p) => p['total_sales'] as double)
            .reduce((a, b) => a + b);

        // Prepare data for pie chart
        final List<PieChartSectionData> sections = [];
        final List<_ProductStat> productStats = [];
        final colors = [
          Colors.blue,
          Colors.red,
          Colors.green,
          Colors.orange,
          Colors.purple,
          Colors.teal,
          Colors.pink,
          Colors.indigo,
          Colors.amber,
          Colors.cyan,
        ];

        for (var i = 0; i < productsData.length; i++) {
          final data = productsData[i];
          final sales = data['total_sales'] as double;
          final quantity = data['total_quantity'] as int;
          final percentage = (sales / totalSales) * 100;
          final color = colors[i % colors.length];
          final name = data['product_name'] as String;

          sections.add(
            PieChartSectionData(
              color: color,
              value: percentage,
              title: '${percentage.toStringAsFixed(1)}%',
              radius: 100,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          );

          productStats.add(_ProductStat(
            name: name,
            quantity: quantity,
            sales: sales,
            color: color,
          ));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Pie Chart
              ProductPieChart(sections: sections),
              const SizedBox(height: 24),

              // Product Stats List
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Top Products',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...productStats.map((stat) => ProductStatItem(
                            name: stat.name,
                            quantity: stat.quantity,
                            amount: stat.sales,
                            color: stat.color,
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getProductsData(
    BuildContext context,
  ) async {
    final orderRepo = context.read<OrderRepository>();
    final productRepo = context.read<ProductRepository>();

    // Get top products data
    final productsData = await orderRepo.getTopProducts(startDate, endDate);

    // Fetch product names
    final enrichedData = await Future.wait(
      productsData.map((data) async {
        try {
          final product = await productRepo.getProductById(
            data['product_id'] as String,
          );
          return {
            ...data,
            'product_name': product.name,
          };
        } catch (e) {
          return {
            ...data,
            'product_name': 'Deleted Product',
          };
        }
      }),
    );

    return enrichedData;
  }
}

class _ProductStat {
  final String name;
  final int quantity;
  final double sales;
  final Color color;

  _ProductStat({
    required this.name,
    required this.quantity,
    required this.sales,
    required this.color,
  });
}
