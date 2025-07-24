import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pocketpos/Model/stock_log.dart';
import 'package:pocketpos/View/Components/Custom/CustomFlatDropdown.dart';
import 'package:provider/provider.dart';
import 'package:pocketpos/Provider/ProductProvider.dart';
import 'package:pocketpos/Provider/LogProvider.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppColor.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  String? selectedProductIdOrName;
  DateTimeRange? selectedRange;

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
            .where((log) => log.reason == StockLogReason.sold)
            .toList()
          ..sort((a, b) => b.dateLogged.compareTo(a.dateLogged));

        return Scaffold(
          appBar: AppBar(
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_ios_new),
            ),
            title: const Text("Receipts"),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
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
                            product?.name ?? "Unknown",
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
                const SizedBox(height: 20),
                Expanded(
                  child: logs.isEmpty
                      ? const Center(child: Text("No sales found"))
                      : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: ListView.separated(
                      itemCount: logs.length,
                      separatorBuilder: (_, __) => Divider(color: Colors.grey.shade300),
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        final product = productProvider.getProductById(log.productId);
                        final dateStr = DateFormat('MMM d, h:mm a').format(log.dateLogged);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Receipt ID: ${log.id}",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product?.name ?? "Unknown Product",
                                      style: const TextStyle(
                                        fontFamily: 'RobotoMono',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      "${log.quantity} ${log.isPiece ? 'pcs' : 'pack'}",
                                      style: const TextStyle(
                                        fontFamily: 'RobotoMono',
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  "+ ₱${log.profit?.toStringAsFixed(2) ?? '0.00'}",
                                  style: const TextStyle(
                                    fontFamily: 'RobotoMono',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                dateStr,
                                style: const TextStyle(
                                  fontFamily: 'RobotoMono',
                                  fontSize: 12,
                                  color: Colors.black45,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
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
}
