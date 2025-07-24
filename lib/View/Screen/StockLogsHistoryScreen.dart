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

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProductProvider, LogProvider>(
      builder: (context, productProvider, logProvider, _) {
        final products = productProvider.products;

        final logs = logProvider
            .getLogs(
          productIdOrName: selectedProductIdOrName,
          dateRange: selectedRange,
        )
            .where((log) => selectedReason == null || log.reason == selectedReason)
            .toList();

        return Scaffold(
          appBar: AppBar(
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            ),
            title: const Text("Stock Logs History", style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // 🔽 Filters Row
                Row(
                  children: [
                    // Product dropdown
                    Expanded(
                      child: CustomFlatDropdown<String>(
                        hint: "All Products",
                        value: selectedProductIdOrName,
                        items: [
                          ...products.map((p) => p.id),
                          ...products.expand((p) => p.variants.map((v) => v.id)),
                        ],
                        onChanged: (val) => setState(() => selectedProductIdOrName = val),
                        itemBuilder: (val) {
                          final product = productProvider.getProductById(val);
                          return Text(
                            product?.name ?? "Deleted",
                            style: const TextStyle(fontSize: 14, overflow: TextOverflow.ellipsis),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Date picker
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
                ),

                // Reason filter
                Padding(
                  padding: const EdgeInsets.only(top: 0),
                  child: CustomFlatDropdown<StockLogReason>(
                    hint: "All Reasons",
                    value: selectedReason,
                    items: StockLogReason.values,
                    onChanged: (val) => setState(() => selectedReason = val),
                    itemBuilder: (val) => Text(val.name, style: const TextStyle(fontSize: 13)),
                  ),
                ),

                const SizedBox(height: 16),

                // 🔄 Logs List
                Expanded(
                  child: logs.isEmpty
                      ? const Center(child: Text("No logs found"))
                      : ListView.separated(
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final product = productProvider.getProductById(log.productId);

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
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  "Reason: ${log.reason.name}",
                                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Qty: ${log.quantity} ${log.isPiece ? 'pcs' : 'pack'}",
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                            if (log.remarks != null && log.remarks!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  "Note: ${log.remarks!}",
                                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                ),
                              ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                DateFormat('MMM d, yyyy • h:mm a').format(log.dateLogged),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black45,
                                  fontFamily: 'RobotoMono',
                                ),
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
          ),
        );
      },
    );
  }
}
