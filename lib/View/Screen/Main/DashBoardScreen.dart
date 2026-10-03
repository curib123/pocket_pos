import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nextpos/Model/product_model.dart';
import 'package:nextpos/Model/stock_log.dart';
import 'package:nextpos/Provider/CurrencyProvider.dart';
import 'package:nextpos/Provider/ProductProvider.dart';
import 'package:nextpos/Provider/TabProvider.dart';
import 'package:nextpos/View/Components/Brand/PocketInventoryBrand.dart';
import 'package:nextpos/View/Components/Widgets/AppDrawer.dart';
import 'package:nextpos/View/Components/Inventory/StockMovementSheet.dart';
import 'package:nextpos/core/brand/app_brand.dart';
import 'package:provider/provider.dart';

enum _DashboardRange { today, week, month, year, all }

class DashBoardScreen extends StatefulWidget {
  const DashBoardScreen({super.key});

  @override
  State<DashBoardScreen> createState() => _DashBoardScreenState();
}

class _DashBoardScreenState extends State<DashBoardScreen> {
  _DashboardRange _range = _DashboardRange.today;

  @override
  Widget build(BuildContext context) {
    final products =
        context.watch<ProductProvider>().getAllProductsWithVariants();
    final currency = context.watch<CurrencyProvider>();
    final totalUnits =
        products.fold<int>(0, (total, product) => total + product.totalQuantity);
    final stockValue = _stockValue(products);
    final lowStock = products.where((product) => product.isLowStock).length;
    final outOfStock = products.where((product) => product.isOutOfStock).length;
    final needsAttention = products
        .where((product) => product.isLowStock || product.isOutOfStock)
        .toList()
      ..sort((a, b) => a.totalQuantity.compareTo(b.totalQuantity));
    final movement = _movementSummary(products, _range);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        toolbarHeight: 76,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PocketInventoryBrand(
              showTagline: false,
              markSize: 32,
            ),
            const SizedBox(height: 3),
            Text(
              DateFormat('EEEE, MMM d').format(DateTime.now()),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppBrand.mutedOf(context),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: IconButton.filledTonal(
              tooltip: 'Open inventory',
              onPressed: () => context.read<TabProvider>().setTab(1),
              icon: const Icon(Icons.inventory_2_outlined),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<ProductProvider>().notifyListeners();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _OverviewHeader(
              productCount: products.length,
              totalUnits: totalUnits,
              needsAttention: needsAttention.length,
              stockValue: currency.formatAmount(stockValue),
            ),
            const SizedBox(height: 18),
            Text(
              'Quick actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.add_rounded,
                    label: 'Stock In',
                    onTap: () => StockMovementSheet.show(
                      context,
                      type: StockMovementType.stockIn,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.remove_rounded,
                    label: 'Stock Out',
                    onTap: () => StockMovementSheet.show(
                      context,
                      type: StockMovementType.stockOut,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.tune_rounded,
                    label: 'Adjust',
                    onTap: () => StockMovementSheet.show(
                      context,
                      type: StockMovementType.adjustment,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            _SectionHeader(
              title: 'Movement',
              actionLabel: null,
              onTap: () {},
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _rangeChip(_DashboardRange.today, 'Today'),
                  _rangeChip(_DashboardRange.week, 'Week'),
                  _rangeChip(_DashboardRange.month, 'Month'),
                  _rangeChip(_DashboardRange.year, 'Year'),
                  _rangeChip(_DashboardRange.all, 'All'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MovementCard(
                    label: 'Stock In',
                    value: movement.stockIn.toString(),
                    color: AppBrand.primary,
                    background: AppBrand.primarySoftOf(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MovementCard(
                    label: 'Stock Out',
                    value: movement.stockOut.toString(),
                    color: AppBrand.danger,
                    background: AppBrand.dangerSoftOf(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MovementCard(
                    label: 'Adjusted',
                    value: movement.adjusted.toString(),
                    color: AppBrand.warning,
                    background: AppBrand.warningSoftOf(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            _SectionHeader(
              title: 'Snapshot',
              actionLabel: 'View inventory',
              onTap: () => context.read<TabProvider>().setTab(1),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.72,
              children: [
                _MetricCard(
                  label: 'Products',
                  value: products.length.toString(),
                  icon: Icons.inventory_2_outlined,
                  color: AppBrand.primary,
                  background: AppBrand.primarySoftOf(context),
                ),
                _MetricCard(
                  label: 'On hand',
                  value: totalUnits.toString(),
                  icon: Icons.layers_outlined,
                  color: AppBrand.primary,
                  background: AppBrand.primarySoftOf(context),
                ),
                _MetricCard(
                  label: 'Low stock',
                  value: lowStock.toString(),
                  icon: Icons.low_priority_rounded,
                  color: AppBrand.warning,
                  background: AppBrand.warningSoftOf(context),
                ),
                _MetricCard(
                  label: 'Out of stock',
                  value: outOfStock.toString(),
                  icon: Icons.inventory_outlined,
                  color: AppBrand.danger,
                  background: AppBrand.dangerSoftOf(context),
                ),
              ],
            ),
            const SizedBox(height: 26),
            _SectionHeader(
              title: 'Needs attention',
              actionLabel: needsAttention.isEmpty ? null : 'See all',
              onTap: () => context.read<TabProvider>().setTab(1),
            ),
            const SizedBox(height: 10),
            if (products.isEmpty)
              _InfoCard(
                icon: Icons.inventory_2_outlined,
                title: 'Start with your products',
                body:
                    'Open Inventory to add your first item, then use Stock In to record what you have.',
                action: 'Open inventory',
                onTap: () => context.read<TabProvider>().setTab(1),
              )
            else if (needsAttention.isEmpty)
              const _InfoCard(
                icon: Icons.check_rounded,
                title: 'Stock looks good',
                body: 'No products are currently low or out of stock.',
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: AppBrand.surfaceOf(context),
                  border: Border.all(color: AppBrand.borderOf(context)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    for (var i = 0;
                        i < needsAttention.length && i < 5;
                        i++) ...[
                      _AttentionRow(product: needsAttention[i]),
                      if (i < needsAttention.length - 1 && i < 4)
                        const Divider(indent: 16, endIndent: 16),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _rangeChip(_DashboardRange value, String label) {
    final selected = _range == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: AppBrand.primarySoftOf(context),
        backgroundColor: AppBrand.surfaceOf(context),
        side: BorderSide(
          color: selected ? AppBrand.primary : AppBrand.borderOf(context),
        ),
        labelStyle: TextStyle(
          color: selected ? AppBrand.primary : AppBrand.inkOf(context),
          fontWeight: FontWeight.w700,
        ),
        onSelected: (_) => setState(() => _range = value),
      ),
    );
  }

  double _stockValue(List<Product> products) {
    var total = 0.0;
    for (final product in products) {
      for (final stock in product.stocks) {
        final price = stock.retailPrice > 0 ? stock.retailPrice : stock.costPrice;
        total += stock.quantity * price;
      }
    }
    return total;
  }

  _MovementSummary _movementSummary(
    List<Product> products,
    _DashboardRange range,
  ) {
    var stockIn = 0;
    var stockOut = 0;
    var adjusted = 0;
    final now = DateTime.now();
    final start = switch (range) {
      _DashboardRange.today => DateTime(now.year, now.month, now.day),
      _DashboardRange.week => DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 6)),
      _DashboardRange.month => DateTime(now.year, now.month),
      _DashboardRange.year => DateTime(now.year),
      _DashboardRange.all => null,
    };

    for (final product in products) {
      for (final log in product.logs) {
        if (start != null && log.dateLogged.isBefore(start)) continue;
        switch (log.reason) {
          case StockLogReason.stockIn:
          case StockLogReason.added:
          case StockLogReason.restocked:
            stockIn += log.quantity.abs();
            break;
          case StockLogReason.stockOut:
          case StockLogReason.sold:
          case StockLogReason.expired:
          case StockLogReason.damaged:
          case StockLogReason.donated:
          case StockLogReason.borrowed:
          case StockLogReason.consumed:
            stockOut += log.quantity.abs();
            break;
          case StockLogReason.stockAdjustment:
          case StockLogReason.adjusted:
            adjusted += log.quantity.abs();
            break;
          default:
            break;
        }
      }
    }

    return _MovementSummary(
      stockIn: stockIn,
      stockOut: stockOut,
      adjusted: adjusted,
    );
  }
}

class _OverviewHeader extends StatelessWidget {
  final int productCount;
  final int totalUnits;
  final int needsAttention;
  final String stockValue;

  const _OverviewHeader({
    required this.productCount,
    required this.totalUnits,
    required this.needsAttention,
    required this.stockValue,
  });

  @override
  Widget build(BuildContext context) {
    final allHealthy = needsAttention == 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppBrand.primaryFaintOf(context),
        border: Border.all(color: AppBrand.primarySoftOf(context)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock value',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppBrand.mutedOf(context),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stockValue,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppBrand.primary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
                              ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: allHealthy
                      ? AppBrand.primarySoftOf(context)
                      : AppBrand.warningSoftOf(context),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      allHealthy
                          ? Icons.check_circle_outline_rounded
                          : Icons.notification_important_outlined,
                      size: 16,
                      color:
                          allHealthy ? AppBrand.primary : AppBrand.warning,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      allHealthy ? 'Healthy' : '$needsAttention attention',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: allHealthy
                                ? AppBrand.primary
                                : AppBrand.warning,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$productCount products • $totalUnits units on hand',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppBrand.mutedOf(context),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            allHealthy
                ? 'Everything is above its reorder level.'
                : 'Review low and out-of-stock products before the next restock.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppBrand.mutedOf(context),
                  height: 1.35,
                ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppBrand.primary,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 25),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MovementCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color background;

  const _MovementCard({
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: AppBrand.surfaceOf(context),
        border: Border.all(color: AppBrand.borderOf(context)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppBrand.mutedOf(context),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppBrand.surfaceOf(context),
        border: Border.all(color: AppBrand.borderOf(context)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppBrand.mutedOf(context),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback onTap;

  const _SectionHeader({
    required this.title,
    required this.onTap,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onTap,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _AttentionRow extends StatelessWidget {
  final Product product;

  const _AttentionRow({required this.product});

  @override
  Widget build(BuildContext context) {
    final quantity = product.totalQuantity;
    final isOut = product.isOutOfStock;
    final color = isOut ? AppBrand.danger : AppBrand.warning;
    final background = isOut
        ? AppBrand.dangerSoftOf(context)
        : AppBrand.warningSoftOf(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          product.name.isEmpty ? '?' : product.name[0].toUpperCase(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      title: Text(
        product.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        isOut
            ? 'Out of stock'
            : '$quantity left · reorder at ${product.reorderLevel}',
        style: TextStyle(color: color),
      ),
      trailing: IconButton(
        tooltip: 'Stock In',
        onPressed: () => StockMovementSheet.show(
          context,
          type: StockMovementType.stockIn,
          product: product,
        ),
        icon: const Icon(Icons.add_circle_outline_rounded),
        color: AppBrand.primary,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? action;
  final VoidCallback? onTap;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppBrand.surfaceOf(context),
        border: Border.all(color: AppBrand.borderOf(context)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppBrand.primarySoftOf(context),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AppBrand.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppBrand.mutedOf(context),
                        height: 1.35,
                      ),
                ),
                if (action != null && onTap != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onTap,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(action!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MovementSummary {
  final int stockIn;
  final int stockOut;
  final int adjusted;

  const _MovementSummary({
    required this.stockIn,
    required this.stockOut,
    required this.adjusted,
  });
}
