import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nextpos/Helper/Classes_Methods/AppColor.dart';
import 'package:nextpos/Provider/ProductProvider.dart';
import 'package:nextpos/Provider/StoreCategoryProvider.dart';
import 'package:nextpos/View/Components/Modal/ProductDetailScreenModal.dart';
import 'package:nextpos/View/Components/Modal/SimpleProductForm.dart';
import 'package:nextpos/View/Components/Widgets/AppDrawer.dart';
import 'package:nextpos/View/Components/Widgets/SearchAndCartRow.dart';
import 'package:provider/provider.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final categoryProvider = context.watch<StoreCategoryProvider>();
    final allProducts = productProvider.getAllProductsWithVariants();
    final products = _category == null
        ? allProducts
        : allProducts.where((product) => product.category == _category).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      drawer: const AppDrawer(),
      appBar: const SearchAndCartAppBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openProductForm(context),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
            child: SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('All'),
                      selected: _category == null,
                      onSelected: (_) => setState(() => _category = null),
                    ),
                  ),
                  ...categoryProvider.visibleCategories.map(
                    (category) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: _category == category,
                        onSelected: (_) => setState(() => _category = category),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: products.isEmpty
                ? _emptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          leading: _image(product.imagePath),
                          title: Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            (product.category ?? 'Uncategorized') +
                                ' • ' +
                                (product.unit ?? 'unit'),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                product.totalQuantity.toString(),
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: _stockColor(product.totalQuantity),
                                ),
                              ),
                              const Text(
                                'on hand',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ),
                          onTap: () => ProductDetailModal.show(
                            context,
                            product.id,
                            product.isVariant,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _image(String? path) {
    final exists = path != null && path.isNotEmpty && File(path).existsSync();
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: exists
          ? Image.file(
              File(path),
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            )
          : Container(
              width: 48,
              height: 48,
              color: Colors.grey.shade100,
              child: const Icon(Icons.inventory_2_outlined),
            ),
    );
  }

  Color _stockColor(int stock) {
    if (stock == 0) return Colors.red;
    if (stock <= 5) return Colors.orange;
    return AppColor.primary;
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 58,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'No products yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Add the product first, then use Stock In to record the opening quantity.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  void _openProductForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const SimpleProductForm(),
    );
  }
}
