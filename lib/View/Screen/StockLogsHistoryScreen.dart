import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pocketpos/Model/stock_log.dart';
import 'package:pocketpos/View/Components/Custom/CustomFlatDropdown.dart';
import 'package:provider/provider.dart';
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
        final logs = logProvider.getLogs(
          productIdOrName: selectedProductIdOrName,
          dateRange: selectedRange,
        ).where((log) => selectedReason == null || log.reason == selectedReason).toList(); // ✅ Apply filter here

        return Scaffold(
          appBar: AppBar(
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_ios_new),
            ),
            title: const Text("Stock Logs History"),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // ✅ Product Filter
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
                          return Text(product?.name ?? "Unknown",style: TextStyle(fontSize: 14,overflow: TextOverflow.ellipsis),);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // ✅ Date Picker Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.secondarySurface,
                        foregroundColor: AppColor.textPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2022),
                          lastDate: DateTime.now(),
                          initialDateRange: selectedRange,
                        );
                        if (picked != null) {
                          setState(() => selectedRange = picked);
                        }
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

                // ✅ Reason Filter Dropdown
                CustomFlatDropdown<StockLogReason>(
                  hint: "All Reasons",
                  value: selectedReason,
                  items: StockLogReason.values,
                  onChanged: (val) => setState(() => selectedReason = val),
                  itemBuilder: (val) => Text(val.name),
                ),

                const SizedBox(height: 20),

                // 🔄 List of Logs
                Expanded(
                  child: logs.isEmpty
                      ? const Center(child: Text("No logs found"))
                      : ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final product = productProvider.getProductById(log.productId);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColor.secondarySurface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product?.name ?? "Unknown Product",
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text("Reason: ${log.reason.name}"),
                            if (log.remarks != null) Text("Remarks: ${log.remarks}"),
                            Text("Qty: ${log.quantity} ${log.isPiece ? 'pcs' : ''}"),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                DateFormat('MMM d, yyyy • h:mm a').format(log.dateLogged),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
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
