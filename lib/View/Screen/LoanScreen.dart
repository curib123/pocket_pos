import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pocketpos/Helper/Enums/Enum.dart';
import 'package:pocketpos/Provider/CurrencyProvider.dart';
import 'package:pocketpos/Provider/ProductProvider.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppColor.dart';
import 'package:pocketpos/View/Components/Alert/showEditLoanDialog.dart';
import 'package:pocketpos/View/Components/Alert/showPayAllDialog.dart';
import 'package:pocketpos/View/Components/Alert/showPayLoanDialog.dart';
import 'package:pocketpos/View/Components/Custom/CustomFlatDropdown.dart';
import 'package:pocketpos/View/Components/Custom/CustomButton.dart';
import 'package:pocketpos/View/Screen/LoanScreenWidget/LoanCardWidget.dart';

class LoanScreen extends StatefulWidget {
  const LoanScreen({super.key});

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  String? selectedBorrower;
  LoanFilterType selectedFilter = LoanFilterType.day;

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProductProvider, CurrencyProvider>(
      builder: (context, productProvider, currencyProvider, _) {
        final allLoans = productProvider.getAllLoans();
        final loaners = productProvider.getAllLoanerNames();

        // ✅ Reset borrower if name was changed and no longer exists
        if (selectedBorrower != null && !loaners.contains(selectedBorrower)) {
          selectedBorrower = null;
        }

        final metrics = productProvider.generateLoanMetrics(filter: selectedFilter);
        final totalLoanCount = metrics['totalLoanCount'] as int? ?? 0;
        final totalLoanQuantity = metrics['totalLoanQuantity'] as int? ?? 0;
        final totalLoanAmount = metrics['totalLoanAmount'] as double? ?? 0.0;

        final totalUnpaid = allLoans
            .where((loan) => !loan.isReturned)
            .fold<double>(0, (sum, loan) => sum + (loan.amount - loan.paid));

        final unpaidBorrowers = productProvider
            .getAllLoansByLoanerName()
            .entries
            .where((entry) => entry.value.any(
              (loan) => !loan.isReturned && loan.amount > loan.paid,
        ))
            .length;

        return Scaffold(
          appBar: AppBar(
            title: const Text("Loan Overview", style: TextStyle(color: AppColor.textSecondary)),
            centerTitle: true,
            backgroundColor: AppColor.surface,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeframe filter dropdown
                CustomFlatDropdown<LoanFilterType>(
                  hint: "Select timeframe",
                  value: selectedFilter,
                  items: LoanFilterType.values.where((e) => e != LoanFilterType.all).toList(),
                  itemBuilder: (val) {
                    switch (val) {
                      case LoanFilterType.day:
                        return const Text("Today");
                      case LoanFilterType.week:
                        return const Text("This Week");
                      case LoanFilterType.month:
                        return const Text("This Month");
                      case LoanFilterType.year:
                        return const Text("This Year");
                      default:
                        return const Text("All");
                    }
                  },
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        selectedFilter = val;
                      });
                    }
                  },
                  prefixIcon: Icons.filter_alt_outlined,
                ),
                const SizedBox(height: 16),

                // Stat Tiles
                _StatTile(
                  icon: Icons.list_alt_rounded,
                  label: "Total Loan Entries",
                  value: "$totalLoanCount",
                  color: Colors.blue,
                ),
                _StatTile(
                  icon: Icons.person_off_rounded,
                  label: "Unpaid Borrowers",
                  value: "$unpaidBorrowers",
                  color: Colors.orange,
                ),
                _StatTile(
                  icon: Icons.warning_amber_rounded,
                  label: "Total Unpaid",
                  value: currencyProvider.formatAmount(totalUnpaid),
                  color: Colors.red,
                ),
                _StatTile(
                  icon: Icons.today_rounded,
                  label: selectedFilter == LoanFilterType.day
                      ? "Today's Loan"
                      : selectedFilter == LoanFilterType.week
                      ? "This Week's Loan"
                      : selectedFilter == LoanFilterType.month
                      ? "This Month's Loan"
                      : "This Year's Loan",
                  value: currencyProvider.formatAmount(totalLoanAmount),
                  color: Colors.indigo,
                ),
                const SizedBox(height: 20),

                // Borrower dropdown
                CustomFlatDropdown<String>(
                  label: "Select Borrower",
                  hint: "Choose borrower name",
                  value: selectedBorrower,
                  items: loaners,
                  itemBuilder: (val) => Text(val),
                  onChanged: (val) {
                    setState(() {
                      selectedBorrower = val;
                    });
                  },
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 10),

                if (selectedBorrower != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Row(
                      children: [
                        Text(
                          'Total: ${currencyProvider.formatAmount(productProvider.getTotalLoanAmountForBorrower(selectedBorrower!))}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          height: 38,
                          child: CustomButton(
                            text: "Pay All Loan",
                            width: 140,
                            onPressed: () {
                              showPayAllLoansDialog(
                                context: context,
                                borrowerName: selectedBorrower!,
                                total: productProvider.getTotalLoanAmountForBorrower(selectedBorrower!),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // List of Loan Cards
                  ...(productProvider.getAllLoansByLoanerName()[selectedBorrower!]
                      ?.map(
                        (loan) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: LoanCardWidget(
                        loan: loan,
                        onPay: (loan) {
                          showPayLoanDialog(
                            context: context,
                            productId: loan.productId,
                            borrowerName: loan.borrowerName,
                            maxPayableAmount: loan.amount - loan.paid,
                          );
                        },
                        onEdit: (loan) {
                          showEditLoanDialog(
                            context: context,
                            productId: loan.productId,
                            borrowerName: loan.borrowerName,
                            loanDate: loan.loanDate,
                            currentQuantity: loan.quantity,
                            currentPrice: loan.price,
                            currentBorrowerName: loan.borrowerName,
                          );
                        },
                      ),
                    ),
                  )
                      .toList() ??
                      [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: Text(
                              "No loans found for this borrower.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      ]),
                ]
              ],
            ),
          ),
        );
      },
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 15)),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          )
        ],
      ),
    );
  }
}
