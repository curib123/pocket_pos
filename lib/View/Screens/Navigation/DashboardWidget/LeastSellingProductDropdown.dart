import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:paninda/Model/product_model.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View/Components/HelperClass/responsive_text.dart';
import 'package:paninda/View/Components/Modal/cart_modal.dart';
import 'package:paninda/View_Model/ProductProvider.dart';
import 'package:provider/provider.dart';

class LeastSellingTileDropdown extends StatefulWidget {
  final ProductProvider productProvider;

  const LeastSellingTileDropdown({super.key, required this.productProvider});

  @override
  State<LeastSellingTileDropdown> createState() => _LeastSellingTileDropdownState();
}

class _LeastSellingTileDropdownState extends State<LeastSellingTileDropdown> {
  Map<String, dynamic>? selectedProduct;
  int _selectedBottomCount = 5;

  @override
  Widget build(BuildContext context) {
    final leastProducts = widget.productProvider.getLeastSellingProducts(_selectedBottomCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            _showProductSelector(context);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColor.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColor.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.trending_down, color: AppColor.error, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        leastProducts.isEmpty
                            ? "No Least-Selling Products"
                            : (selectedProduct != null
                            ? selectedProduct!['productName']
                            : "View a Least-Selling Product"),
                        style: TextStyle(
                          fontSize: getResponsiveFontSize(context, 14),
                          fontWeight: FontWeight.w500,
                          color: AppColor.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (leastProducts.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selectedProduct != null)
                        Text(
                          "#${leastProducts.indexOf(selectedProduct!) + 1}",
                          style: TextStyle(
                            fontSize: getResponsiveFontSize(context, 14),
                            fontWeight: FontWeight.bold,
                            color: AppColor.error,
                          ),
                        ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, color: AppColor.error),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showProductSelector(BuildContext context) {
    final leastProducts = widget.productProvider.getLeastSellingProducts(_selectedBottomCount);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "View Least-Selling Product",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColor.textPrimary,
                    fontSize: getResponsiveFontSize(context, 16),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () async {
                    final selected = await showModalBottomSheet<int>(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (context) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 16),
                          const Text(
                            "Filter by Product Count",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          _buildFilterTile(context, 3, "Bottom 3"),
                          _buildFilterTile(context, 5, "Bottom 5"),
                          _buildFilterTile(context, 10, "Bottom 10"),
                          _buildFilterTile(context, 20, "Bottom 20"),
                          const SizedBox(height: 16),
                        ],
                      ),
                    );

                    if (selected != null) {
                      setState(() {
                        _selectedBottomCount = selected;
                      });
                      Navigator.pop(context);
                      _showProductSelector(context);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColor.surface,
                      borderRadius: BorderRadius.circular(16),
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColor.error.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.filter, color: AppColor.error, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Bottom $_selectedBottomCount Products",
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(LucideIcons.chevronDown, color: AppColor.error),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: leastProducts.isEmpty
                    ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off, color: AppColor.error, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          "No Least-Selling Products Found",
                          style: TextStyle(
                            fontSize: getResponsiveFontSize(context, 16),
                            fontWeight: FontWeight.w600,
                            color: AppColor.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "No low-selling product data available.",
                          style: TextStyle(color: AppColor.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
                    : ListView.builder(
                  itemCount: leastProducts.length,
                  itemBuilder: (context, index) {
                    final product = leastProducts[index];
                    return InkWell(
                      onTap: () {
                        final productProvider = Provider.of<ProductProvider>(context, listen: false);
                        final productModel = productProvider.getProductByName( product['productName']);
                        if (productModel != null) {
                          CartModal.show(context, productModel);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColor.error.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                "#${index + 1}",
                                style: const TextStyle(
                                  color: AppColor.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['productName'],
                                    style: const TextStyle(
                                      color: AppColor.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Sold: ${product['quantitySold']}",
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

  Widget _buildFilterTile(BuildContext context, int value, String label) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: AppColor.error,
        child: Icon(LucideIcons.listFilter, color: Colors.white, size: 20),
      ),
      title: Text(label),
      onTap: () => Navigator.pop(context, value),
    );
  }
}
