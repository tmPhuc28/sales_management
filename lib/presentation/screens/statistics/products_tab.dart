import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sales_management/core/localization/app_strings.dart';
import 'package:sales_management/data/repositories/order_repository.dart';
import 'package:sales_management/data/repositories/product_repository.dart';
import 'package:provider/provider.dart';

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

        final productsData = snapshot.data ?? [];
        if (productsData.isEmpty) {
          return const Center(child: Text(AppStrings.noProductsData));
        }

        // Calculate total sales for percentage
        final totalSales = productsData
            .map((p) => p['total_sales'] as double)
            .reduce((a, b) => a + b);

        // Prepare pie chart sections and product stats
        final sections = <PieChartSectionData>[];
        final List<ProductStatModel> productStats = [];
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

          productStats.add(ProductStatModel(
            name: name,
            quantity: quantity,
            sales: sales,
            color: color,
            percentage: percentage,
          ));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildPieChart(sections),
              const SizedBox(height: 24),
              _buildProductList(productStats),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPieChart(List<PieChartSectionData> sections) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.salesDistribution,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            AspectRatio(
              aspectRatio: 1.3,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections: sections,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(List<ProductStatModel> products) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.topProducts,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: product.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${product.quantity} ${AppStrings.itemsSold}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            NumberFormat.currency(symbol: '₫')
                                .format(product.sales),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${product.percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getProductsData(
      BuildContext context) async {
    final orderRepo = context.read<OrderRepository>();
    final productRepo = context.read<ProductRepository>();

    // Get top products data
    final productsData = await orderRepo.getTopProducts(startDate, endDate);

    // Fetch product names and enrich data
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
            'product_name': AppStrings.deletedProduct,
          };
        }
      }),
    );

    return enrichedData;
  }
}

class ProductStatModel {
  final String name;
  final int quantity;
  final double sales;
  final Color color;
  final double percentage;

  ProductStatModel({
    required this.name,
    required this.quantity,
    required this.sales,
    required this.color,
    required this.percentage,
  });
}
