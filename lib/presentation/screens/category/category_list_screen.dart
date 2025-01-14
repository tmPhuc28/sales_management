// lib/presentation/screens/category/category_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Categories'),
            floating: true,
            snap: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: FutureBuilder<List<Category>>(
              future: _categoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(child: Text('Error: ${snapshot.error}')),
                  );
                }

                final categories = snapshot.data ?? [];
                if (categories.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('No categories found')),
                  );
                }

                return SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final category = categories[index];
                      return CategoryCard(
                        category: category,
                        onEdit: () =>
                            _showEditCategoryDialog(context, category),
                      );
                    },
                    childCount: categories.length,
                  ),
                );
              },
            ),
          ),
        ],
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
        title: const Text('Add Category'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Code'),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter a code';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
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

                await context
                    .read<CategoryRepository>()
                    .insertCategory(category);
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadCategories();
    }
  }

  Future<void> _showEditCategoryDialog(
    BuildContext context,
    Category category,
  ) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: category.name);
    final codeController = TextEditingController(text: category.code);
    final notesController = TextEditingController(text: category.notes);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Code'),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter a code';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
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

                await context
                    .read<CategoryRepository>()
                    .updateCategory(updatedCategory);
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              }
            },
            child: const Text('Save'),
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
              // Category Icon and Edit Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.category,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEdit,
                    tooltip: 'Edit Category',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category Name
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

              // Category Code
              Text(
                'Code: ${category.code}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Notes if available
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