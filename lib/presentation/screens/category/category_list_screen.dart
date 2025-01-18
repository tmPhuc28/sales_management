// lib/presentation/screens/category/category_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales_management/core/localization/app_strings.dart';
import 'package:sales_management/presentation/widgets/custom_app_bar.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/models/category.dart';
import 'package:uuid/uuid.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  _CategoryListScreenState createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  Future<List<Category>>? _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    setState(() {
      _categoriesFuture = context.read<CategoryRepository>().getAllCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: AppStrings.categories),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Category>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(AppStrings.loading),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('${AppStrings.error}: ${snapshot.error}'),
              );
            }

            final categories = snapshot.data ?? [];
            if (categories.isEmpty) {
              return const Center(child: Text(AppStrings.noCategories));
            }

            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return CategoryCard(
                  category: category,
                  onEdit: () => _showEditCategoryDialog(context, category),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }


  Future<void> _showAddCategoryDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final notesController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.addCategory),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: AppStrings.categoryName),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return AppStrings.required;
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: codeController,
                decoration: const InputDecoration(labelText: AppStrings.categoryCode),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return AppStrings.required;
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(labelText: AppStrings.notes),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final category = Category(
                  id: const Uuid().v4(),
                  name: nameController.text,
                  code: codeController.text,
                  notes: notesController.text,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                try {
                  await context.read<CategoryRepository>().insertCategory(category);
                  if (context.mounted) {
                    Navigator.pop(context, true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text(AppStrings.categorySaved)),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${AppStrings.error}: $e')),
                    );
                  }
                }
              }
            },
            child: const Text(AppStrings.add),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadCategories();
    }
  }

  Future<void> _showEditCategoryDialog(BuildContext context, Category category) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: category.name);
    final codeController = TextEditingController(text: category.code);
    final notesController = TextEditingController(text: category.notes);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.editCategory),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: AppStrings.categoryName),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return AppStrings.required;
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: codeController,
                decoration: const InputDecoration(labelText: AppStrings.categoryCode),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return AppStrings.required;
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(labelText: AppStrings.notes),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final updatedCategory = category.copyWith(
                  name: nameController.text,
                  code: codeController.text,
                  notes: notesController.text,
                  updatedAt: DateTime.now(),
                );

                try {
                  await context.read<CategoryRepository>().updateCategory(updatedCategory);
                  if (context.mounted) {
                    Navigator.pop(context, true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text(AppStrings.categorySaved)),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${AppStrings.error}: $e')),
                    );
                  }
                }
              }
            },
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadCategories();
    }
  }
}

class CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onEdit,
  });

  Future<void> _confirmDelete(BuildContext context) async {
    try {
      final hasProducts = await context.read<CategoryRepository>().hasProducts(category.id);
      if (hasProducts && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.cannotDeleteCategory),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!context.mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(AppStrings.deleteCategory),
          content: Text(
            AppStrings.confirmDeleteCategory.replaceAll('{name}', category.name),
          ),
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

      if (confirmed == true && context.mounted) {
        await context.read<CategoryRepository>().deleteCategory(category.id);
        if (context.mounted) {
          // Refresh categories list
          _CategoryListScreenState? state =
          context.findAncestorStateOfType<_CategoryListScreenState>();
          state?._loadCategories();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.categoryDeleted)),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Theme.of(context).colorScheme.primary.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.category,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: onEdit,
                        tooltip: AppStrings.editCategory,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmDelete(context),
                        tooltip: AppStrings.deleteCategory,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Mã: ${category.code}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (category.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  category.notes!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}