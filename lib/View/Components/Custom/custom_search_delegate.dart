import 'dart:io';
import 'package:flutter/material.dart';
import 'package:paninda/View/Components/Modal/cart_modal.dart';
import 'package:paninda/View/Components/Modal/cart_list_modal.dart';
import 'package:paninda/View_Model/ProductProvider.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:provider/provider.dart';
import 'package:paninda/Model/product_model.dart';

class CustomSearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) => [
    Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final count = provider.getCartItems().length;

        return Material(
          color: Colors.transparent, // So it blends with background
          child: InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: () {
              CartListModal.show(context);
            },
            child: Padding(
              padding: const EdgeInsets.all(12), // Make tap area larger
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.shopping_cart_rounded, size: 28),
                  if (count > 0)
                    Positioned(
                      right: 2,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
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
            ),
          ),
        );
      },
    ),

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
    final List<Product> suggestions = query.isEmpty
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
        final hasImage = product.imageUrl.isNotEmpty && File(product.imageUrl).existsSync();

        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: hasImage
                ? Image.file(File(product.imageUrl), width: 60, height: 60, fit: BoxFit.cover)
                : Container(
              width: 60,
              height: 60,
              color: AppColor.border,
              child: const Icon(Icons.image_not_supported, size: 28, color: AppColor.textSecondary),
            ),
          ),
          title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Price : ${product.retailPrice.toStringAsFixed(2)} • ${product.unit}"),
              Text("Stocks: ${product.totalSacks.toStringAsFixed(0)} ${product.unit} | ${product.totalKilos.toStringAsFixed(2)} kg"),
            ],
          ),
          isThreeLine: true,
          onTap: () {
            query = product.name;
            CartModal.show(context, product);
          },
        );
      },
    );
  }

  Widget _buildNotFoundTemplate() {
    return Center(
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
    );
  }
}
