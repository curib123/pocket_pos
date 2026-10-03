import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nextpos/Model/product_model.dart';
import 'package:nextpos/Model/stock_log.dart';
import 'package:nextpos/Provider/ProductProvider.dart';
import 'package:nextpos/core/brand/app_brand.dart';
import 'package:provider/provider.dart';

enum _ActivityFilter { all, stockIn, stockOut, adjustment }

enum _ActivityKind { stockIn, stockOut, adjustment, other }

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  _ActivityFilter _filter = _ActivityFilter.all;

  @override
  Widget build(BuildContext context) {
    final products =
        context.watch<ProductProvider>().getAllProductsWithVariants();
    final activities = _activities(products).where(_matchesFilter).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              scrollDirection: Axis.horizontal,
              children: [
                _chip(_ActivityFilter.all, 'All'),
                _chip(_ActivityFilter.stockIn, 'Stock In'),
                _chip(_ActivityFilter.stockOut, 'Stock Out'),
                _chip(_ActivityFilter.adjustment, 'Adjustments'),
              ],
            ),
          ),
          Expanded(
            child: activities.isEmpty
                ? const _EmptyActivity()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    itemCount: activities.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) =>
                        _ActivityRow(item: activities[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(_ActivityFilter value, String label) {
    final selected = value == _filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: AppBrand.primarySoft,
        backgroundColor: AppBrand.surface,
        side: BorderSide(
          color: selected ? AppBrand.primary : AppBrand.border,
        ),
        labelStyle: TextStyle(
          color: selected ? AppBrand.primary : AppBrand.ink,
          fontWeight: FontWeight.w600,
        ),
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }

  List<_InventoryActivity> _activities(List<Product> products) {
    final result = <_InventoryActivity>[];
    for (final product in products) {
      for (final log in product.logs) {
        result.add(
          _InventoryActivity(
            product: product,
            log: log,
            kind: _kind(log.reason),
          ),
        );
      }
    }

    result.sort((a, b) => b.log.dateLogged.compareTo(a.log.dateLogged));
    return result;
  }

  bool _matchesFilter(_InventoryActivity item) {
    return switch (_filter) {
      _ActivityFilter.all => true,
      _ActivityFilter.stockIn => item.kind == _ActivityKind.stockIn,
      _ActivityFilter.stockOut => item.kind == _ActivityKind.stockOut,
      _ActivityFilter.adjustment => item.kind == _ActivityKind.adjustment,
    };
  }

  _ActivityKind _kind(StockLogReason reason) {
    return switch (reason) {
      StockLogReason.added ||
      StockLogReason.restocked ||
      StockLogReason.restored =>
        _ActivityKind.stockIn,
      StockLogReason.sold ||
      StockLogReason.expired ||
      StockLogReason.damaged ||
      StockLogReason.donated ||
      StockLogReason.borrowed ||
      StockLogReason.consumed =>
        _ActivityKind.stockOut,
      StockLogReason.adjusted => _ActivityKind.adjustment,
      _ => _ActivityKind.other,
    };
  }
}

class _InventoryActivity {
  final Product product;
  final StockLog log;
  final _ActivityKind kind;

  const _InventoryActivity({
    required this.product,
    required this.log,
    required this.kind,
  });
}

class _ActivityRow extends StatelessWidget {
  final _InventoryActivity item;

  const _ActivityRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final label = switch (item.kind) {
      _ActivityKind.stockIn => 'Stock In',
      _ActivityKind.stockOut => 'Stock Out',
      _ActivityKind.adjustment => 'Adjustment',
      _ActivityKind.other => _fallbackReason(item.log.reason),
    };
    final icon = switch (item.kind) {
      _ActivityKind.stockIn => Icons.add_rounded,
      _ActivityKind.stockOut => Icons.remove_rounded,
      _ActivityKind.adjustment => Icons.tune_rounded,
      _ActivityKind.other => Icons.history_rounded,
    };
    final quantity = switch (item.kind) {
      _ActivityKind.stockIn => '+${item.log.quantity}',
      _ActivityKind.stockOut => '-${item.log.quantity}',
      _ => item.log.quantity == 0 ? '—' : item.log.quantity.toString(),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppBrand.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppBrand.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      quantity,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppBrand.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$label · ${DateFormat('MMM d, h:mm a').format(item.log.dateLogged)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppBrand.muted,
                      ),
                ),
                if (item.log.remarks?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 5),
                  Text(
                    item.log.remarks!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppBrand.muted,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fallbackReason(StockLogReason reason) {
    return switch (reason) {
      StockLogReason.deleted => 'Product deleted',
      StockLogReason.cleared => 'Inventory cleared',
      StockLogReason.unknown => 'Inventory update',
      _ => reason.name,
    };
  }
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppBrand.primarySoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.history_rounded,
                color: AppBrand.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No activity yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Stock In, Stock Out, and adjustments will appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppBrand.muted,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
