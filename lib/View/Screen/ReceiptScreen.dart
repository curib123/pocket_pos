// ✨ No change here — imports are fine
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pocketpos/Model/stock_log.dart';
import 'package:pocketpos/Model/product_model.dart';
import 'package:pocketpos/Provider/CurrencyProvider.dart';
import 'package:pocketpos/Provider/ProductProvider.dart';
import 'package:pocketpos/Provider/LogProvider.dart';
import 'package:pocketpos/View/Components/Custom/CustomFlatDropdown.dart';
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

  void _showReceiptDetails(BuildContext context, StockLog log, Product? product) {
    final dateStr = DateFormat('MMM d, yyyy – h:mm a').format(log.dateLogged);
    final quantityStr = "${log.quantity} ${log.isPiece ? 'pcs' : 'pack'}";
    final unitStr = product?.unit != null ? ' (${product!.unit})' : '';
    final piecesPerPackStr = (product?.piecesPerPack != null && product!.isSoldByPack)
        ? "${product.piecesPerPack} pcs per pack"
        : null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const Text("🧾 POCKET POS RECEIPT",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Courier')),
                  const SizedBox(height: 4),
                  Text(dateStr,
                      style: const TextStyle(fontSize: 12, fontFamily: 'Courier', color: Colors.black54)),
                ],
              ),
            ),
            const Divider(thickness: 1),
            Text("Product: ${product?.name ?? 'Deleted'}", style: _receiptStyle()),
            Text("Qty: $quantityStr$unitStr", style: _receiptStyle()),
            if (piecesPerPackStr != null) Text("Pack: $piecesPerPackStr", style: _receiptStyle()),
            if (product?.category != null) Text("Category: ${product!.category}", style: _receiptStyle()),
            if (product?.barcode != null) Text("Barcode: ${product!.barcode}", style: _receiptMonoStyle()),
            const Divider(thickness: 1),
            Text(
              "+ ${Provider.of<CurrencyProvider>(context, listen: false).formatAmount(log.profit ?? 0)}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontFamily: 'RobotoMono',
              ),
            ),
            const SizedBox(height: 6),
            Text("Receipt ID: ${log.id}", style: _receiptMonoStyle(color: Colors.black54)),
            if (log.remarks != null && log.remarks!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text("Note: ${log.remarks!}", style: _receiptStyle(italic: true)),
              ),
            const Divider(thickness: 1),
            const Center(
              child: Text("Thank you!",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Courier')),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close", style: TextStyle(color: Colors.deepPurple)),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _receiptStyle({bool italic = false}) => TextStyle(
    fontFamily: 'Courier',
    fontSize: 13,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
  );

  TextStyle _receiptMonoStyle({Color? color}) => TextStyle(
    fontFamily: 'RobotoMono',
    fontSize: 12,
    color: color ?? Colors.black87,
  );

  @override
  Widget build(BuildContext context) {
    return Consumer3<ProductProvider, LogProvider, CurrencyProvider>(
      builder: (context, productProvider, logProvider, currencyProvider, _) {
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
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            ),
            title: const Text("View Receipts", style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomFlatDropdown<String>(
                        hint: "All Products",
                        value: selectedProductIdOrName != null
                            ? products.expand((p) => [p, ...p.variants])
                            .map((p) => '${p.name}|${p.id}')
                            .firstWhere(
                              (item) => item.split('|').last == selectedProductIdOrName,
                          orElse: () => 'All Products|null',
                        )
                            : null,
                        items: [
                          'All Products|null',
                          ...products.map((p) => '${p.name}|${p.id}'),
                          ...products.expand((p) => p.variants.map((v) => '${v.name}|${v.id}')),
                        ],
                        onChanged: (val) {
                          final id = val?.split('|').last;
                          setState(() => selectedProductIdOrName = id == 'null' ? null : id);
                        },
                        itemBuilder: (val) => Text(val.split('|').first, style: const TextStyle(fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.secondarySurface,
                        foregroundColor: AppColor.textPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                const SizedBox(height: 10),
                Expanded(
                  child: logs.isEmpty
                      ? const Center(child: Text("No sales found"))
                      : ListView.separated(
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => Divider(color: Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final product = productProvider.getProductById(log.productId);
                      final dateStr = DateFormat('MMM d, h:mm a').format(log.dateLogged);

                      return InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _showReceiptDetails(context, log, product),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Receipt ID: ${log.id}",
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product?.name ?? "Deleted Product",
                                          style: const TextStyle(
                                            fontFamily: 'RobotoMono',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          "${log.quantity} ${log.isPiece ? 'pcs' : 'pack'}${product?.unit != null ? ' (${product!.unit})' : ''}",
                                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                                        ),
                                        if (product?.piecesPerPack != null && product!.isSoldByPack)
                                          Text("(${product.piecesPerPack} pcs per pack)",
                                              style: const TextStyle(fontSize: 11, color: Colors.black45)),
                                        if (product?.category != null)
                                          Text("Category: ${product!.category!}",
                                              style: const TextStyle(fontSize: 11, color: Colors.black45)),
                                        if (product?.barcode != null)
                                          Text("Barcode: ${product!.barcode!}",
                                              style: const TextStyle(fontSize: 11, color: Colors.black45)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    "+ ${currencyProvider.formatAmount(log.profit ?? 0)}",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontFamily: 'RobotoMono',
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(dateStr,
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.black38, fontFamily: 'RobotoMono')),
                              ),
                            ],
                          ),
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
