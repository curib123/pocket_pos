import 'dart:io';
import 'package:flutter/material.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View/Components/HelperClass/StoreCategory.dart';
import 'package:paninda/View/Components/Modal/cart_list_modal.dart';
import 'package:paninda/View/Components/Modal/cart_modal.dart';
import 'package:paninda/View_Model/ProductProvider.dart';
import 'package:provider/provider.dart';

class CategoryProductListScreen extends StatefulWidget {
  final String category;

  const CategoryProductListScreen({super.key, required this.category});

  @override
  State<CategoryProductListScreen> createState() => _CategoryProductListScreenState();
}

class _CategoryProductListScreenState extends State<CategoryProductListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final color = StoreCategory.colors[widget.category] ?? Colors.grey;

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios, color: AppColor.surface),
        ),
        title: Text(widget.category),
        backgroundColor: color,
        foregroundColor: Colors.white,
        actions: [
          Consumer<ProductProvider>(
            builder: (context, provider, _) {
              final count = provider.getCartItems().length; // You can use cart count here

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_rounded, size: 28),
                    onPressed: () {
                      // TODO: Navigate to your cart screen
                      CartListModal.show(context);
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                        child: Center(
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),

      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search product...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Product List
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, provider, _) {
                final filtered = provider.getProductsByCategory(widget.category).where((p) {
                  return p.name.toLowerCase().contains(_searchQuery.toLowerCase());
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No products found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    final imageUrl = product.imageUrl;

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(10),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageUrl.isNotEmpty && File(imageUrl).existsSync()
                              ? Image.file(
                            File(imageUrl),
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          )
                              : _placeholderIcon(color),
                        ),
                        title: Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColor.textPrimary,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Stocks: ${product.totalSacks}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColor.textSecondary,
                                ),
                              ),
                              Text(
                                'Price :${product.retailPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: AppColor.textSecondary),
                        onTap: () {
                          // Navigate to detail page if needed
                          CartModal.show(context,product);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderIcon(Color color) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.image_not_supported, color: color),
    );
  }
}
