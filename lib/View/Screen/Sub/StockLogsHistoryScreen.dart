import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nextpos/Helper/Classes_Methods/AppColor.dart';
import 'package:nextpos/Model/stock_log.dart';
import 'package:nextpos/Provider/LogProvider.dart';
import 'package:nextpos/Provider/ProductProvider.dart';
import 'package:provider/provider.dart';

class StockLogsHistoryScreen extends StatefulWidget {
  const StockLogsHistoryScreen({super.key});

  @override
  State<StockLogsHistoryScreen> createState() => _StockLogsHistoryScreenState();
}

class _StockLogsHistoryScreenState extends State<StockLogsHistoryScreen> {
  String? _productId;
  String _type = 'all';
  DateTimeRange? _range;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(
      start: now.subtract(const Duration(days: 30)),
      end: now.add(const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final logProvider = context.watch<LogProvider>();
    final products = productProvider.getAllProductsWithVariants();

    final movements = logProvider
        .getLogs(productIdOrName: _productId, dateRange: _range)
        .where(_isInventoryMovement)
        .where((log) => _type == 'all' || _movementType(log) == _type)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Stock Movement History'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: Column(
              children: [
                DropdownButtonFormField<String?>(
                  value: _productId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Product',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(LucideIcons.box),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All products'),
                    ),
                    ...products.map(
                      (product) => DropdownMenuItem<String?>(
                        value: product.id,
                        child: Text(
                          product.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _productId = value),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _type,
                        decoration: const InputDecoration(
                          labelText: 'Movement',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All movements')),
                          DropdownMenuItem(value: 'in', child: Text('Stock In')),
                          DropdownMenuItem(value: 'out', child: Text('Stock Out')),
                          DropdownMenuItem(value: 'adjustment', child: Text('Adjustment')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _type = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: _pickRange,
                      icon: const Icon(LucideIcons.calendarRange),
                      label: Text(
                        _range == null
                            ? 'Date'
                            : DateFormat('MMM d').format(_range!.start) +
                                ' - ' +
                                DateFormat('MMM d').format(_range!.end),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: movements.isEmpty
                ? const Center(
                    child: Text(
                      'No stock movements found.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: movements.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final log = movements[index];
                      final product = productProvider.getProductById(log.productId);
                      final type = _movementType(log);
                      final signed = _signedQuantity(log);

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColor.primary.withOpacity(0.1),
                              child: Icon(
                                _movementIcon(type),
                                color: AppColor.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product?.name ?? 'Deleted product',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _movementLabel(type),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  if (log.remarks?.isNotEmpty == true) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      log.remarks!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 5),
                                  Text(
                                    DateFormat('MMM d, yyyy • h:mm a')
                                        .format(log.dateLogged),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black38,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              signed,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  bool _isInventoryMovement(StockLog log) {
    return {
      StockLogReason.stockIn,
      StockLogReason.stockOut,
      StockLogReason.stockAdjustment,
      StockLogReason.added,
      StockLogReason.restocked,
      StockLogReason.adjusted,
      StockLogReason.sold,
      StockLogReason.expired,
      StockLogReason.damaged,
      StockLogReason.donated,
      StockLogReason.borrowed,
      StockLogReason.consumed,
    }.contains(log.reason);
  }

  String _movementType(StockLog log) {
    switch (log.reason) {
      case StockLogReason.stockIn:
      case StockLogReason.added:
      case StockLogReason.restocked:
        return 'in';
      case StockLogReason.stockAdjustment:
      case StockLogReason.adjusted:
        return 'adjustment';
      case StockLogReason.stockOut:
      case StockLogReason.sold:
      case StockLogReason.expired:
      case StockLogReason.damaged:
      case StockLogReason.donated:
      case StockLogReason.borrowed:
      case StockLogReason.consumed:
        return 'out';
      default:
        return 'other';
    }
  }

  String _movementLabel(String type) {
    switch (type) {
      case 'in':
        return 'Stock In';
      case 'out':
        return 'Stock Out';
      case 'adjustment':
        return 'Adjustment';
      default:
        return 'Movement';
    }
  }

  String _signedQuantity(StockLog log) {
    final type = _movementType(log);
    if (type == 'adjustment') {
      if (log.reason == StockLogReason.stockAdjustment) {
        return (log.quantity > 0 ? '+' : '') + log.quantity.toString();
      }
      return log.quantity.toString() + ' legacy';
    }
    return (type == 'out' ? '-' : '+') + log.quantity.abs().toString();
  }

  IconData _movementIcon(String type) {
    switch (type) {
      case 'in':
        return LucideIcons.packagePlus;
      case 'out':
        return LucideIcons.packageMinus;
      case 'adjustment':
        return LucideIcons.slidersHorizontal;
      default:
        return LucideIcons.arrowLeftRight;
    }
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _range,
    );
    if (picked != null) {
      setState(() {
        _range = DateTimeRange(
          start: picked.start,
          end: DateTime(
            picked.end.year,
            picked.end.month,
            picked.end.day,
            23,
            59,
            59,
          ),
        );
      });
    }
  }
}
