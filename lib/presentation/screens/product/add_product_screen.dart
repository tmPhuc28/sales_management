// lib/presentation/screens/product/add_product_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sales_management/presentation/blocs/product/product_event.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../../../data/models/product.dart';
import '../../../data/models/category.dart';
import '../../../data/repositories/category_repository.dart';
import '../../blocs/product/product_bloc.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;

  const AddProductScreen({
    super.key,
    this.product,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedCategoryId;
  String? _imagePath;
  final _uuid = const Uuid();
  bool _isLoading = false;

  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.product != null) {
      _initializeProductData();
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories =
          await context.read<CategoryRepository>().getAllCategories();
      setState(() {
        _categories = categories;
        if (_selectedCategoryId == null && categories.isNotEmpty) {
          _selectedCategoryId = categories.first.id;
        }
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load categories: $e');
    }
  }

  void _initializeProductData() {
    final product = widget.product!;
    _nameController.text = product.name;
    _codeController.text = product.code ?? '';
    _sellingPriceController.text = product.sellingPrice.toString();
    _costPriceController.text = product.costPrice.toString();
    _quantityController.text = product.quantity.toString();
    _notesController.text = product.notes ?? '';
    _selectedCategoryId = product.categoryId;
    _imagePath = product.imagePath;
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedCategoryId == null) {
        _showErrorSnackBar('Please select a category');
        return;
      }

      setState(() => _isLoading = true);

      try {
        final product = Product(
          id: widget.product?.id ?? _uuid.v4(),
          name: _nameController.text,
          code: _codeController.text.isEmpty ? null : _codeController.text,
          imagePath: _imagePath,
          sellingPrice: double.parse(_sellingPriceController.text),
          costPrice: double.parse(_costPriceController.text),
          quantity: int.parse(_quantityController.text),
          categoryId: _selectedCategoryId!,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          createdAt: widget.product?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (widget.product == null) {
          context.read<ProductBloc>().add(AddProduct(product));
        } else {
          context.read<ProductBloc>().add(UpdateProduct(product));
        }

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        _showErrorSnackBar('Failed to save product: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        context.read<ProductBloc>().add(DeleteProduct(widget.product!.id));
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting product: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
        actions: [
          if (widget.product != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmation(context),
              color: Colors.red,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Picker
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _buildImageWidget(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedCategoryId = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Product Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name*',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter product name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Product Code
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Product Code (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Prices Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _sellingPriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Selling Price*',
                              border: OutlineInputBorder(),
                              prefixText: '\$',
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Required';
                              }
                              if (double.tryParse(value!) == null) {
                                return 'Invalid number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _costPriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Cost Price*',
                              border: OutlineInputBorder(),
                              prefixText: '\$',
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Required';
                              }
                              if (double.tryParse(value!) == null) {
                                return 'Invalid number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Quantity
                    TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity*',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Required';
                        }
                        if (int.tryParse(value!) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          widget.product == null
                              ? 'Add Product'
                              : 'Save Changes',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageWidget() {
    if (_imagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(_imagePath!),
              fit: BoxFit.cover,
            ),
            Positioned(
              right: 8,
              top: 8,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: _pickImage,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
        SizedBox(height: 8),
        Text(
          'Add Photo',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _sellingPriceController.dispose();
    _costPriceController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
