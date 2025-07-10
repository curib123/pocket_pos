import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:paninda/Model/product_model.dart';
import 'package:paninda/View/Components/Core/product_metrics_container.dart';
import 'package:paninda/View/Components/Core/scalable_appbar.dart';
import 'package:paninda/View/Components/HelperClass/CheckTrialExpired.dart';
import 'package:paninda/View/Components/HelperClass/ProfitHelper.dart';
import 'package:paninda/View/Components/HelperClass/responsive_text.dart';
import 'package:paninda/View/Screens/Navigation/DashboardWidget/CurrentProfitSummary.dart';
import 'package:paninda/View/Screens/Navigation/DashboardWidget/LeastSellingProductDropdown.dart';
import 'package:paninda/View/Screens/Navigation/DashboardWidget/LowStockProduct.dart';
import 'package:paninda/View/Screens/Navigation/DashboardWidget/ProductProfitDropdown.dart';
import 'package:paninda/View/Screens/Navigation/DashboardWidget/TopSellingDropdown.dart';
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
  final dateFormat = DateFormat('MMM d, yyyy');

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
    final lowStockProducts =
    productProvider.products.where((p) => productProvider.isStockLow(p.id, 5)).toList();
    if (lowStockProducts.isNotEmpty) {
      _selectedLowStockProduct = lowStockProducts.first;
    }

    Future.delayed(Duration.zero, () async {
      await productProvider.syncProductsWithServer();
      await productProvider.insertOrUpdateProductsAndProfitsToDatabase();
      await loanProvider.syncLoansWithServer();
      await loanProvider.insertOrUpdateLoansToDatabase();
      await ProfitHelper.syncTwoWay();
    });
  }

  Future<void> _loadUserDetails() async {
    final userDetails =
    await Provider.of<AuthPaymentProvider>(context, listen: false).readUserDetails();
    setState(() {
      accountEmail = userDetails['email'] ?? 'Unknown';
      storeName = userDetails['storeName'] ?? 'Unknown Store';
      ownerName = userDetails['ownerName'] ?? 'Unknown Owner';
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);

    return Scaffold(
      appBar: ScalableAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreetingCard(),
              Consumer<ProductProvider>(
                builder: (context, provider, _) {
                  final totalProducts = provider.totalProductsLength;
                  final stockInHand = provider.totalStocksQuantity.toStringAsFixed(2);
                  final productChange = provider.productCountChangePercent.toStringAsFixed(1);
                  final stockChange = provider.quantityChangePercent.toStringAsFixed(1);

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: FadeIn(
                        duration: const Duration(milliseconds: 600),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ProductMetricsContainer(
                              heading: "Total Products",
                              value: "$totalProducts",
                              percentage: "${productChange.startsWith('-') ? '' : '+'}$productChange%",
                            ),
                            const SizedBox(width: 12),
                            ProductMetricsContainer(
                              heading: "Stock in Hand",
                              value: "$stockInHand",
                              percentage: "${stockChange.startsWith('-') ? '' : '+'}$stockChange%",
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _buildInventoryOverview(provider),
              _buildFinancialSummary(provider),
              _buildMetricSummary(provider),
              _buildProfitSummary(provider),
              const SizedBox(height: 20),
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
                    padding: const EdgeInsets.symmetric(vertical: 10),
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
                                    ).createShader(
                                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                                    ),
                                    blendMode: BlendMode.srcIn,
                                    child: Text(
                                      "Welcome to ${storeName ?? 'Your Store'}",
                                      style: TextStyle(
                                        fontSize: getResponsiveFontSize(context, 12),
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
        _tile("Total Stock Quantity", numberFormat.format(provider.totalStocksQuantity), LucideIcons.truck),
        _tile("Total Stock Weight (kg)", numberFormat.format(provider.totalStocksKilos), LucideIcons.dumbbell),
        _tile("Low Stock Products", numberFormat.format(provider.products.where((p) => p.totalSacks < 10).length), LucideIcons.alertTriangle, AppColor.warning),
      ],
      icon: LucideIcons.boxes,
    );
  }

  Widget _buildFinancialSummary(ProductProvider provider) {
    return _dashboardGroup(
      "Financial Summary",
      [
        _tile("Inventory Cost Value", currencyFormat.format(provider.totalInventoryCostValue), LucideIcons.wallet),
        _tile("Potential Sales Value", currencyFormat.format(provider.totalInventoryRetailValue), LucideIcons.shoppingCart),
        _tile("Estimated Total Profit", currencyFormat.format(provider.allProductsTotalProfit), LucideIcons.coins, AppColor.success),
      ],
      icon: LucideIcons.wallet,
    );
  }

  Widget _buildMetricSummary(ProductProvider provider) {
    return _dashboardGroup(
      "Sales & Inventory Metrics",
      [
        TopSellingTileDropdown(productProvider: provider),
        LeastSellingTileDropdown(productProvider: provider),
        LowStockProductDropdown<Product>(
          items: provider.products.where((p) => provider.isStockLow(p.id, 10)).toList(),
          selected: _selectedLowStockProduct,
          onChanged: (val) => setState(() => _selectedLowStockProduct = val),
          getLabel: (product) => product.name,
        ),
        const SizedBox(height: 16),
      ],
      icon: LucideIcons.barChart,
    );
  }

  Widget _buildProfitSummary(ProductProvider provider) {
    return _dashboardGroup(
      "Profits & Trends Summary",
      [
        ProductProfitDropdown(
          items: provider.products.map((p) => p.id).toList(),
          selected: _selectedProduct?.id,
          onChanged: (val) {
            setState(() {
              _selectedProduct = provider.getProductById(val!);
            });
          },
          getLabel: (productId) => provider.getProductById(productId)?.name ?? '',
          provider: provider,
        ),
        CurrentProfitSummary(
          provider: Provider.of<ProductProvider>(context, listen: false),
        ),

      ],
      icon: LucideIcons.barChart,
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
                if (icon != null) Icon(icon, color: iconColor ?? AppColor.primary, size: 23),
                if (icon != null) const SizedBox(width: 15),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: getResponsiveFontSize(context, 18),
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: tiles),
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
              child: Spin(
                infinite: true,
                duration: const Duration(seconds: 5),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ZoomIn(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: getResponsiveFontSize(context, 14),
                    fontWeight: FontWeight.w500,
                    color: AppColor.textPrimary,
                  ),
                ),
              ),
            ),
            FadeInRight(
              duration: const Duration(milliseconds: 600),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: getResponsiveFontSize(context, 14),
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
