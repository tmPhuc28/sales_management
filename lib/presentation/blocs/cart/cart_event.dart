// lib/presentation/blocs/cart/cart_event.dart
import 'package:equatable/equatable.dart';
import '../../../data/models/product.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class CreateNewCart extends CartEvent {
  final String? cartId;
  const CreateNewCart({this.cartId});

  @override
  List<Object?> get props => [cartId];
}

class SwitchCart extends CartEvent {
  final String cartId;
  const SwitchCart(this.cartId);

  @override
  List<Object> get props => [cartId];
}

class AddToCart extends CartEvent {
  final Product product;
  final int quantity;
  const AddToCart(this.product, {this.quantity = 1});

  @override
  List<Object> get props => [product, quantity];
}

class RemoveFromCart extends CartEvent {
  final String productId;
  final int quantity;
  const RemoveFromCart(this.productId, {this.quantity = 1});

  @override
  List<Object> get props => [productId, quantity];
}

class ClearCart extends CartEvent {}

class ClearAllCarts extends CartEvent {}

class DeleteCart extends CartEvent {
  final String cartId;
  const DeleteCart(this.cartId);

  @override
  List<Object> get props => [cartId];
}
