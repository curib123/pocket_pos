import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View/Components/HelperClass/responsive_text.dart';
import 'package:paninda/View_Model/ProductProvider.dart';

final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

class CurrentProfitSummary extends StatefulWidget {
  final ProductProvider provider;

  const CurrentProfitSummary({
    super.key,
    required this.provider,
  });

  @override
  State<CurrentProfitSummary> createState() => _CurrentProfitSummaryState();
}

class _CurrentProfitSummaryState extends State<CurrentProfitSummary> {
  DateRangeType _selectedRange = DateRangeType.day;
  int _selectedLimit = 10;

  @override
  Widget build(BuildContext context) {
    final profits = widget.provider.getCheckoutProfitBy(_selectedRange);
    final sortedKeys = profits.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Latest first

    final limitedKeys = sortedKeys.take(_selectedLimit).toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "This shows how much profit you’ve made from sales during the selected period.",
            style: TextStyle(
              color: AppColor.textSecondary,
              fontSize: getResponsiveFontSize(context, 10),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          if (profits.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  "No profit records found yet.",
                  style: TextStyle(
                    color: AppColor.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: limitedKeys.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFECECEC)),
              itemBuilder: (context, index) {
                final key = limitedKeys[index];
                final profit = profits[key]!;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppColor.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        "+${currencyFormat.format(profit)}",
                        style: const TextStyle(
                          color: AppColor.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<DateRangeType>(
                value: _selectedRange,
                items: DateRangeType.values.map((range) {
                  return DropdownMenuItem(
                    value: range,
                    child: Text(_getRangeLabel(range)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedRange = value);
                  }
                },
              ),
              DropdownButton<int>(
                value: _selectedLimit,
                items: [5, 10, 20,30].map((limit) {
                  return DropdownMenuItem(
                    value: limit,
                    child: Text("Latest $limit"),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedLimit = value);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getRangeLabel(DateRangeType type) {
    switch (type) {
      case DateRangeType.day:
        return "Daily";
      case DateRangeType.week:
        return "Weekly";
      case DateRangeType.month:
        return "Monthly";
      case DateRangeType.year:
        return "Yearly";
    }
  }
}
