import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pocketpos/Provider/CurrencyProvider.dart';
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
    return Consumer<CurrencyProvider>(
      builder: (context, currencyProvider, _) {
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
                ? Column(
              children: [
                // 🔝 Sticky Dropdown and Date Pickers
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
                                    initialDate: _customStartDate ?? DateTime.now(),
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
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                  margin: const EdgeInsets.only(top: 10, right: 6),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(LucideIcons.calendar, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        _customStartDate != null
                                            ? formatDate(_customStartDate!)
                                            : 'Start Date',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _customEndDate ?? DateTime.now(),
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
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                  margin: const EdgeInsets.only(top: 10, left: 6),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(LucideIcons.calendarCheck, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        _customEndDate != null
                                            ? formatDate(_customEndDate!)
                                            : 'End Date',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🧮 Inventory Overview
                        const _GroupHeader(icon: LucideIcons.boxes, title: "Inventory Overview"),
                        _StatTile(icon: LucideIcons.box, label: "Total Products", value: formatNumber(metrics.totalProducts), color: AppColor.primary),
                        _StatTile(icon: LucideIcons.layers, label: "Total Variants", value: formatNumber(metrics.totalVariants), color: AppColor.secondary),
                        _StatTile(icon: LucideIcons.warehouse, label: "In Stock", value: formatNumber(metrics.totalStocks), color: AppColor.accent),

                        const SizedBox(height: 24),

                        // 💰 Financial Overview
                        const _GroupHeader(icon: LucideIcons.coins, title: "Financial Overview"),
                        _StatTile(icon: LucideIcons.coins, label: "Current Revenue", value: currencyProvider.formatAmount(metrics.currentRevenue), color: Colors.indigo),
                        _StatTile(icon: LucideIcons.piggyBank, label: "Realized Profit", value: currencyProvider.formatAmount(metrics.currentProfit), color: Colors.green),
                        _StatTile(icon: LucideIcons.trendingUp, label: "Unrealized Profit", value: currencyProvider.formatAmount(metrics.unrealizedProfit), color: Colors.orange),
                        _StatTile(icon: LucideIcons.lineChart, label: "Potential Revenue", value: currencyProvider.formatAmount(metrics.possibleRevenue), color: Colors.purple),

                        const SizedBox(height: 24),

                        // 🔄 Stock Movement
                        const _GroupHeader(icon: LucideIcons.repeat, title: "Stock Movement"),
                        _StatTile(icon: LucideIcons.box, label: "Sold (Pack)", value: formatNumber(metrics.totalSoldPerPack), color: AppColor.warning),
                        _StatTile(icon: LucideIcons.layers, label: "Sold (Piece)", value: formatNumber(metrics.totalSoldPerPiece), color: AppColor.secondary),
                        _StatTile(icon: LucideIcons.plusCircle, label: "Added", value: formatNumber(metrics.totalAddedItems), color: Colors.greenAccent),
                        _StatTile(icon: LucideIcons.trash2, label: "Expired", value: formatNumber(metrics.totalExpiredItems), color: Colors.grey),
                        _StatTile(icon: LucideIcons.alertTriangle, label: "Damaged", value: formatNumber(metrics.totalDamageItems), color: Colors.redAccent),
                        _StatTile(icon: LucideIcons.heartHandshake, label: "Donated", value: formatNumber(metrics.totalDonatedItems), color: Colors.pinkAccent),
                        _StatTile(icon: LucideIcons.loader, label: "Loaned", value: formatNumber(metrics.totalLoanItems), color: Colors.blueGrey),
                        _StatTile(icon: LucideIcons.flame, label: "Consumed", value: formatNumber(metrics.totalConsumedItems), color: Colors.orangeAccent),

                        const SizedBox(height: 24),

                        // 💸 Cost Summary
                        const _GroupHeader(icon: LucideIcons.fileText, title: "Cost Summary"),
                        _StatTile(icon: LucideIcons.wallet, label: "Total Cost", value: currencyProvider.formatAmount(metrics.totalCost), color: Colors.redAccent),
                        _StatTile(icon: LucideIcons.wallet2, label: "Current Cost", value: currencyProvider.formatAmount(metrics.currentCost), color: Colors.deepOrange),
                      ],
                    ),
                  ),
                ),

                // 📊 Scrollable Metrics
              ],
            )
                : const Center(child: CircularProgressIndicator()),
          ),
        );
      }
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

  const _GroupHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColor.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20, color: AppColor.primary),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
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

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style:  TextStyle(fontSize: 14, color: AppColor.textPrimary),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
