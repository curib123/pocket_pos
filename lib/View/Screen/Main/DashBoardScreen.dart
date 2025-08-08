import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pocketpos/View/Screen/Main/DashboardScreenWidgets/ProductDashboardStats.dart';
import 'package:provider/provider.dart';
import 'package:pocketpos/Provider/CurrencyProvider.dart';
import 'package:pocketpos/Provider/SwitchProvider.dart';
import 'package:pocketpos/Provider/ProductProvider.dart';
import 'package:pocketpos/View/Components/Widgets/AISnackbarManager.dart';
import 'package:pocketpos/View/Screen/Sub/PoSReportScreen.dart';
import 'package:pocketpos/View/Screen/Sub/PosChatScreen.dart';
import 'package:pocketpos/View/Components/Custom/CustomFlatDropdown.dart';
import 'package:pocketpos/View/Components/Widgets/GreetingsCardWidget.dart';
import 'package:pocketpos/View/Components/Widgets/AppDrawer.dart';
import 'package:pocketpos/View/Components/Widgets/SearchAndCartRow.dart';
import 'package:pocketpos/View/Components/Alert/showLoadingAndNotify.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppColor.dart';
import 'package:pocketpos/Helper/Classes_Methods/DashboardMetrics.dart';
import 'package:pocketpos/Helper/Classes_Methods/helper_methods.dart';

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
    _refreshMetrics();
    AISnackbarManager.showAIAlert(context, screenName: 'Dashboard Screen');
  }

  Future<void> _refreshMetrics() async {
    final allProducts = context.read<ProductProvider>().getAllProductsWithVariants();
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
    return Consumer2<CurrencyProvider, SwitchProvider>(
      builder: (context, currencyProvider, switchProvider, _) {
        return Scaffold(
          drawer: const AppDrawer(),
          appBar: const SearchAndCartAppBar(),
          body: RefreshIndicator(
            onRefresh: () => showLoadingAndNotify(context: context, task: _refreshMetrics),
            child: isReady
                ? Column(
              children: [
                _buildTopSection(), // stays fixed
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 140),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: ProductDashboardStats(
                            metrics: metrics,
                            currencyProvider: currencyProvider,
                            isTile: switchProvider.isDashboardGridView,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
                : const Center(child: CircularProgressIndicator()),
          ),
          // floating buttons layer on top
          floatingActionButton: _buildFloatingButtons(context, switchProvider),
        );
      },
    );
  }

  Widget _buildTopSection() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    onTap: () => _pickDate(isStart: true),
                    child: _dateTile(_customStartDate, "Start Date", LucideIcons.calendar),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickDate(isStart: false),
                    child: _dateTile(_customEndDate, "End Date", LucideIcons.calendarCheck),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingButtons(BuildContext context, SwitchProvider switchProvider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _floatingAction(
          icon: LucideIcons.pieChart,
          tooltip: "AI Reports",
          color: AppColor.primary, // 🔮 AI vibes
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => POSReportScreen()),
          ),
        ),
        const SizedBox(height: 10),
        _floatingAction(
          icon: LucideIcons.bot,
          tooltip: "Open Assistant",
          color: AppColor.secondary, // 🤖 assistant
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => POSChatScreen()),
          ),
        ),
        const SizedBox(height: 10),
        _floatingAction(
          icon: !switchProvider.isDashboardGridView ? LucideIcons.layoutDashboard : LucideIcons.layers,
          tooltip: "Toggle Grid View",
          color: AppColor.textSecondary, // 🧩 layout
          onPressed: () => switchProvider.toggleDashboardGridView(),
        ),
      ],
    );
  }

  Widget _floatingAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color, // 💡 optional, default fallback
  }) {
    final Color buttonColor = color ?? AppColor.primary;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: buttonColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: buttonColor.withOpacity(0.2),
                offset: const Offset(0, 2),
                blurRadius: 6,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: AppColor.surface,
            ),
          ),
        ),
      ),
    );
  }


  Widget _dateTile(DateTime? date, String label, IconData icon) {
    final isSelected = date != null;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      margin: const EdgeInsets.only(top: 10, left: 6, right: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppColor.primary.withOpacity(0.05) : Colors.white,
        border: Border.all(
          color: isSelected ? AppColor.primary : Colors.grey.shade300,
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isSelected ? AppColor.primary : Colors.grey[700]),
          const SizedBox(width: 10),
          Text(
            date != null ? formatDate(date) : label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isSelected ? AppColor.primary : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _customStartDate : _customEndDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _customStartDate = picked;
        } else {
          _customEndDate = picked;
        }
        isReady = false;
      });
      _refreshMetrics();
    }
  }
}
