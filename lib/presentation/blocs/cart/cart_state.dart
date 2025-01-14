// lib/presentation/blocs/cart/cart_state.dart
import 'package:equatable/equatable.dart';
import '../../../data/models/cart.dart';

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final Cart activeCart;
  final Map<String, Cart> allCarts;

  const CartLoaded({
    required this.activeCart,
    required this.allCarts,
  });

  @override
  List<Object> get props => [activeCart, allCarts];
}

class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object> get props => [message];
}
