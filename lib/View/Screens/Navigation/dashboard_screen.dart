import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:paninda/Model/product_model.dart';
import 'package:paninda/View/Components/Core/product_metrics_container.dart';
import 'package:paninda/View/Components/Core/scalable_appbar.dart';
import 'package:paninda/View/Components/HelperClass/CheckTrialExpired.dart';
import 'package:paninda/View/Components/HelperClass/ProfitHelper.dart';
import 'package:paninda/View/Components/HelperClass/ReceiptHelper.dart';
import 'package:paninda/View/Components/HelperClass/responsive_text.dart';
import 'package:paninda/View/Screens/Navigation/DashboardWidget/CurrentProfitSummary.dart';
import 'package:paninda/View/Screens/Navigation/DashboardWidget/GreetingsCardWidget.dart';
import 'package:paninda/View/Screens/Navigation/DashboardWidget/LeastSellingProductDropdown.dart';
import 'package:paninda/View/Screens/Navigation/DashboardWidget/LowStockProduct.dart';
import 'package:paninda/View/Screens/Navigation/DashboardWidget/ProductProfitDropdown.dart';
import 'package:paninda/View/Screens/Navigation/DashboardWidget/TopSellingDropdown.dart';
import 'package:paninda/View/Screens/Navigation/ReceiptHistoryScreen.dart';
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

    ReceiptHelper receiptHelper = ReceiptHelper();
    Future.delayed(Duration.zero, () async {
      await productProvider.syncProductsWithServer();
      await productProvider.insertOrUpdateProductsAndProfitsToDatabase();
      await loanProvider.syncLoansWithServer();
      await loanProvider.insertOrUpdateLoansToDatabase();
      await ProfitHelper.syncTwoWay();
      await receiptHelper.syncReceipts();
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

    return Stack(
      children:[
        Scaffold(
        appBar: ScalableAppBar(),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildGreetingCard(ownerName.toString(),storeName.toString()),
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
                              const SizedBox(width: 40),
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
      ),
        Positioned(
          bottom: 10,
          right: 15,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            elevation: 6,
            child: InkWell(
              onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceiptHistoryScreen()));
              },
              customBorder: const CircleBorder(),
              splashColor: Colors.white24,
              highlightColor: Colors.white10,
              child: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: AppColor.primary,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.receipt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        )
        ,
      ],
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
