// lib/data/repositories/product_repository.dart
import '../models/product.dart';
import '../datasources/local/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class ProductRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<List<Product>> getAllProducts() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<List<Product>> getProductsByCategory(String categoryId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<Product> getProductById(String id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    return Product.fromMap(maps.first);
  }

  Future<void> insertProduct(Product product) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateProduct(Product product) async {
    final db = await _databaseHelper.database;
    await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> deleteProduct(String id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateProductQuantity(String id, int newQuantity) async {
    final db = await _databaseHelper.database;
    await db.update(
      'products',
      {'quantity': newQuantity, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'name LIKE ? OR code LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }
}
