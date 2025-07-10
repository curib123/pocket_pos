import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View/Components/HelperClass/responsive_text.dart';
import 'package:paninda/View_Model/ProductProvider.dart';

class TopSellingTileDropdown extends StatefulWidget {
  final ProductProvider productProvider;

  const TopSellingTileDropdown({super.key, required this.productProvider});

  @override
  State<TopSellingTileDropdown> createState() => _TopSellingTileDropdownState();
}

class _TopSellingTileDropdownState extends State<TopSellingTileDropdown> {
  Map<String, dynamic>? selectedProduct;
  int _selectedTopCount = 5;

  @override
  Widget build(BuildContext context) {
    final topProducts = widget.productProvider.getTopSellingProducts(_selectedTopCount);

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
                    color: AppColor.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.trending_up, color: AppColor.success, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ZoomIn(
                    duration: const Duration(milliseconds: 500),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topProducts.isEmpty
                              ? "No Top Products"
                              : (selectedProduct != null
                              ? selectedProduct!['productName']
                              : "Select a Top Product"),
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
                ),
                if (topProducts.isNotEmpty)
                  FadeInRight(
                    duration: const Duration(milliseconds: 600),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selectedProduct != null)
                          Text(
                            "#${topProducts.indexOf(selectedProduct!) + 1}",
                            style: TextStyle(
                              fontSize: getResponsiveFontSize(context, 14),
                              fontWeight: FontWeight.bold,
                              color: AppColor.primary,
                            ),
                          ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down, color: AppColor.primary),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showProductSelector(BuildContext context) {
    final topProducts = widget.productProvider.getTopSellingProducts(_selectedTopCount);

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
                  "Select a Top-Selling Product",
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
                            "Filter by Top Products",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          _buildFilterTile(context, 3, "Top 3"),
                          _buildFilterTile(context, 5, "Top 5"),
                          _buildFilterTile(context, 10, "Top 10"),
                          _buildFilterTile(context, 20, "Top 20"),
                          const SizedBox(height: 16),
                        ],
                      ),
                    );

                    if (selected != null) {
                      setState(() {
                        _selectedTopCount = selected;
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
                            color: AppColor.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.filter, color: AppColor.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Top $_selectedTopCount Products",
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(LucideIcons.chevronDown, color: AppColor.primary),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: topProducts.isEmpty
                    ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off, color: AppColor.primary, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          "No Top-Selling Products Found",
                          style: TextStyle(
                            fontSize: getResponsiveFontSize(context, 16),
                            fontWeight: FontWeight.w600,
                            color: AppColor.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "No sales have been recorded yet.",
                          style: TextStyle(color: AppColor.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
                    : ListView.builder(
                  itemCount: topProducts.length,
                  itemBuilder: (context, index) {
                    final product = topProducts[index];
                    return InkWell(
                      onTap: () {
                        setState(() {
                          selectedProduct = product;
                        });
                        Navigator.pop(context);
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
                                color: AppColor.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                "#${index + 1}",
                                style: const TextStyle(
                                  color: AppColor.primary,
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
        backgroundColor: AppColor.primary,
        child: Icon(LucideIcons.listFilter, color: Colors.white, size: 20),
      ),
      title: Text(label),
      onTap: () => Navigator.pop(context, value),
    );
  }
}
