// lib/data/repositories/settings_repository.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../datasources/local/database_helper.dart';

class SettingsRepository {
  final DatabaseHelper _databaseHelper;

  SettingsRepository({
    required DatabaseHelper databaseHelper,
  }) : _databaseHelper = databaseHelper;

  Future<void> clearAllData() async {
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      await txn.delete('order_items');
      await txn.delete('orders');
      await txn.delete('products');
      await txn.delete('categories');
    });
  }

  Future<void> importData(String filePath) async {
    final file = File(filePath);
    final jsonString = await file.readAsString();
    final data = jsonDecode(jsonString);

    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      // Clear existing data
      await txn.delete('order_items');
      await txn.delete('orders');
      await txn.delete('products');
      await txn.delete('categories');

      // Import categories
      for (var category in data['categories']) {
        await txn.insert('categories', category);
      }

      // Import products
      for (var product in data['products']) {
        await txn.insert('products', product);
      }

      // Import orders
      for (var order in data['orders']) {
        await txn.insert('orders', order);
      }

      // Import order items
      for (var item in data['order_items']) {
        await txn.insert('order_items', item);
      }
    });
  }

  Future<void> exportData(String filePath) async {
    final db = await _databaseHelper.database;
    final data = {
      'categories': await db.query('categories'),
      'products': await db.query('products'),
      'orders': await db.query('orders'),
      'order_items': await db.query('order_items'),
    };

    final jsonString = jsonEncode(data);
    final file = File(filePath);
    await file.writeAsString(jsonString);
  }

  Future<String> getBackupFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}/backup_$timestamp.json';
  }
}