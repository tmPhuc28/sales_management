// lib/data/repositories/order_repository.dart
import '../models/cart.dart';
import '../datasources/local/database_helper.dart';
import 'package:uuid/uuid.dart';

class OrderRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<String> createOrder(Cart cart, {String? notes}) async {
    final db = await _databaseHelper.database;
    final orderId = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      // Create order
      await txn.insert('orders', {
        'id': orderId,
        'total_amount': cart.total,
        'status': 'completed',
        'notes': notes,
        'created_at': now,
        'updated_at': now,
      });

      // Create order items
      for (var item in cart.items.values) {
        await txn.insert('order_items', {
          'id': _uuid.v4(),
          'order_id': orderId,
          'product_id': item.productId,
          'quantity': item.quantity,
          'price': item.price,
          'created_at': now,
        });
      }
    });

    return orderId;
  }

  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    final db = await _databaseHelper.database;

    // Get order
    final List<Map<String, dynamic>> orderMaps = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [orderId],
    );

    if (orderMaps.isEmpty) throw Exception('Order not found');

    // Get order items
    final List<Map<String, dynamic>> itemMaps = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );

    return {
      'order': orderMaps.first,
      'items': itemMaps,
    };
  }

  Future<List<Map<String, dynamic>>> getAllOrders() async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> orders = await db.query(
      'orders',
      orderBy: 'created_at DESC',
    );

    final List<Map<String, dynamic>> result = [];

    for (var order in orders) {
      final items = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [order['id']],
      );

      result.add({
        ...order,
        'items': items,
      });
    }

    return result;
  }

  Future<Map<String, dynamic>> getStatistics(
      DateTime startDate, DateTime endDate) async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> orders = await db.query(
      'orders',
      where: 'created_at BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    double totalSales = 0;
    int totalOrders = orders.length;

    for (var order in orders) {
      totalSales += order['total_amount'] as double;
    }

    return {
      'totalSales': totalSales,
      'totalOrders': totalOrders,
      'averageOrderValue': totalOrders > 0 ? totalSales / totalOrders : 0,
    };
  }

  Future<List<Map<String, dynamic>>> getDailySales(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> orders = await db.query(
      'orders',
      where: 'created_at BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'created_at ASC',
    );

    // Group orders by date
    final Map<String, double> dailySales = {};
    for (var order in orders) {
      final date =
          DateTime.parse(order['created_at']).toIso8601String().split('T')[0];
      dailySales[date] =
          (dailySales[date] ?? 0) + (order['total_amount'] as double);
    }

    return dailySales.entries
        .map((entry) => {
              'date': entry.key,
              'sales': entry.value,
            })
        .toList();
  }

  Future<List<Map<String, dynamic>>> getTopProducts(
      DateTime startDate, DateTime endDate,
      {int limit = 10}) async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT 
        oi.product_id,
        SUM(oi.quantity) as total_quantity,
        SUM(oi.quantity * oi.price) as total_sales
      FROM order_items oi
      JOIN orders o ON o.id = oi.order_id
      WHERE o.created_at BETWEEN ? AND ?
      GROUP BY oi.product_id
      ORDER BY total_sales DESC
      LIMIT ?
    ''', [startDate.toIso8601String(), endDate.toIso8601String(), limit]);

    return result;
  }
}
