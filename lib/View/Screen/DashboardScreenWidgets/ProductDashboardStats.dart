import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:pocketpos/Helper/Classes_Methods/DashboardMetrics.dart';
import 'package:pocketpos/Provider/CurrencyProvider.dart';
import 'package:pocketpos/View/Components/Widgets/ProductRangePreviewDropdown.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppColor.dart';
import 'package:pocketpos/View/Screen/DashboardScreenWidgets/GroupHeader.dart';
import 'package:pocketpos/View/Screen/DashboardScreenWidgets/StatTile.dart';
import 'package:pocketpos/View/Screen/DashboardScreenWidgets/StatGrid.dart';

String formatNumber(num number) {
  final formatter = NumberFormat.decimalPattern();
  return formatter.format(number);
}

class ProductDashboardStats extends StatelessWidget {
  final DashboardMetrics metrics;
  final CurrencyProvider currencyProvider;
  final bool isTile;

  const ProductDashboardStats({
    super.key,
    required this.metrics,
    required this.currencyProvider,
    this.isTile = true,
  });

  Widget _buildStat({
    required IconData icon,
    required String label,
    required String guide,
    required String value,
    required Color color,
  }) {
    return isTile
        ? StatTile(
      icon: icon,
      label: label,
      guide: guide,
      value: value,
      color: color,
    )
        : StatGrid(
      icon: icon,
      label: label,
      guide: guide,
      value: value,
      color: color,
    );
  }

  List<Widget> _buildStatSection(String title, IconData icon, List<Widget> stats) {
    return [
      GroupHeader(icon: icon, title: title),
      const SizedBox(height: 10),
      ...stats,
      const SizedBox(height: 24),
    ];
  }

  List<Widget> _buildStatGridSection(
      BuildContext context,
      String title,
      IconData icon,
      List<Widget> stats,
      ) {
    return [
      GroupHeader(icon: icon, title: title),
      const SizedBox(height: 10),
      LayoutBuilder(
        builder: (context, constraints) {
          final double fullWidth = constraints.maxWidth;
          final double itemMinWidth = 180;
          int crossAxisCount = (fullWidth / itemMinWidth).floor().clamp(2, 6);

          if (stats.length == 1) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: stats.first,
            );
          }

          return GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.65,
            children: stats,
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final sectionWidgets = <Widget>[];

    final summaryStats = [
      _buildStat(
        icon: LucideIcons.box,
        label: "Total Products",
        guide: "Number of main products",
        value: formatNumber(metrics.totalProducts),
        color: AppColor.primary,
      ),
      _buildStat(
        icon: LucideIcons.layers,
        label: "Products Variants",
        guide: "Different versions like size or type",
        value: formatNumber(metrics.totalVariants),
        color: AppColor.secondary,
      ),
      _buildStat(
        icon: LucideIcons.warehouse,
        label: "Stock on Hand",
        guide: "Total items in inventory",
        value: formatNumber(metrics.totalStocks),
        color: AppColor.accent,
      ),
    ];

    final salesStats = [
      _buildStat(
        icon: LucideIcons.coins,
        label: "Gross Sales",
        guide: "All revenue within time range",
        value: currencyProvider.formatAmount(metrics.currentRevenue),
        color: Colors.indigo,
      ),
      _buildStat(
        icon: LucideIcons.piggyBank,
        label: "Profit Earned",
        guide: "Revenue minus cost of sold items",
        value: currencyProvider.formatAmount(metrics.currentProfit),
        color: Colors.green,
      ),
      _buildStat(
        icon: LucideIcons.trendingUp,
        label: "Estimated Profit",
        guide: "Profit if all stock is sold",
        value: currencyProvider.formatAmount(metrics.unrealizedProfit),
        color: Colors.orange,
      ),
      _buildStat(
        icon: LucideIcons.lineChart,
        label: "Expected Sales",
        guide: "Estimated value of current stock",
        value: currencyProvider.formatAmount(metrics.possibleRevenue),
        color: Colors.purple,
      ),
    ];

    final costStats = [
      _buildStat(
        icon: LucideIcons.wallet,
        label: "Current Cost",
        guide: "Total cost of unsold items",
        value: currencyProvider.formatAmount(metrics.totalCost),
        color: Colors.redAccent,
      ),
      _buildStat(
        icon: LucideIcons.wallet2,
        label: "Cost of Sales",
        guide: "Cost of goods sold",
        value: currencyProvider.formatAmount(metrics.currentCost),
        color: Colors.deepOrange,
      ),
    ];

    final stockLevelStats = <Widget>[
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStat(
            icon: LucideIcons.arrowDownCircle,
            label: "Low Stock",
            guide: "≤ 10 in quantity",
            value: formatNumber(metrics.lowStockCount),
            color: Colors.redAccent,
          ),
          const SizedBox(height: 2),
          const ProductRangePreviewDropdown(
            minQty: 0,
            maxQty: 10,
            hint: "View low stock products",
            prefixIcon: LucideIcons.box,
          ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStat(
            icon: LucideIcons.equal,
            label: "Medium Stock",
            guide: "11 to 50 in quantity",
            value: formatNumber(metrics.mediumStockCount),
            color: Colors.amber,
          ),
          const SizedBox(height: 2),
          const ProductRangePreviewDropdown(
            minQty: 11,
            maxQty: 50,
            hint: "View medium stock products",
            prefixIcon: LucideIcons.box,
          ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStat(
            icon: LucideIcons.arrowUpCircle,
            label: "High Stock",
            guide: "More than 50 in quantity",
            value: formatNumber(metrics.highStockCount),
            color: Colors.green,
          ),
          const SizedBox(height: 2),
          const ProductRangePreviewDropdown(
            minQty: 51,
            maxQty: 999999,
            hint: "View high stock products",
            prefixIcon: LucideIcons.box,
          ),
        ],
      ),
    ];

    final activityStats = [
      _buildStat(
        icon: LucideIcons.box,
        label: "Sold (Packs)",
        guide: "Sold as full packs",
        value: formatNumber(metrics.totalSoldPerPack),
        color: AppColor.warning,
      ),
      _buildStat(
        icon: LucideIcons.layers,
        label: "Sold (Pieces)",
        guide: "Sold as individual pieces",
        value: formatNumber(metrics.totalSoldPerPiece),
        color: AppColor.secondary,
      ),
      _buildStat(
        icon: LucideIcons.plusCircle,
        label: "Stock Added",
        guide: "New stock or restocks added",
        value: formatNumber(metrics.totalAddedItems),
        color: Colors.greenAccent,
      ),
      _buildStat(
        icon: LucideIcons.trash2,
        label: "Expired Items",
        guide: "Items removed due to expiry",
        value: formatNumber(metrics.totalExpiredItems),
        color: Colors.grey,
      ),
      _buildStat(
        icon: LucideIcons.alertTriangle,
        label: "Damaged Items",
        guide: "Lost due to damage",
        value: formatNumber(metrics.totalDamageItems),
        color: Colors.redAccent,
      ),
      _buildStat(
        icon: LucideIcons.heartHandshake,
        label: "Given Away",
        guide: "Items donated or free",
        value: formatNumber(metrics.totalDonatedItems),
        color: Colors.pinkAccent,
      ),
      _buildStat(
        icon: LucideIcons.loader,
        label: "Loaned Out",
        guide: "Items currently on loan",
        value: formatNumber(metrics.totalLoanItems),
        color: Colors.blueGrey,
      ),
      _buildStat(
        icon: LucideIcons.flame,
        label: "Used Internally",
        guide: "Used in-store or for ops",
        value: formatNumber(metrics.totalConsumedItems),
        color: Colors.orangeAccent,
      ),
    ];

    sectionWidgets.addAll(
      isTile
          ? _buildStatSection("Product Summary", LucideIcons.boxes, summaryStats)
          : _buildStatGridSection(context, "Product Summary", LucideIcons.boxes, summaryStats),
    );
    sectionWidgets.addAll(
      isTile
          ? _buildStatSection("Sales & Revenue", LucideIcons.coins, salesStats)
          : _buildStatGridSection(context, "Sales & Revenue", LucideIcons.coins, salesStats),
    );
    sectionWidgets.addAll(
      isTile
          ? _buildStatSection("Expenses & Costs", LucideIcons.fileText, costStats)
          : _buildStatGridSection(context, "Expenses & Costs", LucideIcons.fileText, costStats),
    );
    sectionWidgets.addAll(
      isTile
          ? _buildStatSection("Stock Levels", LucideIcons.thermometer, stockLevelStats)
          : _buildStatGridSection(context, "Stock Levels", LucideIcons.thermometer, stockLevelStats),
    );
    sectionWidgets.addAll(
      isTile
          ? _buildStatSection("Stock Activity", LucideIcons.repeat, activityStats)
          : _buildStatGridSection(context, "Stock Activity", LucideIcons.repeat, activityStats),
    );

    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sectionWidgets,
        ),
      ),
    );
  }
}
