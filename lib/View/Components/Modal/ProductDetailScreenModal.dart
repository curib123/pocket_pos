import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nextpos/Helper/Classes_Methods/AppColor.dart';
import 'package:nextpos/Provider/ProductProvider.dart';
import 'package:nextpos/Model/product_model.dart';
import 'package:nextpos/View/Components/Modal/SimpleProductForm.dart';
import 'package:nextpos/View/Screen/Main/StockManagementScreen.dart';
import 'package:provider/provider.dart';

class ProductDetailModal {
  static void show(
    BuildContext context,
    String productId, [
    bool? modalAsVariant,
  ]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.72,
        child: _ProductDetailContent(productId: productId),
      ),
    );
  }
}

class _ProductDetailContent extends StatelessWidget {
  final String productId;

  const _ProductDetailContent({required this.productId});

  @override
  Widget build(BuildContext context) {
    final product = context.watch<ProductProvider>().getProductById(productId);
    if (product == null) {
      return const Center(child: Text('Product not found'));
    }

    final hasImage = product.imagePath != null &&
        product.imagePath!.isNotEmpty &&
        File(product.imagePath!).existsSync();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: hasImage
                      ? Image.file(
                          File(product.imagePath!),
                          width: 82,
                          height: 82,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 82,
                          height: 82,
                          color: Colors.grey.shade100,
                          child: const Icon(LucideIcons.box, size: 30),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.category ?? 'Uncategorized',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.totalQuantity.toString() +
                            ' ' +
                            (product.unit ?? 'unit') +
                            ' on hand',
                        style: const TextStyle(
                          color: AppColor.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit product',
                  icon: const Icon(LucideIcons.pencil),
                  onPressed: () => _editProduct(context, product),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _infoRow('Unit', product.unit ?? 'unit'),
            _infoRow('Barcode', product.barcode?.isNotEmpty == true ? product.barcode! : 'Not set'),
            _infoRow('Variants', product.variants.length.toString()),
            const Spacer(),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Inventory actions',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            _actionButton(
              context,
              title: 'Stock In',
              icon: LucideIcons.packagePlus,
              mode: StockMovementMode.stockIn,
            ),
            const SizedBox(height: 8),
            _actionButton(
              context,
              title: 'Stock Out',
              icon: LucideIcons.packageMinus,
              mode: StockMovementMode.stockOut,
            ),
            const SizedBox(height: 8),
            _actionButton(
              context,
              title: 'Adjustment',
              icon: LucideIcons.slidersHorizontal,
              mode: StockMovementMode.adjustment,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required StockMovementMode mode,
  }) {
    return OutlinedButton.icon(
      onPressed: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StockManagementScreen(
              initialMode: mode,
              initialProductId: productId,
            ),
          ),
        );
      },
      icon: Icon(icon),
      label: Text(title),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        alignment: Alignment.centerLeft,
        foregroundColor: AppColor.primary,
        side: BorderSide(color: AppColor.primary.withOpacity(0.25)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _editProduct(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SimpleProductForm(existingProduct: product),
    );
  }
}
