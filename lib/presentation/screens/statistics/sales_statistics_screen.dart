// lib/presentation/screens/statistics/sales_statistics_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sales_management/core/localization/app_strings.dart';
import 'package:sales_management/data/repositories/order_repository.dart';
import 'package:sales_management/data/repositories/product_repository.dart';
import 'package:sales_management/presentation/screens/statistics/products_tab.dart';
import 'package:sales_management/presentation/screens/statistics/sales_tab.dart';
import 'package:sales_management/presentation/widgets/date_range_picker.dart';
import 'package:sales_management/presentation/widgets/statistics/statistic_card.dart';

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
              title: const Text(AppStrings.statistics),
              centerTitle: true,
              pinned: true,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(110),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: CustomDateRangePicker(
                        startDate: _startDate,
                        endDate: _endDate,
                        onDateRangeChanged: (start, end) {
                          setState(() {
                            _startDate = start;
                            _endDate = end;
                          });
                        },
                      ),
                    ),
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: AppStrings.overview),
                        Tab(text: AppStrings.sales),
                        Tab(text: AppStrings.products),
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

        final data = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            StatisticCard(
              title: AppStrings.totalRevenue,
              value:
                  NumberFormat.currency(symbol: '₫').format(data['totalSales']),
              icon: Icons.attach_money,
              color: Colors.green.shade700,
            ),
            const SizedBox(height: 16),
            StatisticCard(
              title: AppStrings.totalOrders,
              value: NumberFormat.compact().format(data['totalOrders']),
              icon: Icons.shopping_cart,
              color: Colors.blue.shade700,
              subtitle: '${data['orderGrowth']}% ${AppStrings.vsLastPeriod}',
            ),
            const SizedBox(height: 16),
            StatisticCard(
              title: AppStrings.averageOrderValue,
              value: NumberFormat.currency(symbol: '₫')
                  .format(data['averageOrderValue']),
              icon: Icons.analytics,
              color: Colors.purple.shade700,
            ),
            const SizedBox(height: 16),
            StatisticCard(
              title: AppStrings.totalProfit,
              value: NumberFormat.currency(symbol: '₫')
                  .format(data['totalProfit']),
              icon: Icons.trending_up,
              color: Colors.orange.shade700,
              subtitle: '${data['profitMargin']}% ${AppStrings.profitMargin}',
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadOverviewData(BuildContext context) async {
    final orderRepo = context.read<OrderRepository>();
    final productRepo = context.read<ProductRepository>();

    // Get current period statistics
    final currentStats = await orderRepo.getStatistics(startDate, endDate);

    // Calculate previous period statistics
    final periodDuration = endDate.difference(startDate);
    final previousStart = startDate.subtract(periodDuration);
    final previousEnd = startDate.subtract(const Duration(days: 1));
    final previousStats =
        await orderRepo.getStatistics(previousStart, previousEnd);

    // Calculate growth rates
    final orderGrowth = previousStats['totalOrders'] != 0
        ? ((currentStats['totalOrders'] - previousStats['totalOrders']) /
                previousStats['totalOrders'] *
                100)
            .toStringAsFixed(1)
        : '0.0';

    // Calculate total profit and margin
    final orders = await orderRepo.getAllOrders();
    double totalProfit = 0;
    double totalRevenue = 0;

    for (var order in orders) {
      final orderDate = DateTime.parse(order['created_at']);
      if (orderDate.isAfter(startDate) && orderDate.isBefore(endDate)) {
        totalRevenue += order['total_amount'];
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

    final profitMargin = totalRevenue > 0
        ? ((totalProfit / totalRevenue) * 100).toStringAsFixed(1)
        : '0.0';

    return {
      'totalSales': currentStats['totalSales'],
      'totalOrders': currentStats['totalOrders'],
      'averageOrderValue': currentStats['averageOrderValue'],
      'totalProfit': totalProfit,
      'orderGrowth': orderGrowth,
      'profitMargin': profitMargin,
    };
  }
}
