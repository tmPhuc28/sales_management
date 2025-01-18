// lib/presentation/widgets/home/category_list.dart
import 'package:flutter/material.dart';
import '../../../data/models/category.dart';

class CategoryList extends StatelessWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final Function(String?) onCategorySelected;

  const CategoryList({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildCategoryTab(
              context,
              categoryId: null,
              name: 'Tất cả',
              isSelected: selectedCategoryId == null,
            );
          }

          final category = categories[index - 1];
          return _buildCategoryTab(
            context,
            categoryId: category.id,
            name: category.name,
            isSelected: selectedCategoryId == category.id,
          );
        },
      ),
    );
  }

  Widget _buildCategoryTab(
      BuildContext context, {
        required String? categoryId,
        required String name,
        required bool isSelected,
      }) {
    return InkWell(
      onTap: () => onCategorySelected(categoryId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Center(
          child: Text(
            name,
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : null,
            ),
          ),
        ),
      ),
    );
  }
}