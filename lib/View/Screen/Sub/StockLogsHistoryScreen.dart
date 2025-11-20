import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:nextpos/Model/stock_log.dart';
import 'package:nextpos/View/Components/Custom/CustomFlatDropdown.dart';
import 'package:nextpos/Provider/ProductProvider.dart';
import 'package:nextpos/Provider/LogProvider.dart';
import 'package:nextpos/Helper/Classes_Methods/AppColor.dart';

class StockLogsHistoryScreen extends StatefulWidget {
  const StockLogsHistoryScreen({super.key});

  @override
  State<StockLogsHistoryScreen> createState() => _StockLogsHistoryScreenState();
}

class _StockLogsHistoryScreenState extends State<StockLogsHistoryScreen> {
  String? selectedProductIdOrName;
  DateTimeRange? selectedRange;
  StockLogReason? selectedReason;

  final ScrollController _scrollController = ScrollController();
  List<StockLog> paginatedLogs = [];
  bool isLoadingMore = false;
  int currentPage = 0;
  final int pageSize = 50;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    selectedRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    );

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        final logProvider = Provider.of<LogProvider>(context, listen: false);
        loadMoreLogs(logProvider);
      }
    });
  }

  void loadInitialLogs(LogProvider logProvider) {
    setState(() {
      currentPage = 0;
      paginatedLogs.clear();
      hasMore = true;
    });
    loadMoreLogs(logProvider);
  }

  void loadMoreLogs(LogProvider logProvider) async {
    if (isLoadingMore || !hasMore) return;

    setState(() => isLoadingMore = true);

    final offset = currentPage * pageSize;
    final newLogs = logProvider.getLogsChunked(
      productIdOrName: selectedProductIdOrName,
      dateRange: selectedRange,
      limit: pageSize,
      offset: offset,
    ).where((log) => selectedReason == null || log.reason == selectedReason).toList();

    setState(() {
      paginatedLogs.addAll(newLogs);
      currentPage++;
      isLoadingMore = false;
      if (newLogs.length < pageSize) hasMore = false;
    });
  }

  void onFilterChanged(LogProvider logProvider) {
    loadInitialLogs(logProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProductProvider, LogProvider>(
      builder: (context, productProvider, logProvider, _) {
        final products = productProvider.getAllProductsWithVariants();

        if (paginatedLogs.isEmpty && !isLoadingMore) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            loadInitialLogs(logProvider);
          });
        }

        return Scaffold(
          appBar: AppBar(
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            ),
            title: const Text("Activity Logs", style: TextStyle(color: Colors.black)),
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
                      child: CustomFlatDropdown<String?>(
                        hint: "All Products",
                        value: selectedProductIdOrName,
                        items: [
                          null,
                          ...products.map((p) => p.id),
                          ...products.expand((p) => p.variants.map((v) => v.id)),
                        ],
                        onChanged: (val) {
                          setState(() => selectedProductIdOrName = val);
                          onFilterChanged(logProvider);
                        },
                        itemBuilder: (val) {
                          if (val == null) {
                            return const Text("All Products", style: TextStyle(fontSize: 14));
                          }
                          final product = productProvider.getProductById(val);
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
                        if (picked != null) {
                          setState(() => selectedRange = picked);
                          onFilterChanged(logProvider);
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
                Padding(
                  padding: const EdgeInsets.only(top: 0),
                  child: CustomFlatDropdown<StockLogReason?>(
        hint: "All Reasons",
        value: selectedReason,
        items: [null, ...StockLogReason.values],
        onChanged: (val) {
        setState(() => selectedReason = val);
        onFilterChanged(logProvider);
        },
        itemBuilder: (val) => Text(
        val == null ? "All Reasons" : val.name,
        style: const TextStyle(fontSize: 13),
        ),

        ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: paginatedLogs.isEmpty && !isLoadingMore
                      ? const Center(child: Text("No logs found"))
                      : ListView.separated(
                    controller: _scrollController,
                    itemCount: paginatedLogs.length + (hasMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == paginatedLogs.length && hasMore) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final log = paginatedLogs[index];
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
