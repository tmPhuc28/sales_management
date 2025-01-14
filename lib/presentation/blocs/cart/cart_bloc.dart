// lib/presentation/blocs/cart/cart_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/cart.dart';
import '../../../data/models/cart_item.dart';
import 'package:uuid/uuid.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final Map<String, Cart> _carts = {};
  String? _activeCartId;
  final _uuid = const Uuid();

  CartBloc() : super(CartInitial()) {
    on<CreateNewCart>(_onCreateNewCart);
    on<SwitchCart>(_onSwitchCart);
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<ClearCart>(_onClearCart);
    on<ClearAllCarts>(_onClearAllCarts);
    on<DeleteCart>(_onDeleteCart);
  }

  void _onCreateNewCart(CreateNewCart event, Emitter<CartState> emit) {
    final cartId = event.cartId ?? _uuid.v4();
    final newCart = Cart(
      id: cartId,
      items: const {},
      createdAt: DateTime.now(),
    );

    _carts[cartId] = newCart;
    _activeCartId = cartId;

    emit(CartLoaded(
      activeCart: newCart,
      allCarts: _carts,
    ));
  }

  void _onSwitchCart(SwitchCart event, Emitter<CartState> emit) {
    if (_carts.containsKey(event.cartId)) {
      _activeCartId = event.cartId;
      emit(CartLoaded(
        activeCart: _carts[_activeCartId]!,
        allCarts: _carts,
      ));
    }
  }

  void _onAddToCart(AddToCart event, Emitter<CartState> emit) {
    if (_activeCartId == null) {
      // Nếu chưa có giỏ hàng nào, tạo giỏ hàng mới
      final cartId = _uuid.v4();
      final newCart = Cart(
        id: cartId,
        items: const {},
        createdAt: DateTime.now(),
      );
      _carts[cartId] = newCart;
      _activeCartId = cartId;
    }

    final cart = _carts[_activeCartId]!;
    final productId = event.product.id;

    if (event.product.quantity < event.quantity) {
      emit(const CartError('Not enough stock available'));
      return;
    }

    final items = Map<String, CartItem>.from(cart.items);
    if (items.containsKey(productId)) {
      final currentQuantity = items[productId]!.quantity;
      if (currentQuantity + event.quantity > event.product.quantity) {
        emit(const CartError('Not enough stock available'));
        return;
      }
      items[productId] = CartItem(
        productId: productId,
        quantity: currentQuantity + event.quantity,
        price: event.product.sellingPrice,
      );
    } else {
      items[productId] = CartItem(
        productId: productId,
        quantity: event.quantity,
        price: event.product.sellingPrice,
      );
    }

    _carts[_activeCartId!] = cart.copyWith(items: items);
    emit(CartLoaded(
      activeCart: _carts[_activeCartId]!,
      allCarts: _carts,
    ));
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<CartState> emit) {
    if (_activeCartId == null) return;

    final cart = _carts[_activeCartId]!;
    final items = Map<String, CartItem>.from(cart.items);

    if (items.containsKey(event.productId)) {
      final currentQuantity = items[event.productId]!.quantity;
      if (currentQuantity <= event.quantity) {
        items.remove(event.productId);
      } else {
        items[event.productId] = items[event.productId]!.copyWith(
          quantity: currentQuantity - event.quantity,
        );
      }
    }

    _carts[_activeCartId!] = cart.copyWith(items: items);
    emit(CartLoaded(
      activeCart: _carts[_activeCartId]!,
      allCarts: _carts,
    ));
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    if (_activeCartId == null) return;

    final cart = _carts[_activeCartId]!;
    _carts[_activeCartId!] = cart.copyWith(items: {});

    emit(CartLoaded(
      activeCart: _carts[_activeCartId]!,
      allCarts: _carts,
    ));
  }

  void _onClearAllCarts(ClearAllCarts event, Emitter<CartState> emit) {
    _carts.clear();
    _activeCartId = null;
    emit(CartInitial());
  }

  void _onDeleteCart(DeleteCart event, Emitter<CartState> emit) {
    _carts.remove(event.cartId);

    // Nếu xóa giỏ hàng đang active
    if (_activeCartId == event.cartId) {
      // Chọn giỏ hàng khác nếu còn
      _activeCartId = _carts.isNotEmpty ? _carts.keys.first : null;
    }

    if (_carts.isEmpty) {
      emit(CartInitial());
    } else {
      emit(CartLoaded(
        activeCart: _carts[_activeCartId]!,
        allCarts: _carts,
      ));
    }
  }
}
