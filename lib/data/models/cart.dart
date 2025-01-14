// lib/data/models/cart.dart
import 'package:equatable/equatable.dart';
import 'cart_item.dart';

class Cart extends Equatable {
  final String id;
  final Map<String, CartItem> items;
  final DateTime createdAt;

  const Cart({
    required this.id,
    required this.items,
    required this.createdAt,
  });

  double get total => items.values.fold(
        0,
        (sum, item) => sum + (item.price * item.quantity),
      );

  Cart copyWith({
    Map<String, CartItem>? items,
  }) {
    return Cart(
      id: id,
      items: items ?? this.items,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, items, createdAt];
}
