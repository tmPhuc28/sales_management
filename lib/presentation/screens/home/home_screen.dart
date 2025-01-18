// lib/presentation/screens/home/home_screen.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sales_management/presentation/screens/product/product_screen.dart';
import 'package:sales_management/presentation/widgets/cart/cart_panel.dart';
import 'package:sales_management/presentation/widgets/home/category_list.dart';
import 'package:sales_management/presentation/widgets/home/home_header.dart';
import 'package:sales_management/presentation/widgets/product/product_card.dart';
import 'package:sales_management/presentation/blocs/cart/cart_event.dart';
import 'package:sales_management/presentation/blocs/cart/cart_state.dart';
import 'package:sales_management/presentation/blocs/product/product_event.dart';
import 'package:sales_management/presentation/blocs/product/product_state.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../../data/models/category.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../core/localization/app_strings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategoryId;
  List<Category> _categories = [];
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
          SnackBar(content: Text('${AppStrings.error}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              HomeHeader(
                onSearch: (query) {
                  if (query.isNotEmpty) {
                    context.read<ProductBloc>().add(SearchProducts(query));
                  } else {
                    context.read<ProductBloc>().add(const LoadProducts());
                  }
                },
                onCartTap: () => setState(() => _showCartPanel = true),
                onAddProductTap: () =>
                    Navigator.pushNamed(context, '/add-product'),
                cartItemCount: _getCartItemCount(context),
              ),

              // Category List
              CategoryList(
                categories: _categories,
                selectedCategoryId: _selectedCategoryId,
                onCategorySelected: (categoryId) {
                  setState(() => _selectedCategoryId = categoryId);
                  context.read<ProductBloc>().add(
                        LoadProducts(categoryId: categoryId),
                      );
                },
              ),

              // Product List
              Expanded(
                child: BlocBuilder<ProductBloc, ProductState>(
                  builder: (context, state) {
                    if (state is ProductLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is ProductError) {
                      return _buildErrorView(state.message);
                    }

                    if (state is ProductLoaded) {
                      if (state.products.isEmpty) {
                        return _buildEmptyView();
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio:
                              0.7, // Điều chỉnh tỷ lệ để hiển thị 6 sản phẩm
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                        itemCount: min(
                            state.products.length, 6), // Giới hạn 6 sản phẩm
                        itemBuilder: (context, index) {
                          final product = state.products[index];
                          return ProductCard(
                            product: product,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProductScreen(product: product),
                              ),
                            ),
                            onAddToCart: () {
                              if (product.quantity > 0) {
                                context
                                    .read<CartBloc>()
                                    .add(AddToCart(product));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        AppStrings.addedToCart(product.name)),
                                    action: SnackBarAction(
                                      label: AppStrings.viewCart,
                                      onPressed: () =>
                                          setState(() => _showCartPanel = true),
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      );
                    }

                    return const Center(child: Text(AppStrings.noProducts));
                  },
                ),
              ),
            ],
          ),
          if (_showCartPanel)
            CartPanel(
              cartState: context.watch<CartBloc>().state,
              onClose: () => setState(() => _showCartPanel = false),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text('${AppStrings.error}: $message'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<ProductBloc>().add(
                    LoadProducts(categoryId: _selectedCategoryId),
                  );
            },
            child: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(AppStrings.noProducts),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/add-product');
            },
            icon: const Icon(Icons.add),
            label: const Text(AppStrings.addProduct),
          ),
        ],
      ),
    );
  }

  int _getCartItemCount(BuildContext context) {
    final cartState = context.watch<CartBloc>().state;
    if (cartState is CartLoaded) {
      return cartState.activeCart.items.values.fold(
        0,
        (sum, item) => sum + item.quantity,
      );
    }
    return 0;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Thêm AppBar mới với thiết kế hiện đại
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onCartTap;
  final VoidCallback onAddProductTap;
  final int cartItemCount;

  const HomeAppBar({
    super.key,
    required this.onSearchTap,
    required this.onCartTap,
    required this.onAddProductTap,
    required this.cartItemCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top section with title and actions
            Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppStrings.appName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, dd/MM/yyyy', 'vi_VN')
                            .format(DateTime.now()),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_business),
                  onPressed: onAddProductTap,
                  tooltip: AppStrings.addProduct,
                  color: Colors.white,
                ),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart),
                      onPressed: onCartTap,
                      tooltip: AppStrings.cart,
                      color: Colors.white,
                    ),
                    if (cartItemCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            cartItemCount.toString(),
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
                ),
                const SizedBox(width: 8),
              ],
            ),
            // Search bar section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: InkWell(
                onTap: onSearchTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppStrings.search,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(130);
}
