import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View/Components/HelperClass/StoreCategory.dart';
import 'package:paninda/View/Components/Modal/cart_list_modal.dart';
import 'package:paninda/View/Components/Modal/cart_modal.dart';
import 'package:paninda/View_Model/ProductProvider.dart';

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
          child: const Icon(Icons.arrow_back_ios, color: AppColor.surface),
        ),
        title: Text(widget.category),
        backgroundColor: color,
        foregroundColor: Colors.white,
        actions: [
          Consumer<ProductProvider>(
            builder: (context, provider, _) {
              final count = provider.getCartItemCount();

              return SizedBox(
                width: 48, // make tap target bigger than just icon
                height: 48,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_rounded, size: 28),
                      onPressed: () {
                        CartListModal.show(context);
                      },
                      padding: EdgeInsets.zero, // optional, reduces icon padding
                      constraints: const BoxConstraints(), // shrink to icon size
                    ),
                    if (count > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                          alignment: Alignment.center,
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 12),

        ],
      ),
      body: Column(
        children: [
          // Search Bar with animation
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Padding(
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

                    return FadeInUp(
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          tileColor: color.withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: imageUrl.isNotEmpty && File(imageUrl).existsSync()
                                ? Image.file(
                              File(imageUrl),
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              key: ValueKey(product.imageUrl),  // This forces Flutter to reload image if imageUrl changes
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
                            CartModal.show(context, product);
                          },
                        ),
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
