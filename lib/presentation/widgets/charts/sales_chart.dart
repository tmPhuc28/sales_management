// lib/presentation/widgets/charts/sales_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class SalesChart extends StatelessWidget {
  final List<FlSpot> salesData;
  final double maxY;
  final double minY;

  const SalesChart({
    super.key,
    required this.salesData,
    required this.maxY,
    required this.minY,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate interval for Y axis
    final yInterval = ((maxY - minY) / 5).roundToDouble();
    final adjustedYInterval = yInterval == 0 ? 1.0 : yInterval;

    // Calculate interval for X axis (1 day in milliseconds)
    final xInterval = const Duration(days: 1).inMilliseconds.toDouble();

    return AspectRatio(
      aspectRatio: 1.70,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: adjustedYInterval,
              verticalInterval: xInterval,
              getDrawingHorizontalLine: (value) {
                return const FlLine(
                  color: Color(0xffe7e8ec),
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return const FlLine(
                  color: Color(0xffe7e8ec),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: xInterval,
                  getTitlesWidget: (value, meta) {
                    final date = DateTime.fromMillisecondsSinceEpoch(
                      value.toInt(),
                    );
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 8,
                      child: Text(
                        DateFormat('MMM dd').format(date),
                        style: const TextStyle(
                          color: Color(0xff72719b),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: adjustedYInterval,
                  reservedSize: 42,
                  getTitlesWidget: (value, meta) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 8,
                      child: Text(
                        NumberFormat.currency(
                          symbol: '\$',
                          decimalDigits: 0,
                        ).format(value),
                        style: const TextStyle(
                          color: Color(0xff72719b),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: const Color(0xffe7e8ec)),
            ),
            minX: salesData.first.x,
            maxX: salesData.last.x,
            minY: minY,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: salesData,
                isCurved: true,
                color: Colors.blue,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.blue.withOpacity(0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
