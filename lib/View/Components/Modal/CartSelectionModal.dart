import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:paninda/View/Components/Custom/custom_btn.dart';
import 'package:paninda/View/Components/Modal/CartPaymentModal.dart';
import 'package:provider/provider.dart';
import 'package:paninda/Model/product_model.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View_Model/ProductProvider.dart';
import '../../../View_Model/CurrencyProvider.dart';

class CartSelectionModal {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColor.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const FractionallySizedBox(
        heightFactor: 0.85,
        child: _CartSelectionContent(),
      ),
    );
  }
}

class _CartSelectionContent extends StatefulWidget {
  const _CartSelectionContent({super.key});

  @override
  State<_CartSelectionContent> createState() => _CartSelectionContentState();
}

class _CartSelectionContentState extends State<_CartSelectionContent> {
  final Map<String, TextEditingController> kiloControllers = {};
  final Map<String, int> quantities = {};
  final Map<String, int> selectedModes = {};
  late final currencyFormat;

  @override
  void initState() {
    super.initState();
    final cartItems = context.read<ProductProvider>().getCartItems();
    currencyFormat = context.read<CurrencyProvider>().currencyFormat;
    for (var entry in cartItems.entries) {
      final product = entry.key;
      quantities[product.id] = entry.value;
      bool isKiloProduct = product.unit.toLowerCase().contains("kilo") || product.unit.toLowerCase().contains("kg");
      selectedModes[product.id] = isKiloProduct ? 1 : 0;
    }
  }

  @override
  void dispose() {
    for (var controller in kiloControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double getFinalTotal(Map<Product, int> cartItems) {
    double total = 0;
    for (var product in cartItems.keys) {
      int selectedMode = selectedModes[product.id] ?? 0;
      double quantity = selectedMode == 1
          ? double.tryParse(kiloControllers[product.id]?.text ?? '0') ?? 0
          : (quantities[product.id] ?? 1).toDouble();
      total += quantity * product.retailPrice;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final cartItems = productProvider.getCartItems();

    kiloControllers.removeWhere((key, _) => !cartItems.keys.any((p) => p.id == key));

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDragHandle(),
              const SizedBox(height: 24),
              if (cartItems.isEmpty) ...[
                const SizedBox(height: 40),
                Icon(LucideIcons.shoppingCart, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  "Your cart is empty",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey),
                ),
                const SizedBox(height: 40),
              ] else ...[
                ...cartItems.keys.map((product) => _buildProductCard(product, productProvider)).toList(),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColor.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Final Total:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        currencyFormat.format(getFinalTotal(cartItems)),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColor.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  label: "Proceed to Payment",
                  icon: LucideIcons.checkCircle2,
                  color: AppColor.textPrimary,
                  onPressed: () {
                    
                    CartPaymentDialog.show(
                      context,
                      quantities: quantities,
                      kiloQuantities: kiloControllers.map((k, v) => MapEntry(k, v.text)),
                      selectedModes: selectedModes,
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product, ProductProvider productProvider) {
    int selectedMode = selectedModes[product.id] ?? 0;
    kiloControllers.putIfAbsent(product.id, () => TextEditingController(text: '1'));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColor.primary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: product.imageUrl.isNotEmpty
                    ? Image.file(
                  File(product.imageUrl),
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 100,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined, size: 48),
                  ),
                )
                    : Container(
                  height: 100,
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_outlined, size: 48),
                ),
              ),
              Positioned(
                bottom: 6,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${currencyFormat.format(product.retailPrice)} / ${product.unit}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.trash2, color: AppColor.error),
                      onPressed: () {
                        setState(() {
                          productProvider.removeFromCart(product);
                          quantities.remove(product.id);
                          kiloControllers.remove(product.id)?.dispose();
                          selectedModes.remove(product.id);
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildChoiceChip(product.id, "Quantity", 0),
                    const SizedBox(width: 10),
                    _buildChoiceChip(product.id, "Kilo", 1),
                  ],
                ),
                const SizedBox(height: 12),
                selectedMode == 0
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline, color: AppColor.errorText),
                      onPressed: () {
                        setState(() {
                          final current = quantities[product.id] ?? 1;
                          if (current > 1) quantities[product.id] = current - 1;
                        });
                      },
                    ),
                    Text(
                      '${quantities[product.id] ?? 1}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline, color: AppColor.primary),
                      onPressed: () {
                        setState(() {
                          final current = quantities[product.id] ?? 1;
                          quantities[product.id] = current + 1;
                        });
                      },
                    ),
                  ],
                )
                    : TextField(
                  controller: kiloControllers[product.id],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: "Enter kilo quantity",
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                // Subtotal Display
                Builder(
                  builder: (context) {
                    final quantity = selectedMode == 1
                        ? double.tryParse(kiloControllers[product.id]?.text ?? '0') ?? 0
                        : (quantities[product.id] ?? 1).toDouble();
                    final subtotal = quantity * product.retailPrice;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Subtotal:",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          currencyFormat.format(subtotal),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColor.primary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String productId, String label, int mode) {
    final isSelected = selectedModes[productId] == mode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() {
            selectedModes[productId] = mode;
            if (mode == 1) kiloControllers[productId]?.text = '1';
          });
        }
      },
      selectedColor: AppColor.primary.withOpacity(0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColor.primary : Colors.grey.shade600,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 5,
        decoration: BoxDecoration(
          color: AppColor.border,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
