// lib/presentation/screens/home/home_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sales_management/presentation/widgets/product/product_grid.dart';
import 'package:sales_management/presentation/blocs/cart/cart_event.dart';
import 'package:sales_management/presentation/blocs/cart/cart_state.dart';
import 'package:sales_management/presentation/blocs/product/product_event.dart';
import 'package:sales_management/presentation/blocs/product/product_state.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../../data/models/category.dart';
import '../../../data/repositories/category_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategoryId;
  List<Category> _categories = [];
  bool _showSearch = false;
  bool _showCartPanel = false;

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(const LoadProducts());
    final cartState = context.read<CartBloc>().state;
    if (cartState is CartInitial) {
      context.read<CartBloc>().add(const CreateNewCart());
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories =
          await context.read<CategoryRepository>().getAllCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading categories: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Tìm kiếm...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              context.read<ProductBloc>().add(SearchProducts(value));
            } else {
              context.read<ProductBloc>().add(const LoadProducts());
            }
          },
        )
            : const Text('Quản lý bán hàng'),
        actions: [
          // Search Toggle Button
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  context.read<ProductBloc>().add(const LoadProducts());
                }
              });
            },
          ),
          // Cart Button with Badge
          BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              if (state is CartLoaded) {
                final totalItems = state.activeCart.items.values
                    .fold(0, (sum, item) => sum + item.quantity);
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart),
                      onPressed: () {
                        setState(() => _showCartPanel = true);
                      },
                      tooltip: 'Giỏ hàng',
                    ),
                    if (totalItems > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            totalItems.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Simple Add Product Button
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/add-product'),
            tooltip: 'Add Product',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 8),
              // Category Filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Tất cả'),
                      selected: _selectedCategoryId == null,
                      onSelected: (selected) {
                        setState(() => _selectedCategoryId = null);
                        context.read<ProductBloc>().add(const LoadProducts());
                      },
                    ),
                    const SizedBox(width: 8),
                    ..._categories.map((category) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category.name),
                        selected: _selectedCategoryId == category.id,
                        onSelected: (selected) {
                          setState(() => _selectedCategoryId =
                          selected ? category.id : null);
                          context.read<ProductBloc>().add(
                            LoadProducts(
                                categoryId:
                                selected ? category.id : null),
                          );
                        },
                      ),
                    )),
                  ],
                ),
              ),

              // Product Grid
              Expanded(
                child: BlocBuilder<ProductBloc, ProductState>(
                  builder: (context, state) {
                    if (state is ProductLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is ProductError) {
                      return Center(child: Text(state.message));
                    }
                    if (state is ProductLoaded) {
                      if (state.products.isEmpty) {
                        return const Center(child: Text('Không có sản phẩm nào'));
                      }
                      return ProductGrid(products: state.products);
                    }
                    return const Center(child: Text('Chưa tìm được sản phẩm'));
                  },
                ),
              ),
            ],
          ),

          // Cart Panel
          if (_showCartPanel)
            CartPanel(
              cartState: context.watch<CartBloc>().state,
              onClose: () => setState(() => _showCartPanel = false),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class CartPanel extends StatelessWidget {
  final VoidCallback onClose;
  final CartState cartState;

  const CartPanel({
    super.key,
    required this.onClose,
    required this.cartState,
  });

  @override
  Widget build(BuildContext context) {
    if (cartState is! CartLoaded) return const SizedBox.shrink();
    final state = cartState as CartLoaded;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Backdrop with opacity
          GestureDetector(
            onTap: onClose,
            child: Container(
              color: Colors.black54,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          // Side Panel
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 320,
            child: Card(
              margin: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.horizontal(left: Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shopping_cart),
                            const SizedBox(width: 8),
                            Text(
                              'Giỏ hàng (${state.allCarts.length})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: onClose,
                          tooltip: 'Đóng',
                        ),
                      ],
                    ),
                  ),

                  // Cart Actions
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add_shopping_cart, size: 18),
                            label: const Text('Thêm giỏ hàng'),
                            onPressed: () {
                              context
                                  .read<CartBloc>()
                                  .add(const CreateNewCart());
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ),
                        if (state.allCarts.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_sweep),
                            onPressed: () => _confirmClearAllCarts(context),
                            tooltip: 'Xóa toàn bộ giỏ hàng',
                            color: Colors.red,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Cart List
                  Expanded(
                    child: state.allCarts.isEmpty
                        ? const Center(
                            child: Text('Không có giỏ hàng nào'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: state.allCarts.length,
                            itemBuilder: (context, index) {
                              final cart =
                                  state.allCarts.values.elementAt(index);
                              final isActive = cart.id == state.activeCart.id;
                              final itemCount = cart.items.values
                                  .fold(0, (sum, item) => sum + item.quantity);
                              final total = NumberFormat.currency(symbol: '\$')
                                  .format(cart.total);

                              return InkWell(
                                onTap: () {
                                  if (!isActive) {
                                    context
                                        .read<CartBloc>()
                                        .add(SwitchCart(cart.id));
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.blue.withOpacity(0.1)
                                        : null,
                                    border: Border.all(
                                      color: isActive
                                          ? Colors.blue
                                          : Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      // Cart icon with count
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? Colors.blue.withOpacity(0.2)
                                              : Colors.grey.shade100,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.shopping_cart,
                                              size: 16,
                                              color: isActive
                                                  ? Colors.blue
                                                  : Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              itemCount.toString(),
                                              style: TextStyle(
                                                color: isActive
                                                    ? Colors.blue
                                                    : Colors.grey[600],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Cart details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Giỏ hàng #${cart.id.substring(0, 8)}',
                                              style: TextStyle(
                                                fontWeight: isActive
                                                    ? FontWeight.bold
                                                    : null,
                                                color: isActive
                                                    ? Colors.blue
                                                    : null,
                                              ),
                                            ),
                                            Text(
                                              total,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Action buttons
                                      if (isActive)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.shopping_bag_outlined,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () {
                                            onClose();
                                            Navigator.pushNamed(
                                                context, '/cart');
                                          },
                                          tooltip: 'Xem giỏ hàng',
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearAllCarts(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa toàn bộ giỏ hàng'),
        content:
            const Text('Bạn có chắc muốn xóa tất cả giỏ hàng không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<CartBloc>().add(ClearAllCarts());
    }
  }
}
