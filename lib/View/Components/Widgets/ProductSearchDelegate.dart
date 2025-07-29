import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pocketpos/Model/product_model.dart';
import 'package:pocketpos/View/Components/Modal/ProductDetailScreenModal.dart';

class ProductSearchDelegate extends SearchDelegate<Product?> {
  final List<Product> products;
  final Duration debounceDuration;

  Timer? _debounce;
  List<Product> _filtered = [];

  ProductSearchDelegate({
    required this.products,
    this.debounceDuration = const Duration(milliseconds: 300),
  }) : super(
    searchFieldLabel: 'Search products...',
    keyboardType: TextInputType.text,
    textInputAction: TextInputAction.search,
  );

  void _debounceSearch(String query, VoidCallback refresh) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(debounceDuration, () {
      _filtered = products
          .where((p) =>
          p.name.toLowerCase().contains(query.toLowerCase()))
          .take(50)
          .toList();
      refresh();
    });
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return query.isNotEmpty
        ? [
      IconButton(
        icon: const Icon(LucideIcons.x),
        onPressed: () {
          query = '';
          _filtered.clear();
          showSuggestions(context);
        },
      )
    ]
        : null;
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(LucideIcons.arrowLeft),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.length < 2) {
      return const Center(child: Text('Type at least 2 characters to search.'));
    }

    _debounceSearch(query, () {
      showResults(context);
    });

    if (_filtered.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.separated(
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 0.5),
      itemBuilder: (context, index) {
        return _buildProductTile(context, _filtered[index]);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final List<Product> displayList = query.isEmpty
        ? products.take(10).toList()
        : products
        .where((p) =>
        p.name.toLowerCase().contains(query.toLowerCase()))
        .take(5)
        .toList();

    if (displayList.isEmpty) {
      return const Center(child: Text('No suggestions found.'));
    }

    return ListView.builder(
      itemCount: displayList.length,
      itemBuilder: (context, index) =>
          _buildProductTile(context, displayList[index]),
    );
  }

  Widget _buildProductTile(BuildContext context, Product product) {
    return ListTile(
      key: ValueKey(product.id),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: (product.imagePath != null &&
            product.imagePath!.isNotEmpty &&
            File(product.imagePath!).existsSync())
            ? Image.file(
          File(product.imagePath!),
          width: 44,
          height: 44,
          fit: BoxFit.cover,
        )
            : Container(
          width: 44,
          height: 44,
          color: Colors.grey[100],
          child: const Icon(LucideIcons.box, size: 20, color: Colors.grey),
        ),
      ),
      title: Text(
        product.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        "Qty: ${product.totalQuantity}",
        style: const TextStyle(fontSize: 12.5, color: Colors.grey),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      onTap: () {
        ProductDetailModal.show(context, product.id, product.isVariant);
      },
    );
  }

  @override
  void close(BuildContext context, Product? result) {
    _debounce?.cancel();
    super.close(context, result);
  }
}
