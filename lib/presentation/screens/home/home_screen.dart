// lib/presentation/screens/home/home_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:sales_management/presentation/blocs/cart/cart_event.dart';
import 'package:sales_management/presentation/blocs/cart/cart_state.dart';
import 'package:sales_management/presentation/blocs/product/product_event.dart';
import 'package:sales_management/presentation/blocs/product/product_state.dart';
import 'package:sales_management/presentation/screens/product/add_product_screen.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../../data/models/product.dart';
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
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      context.read<ProductBloc>().add(const LoadProducts());
                      setState(() => _showSearch = false);
                    },
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    context.read<ProductBloc>().add(SearchProducts(value));
                  } else {
                    context.read<ProductBloc>().add(const LoadProducts());
                  }
                },
              )
            : const Text('Sales Management'),
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
                      tooltip: 'Shopping Carts',
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
          // Add Product Button
          PopupMenuButton(
            icon: const Icon(Icons.add),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new_product',
                child: Row(
                  children: [
                    Icon(Icons.add_box),
                    SizedBox(width: 8),
                    Text('New Product'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'new_category',
                child: Row(
                  children: [
                    Icon(Icons.category),
                    SizedBox(width: 8),
                    Text('New Category'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'new_product') {
                Navigator.pushNamed(context, '/add-product');
              } else if (value == 'new_category') {
                showDialog(
                  context: context,
                  builder: (context) => const AddCategoryDialog(),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Category Filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
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
                        return const Center(child: Text('No products found'));
                      }
                      return ProductGrid(products: state.products);
                    }
                    return const Center(child: Text('No products found'));
                  },
                ),
              ),
            ],
          ),

          // Cart Panel with Animation
          if (_showCartPanel)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                final slideAnimation = Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ));

                return SlideTransition(
                  position: slideAnimation,
                  child: child,
                );
              },
              child: BlocBuilder<CartBloc, CartState>(
                builder: (context, state) => CartPanel(
                  cartState: state,
                  onClose: () => setState(() => _showCartPanel = false),
                ),
              ),
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

class ProductGrid extends StatelessWidget {
  final List<Product> products;

  const ProductGrid({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(product: product);
      },
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: product.quantity > 0
          ? () {
              context.read<CartBloc>().add(AddToCart(product));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.shopping_cart, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Added to cart'),
                      Spacer(),
                      Text('Quantity: 1'),
                    ],
                  ),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          : null,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Container
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  image: product.imagePath != null
                      ? DecorationImage(
                          image: FileImage(File(product.imagePath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: product.imagePath == null
                    ? Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child:
                              Icon(Icons.image, size: 40, color: Colors.grey),
                        ),
                      )
                    : null,
              ),
            ),

            // Product Info Container
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Product Name and Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '\$${product.sellingPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    // Stock Status and Edit Button
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 12,
                              color: product.quantity > 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Stock: ${product.quantity}',
                              style: TextStyle(
                                fontSize: 12,
                                color: product.quantity > 0
                                    ? Colors.black54
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 32,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddProductScreen(product: product),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text(
                              'Edit',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddCategoryDialog extends StatefulWidget {
  const AddCategoryDialog({super.key});

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Category'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Code',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter a code';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState?.validate() ?? false) {
              final category = Category(
                id: const Uuid().v4(),
                name: _nameController.text,
                code: _codeController.text,
                notes: _notesController.text.isEmpty
                    ? null
                    : _notesController.text,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              try {
                await context
                    .read<CategoryRepository>()
                    .insertCategory(category);
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error creating category: $e')),
                  );
                }
              }
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _notesController.dispose();
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
                              'Shopping Carts (${state.allCarts.length})',
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
                          tooltip: 'Close',
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
                            label: const Text('New Cart'),
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
                            tooltip: 'Clear All Carts',
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
                            child: Text('No shopping carts'),
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
                                              'Cart #${cart.id.substring(0, 8)}',
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
                                          tooltip: 'View Cart',
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
        title: const Text('Clear All Carts'),
        content:
            const Text('Are you sure you want to clear all shopping carts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<CartBloc>().add(ClearAllCarts());
    }
  }
}
