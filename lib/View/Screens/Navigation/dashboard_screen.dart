import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:paninda/Model/product_model.dart';
import 'package:paninda/View/Components/Core/scalable_appbar.dart';
import 'package:paninda/View/Components/HelperClass/responsive_text.dart';
import 'package:paninda/View/Components/Modal/showProductSelectorModal.dart';
import 'package:paninda/View_Model/ProductProvider.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;
  const DashboardScreen({super.key, this.userName = "John Doe"});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'fil_PH', symbol: '₱ ', decimalDigits: 2);
  final numberFormat = NumberFormat.decimalPattern();

  DateRangeType _selectedRange = DateRangeType.day;
  Product? _selectedProduct;
  Product? _selectedLowStockProduct;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ProductProvider>(context, listen: false);
    if (provider.products.isNotEmpty) {
      _selectedProduct = provider.products.first;
    }
    final lowStockProducts = provider.products.where((p) => provider.isStockLow(p.id, 5)).toList();
    if (lowStockProducts.isNotEmpty) {
      _selectedLowStockProduct = lowStockProducts.first;
    }
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return "Good Morning";
    if (hour >= 12 && hour < 17) return "Good Afternoon";
    if (hour >= 17 && hour < 20) return "Good Evening";
    return "Good Night";
  }

  IconData getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return LucideIcons.sun;
    if (hour >= 12 && hour < 17) return LucideIcons.sunMedium;
    if (hour >= 17 && hour < 20) return LucideIcons.cloudSun;
    return LucideIcons.moon;
  }

  List<Map<String, dynamic>> getProfitPerBatch(Product product) {
    return product.batches.map((b) {
      final sackProfit = b.quantity * (product.retailPrice - product.costPrice);
      final kiloProfit = b.kiloQuantity * (product.retailPrice - product.costPrice);
      return {
        'date': b.date,
        'quantity': b.quantity,
        'kiloQuantity': b.kiloQuantity,
        'profitSacks': sackProfit,
        'profitKilos': kiloProfit,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);
    final profitBy = provider.getCheckoutProfitBy(_selectedRange);
    final batchProfit = _selectedProduct != null ? getProfitPerBatch(_selectedProduct!) : [];

    return Scaffold(
      appBar: ScalableAppBar(
        isTitle: false,
        showSearchBar: true,
        title: "Dashboard",
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreetingCard(),
              const SizedBox(height: 30),
              _buildInventoryOverview(provider),
              _buildFinancialSummary(provider),
              _buildLowStockSection(provider),
              const SizedBox(height: 30),
              const Text("Realized Profit by Date", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColor.textPrimary)),
              const SizedBox(height: 12),
              _customDropdown<DateRangeType>(
                items: DateRangeType.values,
                selected: _selectedRange,
                hint: "Select Range",
                onChanged: (val) => setState(() => _selectedRange = val!),
                getLabel: (range) => {
                  DateRangeType.day: 'Day',
                  DateRangeType.week: 'Week',
                  DateRangeType.month: 'Month',
                  DateRangeType.year: 'Year',
                }[range]!,
              ),
              const SizedBox(height: 16),
              ...profitBy.entries.toList().reversed.take(12).map((entry) =>
                  _tile(entry.key, currencyFormat.format(entry.value), LucideIcons.lineChart, AppColor.accent)),
              if (provider.products.isNotEmpty) ...[
                const SizedBox(height: 30),
                const Text("Possible Profit Per Stocks", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColor.textPrimary)),
                const SizedBox(height: 12),
                _customDropdown<Product>(
                  items: provider.products,
                  selected: _selectedProduct,
                  hint: "Select Product",
                  onChanged: (val) => setState(() => _selectedProduct = val),
                  getLabel: (product) => product.name,
                ),
                const SizedBox(height: 16),
                ...batchProfit.map((batch) => _batchTile(batch)),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text("Open Product Selector"),
          onPressed: () {
            final productProvider = Provider.of<ProductProvider>(context, listen: false);
           showProductCalculatorModal(context, productProvider.products);
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingCard() {
    return FadeInDown(
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [AppColor.primary.withOpacity(0.7), AppColor.primary.withOpacity(0.5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(color: AppColor.primary.withOpacity(0.3), blurRadius: 20, spreadRadius: 3, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Colors.cyanAccent.withOpacity(0.2), Colors.transparent],
                      radius: 0.9,
                    ),
                  ),
                ),
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  child: Spin(
                    infinite: true,
                    duration: const Duration(seconds: 4),
                    child: Icon(getGreetingIcon(), color: Colors.white, size: 26),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            // Greeting text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOut,
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.white, Colors.cyanAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                        blendMode: BlendMode.srcIn,
                        child: Text(
                          getGreeting(),
                          style: TextStyle(
                            fontSize: getResponsiveFontSize(context, 18),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.userName,
                    style: TextStyle(
                      fontSize: getResponsiveFontSize(context, 15),
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Let's make today productive.",
                    style: TextStyle(
                      fontSize: getResponsiveFontSize(context, 10),
                      color: Colors.white.withOpacity(0.75),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Animated Icon
            FadeInRight(
              duration: const Duration(milliseconds: 800),
              child: Spin(
                infinite: true,
                duration: const Duration(seconds: 3),
                child: Icon(LucideIcons.zap, size: 22, color: Colors.white70, shadows: [
                  Shadow(color: Colors.cyanAccent.withOpacity(0.5), blurRadius: 10),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryOverview(ProductProvider provider) {
    return _dashboardGroup(
      "Inventory Overview",
      [
        _tile("Total Products", provider.totalProductsLength.toString(), LucideIcons.box),
        _tile("Total Stocks", numberFormat.format(provider.totalStocksQuantity), LucideIcons.truck),
        _tile("Total Kilos", numberFormat.format(provider.totalStocksKilos), LucideIcons.dumbbell),
        _tile("Low Stock Product", numberFormat.format(provider.products.where((p) => p.totalSacks < 10).length), LucideIcons.alertTriangle, AppColor.warning),
      ],
      icon: LucideIcons.boxes,
    );
  }

  Widget _buildFinancialSummary(ProductProvider provider) {
    return _dashboardGroup(
      "Financial Summary",
      [
        _tile("Cost Value", currencyFormat.format(provider.totalInventoryCostValue), LucideIcons.wallet),
        _tile("Retail Value", currencyFormat.format(provider.totalInventoryRetailValue), LucideIcons.shoppingCart),
        _tile("Potential Profit", currencyFormat.format(provider.allProductsTotalProfit), LucideIcons.coins, AppColor.success),
      ],
      icon: LucideIcons.wallet,
    );
  }

  Widget _buildLowStockSection(ProductProvider provider) {
    final lowStockProducts = provider.products.where((p) => provider.isStockLow(p.id, 10)).toList();
    if (lowStockProducts.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Icon(LucideIcons.arrowDownCircle, size: 20, color: AppColor.textPrimary),
              SizedBox(width: 8),
              Text(
                "Low Stock Products",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _customDropdown<Product>(
          items: lowStockProducts,
          selected: _selectedLowStockProduct,
          hint: "Select Low Stock Product",
          onChanged: (val) => setState(() => _selectedLowStockProduct = val),
          getLabel: (product) => product.name,
        ),
        const SizedBox(height: 16),
        if (_selectedLowStockProduct != null) _lowStockTile(_selectedLowStockProduct!),
      ],
    );
  }

  Widget _dashboardGroup(String title, List<Widget> tiles, {IconData? icon, Color? iconColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              if (icon != null)
                Icon(icon, color: iconColor ?? AppColor.primary, size: 22),
              if (icon != null) const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: tiles,
        ),
        const Divider(height: 32),
      ],
    );
  }

  Widget _tile(String title, String value, IconData icon, [Color? color]) {
    final Color iconColor = color ?? AppColor.primary;

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
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
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Spin( // animated
                infinite: true,
                duration: const Duration(seconds: 5),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ZoomIn( // animated
                duration: const Duration(milliseconds: 500),
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColor.textPrimary),
                ),
              ),
            ),
            FadeInRight( // animated
              duration: const Duration(milliseconds: 600),
              child: Text(
                value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: iconColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _batchTile(Map<String, dynamic> batch) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: AppColor.textSecondary),
                const SizedBox(width: 8),
                Text(
                  batch['date'].toString(),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.inventory, size: 16, color: AppColor.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "All Stocks: ${numberFormat.format(batch['quantity'])}",
                    style: const TextStyle(color: AppColor.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.scale, size: 16, color: AppColor.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "All Kilos: ${numberFormat.format(batch['kiloQuantity'])}",
                    style: const TextStyle(color: AppColor.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.monetization_on, size: 16, color: AppColor.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Qty Profit: ${currencyFormat.format(batch['profitSacks'])}",
                    style: const TextStyle(color: AppColor.success, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.monetization_on_outlined, size: 16, color: AppColor.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Kilo Profit: ${currencyFormat.format(batch['profitKilos'])}",
                    style: const TextStyle(color: AppColor.accent, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _lowStockTile(Product product) {
    final hasBatches = product.batches.isNotEmpty;

    return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_bag, color: AppColor.textSecondary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColor.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Stock Batches:",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColor.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          if (hasBatches)
            ...product.batches.asMap().entries.map((entry) {
              final index = entry.key;
              final batch = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColor.surface.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColor.border, width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Batch #${index + 1}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColor.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: AppColor.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            batch.date.toString(),
                            style: const TextStyle(color: AppColor.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.inventory, size: 14, color: AppColor.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            "Qty: ${batch.quantity} | ⚖️ ${batch.kiloQuantity} kg",
                            style: const TextStyle(color: AppColor.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            })
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColor.surface.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColor.errorText.withOpacity(0.5)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: AppColor.errorText, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "No Stock available. Restock now!",
                      style: TextStyle(
                        color: AppColor.errorText,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _customDropdown<T>({
    required List<T> items,
    required T? selected,
    required String hint,
    required ValueChanged<T?> onChanged,
    required String Function(T) getLabel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: selected,
          isExpanded: true,
          icon: const Icon(Icons.expand_more, color: AppColor.textSecondary),
          dropdownColor: AppColor.surface,
          borderRadius: BorderRadius.circular(12),
          hint: Text(hint, style: const TextStyle(color: AppColor.textSecondary)),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColor.textPrimary),
          onChanged: items.isEmpty ? null : onChanged,
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(getLabel(item), overflow: TextOverflow.ellipsis))).toList(),
        ),
      ),
    );
  }
}
