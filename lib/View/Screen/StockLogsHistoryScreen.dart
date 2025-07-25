import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pocketpos/Model/stock_log.dart';
import 'package:pocketpos/View/Components/Custom/CustomFlatDropdown.dart';
import 'package:pocketpos/Provider/ProductProvider.dart';
import 'package:pocketpos/Provider/LogProvider.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppColor.dart';

class StockLogsHistoryScreen extends StatefulWidget {
  const StockLogsHistoryScreen({super.key});

  @override
  State<StockLogsHistoryScreen> createState() => _StockLogsHistoryScreenState();
}

class _StockLogsHistoryScreenState extends State<StockLogsHistoryScreen> {
  String? selectedProductIdOrName;
  DateTimeRange? selectedRange;
  StockLogReason? selectedReason;

  @override
  void initState() {
    super.initState();
    selectedRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    );
  }

  List<StockLog> _getFilteredLogs(LogProvider logProvider) {
    final logs = logProvider.getLogs(
      productIdOrName: selectedProductIdOrName,
      dateRange: selectedRange,
    );

    // Debug all logs and reasons
    for (final log in logs) {
      print('[LOG] Product: ${log.productId}, Reason: ${log.reason}, Matches: ${log.reason == selectedReason}');
    }

    final filtered = selectedReason != null
        ? logs.where((log) => log.reason == selectedReason).toList()
        : logs;

    print('[DEBUG] Logs total: ${logs.length}, Filtered by reason: ${filtered.length}');
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProductProvider, LogProvider>(
      builder: (context, productProvider, logProvider, _) {
        final products = productProvider.products;
        final logs = _getFilteredLogs(logProvider);

        return Scaffold(
          appBar: AppBar(
            leading: const BackButton(color: Colors.black),
            title: const Text("Stock Logs History", style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildFiltersRow(products, productProvider),
                const SizedBox(height: 12),
                _buildReasonDropdown(),
                const SizedBox(height: 16),
                Expanded(
                  child: logs.isEmpty
                      ? const Center(child: Text("No logs found"))
                      : ListView.separated(
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) => StockLogTile(
                      log: logs[index],
                      product: productProvider.getProductById(logs[index].productId),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFiltersRow(List products, ProductProvider provider) {
    final allProductIds = [
      ...products.map((p) => p.id),
      ...products.expand((p) => p.variants.map((v) => v.id)),
    ].cast<String>();

    return Row(
      children: [
        Expanded(
          child: CustomFlatDropdown<String>(
            hint: "All Products",
            value: selectedProductIdOrName,
            items: allProductIds,
            onChanged: (val) => setState(() => selectedProductIdOrName = val),
            itemBuilder: (val) {
              final product = provider.getProductById(val);
              return Text(
                product?.name ?? "Deleted",
                style: const TextStyle(fontSize: 14, overflow: TextOverflow.ellipsis),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.secondarySurface,
            foregroundColor: AppColor.textPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          onPressed: () async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2022),
              lastDate: DateTime.now(),
              initialDateRange: selectedRange,
            );
            if (picked != null) setState(() => selectedRange = picked);
          },
          child: Text(
            selectedRange == null
                ? "Pick Date"
                : "${DateFormat('MMM d').format(selectedRange!.start)} - ${DateFormat('MMM d').format(selectedRange!.end)}",
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildReasonDropdown() {
    return CustomFlatDropdown<StockLogReason>(
      hint: "All Reasons",
      value: selectedReason,
      items: StockLogReason.values,
      onChanged: (val) => setState(() => selectedReason = val),
      itemBuilder: (val) => Text(val.name, style: const TextStyle(fontSize: 13)),
    );
  }
}

class StockLogTile extends StatelessWidget {
  final StockLog log;
  final dynamic product;

  const StockLogTile({super.key, required this.log, this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product?.name ?? "Deleted Product",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text("Reason: ${log.reason.name}", style: const TextStyle(fontSize: 12, color: Colors.black87)),
              const SizedBox(width: 12),
              Text("Qty: ${log.quantity} ${log.isPiece ? 'pcs' : 'pack'}", style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
          if (log.remarks?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text("Note: ${log.remarks!}", style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
            ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              DateFormat('MMM d, yyyy • h:mm a').format(log.dateLogged),
              style: const TextStyle(fontSize: 11, color: Colors.black45, fontFamily: 'RobotoMono'),
            ),
          ),
        ],
      ),
    );
  }
}
