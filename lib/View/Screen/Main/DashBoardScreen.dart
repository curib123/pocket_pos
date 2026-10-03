import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nextpos/Helper/Classes_Methods/AppColor.dart';
import 'package:nextpos/Model/stock_log.dart';
import 'package:nextpos/Provider/LogProvider.dart';
import 'package:nextpos/Provider/ProductProvider.dart';
import 'package:nextpos/View/Components/Widgets/AppDrawer.dart';
import 'package:nextpos/View/Components/Widgets/SearchAndCartRow.dart';
import 'package:nextpos/View/Screen/Main/StockManagementScreen.dart';
import 'package:nextpos/View/Screen/Sub/StockLogsHistoryScreen.dart';
import 'package:provider/provider.dart';

class DashBoardScreen extends StatelessWidget {
  const DashBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().getAllProductsWithVariants();
    final logProvider = context.watch<LogProvider>();
    final totalStock = products.fold<int>(0, (sum, product) => sum + product.totalQuantity);
    final outOfStock = products.where((product) => product.totalQuantity == 0).length;
    final lowStock = products
        .where((product) => product.totalQuantity > 0 && product.totalQuantity <= 5)
        .length;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayLogs = logProvider.getLogs(
      dateRange: DateTimeRange(
        start: today,
        end: now.add(const Duration(seconds: 1)),
      ),
    );

    final stockInToday = todayLogs
        .where((log) => log.reason == StockLogReason.stockIn)
        .fold<int>(0, (sum, log) => sum + log.quantity);
    final stockOutToday = todayLogs
        .where((log) => log.reason == StockLogReason.stockOut)
        .fold<int>(0, (sum, log) => sum + log.quantity);
    final adjustmentToday = todayLogs
        .where((log) => log.reason == StockLogReason.stockAdjustment)
        .fold<int>(0, (sum, log) => sum + log.quantity);

    final recent = logProvider
        .getLogs()
        .where((log) =>
            log.reason == StockLogReason.stockIn ||
            log.reason == StockLogReason.stockOut ||
            log.reason == StockLogReason.stockAdjustment)
        .take(5)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      drawer: const AppDrawer(),
      appBar: const SearchAndCartAppBar(),
      body: RefreshIndicator(
        onRefresh: () async => context.read<ProductProvider>().notifyListeners(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            const Text(
              'Sari-sari inventory',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Simple stock tracking. No checkout flow—just Stock In, Stock Out, and physical-count adjustments.',
              style: TextStyle(color: Colors.black54, height: 1.35),
            ),
            const SizedBox(height: 18),
            _summaryGrid(
              totalProducts: products.length,
              totalStock: totalStock,
              lowStock: lowStock,
              outOfStock: outOfStock,
            ),
            const SizedBox(height: 20),
            const Text(
              'Today',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _movementSummary(
                    icon: LucideIcons.packagePlus,
                    label: 'Stock In',
                    value: stockInToday,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _movementSummary(
                    icon: LucideIcons.packageMinus,
                    label: 'Stock Out',
                    value: stockOutToday,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _movementSummary(
                    icon: LucideIcons.slidersHorizontal,
                    label: 'Adjust',
                    value: adjustmentToday,
                    signed: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Quick actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            _quickAction(
              context,
              mode: StockMovementMode.stockIn,
              icon: LucideIcons.packagePlus,
              title: 'Stock In',
              subtitle: 'Record deliveries and restocks',
            ),
            const SizedBox(height: 8),
            _quickAction(
              context,
              mode: StockMovementMode.stockOut,
              icon: LucideIcons.packageMinus,
              title: 'Stock Out',
              subtitle: 'Record sold, damaged, expired, or used stock',
            ),
            const SizedBox(height: 8),
            _quickAction(
              context,
              mode: StockMovementMode.adjustment,
              icon: LucideIcons.slidersHorizontal,
              title: 'Adjustment',
              subtitle: 'Reconcile system stock with your physical count',
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Recent movements',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StockLogsHistoryScreen(),
                    ),
                  ),
                  child: const Text('View all'),
                ),
              ],
            ),
            if (recent.isEmpty)
              _emptyMovements()
            else
              ...recent.map((log) => _movementTile(context, log)),
          ],
        ),
      ),
    );
  }

  Widget _summaryGrid({
    required int totalProducts,
    required int totalStock,
    required int lowStock,
    required int outOfStock,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        _summaryCard('Products', totalProducts.toString(), LucideIcons.boxes),
        _summaryCard('Stock on hand', totalStock.toString(), LucideIcons.warehouse),
        _summaryCard('Low stock', lowStock.toString(), LucideIcons.alertTriangle),
        _summaryCard('Out of stock', outOfStock.toString(), LucideIcons.xCircle),
      ],
    );
  }

  Widget _summaryCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColor.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _movementSummary({
    required IconData icon,
    required String label,
    required int value,
    bool signed = false,
  }) {
    final shown = signed && value > 0 ? '+' + value.toString() : value.toString();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColor.primary, size: 20),
          const SizedBox(height: 6),
          Text(shown, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _quickAction(
    BuildContext context, {
    required StockMovementMode mode,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: CircleAvatar(
          backgroundColor: AppColor.primary.withOpacity(0.1),
          child: Icon(icon, color: AppColor.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StockManagementScreen(initialMode: mode),
          ),
        ),
      ),
    );
  }

  Widget _movementTile(BuildContext context, StockLog log) {
    final product = context.read<ProductProvider>().getProductById(log.productId);
    final isAdjustment = log.reason == StockLogReason.stockAdjustment;
    final signedQuantity = isAdjustment
        ? (log.quantity > 0 ? '+' + log.quantity.toString() : log.quantity.toString())
        : (log.reason == StockLogReason.stockOut ? '-' : '+') + log.quantity.toString();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(_movementIcon(log.reason), color: AppColor.primary),
        title: Text(product?.name ?? 'Deleted product'),
        subtitle: Text(_movementLabel(log.reason)),
        trailing: Text(
          signedQuantity,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _emptyMovements() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'No inventory movements yet.',
        style: TextStyle(color: Colors.black54),
      ),
    );
  }

  String _movementLabel(StockLogReason reason) {
    switch (reason) {
      case StockLogReason.stockIn:
        return 'Stock In';
      case StockLogReason.stockOut:
        return 'Stock Out';
      case StockLogReason.stockAdjustment:
        return 'Adjustment';
      default:
        return 'Inventory movement';
    }
  }

  IconData _movementIcon(StockLogReason reason) {
    switch (reason) {
      case StockLogReason.stockIn:
        return LucideIcons.packagePlus;
      case StockLogReason.stockOut:
        return LucideIcons.packageMinus;
      case StockLogReason.stockAdjustment:
        return LucideIcons.slidersHorizontal;
      default:
        return LucideIcons.arrowLeftRight;
    }
  }
}
