import 'dart:io';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:paninda/View/Components/Custom/ShoppingCartAnimatedWidget.dart';
import 'package:paninda/View/Components/Modal/cart_modal.dart';
import 'package:paninda/View_Model/ProductProvider.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:provider/provider.dart';
import 'package:paninda/Model/product_model.dart';
import 'package:paninda/View/Components/HelperClass/StoreCategory.dart'; // <- Important

class CustomSearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) => [
    ShoppingCartAnimatedwidget(),
    IconButton(
      icon: const Icon(Icons.clear),
      onPressed: () => query = '',
    ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back_ios_new),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final results = productProvider.searchProducts(query);

    if (results.isEmpty) {
      return _buildNotFoundTemplate();
    }

    return _buildProductList(results, context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final suggestions = query.isEmpty
        ? productProvider.products.take(10).toList()
        : productProvider.searchProducts(query);

    if (suggestions.isEmpty) {
      return _buildNotFoundTemplate();
    }

    return _buildProductList(suggestions, context);
  }

  Widget _buildProductList(List<Product> list, BuildContext context) {
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final product = list[index];
        final hasImage =
            product.imageUrl.isNotEmpty && File(product.imageUrl).existsSync();

        final icon = StoreCategory.icons[product.category] ?? Icons.category;
        final color = StoreCategory.colors[product.category] ?? Colors.grey;

        return SlideInUp(
          duration: Duration(milliseconds: 500), // slight stagger per item
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: hasImage
                    ? Image.file(
                  File(product.imageUrl),
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                )
                    : Container(
                  width: 60,
                  height: 60,
                  color: AppColor.border.withOpacity(0.3),
                  child: Icon(
                    Icons.image_not_supported,
                    size: 40,
                    color: AppColor.textSecondary.withOpacity(0.6),
                  ),
                ),
              ),
              title: Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      product.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: color,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Price: ${product.retailPrice.toStringAsFixed(2)} • ${product.unit}",
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Stocks: ${product.totalSacks.toStringAsFixed(0)} ${product.unit} | ${product.totalKilos.toStringAsFixed(2)} kg",
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () {
                CartModal.show(context, product);
              },
            ),
          ),
        );
      },
    );
  }


  Widget _buildNotFoundTemplate() {
    return Center(
      child: FadeIn(
        duration: const Duration(milliseconds: 500),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              "No results found",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColor.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Try checking spelling or use another keyword.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColor.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

}
