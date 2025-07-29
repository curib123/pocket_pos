import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppColor.dart';
import 'package:pocketpos/View/Components/Modal/ProductDetailScreenModal.dart';
import 'package:provider/provider.dart';
import 'package:pocketpos/Provider/ProductStockProvider.dart';

class ProductRangePreviewDropdown extends StatelessWidget {
  final int minQty;
  final int maxQty;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;

  const ProductRangePreviewDropdown({
    super.key,
    required this.minQty,
    required this.maxQty,
    this.label,
    this.hint,
    this.prefixIcon,
  });

  void _showDropdown(BuildContext context) {
    final products = context.read<ProductStockProvider>().getProductsByStockRange(
      context: context,
      minQty: minQty,
      maxQty: maxQty,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColor.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Products with stock $minQty–$maxQty",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                if (products.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.inventory_2_rounded,
                            size: 48,
                            color: AppColor.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "No products found",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColor.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Try a different stock range.",
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColor.textPrimary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: products.length,
                      itemBuilder: (_, i) {
                        final product = products[i];
                        final totalQty = product.stocks.fold(0, (sum, s) => sum + s.quantity);

                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListTile(
                            onTap: () => ProductDetailModal.show(context, product.id, false),
                            tileColor: AppColor.secondarySurface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),

                            // ✅ File-based image preview
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: product.imagePath != null && File(product.imagePath!).existsSync()
                                  ? Image.file(
                                File(product.imagePath!),
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              )
                                  : Container(
                                width: 48,
                                height: 48,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.image_not_supported, color: Colors.grey),
                              ),
                            ),

                            title: Text(
                              product.name,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              "Qty: $totalQty",
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColor.textSecondary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label!,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
              ),
            ),
          ),
        GestureDetector(
          onTap: () => _showDropdown(context),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColor.secondarySurface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColor.surface, width: 0.8),
            ),
            child: Row(
              children: [
                if (prefixIcon != null) ...[
                  Icon(prefixIcon, color: AppColor.textSecondary, size: 18),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    hint ?? "Tap to view products",
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: AppColor.textSecondary,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
