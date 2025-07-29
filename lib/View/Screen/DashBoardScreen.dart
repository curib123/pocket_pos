import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pocketpos/Provider/CurrencyProvider.dart';
import 'package:pocketpos/View/Components/Widgets/AISnackbarManager.dart';
import 'package:pocketpos/View/Components/Widgets/ProductRangePreviewDropdown.dart';
import 'package:pocketpos/View/Screen/PoSReportScreen.dart';
import 'package:pocketpos/View/Screen/PosChatScreen.dart';
import 'package:provider/provider.dart';

import 'package:pocketpos/View/Components/Custom/CustomFlatDropdown.dart';
import 'package:pocketpos/View/Components/Widgets/GreetingsCardWidget.dart';
import 'package:pocketpos/View/Components/Widgets/AppDrawer.dart';
import 'package:pocketpos/View/Components/Widgets/SearchAndCartRow.dart';
import 'package:pocketpos/View/Components/Alert/showLoadingAndNotify.dart';

import 'package:pocketpos/Helper/Classes_Methods/AppColor.dart';
import 'package:pocketpos/Helper/Classes_Methods/DashboardMetrics.dart';
import 'package:pocketpos/Helper/Classes_Methods/helper_methods.dart';

import 'package:pocketpos/Provider/ProductProvider.dart';
import 'package:shimmer/shimmer.dart';

class DashBoardScreen extends StatefulWidget {
  const DashBoardScreen({super.key});

  @override
  State<DashBoardScreen> createState() => _DashBoardScreenState();
}

class _DashBoardScreenState extends State<DashBoardScreen> {
  late DashboardMetrics metrics;
  bool isReady = false;
  DateFilterType _selectedFilter = DateFilterType.day;

  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    autoSync(context);
    refreshProduct(context);
    _refreshMetrics();
    AISnackbarManager.showAIAlert(context, screenName: 'Dashboard Screen');
  }

  Future<void> _refreshMetrics() async {
    autoSync(context);
    refreshProduct(context);

    final allProducts = context.read<ProductProvider>().products;
    final data = generateDashboardMetrics(
      allProducts: allProducts,
      filterType: _selectedFilter,
      customStart: _customStartDate,
      customEnd: _customEndDate,
    );

    setState(() {
      metrics = data;
      isReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrencyProvider>(builder: (context, currencyProvider, _) {
      return Scaffold(
        drawer: const AppDrawer(),
        appBar: const SearchAndCartAppBar(),
        body: RefreshIndicator(
          onRefresh: () async {
            await showLoadingAndNotify(
              context: context,
              task: () async => await _refreshMetrics(),
            );
          },
          child: isReady
              ? Stack(
                children: [
                  Column(
                    children: [
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Column(
                      children: [
                        GreetingCard(),
                        const SizedBox(height: 5),
                        CustomFlatDropdown<DateFilterType>(
                          hint: "Choose timeframe",
                          value: _selectedFilter,
                          items: DateFilterType.values,
                          prefixIcon: LucideIcons.calendarRange,
                          onChanged: (type) {
                            if (type != null) {
                              setState(() {
                                _selectedFilter = type;
                                isReady = false;
                              });
                              _refreshMetrics();
                            }
                          },
                          itemBuilder: (type) => Text(type.name.toUpperCase()),
                        ),
                        if (_selectedFilter == DateFilterType.range)
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate:
                                      _customStartDate ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _customStartDate = picked;
                                        isReady = false;
                                      });
                                      _refreshMetrics();
                                    }
                                  },
                                  child: _dateTile(
                                      _customStartDate, "Start Date", LucideIcons.calendar),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate:
                                      _customEndDate ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _customEndDate = picked;
                                        isReady = false;
                                      });
                                      _refreshMetrics();
                                    }
                                  },
                                  child: _dateTile(
                                      _customEndDate, "End Date", LucideIcons.calendarCheck),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _GroupHeader(icon: LucideIcons.boxes, title: "Product Summary"),
                          _StatTile(
                            icon: LucideIcons.box,
                            label: "Total Products",
                            guide: "Number of main products",
                            value: formatNumber(metrics.totalProducts),
                            color: AppColor.primary,
                          ),
                          _StatTile(
                            icon: LucideIcons.layers,
                            label: "Products Variants",
                            guide: "Different versions like size or type",
                            value: formatNumber(metrics.totalVariants),
                            color: AppColor.secondary,
                          ),
                          _StatTile(
                            icon: LucideIcons.warehouse,
                            label: "Stock on Hand",
                            guide: "Total items in inventory",
                            value: formatNumber(metrics.totalStocks),
                            color: AppColor.accent,
                          ),

                          const SizedBox(height: 24),

                          const _GroupHeader(icon: LucideIcons.coins, title: "Sales & Revenue"),
                          _StatTile(
                            icon: LucideIcons.coins,
                            label: "Gross Sales",
                            guide: "All revenue within time range",
                            value: currencyProvider.formatAmount(metrics.currentRevenue),
                            color: Colors.indigo,
                          ),
                          _StatTile(
                            icon: LucideIcons.piggyBank,
                            label: "Profit Earned",
                            guide: "Revenue minus cost of sold items",
                            value: currencyProvider.formatAmount(metrics.currentProfit),
                            color: Colors.green,
                          ),
                          _StatTile(
                            icon: LucideIcons.trendingUp,
                            label: "Estimated Profit",
                            guide: "Profit if all stock is sold",
                            value: currencyProvider.formatAmount(metrics.unrealizedProfit),
                            color: Colors.orange,
                          ),
                          _StatTile(
                            icon: LucideIcons.lineChart,
                            label: "Expected Sales",
                            guide: "Estimated value of current stock",
                            value: currencyProvider.formatAmount(metrics.possibleRevenue),
                            color: Colors.purple,
                          ),
                          const SizedBox(height: 24),

                          const _GroupHeader(icon: LucideIcons.fileText, title: "Expenses & Costs"),
                          _StatTile(
                            icon: LucideIcons.wallet,
                            label: "Current Cost",
                            guide: "Total cost of unsold items",
                            value: currencyProvider.formatAmount(metrics.totalCost),
                            color: Colors.redAccent,
                          ),
                          _StatTile(
                            icon: LucideIcons.wallet2,
                            label: "Cost of Sales",
                            guide: "Cost of goods sold",
                            value: currencyProvider.formatAmount(metrics.currentCost),
                            color: Colors.deepOrange,
                          ),
                          const SizedBox(height: 24),
                          _GroupHeader(
                            icon: LucideIcons.thermometer,
                            title: "Stock Levels",
                            seeMore: false,
                            onSeeMore: () {
                              print("See more clicked");
                            },
                          ),

                          _StatTile(
                            icon: LucideIcons.arrowDownCircle,
                            label: "Low Stock",
                            guide: "≤ 10 in quantity",
                            value: formatNumber(metrics.lowStockCount),
                            color: Colors.redAccent,
                          ),
                          ProductRangePreviewDropdown(
                            minQty: 0,
                            maxQty: 10,
                            hint: "View low stock products",
                            prefixIcon: LucideIcons.box,
                          ),

                          _StatTile(
                            icon: LucideIcons.equal,
                            label: "Medium Stock",
                            guide: "11 to 50 in quantity",
                            value: formatNumber(metrics.mediumStockCount),
                            color: Colors.amber,
                          ),
                          ProductRangePreviewDropdown(
                            minQty: 11,
                            maxQty: 50,
                            hint: "View medium stock products",
                            prefixIcon: LucideIcons.box,
                          ),

                          _StatTile(
                            icon: LucideIcons.arrowUpCircle,
                            label: "High Stock",
                            guide: "More than 50 in quantity",
                            value: formatNumber(metrics.highStockCount),
                            color: Colors.green,
                          ),
                          ProductRangePreviewDropdown(
                            minQty: 51,
                            maxQty: 999999, // High enough upper bound
                            hint: "View high stock products",
                            prefixIcon: LucideIcons.box,
                          ),

                          const SizedBox(height: 24),

                          _GroupHeader(
                            icon: LucideIcons.repeat,
                            title: "Stock Activity",
                            seeMore: false,
                            onSeeMore: () {
                              print("Tapped see more on Stock Levels");
                            },
                          ),
                          _StatTile(
                            icon: LucideIcons.box,
                            label: "Sold (Packs)",
                            guide: "Sold as full packs",
                            value: formatNumber(metrics.totalSoldPerPack),
                            color: AppColor.warning,
                          ),
                          _StatTile(
                            icon: LucideIcons.layers,
                            label: "Sold (Pieces)",
                            guide: "Sold as individual pieces",
                            value: formatNumber(metrics.totalSoldPerPiece),
                            color: AppColor.secondary,
                          ),
                          _StatTile(
                            icon: LucideIcons.plusCircle,
                            label: "Stock Added",
                            guide: "New stock or restocks added",
                            value: formatNumber(metrics.totalAddedItems),
                            color: Colors.greenAccent,
                          ),
                          _StatTile(
                            icon: LucideIcons.trash2,
                            label: "Expired Items",
                            guide: "Items removed due to expiry",
                            value: formatNumber(metrics.totalExpiredItems),
                            color: Colors.grey,
                          ),
                          _StatTile(
                            icon: LucideIcons.alertTriangle,
                            label: "Damaged Items",
                            guide: "Lost due to damage",
                            value: formatNumber(metrics.totalDamageItems),
                            color: Colors.redAccent,
                          ),
                          _StatTile(
                            icon: LucideIcons.heartHandshake,
                            label: "Given Away",
                            guide: "Items donated or free",
                            value: formatNumber(metrics.totalDonatedItems),
                            color: Colors.pinkAccent,
                          ),
                          _StatTile(
                            icon: LucideIcons.loader,
                            label: "Loaned Out",
                            guide: "Items currently on loan",
                            value: formatNumber(metrics.totalLoanItems),
                            color: Colors.blueGrey,
                          ),
                          _StatTile(
                            icon: LucideIcons.flame,
                            label: "Used Internally",
                            guide: "Used in-store or for ops",
                            value: formatNumber(metrics.totalConsumedItems),
                            color: Colors.orangeAccent,
                          ),

                        ],
                      ),
                    ),
                  ),
                              ],
                            ),

                  Positioned(
                    bottom: 30,
                    right: 16,
                    child: Material(
                      shape: const CircleBorder(),
                      elevation: 6,
                      child: Ink(
                        decoration: BoxDecoration(
                          color: AppColor.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => POSChatScreen(),
                              ),
                            );
                          },
                          icon: const Icon(LucideIcons.bot,color: AppColor.surface,size: 25,),
                          tooltip: "Open Assistant",
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 90,
                    right: 16,
                    child: Material(
                      shape: const CircleBorder(),
                      elevation: 6,
                      child: Ink(
                        decoration: BoxDecoration(
                          color: AppColor.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => POSReportScreen(),
                              ),
                            );
                          },
                          icon: const Icon(LucideIcons.pieChart,color: AppColor.surface,size: 25,),
                          tooltip: "Ai Reports",
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                  ),

                ],
              )
              : const Center(child: CircularProgressIndicator()),
        ),
      );
    });
  }

  Widget _dateTile(DateTime? date, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      margin: const EdgeInsets.only(top: 10, left: 6, right: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(
            date != null ? formatDate(date) : label,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  String formatNumber(int value) {
    return NumberFormat.decimalPattern().format(value);
  }

  String formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}

class _GroupHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool seeMore;
  final VoidCallback? onSeeMore;

  const _GroupHeader({
    required this.icon,
    required this.title,
    this.seeMore = false,
    this.onSeeMore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// Icon + Gradient Shimmer Title
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColor.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(6),
                child: Icon(icon, size: 18, color: AppColor.primary),
              ),
              const SizedBox(width: 10),
              Shimmer.fromColors(
                baseColor: Colors.black87,
                highlightColor: Colors.deepPurpleAccent.shade100,
                period: const Duration(seconds: 3),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87, // actual text color overridden by shimmer
                  ),
                ),
              ),
            ],
          ),

          /// See More (if enabled)
          if (seeMore && onSeeMore != null)
            GestureDetector(
              onTap: onSeeMore,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: const [
                  Text(
                    "See more",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColor.primary,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 16, color: AppColor.primary),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? guide;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.guide,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.black87,
                  highlightColor: Colors.deepPurpleAccent.shade100,
                  period: const Duration(seconds: 3),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textPrimary,
                    ),
                  ),
                ),

                if (guide != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      guide!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}


class _StockDropdown extends StatefulWidget {
  final String stockType;

  const _StockDropdown({required this.stockType});

  @override
  State<_StockDropdown> createState() => _StockDropdownState();
}

class _StockDropdownState extends State<_StockDropdown> {
  String? _selectedAction;

  final List<String> _options = ["View Products", "Restock", "Export", "Alert"];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          hintText: "Select action for ${widget.stockType} stock",
        ),
        value: _selectedAction,
        items: _options.map((option) {
          return DropdownMenuItem(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: (val) {
          setState(() {
            _selectedAction = val!;
          });

          // 👇 You can handle dropdown logic here based on stock type
          debugPrint("${widget.stockType} stock -> Selected: $_selectedAction");

          // Optionally: trigger logic like context.read<ProductProvider>().filterBy(...);
        },
      ),
    );
  }
}
