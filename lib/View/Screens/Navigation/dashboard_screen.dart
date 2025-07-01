import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:paninda/Model/product_model.dart';
import 'package:paninda/View/Components/HelperClass/responsive_text.dart';
import 'package:paninda/View_Model/ProductProvider.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'fil_PH', symbol: '₱ ', decimalDigits: 2);
  final numberFormat = NumberFormat.decimalPattern();

  DateRangeType _selectedRange = DateRangeType.day;
  Product? _selectedProduct;

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 18) return "Good Afternoon";
    if (hour < 19) return "Good Evening";
    return "Good Night";
  }

  IconData getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return LucideIcons.sun;
    if (hour < 18) return LucideIcons.sunMedium;
    if (hour < 19) return LucideIcons.cloudSun;
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

    if (_selectedProduct == null && provider.products.isNotEmpty) {
      _selectedProduct = provider.products.first;
    }

    final batchProfit = _selectedProduct != null ? getProfitPerBatch(_selectedProduct!) : [];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColor.primary.withOpacity(0.15),
                      child: Icon(getGreetingIcon(), color: AppColor.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getGreeting(),
                          style:  TextStyle(
                            fontSize: getResponsiveFontSize(context, 30),
                            fontWeight: FontWeight.w800,
                            color: AppColor.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                         Text(
                          "Welcome back to Paninda",
                          style: TextStyle(
                            fontSize: getResponsiveFontSize(context, 14),
                            color: AppColor.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              _dashboardGroup("🧺 Inventory Overview", [
                _tile("Total Products", provider.totalProductsLength.toString(), LucideIcons.box),
                _tile("Total Stocks", numberFormat.format(provider.totalStocksQuantity), LucideIcons.truck),
                _tile("Total Kilos", numberFormat.format(provider.totalStocksKilos), LucideIcons.dumbbell),
                _tile("Low Stock Product", numberFormat.format(provider.products.where((p) => p.totalSacks < 5).length),
                    LucideIcons.alertTriangle, AppColor.warning),
              ]),

              _dashboardGroup("💰 Financial Summary", [
                _tile("Cost Value", currencyFormat.format(provider.totalInventoryCostValue), LucideIcons.wallet),
                _tile("Retail Value", currencyFormat.format(provider.totalInventoryRetailValue), LucideIcons.shoppingCart),
                _tile("Potential Profit", currencyFormat.format(provider.allProductsTotalProfit), LucideIcons.coins, AppColor.success),
              ]),

              _dashboardGroup("📈 Growth Trends", [
                _tile("Product Growth", "${provider.productCountChangePercent.toStringAsFixed(1)}%", LucideIcons.trendingUp),
                _tile("Stock Growth", "${provider.quantityChangePercent.toStringAsFixed(1)}%", LucideIcons.barChart3),
              ]),

              const SizedBox(height: 30),
              const Text("📊Realized Profit by Range", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColor.textPrimary)),
              const SizedBox(height: 12),
              _dateRangeDropdown(),
              const SizedBox(height: 16),
              ...profitBy.entries.toList().reversed.take(12).map((entry) =>
                  _tile(entry.key, currencyFormat.format(entry.value), LucideIcons.lineChart, AppColor.accent)),


              if (_selectedProduct != null && provider.products.isNotEmpty) ...[
                const SizedBox(height: 30),
                const Text("📦 Profit Per Stocks", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColor.textPrimary)),
                const SizedBox(height: 12),
                _productDropdown(provider.products),
                const SizedBox(height: 16),
                ...batchProfit.map((batch) => _batchTile(batch)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _dashboardGroup(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColor.textPrimary),
          ),
        ),
        Column(children: tiles),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _tile(String title, String value, IconData icon, [Color? color]) {
    final Color iconColor = color ?? AppColor.primary;

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColor.textPrimary)),
            ),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: iconColor),
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
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Date: ${batch['date']}", style: const TextStyle(fontWeight: FontWeight.w600, color: AppColor.textPrimary)),
            const SizedBox(height: 8),
            Text("All Stocks: ${numberFormat.format(batch['quantity'])}", style: const TextStyle(color: AppColor.textSecondary)),
            const SizedBox(height: 4),
            Text("All Kilos: ${numberFormat.format(batch['kiloQuantity'])}", style: const TextStyle(color: AppColor.textSecondary)),
            const SizedBox(height: 8),
            Text("Possible Profit (Qty): ${currencyFormat.format(batch['profitSacks'])}", style: const TextStyle(color: AppColor.success)),
            const SizedBox(height: 4),
            Text("Possible Profit (Kilos): ${currencyFormat.format(batch['profitKilos'])}", style: const TextStyle(color: AppColor.accent)),
          ],
        ),
      ),
    );
  }

  Widget _dateRangeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.04), blurRadius: 6)],
      ),
      child: DropdownButton<DateRangeType>(
        value: _selectedRange,
        isExpanded: true,
        underline: const SizedBox(),
        style: const TextStyle(fontSize: 16, color: AppColor.textPrimary),
        borderRadius: BorderRadius.circular(10),
        onChanged: (val) => setState(() => _selectedRange = val!),
        items: DateRangeType.values.map((range) {
          final label = {
            DateRangeType.day: 'Day',
            DateRangeType.week: 'Week',
            DateRangeType.month: 'Month',
            DateRangeType.year: 'Year',
          }[range];
          return DropdownMenuItem(value: range, child: Text(label!));
        }).toList(),
      ),
    );
  }

  Widget _productDropdown(List<Product> products) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.04), blurRadius: 6)],
      ),
      child: DropdownButton<Product>(
        value: _selectedProduct,
        isExpanded: true,
        underline: const SizedBox(),
        style: const TextStyle(fontSize: 16, color: AppColor.textPrimary),
        borderRadius: BorderRadius.circular(10),
        onChanged: (val) => setState(() => _selectedProduct = val),
        items: products.map((product) {
          return DropdownMenuItem(
            value: product,
            child: Text(product.name, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
      ),
    );
  }
}
