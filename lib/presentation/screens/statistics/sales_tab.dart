// lib/presentation/screens/statistics/sales_tab.dart

import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sales_management/core/localization/app_strings.dart';
import 'package:sales_management/data/repositories/order_repository.dart';
import 'package:provider/provider.dart';

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
      future: _loadSalesData(context),
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

        final salesData = snapshot.data ?? [];
        if (salesData.isEmpty) {
          return const Center(child: Text(AppStrings.noSalesData));
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildSalesChart(salesData, context),
              _buildSalesSummary(salesData),
              _buildDailySales(salesData),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSalesChart(
      List<Map<String, dynamic>> salesData, BuildContext context) {
    final spots = salesData.map((data) {
      final date = DateTime.parse(data['date']);
      return FlSpot(
        date.millisecondsSinceEpoch.toDouble(),
        data['sales'],
      );
    }).toList();

    double maxY = spots.map((spot) => spot.y).reduce(max);
    double minY = spots.map((spot) => spot.y).reduce(min);
    final padding = (maxY - minY) * 0.1;
    maxY += padding;
    minY = max(0, minY - padding);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.salesTrend,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.fromMillisecondsSinceEpoch(
                              value.toInt());
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              DateFormat('dd/MM').format(date),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                        interval: 86400000 * 2, // 2 days
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              NumberFormat.compact().format(value),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.white,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final date = DateTime.fromMillisecondsSinceEpoch(
                            spot.x.toInt(),
                          );
                          return LineTooltipItem(
                            '${DateFormat('dd/MM/yyyy').format(date)}\n',
                            const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: NumberFormat.currency(symbol: '₫')
                                    .format(spot.y),
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesSummary(List<Map<String, dynamic>> salesData) {
    final totalSales = salesData.fold<double>(
      0,
      (sum, data) => sum + (data['sales'] as double),
    );
    final avgDailySales = totalSales / salesData.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  AppStrings.totalSales,
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  NumberFormat.currency(symbol: '₫').format(totalSales),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  AppStrings.averageDailySales,
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  NumberFormat.currency(symbol: '₫').format(avgDailySales),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySales(List<Map<String, dynamic>> salesData) {
    final sortedData = [...salesData]
      ..sort((a, b) => (b['sales'] as double).compareTo(a['sales'] as double));

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.dailySales,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedData.length,
              itemBuilder: (context, index) {
                final data = sortedData[index];
                final date = DateTime.parse(data['date']);
                return ListTile(
                  title: Text(DateFormat('dd/MM/yyyy').format(date)),
                  trailing: Text(
                    NumberFormat.currency(symbol: '₫').format(data['sales']),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadSalesData(
      BuildContext context) async {
    final orderRepo = context.read<OrderRepository>();
    return orderRepo.getDailySales(startDate, endDate);
  }
}
