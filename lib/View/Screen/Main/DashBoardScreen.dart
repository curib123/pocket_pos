import 'package:flutter/material.dart';
import 'package:nextpos/Model/product_model.dart';
import 'package:nextpos/Provider/ProductProvider.dart';
import 'package:nextpos/Provider/TabProvider.dart';
import 'package:nextpos/View/Components/Brand/BantayStockBrand.dart';
import 'package:nextpos/View/Components/Inventory/StockMovementSheet.dart';
import 'package:nextpos/core/brand/app_brand.dart';
import 'package:provider/provider.dart';

class DashBoardScreen extends StatelessWidget {
  const DashBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products =
        context.watch<ProductProvider>().getAllProductsWithVariants();
    final totalUnits =
        products.fold<int>(0, (total, product) => total + product.totalQuantity);
    final lowStock =
        products.where((product) => product.totalQuantity > 0 && product.totalQuantity <= 5).length;
    final outOfStock =
        products.where((product) => product.totalQuantity == 0).length;
    final needsAttention = products
        .where((product) => product.totalQuantity <= 5)
        .toList()
      ..sort((a, b) => a.totalQuantity.compareTo(b.totalQuantity));

    return Scaffold(
      appBar: AppBar(
        title: const BantayStockBrand(showTagline: true, markSize: 38),
        toolbarHeight: 72,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<ProductProvider>().notifyListeners();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text(
              'Inventory at a glance',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
            ),
            const SizedBox(height: 5),
            Text(
              'The three actions you need for daily stock keeping.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppBrand.muted,
                  ),
            ),
            const SizedBox(height: 20),
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
                ),
                _MetricCard(
                  label: 'On hand',
                  value: totalUnits.toString(),
                  icon: Icons.layers_outlined,
                ),
                _MetricCard(
                  label: 'Low stock',
                  value: lowStock.toString(),
                  icon: Icons.low_priority_rounded,
                ),
                _MetricCard(
                  label: 'Out of stock',
                  value: outOfStock.toString(),
                  icon: Icons.inventory_outlined,
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
                  color: AppBrand.surface,
                  border: Border.all(color: AppBrand.border),
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

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppBrand.surface,
        border: Border.all(color: AppBrand.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppBrand.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppBrand.primary, size: 20),
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
                      ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppBrand.muted,
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

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppBrand.primarySoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          product.name.isEmpty ? '?' : product.name[0].toUpperCase(),
          style: const TextStyle(
            color: AppBrand.primary,
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
        quantity == 0 ? 'Out of stock' : 'Only $quantity left',
        style: const TextStyle(color: AppBrand.muted),
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
        color: AppBrand.surface,
        border: Border.all(color: AppBrand.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppBrand.primarySoft,
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
                        color: AppBrand.muted,
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
