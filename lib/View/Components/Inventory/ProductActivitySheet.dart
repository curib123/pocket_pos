import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nextpos/Model/product_model.dart';
import 'package:nextpos/Model/stock_log.dart';
import 'package:nextpos/Provider/ProductProvider.dart';
import 'package:nextpos/core/brand/app_brand.dart';
import 'package:provider/provider.dart';

enum _ProductActivityKind { stockIn, stockOut, adjustment }

class ProductActivitySheet extends StatefulWidget {
  final String productId;

  const ProductActivitySheet({
    super.key,
    required this.productId,
  });

  static Future<void> show(
    BuildContext context, {
    required Product product,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.88,
        child: ProductActivitySheet(productId: product.id),
      ),
    );
  }

  @override
  State<ProductActivitySheet> createState() => _ProductActivitySheetState();
}

class _ProductActivitySheetState extends State<ProductActivitySheet> {
  bool _newestFirst = true;
  int _page = 0;
  int _pageSize = 10;

  @override
  Widget build(BuildContext context) {
    final product =
        context.watch<ProductProvider>().getProductById(widget.productId);

    if (product == null) {
      return const Center(child: Text('Product not found.'));
    }

    final activities = product.logs.where(_isInventoryMovement).toList()
      ..sort(
        (a, b) => _newestFirst
            ? b.dateLogged.compareTo(a.dateLogged)
            : a.dateLogged.compareTo(b.dateLogged),
      );

    final totalPages =
        activities.isEmpty ? 1 : (activities.length / _pageSize).ceil();
    final safePage = _page.clamp(0, totalPages - 1).toInt();
    final start = safePage * _pageSize;
    final end = (start + _pageSize) > activities.length
        ? activities.length
        : start + _pageSize;
    final visible = activities.sublist(start, end);
    final status = _statusFor(context, product);

    return SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _ProductAvatar(product: product),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Product activity',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppBrand.mutedOf(context),
                                    ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(
                      label: status.label,
                      color: status.color,
                      background: status.background,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppBrand.primaryFaintOf(context),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryValue(
                          label: 'On hand',
                          value: product.totalQuantity.toString(),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 34,
                        color: AppBrand.borderOf(context),
                      ),
                      Expanded(
                        child: _SummaryValue(
                          label: 'Reorder at',
                          value: product.reorderLevel.toString(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Timeline',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const Spacer(),
                    SegmentedButton<bool>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: true,
                          label: Text('Newest'),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text('Oldest'),
                        ),
                      ],
                      selected: {_newestFirst},
                      onSelectionChanged: (selection) {
                        setState(() {
                          _newestFirst = selection.first;
                          _page = 0;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: activities.isEmpty
                ? const _EmptyProductActivity()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      return _TimelineItem(
                        log: visible[index],
                        isLast: index == visible.length - 1,
                      );
                    },
                  ),
          ),
          if (activities.isNotEmpty) ...[
            const Divider(height: 1),
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
        ],
      ),
    );
  }

  bool _isInventoryMovement(StockLog log) {
    return switch (log.reason) {
      StockLogReason.stockIn ||
      StockLogReason.added ||
      StockLogReason.restocked ||
      StockLogReason.stockOut ||
      StockLogReason.sold ||
      StockLogReason.expired ||
      StockLogReason.damaged ||
      StockLogReason.donated ||
      StockLogReason.borrowed ||
      StockLogReason.consumed ||
      StockLogReason.stockAdjustment ||
      StockLogReason.adjusted =>
        true,
      _ => false,
    };
  }

  _StockStatus _statusFor(BuildContext context, Product product) {
    if (product.isOutOfStock) {
      return _StockStatus(
        label: 'Out of stock',
        color: AppBrand.danger,
        background: AppBrand.dangerSoftOf(context),
      );
    }
    if (product.isLowStock) {
      return _StockStatus(
        label: 'Low stock',
        color: AppBrand.warning,
        background: AppBrand.warningSoftOf(context),
      );
    }
    return _StockStatus(
      label: 'Healthy',
      color: AppBrand.primary,
      background: AppBrand.primarySoftOf(context),
    );
  }
}

class _ProductAvatar extends StatelessWidget {
  final Product product;

  const _ProductAvatar({required this.product});

  @override
  Widget build(BuildContext context) {
    final path = product.imagePath;
    final hasImage =
        path != null && path.isNotEmpty && File(path).existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: hasImage
          ? Image.file(
              File(path),
              width: 52,
              height: 52,
              fit: BoxFit.cover,
            )
          : Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              color: AppBrand.primarySoftOf(context),
              child: Text(
                product.name.isEmpty ? '?' : product.name[0].toUpperCase(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppBrand.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryValue({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppBrand.mutedOf(context),
              ),
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final StockLog log;
  final bool isLast;

  const _TimelineItem({
    required this.log,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final kind = _kind(log.reason);
    final presentation = _presentation(context, kind, log.quantity);
    final imagePath = log.imagePath;
    final hasImage = imagePath != null &&
        imagePath.trim().isNotEmpty &&
        File(imagePath).existsSync();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: presentation.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    presentation.icon,
                    size: 18,
                    color: presentation.color,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      color: AppBrand.borderOf(context),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppBrand.surfaceOf(context),
                  border: Border.all(color: AppBrand.borderOf(context)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            presentation.label,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                          ),
                        ),
                        Text(
                          presentation.quantity,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: presentation.color,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, yyyy • h:mm a').format(log.dateLogged),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppBrand.mutedOf(context),
                          ),
                    ),
                    if (log.remarks?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text(
                        log.remarks!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppBrand.mutedOf(context),
                              height: 1.4,
                            ),
                      ),
                    ],
                    if (hasImage) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(imagePath),
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _ProductActivityKind _kind(StockLogReason reason) {
    return switch (reason) {
      StockLogReason.stockIn ||
      StockLogReason.added ||
      StockLogReason.restocked =>
        _ProductActivityKind.stockIn,
      StockLogReason.stockOut ||
      StockLogReason.sold ||
      StockLogReason.expired ||
      StockLogReason.damaged ||
      StockLogReason.donated ||
      StockLogReason.borrowed ||
      StockLogReason.consumed =>
        _ProductActivityKind.stockOut,
      _ => _ProductActivityKind.adjustment,
    };
  }

  _ActivityPresentation _presentation(
    BuildContext context,
    _ProductActivityKind kind,
    int quantity,
  ) {
    return switch (kind) {
      _ProductActivityKind.stockIn => _ActivityPresentation(
          label: 'Stock In',
          quantity: '+${quantity.abs()}',
          icon: Icons.add_rounded,
          color: AppBrand.primary,
          background: AppBrand.primarySoftOf(context),
        ),
      _ProductActivityKind.stockOut => _ActivityPresentation(
          label: 'Stock Out',
          quantity: '-${quantity.abs()}',
          icon: Icons.remove_rounded,
          color: AppBrand.danger,
          background: AppBrand.dangerSoftOf(context),
        ),
      _ProductActivityKind.adjustment => _ActivityPresentation(
          label: 'Adjustment',
          quantity: quantity > 0 ? '+$quantity' : quantity.toString(),
          icon: Icons.tune_rounded,
          color: AppBrand.warning,
          background: AppBrand.warningSoftOf(context),
        ),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          DropdownButton<int>(
            value: pageSize,
            underline: const SizedBox.shrink(),
            borderRadius: BorderRadius.circular(12),
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
          const SizedBox(width: 10),
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
    );
  }
}

class _EmptyProductActivity extends StatelessWidget {
  const _EmptyProductActivity();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: AppBrand.primarySoftOf(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.timeline_rounded,
                color: AppBrand.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No stock activity yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Stock In, Stock Out, and adjustments for this product will appear here.',
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

class _StockStatus {
  final String label;
  final Color color;
  final Color background;

  const _StockStatus({
    required this.label,
    required this.color,
    required this.background,
  });
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _ActivityPresentation {
  final String label;
  final String quantity;
  final IconData icon;
  final Color color;
  final Color background;

  const _ActivityPresentation({
    required this.label,
    required this.quantity,
    required this.icon,
    required this.color,
    required this.background,
  });
}
