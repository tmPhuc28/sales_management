// lib/data/models/category.dart
import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String code;
  final String name;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    required this.id,
    required this.code,
    required this.name,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Category copyWith({
    String? code,
    String? name,
    String? notes,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id,
      code: code ?? this.code,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      code: map['code'],
      name: map['name'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  @override
  List<Object?> get props => [id, code, name, notes, createdAt, updatedAt];
}
