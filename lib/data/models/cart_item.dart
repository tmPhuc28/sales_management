// lib/data/models/cart_item.dart
import 'package:equatable/equatable.dart';

class CartItem extends Equatable {
  final String productId;
  final int quantity;
  final double price;

  const CartItem({
    required this.productId,
    required this.quantity,
    required this.price,
  });

  CartItem copyWith({
    int? quantity,
    double? price,
  }) {
    return CartItem(
      productId: productId,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }

  @override
  List<Object?> get props => [productId, quantity, price];
}
