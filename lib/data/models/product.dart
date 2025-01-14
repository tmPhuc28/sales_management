// lib/data/models/product.dart
import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String? code;
  final String? imagePath;
  final double sellingPrice;
  final double costPrice;
  final int quantity;
  final String categoryId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.name,
    this.code,
    this.imagePath,
    required this.sellingPrice,
    required this.costPrice,
    required this.quantity,
    required this.categoryId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Product copyWith({
    String? name,
    String? code,
    String? imagePath,
    double? sellingPrice,
    double? costPrice,
    int? quantity,
    String? categoryId,
    String? notes,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      code: code ?? this.code,
      imagePath: imagePath ?? this.imagePath,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      costPrice: costPrice ?? this.costPrice,
      quantity: quantity ?? this.quantity,
      categoryId: categoryId ?? this.categoryId,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'image_path': imagePath,
      'selling_price': sellingPrice,
      'cost_price': costPrice,
      'quantity': quantity,
      'category_id': categoryId,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      code: map['code'],
      imagePath: map['image_path'],
      sellingPrice: map['selling_price'],
      costPrice: map['cost_price'],
      quantity: map['quantity'],
      categoryId: map['category_id'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        code,
        imagePath,
        sellingPrice,
        costPrice,
        quantity,
        categoryId,
        notes,
        createdAt,
        updatedAt,
      ];
}
