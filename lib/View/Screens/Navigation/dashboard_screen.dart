import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:paninda/Model/product_model.dart';
import 'package:paninda/View/Components/Core/scalable_appbar.dart';
import 'package:paninda/View/Components/HelperClass/CheckTrialExpired.dart';
import 'package:paninda/View/Components/HelperClass/responsive_text.dart';
import 'package:paninda/View_Model/AuthPaymentProvider.dart';
import 'package:paninda/View_Model/CurrencyProvider.dart';
import 'package:paninda/View_Model/LoanPersonProvider.dart';
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

  late NumberFormat currencyFormat;
  final numberFormat = NumberFormat.decimalPattern();

  DateRangeType _selectedRange = DateRangeType.day;
  Product? _selectedProduct;
  Product? _selectedLowStockProduct;
  String? accountEmail;
  String? storeName;
  String? ownerName;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
    checkIfTrialExpired(context);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    currencyFormat = context.read<CurrencyProvider>().currencyFormat;
    if (productProvider.products.isNotEmpty) {
      _selectedProduct = productProvider.products.first;
    }
    final lowStockProducts = productProvider.products.where((p) => productProvider.isStockLow(p.id, 5)).toList();
    if (lowStockProducts.isNotEmpty) {
      _selectedLowStockProduct = lowStockProducts.first;
    }

    Future.delayed(Duration.zero, () async {
      await productProvider.syncProductsWithServer();
      await productProvider.insertOrUpdateProductsToDatabase();
      await loanProvider.syncLoansWithServer();
      await loanProvider.insertOrUpdateLoansToDatabase();
    });
  }


  Future<void> _loadUserDetails() async {
    final userDetails = await Provider.of<AuthPaymentProvider>(context, listen: false).readUserDetails();
    setState(() {
      accountEmail = userDetails['email'] ?? 'Unknown';
      storeName = userDetails['storeName'] ?? 'Unknown Store';
      ownerName = userDetails['ownerName'] ?? 'Unknown Owner';
    });
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
      appBar: ScalableAppBar(),
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
              Row(
                children: [
                  const Icon(Icons.trending_up_rounded, size: 18, color: AppColor.primary),
                  SizedBox(width: 6),
                   Text("Current Profit Per Stock", style: TextStyle( fontWeight: FontWeight.w600, color: AppColor.textPrimary,fontSize: getResponsiveFontSize(context, 16))),
                ],
              ),
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
                context: context,
              ),
              const SizedBox(height: 16),
              ...profitBy.entries.toList().reversed.take(12).map((entry) =>
                  _tile(entry.key, currencyFormat.format(entry.value), LucideIcons.lineChart, AppColor.accent)),
              if (provider.products.isNotEmpty) ...[
                const SizedBox(height: 30),
                Row(
                  children: [
                    const Icon(Icons.trending_up_rounded, size: 18, color: AppColor.primary),
                    SizedBox(width: 6),
                     Text("Potential Profit Per Stock", style: TextStyle(fontSize: getResponsiveFontSize(context, 16), fontWeight: FontWeight.w600, color: AppColor.textPrimary,)),
                  ],
                ),
                const SizedBox(height: 12),
                _customDropdown<String>(
                  items: provider.products.map((p) => p.id).toList(),
                  selected: _selectedProduct?.id,
                  hint: "Select Product",
                  onChanged: (val) {
                    setState(() {
                      _selectedProduct = provider.products.firstWhere((p) => p.id == val);
                    });
                  },
                  getLabel: (productId) =>
                  provider.products.firstWhere((p) => p.id == productId).name,
                  context: context,
                ),
              const SizedBox(height: 16),
                ...batchProfit.map((batch) => _batchTile(batch)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingCard() {
    return Consumer<AuthPaymentProvider>(
      builder: (context, authPaymentProvider, child) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: authPaymentProvider.getTrialInfoOffline(),
          builder: (context, snapshot) {
            final trialInfo = snapshot.data;

            return Column(
              children: [
                FadeInDown(
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: [
                          AppColor.primary.withOpacity(0.8),
                          AppColor.primary.withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColor.primary.withOpacity(0.4),
                          blurRadius: 25,
                          spreadRadius: 4,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Store Icon Avatar with Glow
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.cyanAccent.withOpacity(0.2),
                                    Colors.transparent,
                                  ],
                                  radius: 0.8,
                                ),
                              ),
                            ),
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white.withOpacity(0.1),
                              child: Spin(
                                infinite: true,
                                duration: const Duration(seconds: 5),
                                child: Icon(
                                  LucideIcons.store,
                                  color: Colors.white,
                                  size: 30,
                                  shadows: [
                                    Shadow(
                                      color: Colors.cyanAccent.withOpacity(0.6),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 22),

                        // Greeting Texts (NO trial here)
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
                                    shaderCallback: (bounds) =>
                                        const LinearGradient(
                                          colors: [Colors.white, Colors.cyanAccent],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ).createShader(
                                          Rect.fromLTWH(
                                              0, 0, bounds.width, bounds.height),
                                        ),
                                    blendMode: BlendMode.srcIn,
                                    child: Text(
                                      "Welcome to ${storeName ?? 'Your Store'}",
                                      style: TextStyle(
                                        fontSize:
                                        getResponsiveFontSize(context, 12),
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                ownerName ?? 'Unknown Owner',
                                style: TextStyle(
                                  fontSize: getResponsiveFontSize(context, 16),
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Keep growing your business today.",
                                style: TextStyle(
                                  fontSize: getResponsiveFontSize(context, 11),
                                  color: Colors.white.withOpacity(0.75),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Glowing Animated Icon (Sparkles)
                        FadeInRight(
                          duration: const Duration(milliseconds: 800),
                          child: Spin(
                            infinite: true,
                            duration: const Duration(seconds: 4),
                            child: Icon(
                              LucideIcons.sparkles,
                              size: 26,
                              color: Colors.white70,
                              shadows: [
                                Shadow(
                                  color: Colors.cyanAccent.withOpacity(0.5),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ✅ Trial Text BELOW the card now
                if (snapshot.connectionState == ConnectionState.done &&
                    trialInfo != null &&
                    trialInfo['isTrial'] == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      "🎁 You’re enjoying a Free Trial — ${trialInfo['remainingDays']} day(s) left!\nUnlock lifetime access anytime to keep your progress safe.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: getResponsiveFontSize(context, 11),
                        color: AppColor.textSecondary,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }


  Widget _buildInventoryOverview(ProductProvider provider) {
    return _dashboardGroup(
      "Inventory Overview",
      [
        _tile("Available Products", provider.totalProductsLength.toString(), LucideIcons.box),
        _tile("Total Stock Items", numberFormat.format(provider.totalStocksQuantity), LucideIcons.truck),
        _tile("Total Stock Weight (kg)", numberFormat.format(provider.totalStocksKilos), LucideIcons.dumbbell),
        _tile("Low Stock Alerts", numberFormat.format(provider.products.where((p) => p.totalSacks < 10).length), LucideIcons.alertTriangle, AppColor.warning),
      ],
      icon: LucideIcons.boxes,
    );
  }

  Widget _buildFinancialSummary(ProductProvider provider) {
    return _dashboardGroup(
      "Financial Summary",
      [
        _tile("Total Cost Value", currencyFormat.format(provider.totalInventoryCostValue), LucideIcons.wallet),
        _tile("Total Selling Value", currencyFormat.format(provider.totalInventoryRetailValue), LucideIcons.shoppingCart),
        _tile("Total Potential Profit", currencyFormat.format(provider.allProductsTotalProfit), LucideIcons.coins, AppColor.success),
      ],
      icon: LucideIcons.wallet,
    );
  }


  Widget _buildLowStockSection(ProductProvider provider) {
    final lowStockProducts = provider.products
        .where((p) => provider.isStockLow(p.id, 10))
        .toList();
    if (lowStockProducts.isEmpty) return const SizedBox();

    // ✅ Fix here:
    if (_selectedLowStockProduct == null ||
        !lowStockProducts.any((p) => p.id == _selectedLowStockProduct!.id)) {
      _selectedLowStockProduct = lowStockProducts.first;
    } else {
      _selectedLowStockProduct = lowStockProducts.firstWhere(
              (p) => p.id == _selectedLowStockProduct!.id);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Row(
          children: [
            Icon(LucideIcons.arrowDownCircle, size: 20, color: AppColor.textPrimary),
            SizedBox(width: 8),
            Text(
              "Low Stock Alerts",
              style: TextStyle(fontSize:getResponsiveFontSize(context, 18) , fontWeight: FontWeight.w600, color: AppColor.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _customDropdown<Product>(
          items: lowStockProducts,
          selected: _selectedLowStockProduct,
          hint: "Pick a Product Below",
          onChanged: (val) => setState(() => _selectedLowStockProduct = val),
          getLabel: (product) => product.name,
          context: context,
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
          child: SlideInLeft(
            duration: const Duration(milliseconds: 500),
            child: Row(
            children: [
              if (icon != null)
                Icon(icon, color: iconColor ?? AppColor.primary, size: 23),
              if (icon != null) const SizedBox(width: 15),
              Text(
                title,
                style:  TextStyle(
                  fontSize: getResponsiveFontSize(context, 18),
                  fontWeight: FontWeight.w700,
                  color: AppColor.textPrimary,
                ),
              ),
            ],
          ),)
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
                  style:  TextStyle(fontSize: getResponsiveFontSize(context, 14), fontWeight: FontWeight.w500, color: AppColor.textPrimary),
                ),
              ),
            ),
            FadeInRight( // animated
              duration: const Duration(milliseconds: 600),
              child: Text(
                value,
                style: TextStyle(fontSize: getResponsiveFontSize(context, 14), fontWeight: FontWeight.bold, color: iconColor),
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(16),
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
                  "Batch Created: ${batch['date']}",
                  style:  TextStyle(fontWeight: FontWeight.w600, fontSize: getResponsiveFontSize(context, 12)),
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
                    "Total Items: ${numberFormat.format(batch['quantity'])}",
                    style:  TextStyle(color: AppColor.textSecondary,fontSize: getResponsiveFontSize(context, 12)),
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
                    "Total Weight: ${numberFormat.format(batch['kiloQuantity'])} kg",
                    style:  TextStyle(color: AppColor.textSecondary,fontSize: getResponsiveFontSize(context, 12)),
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
                  child: Row(
                    children: [
                      Text(
                        "Potential Profit from Items: ${currencyFormat.format(batch['profitSacks'])}",
                        style:  TextStyle(color: AppColor.success, fontWeight: FontWeight.w600,fontSize: getResponsiveFontSize(context, 12)),
                      ),
                    ],
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
                    "Potential Profit from Weight: ${currencyFormat.format(batch['profitKilos'])}",
                    style:  TextStyle(color: AppColor.accent, fontWeight: FontWeight.w600,fontSize: getResponsiveFontSize(context, 12)),
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
                  style:  TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize:  getResponsiveFontSize(context, 16),
                    color: AppColor.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
           Text(
            "Stock Details",
            style: TextStyle(
              fontWeight: FontWeight.w600,
    fontSize: getResponsiveFontSize(context, 12),
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
                        "Batch ${index + 1}",
                        style:  TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColor.textPrimary, fontSize: getResponsiveFontSize(context, 12)
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: AppColor.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            "Added: ${batch.date}",
                            style:  TextStyle(color: AppColor.textSecondary,fontSize: getResponsiveFontSize(context, 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.inventory, size: 14, color: AppColor.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            "Quantity: ${batch.quantity} | Weight: ${batch.kiloQuantity} kg",
                            style:  TextStyle(color: AppColor.textSecondary,fontSize: getResponsiveFontSize(context, 12)),
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
                children:  [
                  Icon(Icons.warning_amber_rounded, color: AppColor.errorText, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Out of Stock — Please Restock",
                      style: TextStyle(
                        color: AppColor.errorText,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                       fontSize: getResponsiveFontSize(context, 12),
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
    required BuildContext context,
    required List<T> items,
    required T? selected,
    required String hint,
    required ValueChanged<T?> onChanged,
    required String Function(T) getLabel,
  }) {
    return GestureDetector(
      onTap: () {
        if (items.isNotEmpty) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) {
              return DraggableScrollableSheet(
                initialChildSize: 0.5,
                minChildSize: 0.3,
                maxChildSize: 0.8,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColor.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          height: 4,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final isSelected = item == selected;

                              return ListTile(
                                leading: Icon(
                                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                                  color: isSelected ? AppColor.accent : Colors.grey[400],
                                ),
                                title: Text(
                                  getLabel(item),
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? AppColor.accent : AppColor.textPrimary,
                                    fontSize: getResponsiveFontSize(context, 15)
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  onChanged(item);
                                },
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
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.border.withOpacity(0.4), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selected != null ? getLabel(selected) : hint,
                style: TextStyle(
                  fontSize: getResponsiveFontSize(context, 15),
                  fontWeight: FontWeight.w500,
                  color: selected != null ? AppColor.textPrimary : AppColor.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: AppColor.textSecondary),
          ],
        ),
      ),
    );
  }




}
