import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:paninda/View/Components/Custom/ShoppingCartAnimatedWidget.dart';
import 'package:paninda/View/Components/Custom/custom_btn.dart';
import 'package:paninda/View/Components/Modal/add_product_modal.dart';
import 'package:paninda/View_Model/CurrencyProvider.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View/Components/Modal/cart_modal.dart';
import 'package:paninda/View_Model/ProductProvider.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _searchQuery = '';
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = context.read<CurrencyProvider>().currencyFormat;

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios, color: AppColor.surface),
        ),
        title: const Text('All Products'),
        backgroundColor: AppColor.accent,
        foregroundColor: Colors.white,
        actions: [
          ShoppingCartAnimatedwidget(iconColor: AppColor.surface),
          const SizedBox(width: 12),
        ],
      ),
      bottomNavigationBar:  Padding(
        padding: const EdgeInsets.all(15.0),
        child: CustomButton(
          color: AppColor.accent,
          icon: LucideIcons.plusCircle,
          label: "Add New Product",
          onPressed: () => AddProductModal.show(context, isStock: false, isEdit: false),
        ),
      ),
      body: Column(
        children: [
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search product...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isGridView = !_isGridView;
                      });
                    },
                    icon: Icon(
                      _isGridView ? Icons.layers_rounded : Icons.dashboard_rounded,
                      color: AppColor.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, provider, _) {

                final filtered = provider.products
                    .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                    .take(40)
                    .toList();


                if (filtered.isEmpty) {
                  return const Center(child: Text('No products found.'));
                }

                return _isGridView
                    ? GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    final imageUrl = product.imageUrl;

                    return FadeInUp(
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      child: GestureDetector(
                        onTap: () {
                          CartModal.show(context, product);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColor.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: imageUrl.isNotEmpty &&
                                    File(imageUrl).existsSync()
                                    ? Image.file(
                                  File(imageUrl),
                                  width: double.infinity,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  key: ValueKey(product.imageUrl),
                                )
                                    : _placeholderIcon(AppColor.accent),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: AppColor.textPrimary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Stocks: ${product.totalSacks}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColor.textSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                      'Price: ${currencyFormat.format(product.retailPrice)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                )
                    : ListView.builder(
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
                          tileColor: AppColor.accent.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: imageUrl.isNotEmpty &&
                                File(imageUrl).existsSync()
                                ? Image.file(
                              File(imageUrl),
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              key: ValueKey(product.imageUrl),
                            )
                                : _placeholderIcon(AppColor.accent),
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
                                  'Price: ${currencyFormat.format(product.retailPrice)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right,
                              color: AppColor.textSecondary),
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
      width: _isGridView ? double.infinity : 90,
      height: 100,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.image_not_supported, color: color),
    );
  }
}
