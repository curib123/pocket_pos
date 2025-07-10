import 'package:flutter/material.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View/Components/HelperClass/responsive_text.dart';
import 'package:paninda/View/Components/Modal/cart_modal.dart';
import 'package:paninda/View_Model/ProductProvider.dart';
import 'package:provider/provider.dart';

class LowStockProductDropdown<T> extends StatefulWidget {
  final List<T> items;
  final T? selected;
  final ValueChanged<T?> onChanged;
  final String Function(T) getLabel;

  const LowStockProductDropdown({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
    required this.getLabel,
  });

  @override
  State<LowStockProductDropdown<T>> createState() => _LowStockProductDropdownState<T>();
}

class _LowStockProductDropdownState<T> extends State<LowStockProductDropdown<T>> {
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
                color: AppColor.warning.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inventory, color: AppColor.warning, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                widget.selected != null
                    ? widget.getLabel(widget.selected!)
                    : "Select Low Stock Product",
                style: TextStyle(
                  fontSize: getResponsiveFontSize(context, 14),
                  fontWeight: FontWeight.w500,
                  color: AppColor.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.items.isNotEmpty)
              const Icon(Icons.keyboard_arrow_down, color: AppColor.warning),
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
        final filteredItems = widget.items
            .where((item) => widget
            .getLabel(item)
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
            .toList();

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      "Select a Low Stock Product",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColor.textPrimary,
                        fontSize: getResponsiveFontSize(context, 16),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search product...",
                        prefixIcon: const Icon(Icons.search, color: AppColor.warning),
                        filled: true,
                        fillColor: Colors.white54,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none, // No border line
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          _searchQuery = value;
                        });
                      },
                    ),

                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: filteredItems.isEmpty
                        ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off,
                                color: AppColor.warning, size: 48),
                            const SizedBox(height: 16),
                            const Text(
                              "No Matching Products",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColor.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Try adjusting your search.",
                              style: TextStyle(color: AppColor.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                        : ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final product = filteredItems[index];
                        return InkWell(
                          onTap: () {
                            widget.onChanged(product);
                            final productProvider = Provider.of<ProductProvider>(context, listen: false);
                            final selectedProduct = productProvider.getProductByName(widget.getLabel(product).toString());
                            if (selectedProduct != null) {
                              CartModal.show(context, selectedProduct);
                            }
                          },

                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColor.warning.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.inventory, color: AppColor.warning, size: 18),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    widget.getLabel(product),
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColor.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: AppColor.warning),
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
      },
    );
  }
}
