import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sales_management/core/localization/app_strings.dart';
import 'package:sales_management/data/models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final bool isEditable;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.isEditable = false,
  });

  @override
  Widget build(BuildContext context) {
    final inStock = product.quantity > 0;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 48) / 2; // 48 = padding (16 * 2) + spacing (16)
    final imageSize = cardWidth - 16; // Trừ padding của card

    return Card(
      clipBehavior: Clip.hardEdge,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: cardWidth,
          height: cardWidth * 1.4, // Tỷ lệ chiều cao = 1.4 lần chiều rộng
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image container
              SizedBox(
                height: imageSize,
                width: imageSize,
                child: _buildProductImage(),
              ),

              // Product info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Product name
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Price and add to cart
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            NumberFormat.currency(symbol: '₫', decimalDigits: 0)
                                .format(product.sellingPrice),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          if (inStock && onAddToCart != null)
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.add_shopping_cart, size: 18),
                                onPressed: onAddToCart,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                        ],
                      ),

                      const Spacer(),

                      // Stock status
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: inStock
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2,
                              size: 12,
                              color: inStock ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${product.quantity}',
                              style: TextStyle(
                                fontSize: 11,
                                color: inStock ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    if (product.imagePath != null) {
      return Image.file(
        File(product.imagePath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.image,
          size: 32,
          color: Colors.grey,
        ),
      ),
    );
  }
}