// ProductProfitDropdown.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View/Components/HelperClass/responsive_text.dart';
import 'package:paninda/View_Model/ProductProvider.dart';

final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

class ProductProfitDropdown extends StatefulWidget {
  final List<String> items;
  final String? selected;
  final ValueChanged<String?> onChanged;
  final String Function(String) getLabel;
  final ProductProvider provider;

  const ProductProfitDropdown({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
    required this.getLabel,
    required this.provider,
  });

  @override
  State<ProductProfitDropdown> createState() => _ProductProfitDropdownState();
}

class _ProductProfitDropdownState extends State<ProductProfitDropdown> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.items.isNotEmpty) {
          _showDropdownSelector(context);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColor.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_bag, color: AppColor.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Potential Product Profits",
                    style: TextStyle(
                      fontSize: getResponsiveFontSize(context, 14),
                      fontWeight: FontWeight.w600,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Possible profit for each product you have in stock.",
                    style: TextStyle(
                      fontSize: getResponsiveFontSize(context, 10),
                      color: AppColor.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),

            ),
            if (widget.items.isNotEmpty)
              const Icon(Icons.keyboard_arrow_down, color: AppColor.primary),
          ],
        ),
      ),
    );
  }

  void _showDropdownSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final filteredItems = widget.items.where((productId) {
          final productName = widget.getLabel(productId).toLowerCase();
          return productName.contains(_searchQuery.toLowerCase());
        }).toList();

        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.50,  // ✅ 50% height
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Search & Select Product",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColor.textPrimary,
                    fontSize: getResponsiveFontSize(context, 16),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white60,
                    borderRadius: BorderRadius.circular(10), // ✅ Border radius 10
                  ),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: "Search product name...",
                      prefixIcon: Icon(Icons.search, color: AppColor.primary),
                      border: InputBorder.none, // ✅ No Border
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              ),


              const SizedBox(height: 12),
              Expanded(
                child: filteredItems.isEmpty
                    ? const Center(
                  child: Text(
                    "No matching products found.",
                    style: TextStyle(color: AppColor.textSecondary),
                  ),
                )
                    : ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final productId = filteredItems[index];
                    final product = widget.provider.getProductById(productId);
                    final batchData = product != null
                        ? widget.provider.getProfitPerBatch(product)
                        : [];

                    final profitSacks = batchData.fold<double>(
                        0, (sum, batch) => sum + (batch['profitSacks'] ?? 0));
                    final profitKilos = batchData.fold<double>(
                        0, (sum, batch) => sum + (batch['profitKilos'] ?? 0));

                    return InkWell(
                      onTap: () {
                        widget.onChanged(productId);
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColor.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                "${index + 1}",
                                style: const TextStyle(
                                  color: AppColor.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.getLabel(productId),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColor.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Qty: ${currencyFormat.format(profitSacks)} | Kilos: ${currencyFormat.format(profitKilos)}",
                                    style: const TextStyle(
                                      color: AppColor.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
