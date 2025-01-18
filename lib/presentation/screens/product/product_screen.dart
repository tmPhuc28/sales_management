// lib/presentation/screens/product/product_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sales_management/core/localization/app_strings.dart';
import 'package:sales_management/presentation/blocs/product/product_event.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../../../data/models/product.dart';
import '../../../data/models/category.dart';
import '../../../data/repositories/category_repository.dart';
import '../../blocs/product/product_bloc.dart';

class ProductScreen extends StatefulWidget {
  final Product? product;

  const ProductScreen({
    super.key,
    this.product,
  });

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
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
      _showErrorSnackBar('Lỗi không thể tải danh mục: $e');
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
      _showErrorSnackBar('Lỗi không thể chọn được hình ảnh: $e');
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
        _showErrorSnackBar('Vui lòng chọn danh mục');
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
        _showErrorSnackBar('Lỗi khi lưu sản phẩm: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteProduct),
        content: const Text(AppStrings.confirmDeleteProduct),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        context.read<ProductBloc>().add(DeleteProduct(widget.product!.id));
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.productDeleted)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${AppStrings.error}: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null
            ? AppStrings.addProduct
            : AppStrings.editProduct),
        actions: widget.product != null
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                  onPressed: () => _showDeleteConfirmation(context),
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(AppStrings.loading),
                ],
              ),
            )
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
                        labelText: AppStrings.category,
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
                          return AppStrings.required;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Product Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '${AppStrings.productName}*',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return AppStrings.required;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Product Code
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.productCode,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Prices Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _costPriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '${AppStrings.costPrice}*',
                              border: OutlineInputBorder(),
                              prefixText: '₫',
                            ),
                            validator: _validatePrice,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _sellingPriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '${AppStrings.sellingPrice}*',
                              border: OutlineInputBorder(),
                              prefixText: '₫',
                            ),
                            validator: _validateSellingPrice,
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
                        labelText: '${AppStrings.quantity}*',
                        border: OutlineInputBorder(),
                      ),
                      validator: _validateQuantity,
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: AppStrings.notes,
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
                              ? AppStrings.add
                              : AppStrings.save,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String? _validatePrice(String? value) {
    if (value?.isEmpty ?? true) {
      return AppStrings.required;
    }
    if (double.tryParse(value!) == null) {
      return AppStrings.invalidPrice;
    }
    return null;
  }

  String? _validateSellingPrice(String? value) {
    final priceError = _validatePrice(value);
    if (priceError != null) {
      return priceError;
    }

    final costPrice = double.tryParse(_costPriceController.text) ?? 0;
    final sellingPrice = double.tryParse(value!) ?? 0;

    if (sellingPrice < costPrice) {
      return AppStrings.sellingPriceTooLow;
    }
    return null;
  }

  String? _validateQuantity(String? value) {
    if (value?.isEmpty ?? true) {
      return AppStrings.required;
    }
    if (int.tryParse(value!) == null) {
      return AppStrings.invalidQuantity;
    }
    if (int.parse(value) < 0) {
      return AppStrings.invalidQuantity;
    }
    return null;
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
          'Thêm hình ảnh',
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
