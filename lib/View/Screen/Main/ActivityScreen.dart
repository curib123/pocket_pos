import 'dart:io';

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
  int _page = 0;
  int _pageSize = 10;

  @override
  Widget build(BuildContext context) {
    final products =
        context.watch<ProductProvider>().getAllProductsWithVariants();
    final activities = _activities(products).where(_matchesFilter).toList();

    final totalPages =
        activities.isEmpty ? 1 : (activities.length / _pageSize).ceil();
    final safePage = _page.clamp(0, totalPages - 1).toInt();
    final start = safePage * _pageSize;
    final end = (start + _pageSize) > activities.length
        ? activities.length
        : start + _pageSize;
    final visible = activities.sublist(start, end);

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
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) =>
                        _ActivityRow(item: visible[index]),
                  ),
          ),
          if (activities.isNotEmpty)
            _PaginationBar(
              page: safePage,
              pageSize: _pageSize,
              totalItems: activities.length,
              totalPages: totalPages,
              onPrevious: safePage == 0
                  ? null
                  : () => setState(() => _page = safePage - 1),
              onNext: safePage >= totalPages - 1
                  ? null
                  : () => setState(() => _page = safePage + 1),
              onPageSizeChanged: (value) {
                setState(() {
                  _pageSize = value;
                  _page = 0;
                });
              },
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
        selectedColor: AppBrand.primarySoftOf(context),
        backgroundColor: AppBrand.surfaceOf(context),
        side: BorderSide(
          color: selected ? AppBrand.primary : AppBrand.borderOf(context),
        ),
        labelStyle: TextStyle(
          color: selected ? AppBrand.primary : AppBrand.inkOf(context),
          fontWeight: FontWeight.w600,
        ),
        onSelected: (_) {
          setState(() {
            _filter = value;
            _page = 0;
          });
        },
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
      StockLogReason.stockIn ||
      StockLogReason.added ||
      StockLogReason.restocked ||
      StockLogReason.restored =>
        _ActivityKind.stockIn,
      StockLogReason.stockOut ||
      StockLogReason.sold ||
      StockLogReason.expired ||
      StockLogReason.damaged ||
      StockLogReason.donated ||
      StockLogReason.borrowed ||
      StockLogReason.consumed =>
        _ActivityKind.stockOut,
      StockLogReason.stockAdjustment ||
      StockLogReason.adjusted =>
        _ActivityKind.adjustment,
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
    final color = switch (item.kind) {
      _ActivityKind.stockIn => AppBrand.primary,
      _ActivityKind.stockOut => AppBrand.danger,
      _ActivityKind.adjustment => AppBrand.warning,
      _ActivityKind.other => AppBrand.mutedOf(context),
    };
    final background = switch (item.kind) {
      _ActivityKind.stockIn => AppBrand.primarySoftOf(context),
      _ActivityKind.stockOut => AppBrand.dangerSoftOf(context),
      _ActivityKind.adjustment => AppBrand.warningSoftOf(context),
      _ActivityKind.other => Theme.of(context).colorScheme.surfaceContainerHighest,
    };
    final quantity = switch (item.kind) {
      _ActivityKind.stockIn => '+${item.log.quantity.abs()}',
      _ActivityKind.stockOut => '-${item.log.quantity.abs()}',
      _ActivityKind.adjustment => item.log.quantity > 0
          ? '+${item.log.quantity}'
          : item.log.quantity.toString(),
      _ActivityKind.other =>
        item.log.quantity == 0 ? '—' : item.log.quantity.toString(),
    };
    final imagePath = item.log.imagePath;
    final hasImage = imagePath != null &&
        imagePath.trim().isNotEmpty &&
        File(imagePath).existsSync();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
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
                            color: color,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$label · ${DateFormat('MMM d, h:mm a').format(item.log.dateLogged)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppBrand.mutedOf(context),
                      ),
                ),
                if (item.log.remarks?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 5),
                  Text(
                    item.log.remarks!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppBrand.mutedOf(context),
                        ),
                  ),
                ],
                if (hasImage) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(imagePath!),
                      width: 92,
                      height: 64,
                      fit: BoxFit.cover,
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

class _PaginationBar extends StatelessWidget {
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<int> onPageSizeChanged;

  const _PaginationBar({
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
    required this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final start = totalItems == 0 ? 0 : (page * pageSize) + 1;
    final calculatedEnd = (page + 1) * pageSize;
    final end = calculatedEnd > totalItems ? totalItems : calculatedEnd;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        decoration: BoxDecoration(
          color: AppBrand.surfaceOf(context),
          border: Border(
            top: BorderSide(color: AppBrand.borderOf(context)),
          ),
        ),
        child: Row(
          children: [
            DropdownButton<int>(
              value: pageSize,
              underline: const SizedBox.shrink(),
              items: const [10, 25, 50]
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text('$value / page'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) onPageSizeChanged(value);
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$start–$end of $totalItems',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppBrand.mutedOf(context),
                    ),
              ),
            ),
            IconButton(
              tooltip: 'Previous page',
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Text(
              '${page + 1}/$totalPages',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            IconButton(
              tooltip: 'Next page',
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
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
                color: AppBrand.primarySoftOf(context),
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
                    color: AppBrand.mutedOf(context),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
