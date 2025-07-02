import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:paninda/View/Components/Core/scalable_appbar.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View_Model/LoanPersonProvider.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';

class LoanScreen extends StatefulWidget {
  const LoanScreen({super.key});

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  String? _selectedBorrowerName;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LoanProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'fil_PH', symbol: '₱ ', decimalDigits: 2);

    final borrowerNames = provider.unpaidLoans.map((e) => e.name).toSet().toList();
    final selectedLoans = _selectedBorrowerName == null
        ? []
        : provider.getLoansByName(_selectedBorrowerName!).where((e) => !e.isPaid).toList();

    return Scaffold(
      appBar: ScalableAppBar(
        isTitle: false,
        showSearchBar: true,
        title: "Loan",
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(
                duration: const Duration(milliseconds: 500),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColor.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColor.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.scrollText, color: AppColor.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Loan Overview",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColor.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Borrower stats and loan insights",
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColor.textSecondary,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _tile("Total Loan Entries", provider.loans.length.toString(), LucideIcons.wallet2),
              _tile("Unpaid Borrowers", provider.totalUnpaidBorrowers.toString(), LucideIcons.userX, AppColor.warning),
              _tile("Total Unpaid", currencyFormat.format(provider.totalLoanAmount), LucideIcons.alertCircle, AppColor.error),
              _tile("Today's Loan", currencyFormat.format(provider.todayLoanAmount), LucideIcons.calendarDays),
              const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Select Borrower", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
               if(selectedLoans.isNotEmpty) Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => _showPayAllDialog(context, selectedLoans),
                    icon:  Icon(LucideIcons.checkCircle,color: AppColor.surface,),
                    label: const Text("Pay All Loans"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8,horizontal: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedBorrowerName,
                isExpanded: true,
                decoration: InputDecoration(
                  hintText: "Choose name...",
                  filled: true,
                  fillColor: AppColor.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: borrowerNames.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
                onChanged: (name) {
                  setState(() => _selectedBorrowerName = name);
                },
              ),
              SizedBox(height: 10,),

              const SizedBox(height: 20),
              if (_selectedBorrowerName == null)
                _emptyState()
              else if (selectedLoans.isEmpty)
                _noLoansState()
              else ...[
                  ...selectedLoans.map((loan) => _buildLoanCard(loan)),
                  const SizedBox(height: 16),

                ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoanCard(loan) {
    final currencyFormat = NumberFormat.currency(locale: 'fil_PH', symbol: '₱ ', decimalDigits: 2);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.user, size: 18, color: AppColor.primary),
              const SizedBox(width: 8),
              Expanded(child: Text("${loan.name} - ${loan.productName}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
              IconButton(
                icon: const Icon(LucideIcons.minusCircle, color: AppColor.warning, size: 20),
                onPressed: () => _showDeductDialog(context, loan),
              )
            ],
          ),
          const SizedBox(height: 6),
          _loanRow(LucideIcons.layers, "Quantity: ${loan.quantity}"),
          _loanRow(LucideIcons.wallet, "Total: ${currencyFormat.format(loan.totalAmount)}"),
          _loanRow(LucideIcons.calendar, "Date: ${DateFormat.yMMMMd().format(loan.date)}"),
        ],
      ),
    );
  }

  void _showDeductDialog(BuildContext context, loan) {
    final provider = Provider.of<LoanProvider>(context, listen: false);
    final currencyFormat = NumberFormat.currency(locale: 'fil_PH', symbol: '₱ ', decimalDigits: 2);
    final totalLoan = loan.totalAmount;
    final controller = TextEditingController();
    double change = 0.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                const Icon(LucideIcons.badgeDollarSign, color: AppColor.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(child: Text("Pay Loan - ${loan.name}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))
              ]),
              const SizedBox(height: 14),
              _readonlyAmount(currencyFormat, totalLoan),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (val) {
                  final entered = double.tryParse(val) ?? 0.0;
                  setState(() => change = entered - totalLoan);
                },
                decoration: InputDecoration(
                  labelText: "Amount Paid",
                  prefixIcon: const Icon(LucideIcons.coins),
                  hintText: 'Enter cash amount...',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
              const SizedBox(height: 14),
              _changeAmount(currencyFormat, change),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel"))),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(LucideIcons.checkCircle2, size: 18),
                    label: const Text("Pay"),
                    onPressed: () {
                      final double amt = double.tryParse(controller.text) ?? 0.0;
                      if (amt > 0) {
                        provider.deductLoan(name: loan.name, productId: loan.productId, quantityToDeduct: 0, amountToDeduct: amt);
                        Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                )
              ])
            ]),
          ),
        ),
      ),
    );
  }

  void _showPayAllDialog(BuildContext context, List selectedLoans) {
    final provider = Provider.of<LoanProvider>(context, listen: false);
    final currencyFormat = NumberFormat.currency(locale: 'fil_PH', symbol: '₱ ', decimalDigits: 2);
    final totalLoan = selectedLoans.fold(0.0, (sum, loan) => sum + loan.totalAmount);
    final controller = TextEditingController();
    double change = 0.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                const Icon(LucideIcons.badgeDollarSign, color: AppColor.success, size: 22),
                const SizedBox(width: 10),
                Expanded(child: Text("Pay All Loans - ${selectedLoans.first.name}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))
              ]),
              const SizedBox(height: 14),
              _readonlyAmount(currencyFormat, totalLoan),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (val) {
                  final entered = double.tryParse(val) ?? 0.0;
                  setState(() => change = entered - totalLoan);
                },
                decoration: InputDecoration(
                  labelText: "Amount Paid",
                  prefixIcon: const Icon(LucideIcons.coins),
                  hintText: 'Enter cash amount...',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
              const SizedBox(height: 14),
              _changeAmount(currencyFormat, change),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel"))),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon:  Icon(LucideIcons.checkCircle2, size: 18,color: AppColor.surface,),
                    label: const Text("Pay All"),
                    onPressed: () {
                      final double amt = double.tryParse(controller.text) ?? 0.0;
                      if (amt >= totalLoan) {
                        for (var loan in selectedLoans) {
                          provider.deductLoan(
                            name: loan.name,
                            productId: loan.productId,
                            quantityToDeduct: 0,
                            amountToDeduct: loan.totalAmount,
                          );
                        }
                        Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                )
              ])
            ]),
          ),
        ),
      ),
    );
  }

  Widget _readonlyAmount(NumberFormat f, double amt) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColor.surface.withOpacity(0.95),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Row(children: [
      const Icon(LucideIcons.wallet, color: AppColor.textSecondary, size: 18),
      const SizedBox(width: 10),
      const Text("Total Loan:", style: TextStyle(fontSize: 14)),
      const Spacer(),
      Text(f.format(amt), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))
    ]),
  );

  Widget _changeAmount(NumberFormat f, double change) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: (change >= 0 ? AppColor.success.withOpacity(0.08) : AppColor.error.withOpacity(0.08)),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: change >= 0 ? AppColor.success.withOpacity(0.4) : AppColor.error.withOpacity(0.4),
      ),
    ),
    child: Row(children: [
      Icon(LucideIcons.wallet2, size: 18, color: change >= 0 ? AppColor.success : AppColor.error),
      const SizedBox(width: 10),
      const Text("Change:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      const Spacer(),
      Text(f.format(change > 0 ? change : 0),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: change >= 0 ? AppColor.success : AppColor.error,
          ))
    ]),
  );

  Widget _loanRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      Icon(icon, size: 16, color: AppColor.textSecondary),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(color: AppColor.textSecondary, fontSize: 13)))
    ]),
  );

  Widget _tile(String title, String value, IconData icon, [Color? color]) {
    final Color iconColor = color ?? AppColor.primary;
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.025), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Spin(
              infinite: true,
              duration: const Duration(seconds: 5),
              child: Icon(icon, color: iconColor, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: ZoomIn(
              duration: const Duration(milliseconds: 400),
              child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColor.textPrimary)),
            ),
          ),
          FadeInRight(
            duration: const Duration(milliseconds: 600),
            child: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: iconColor)),
          ),
        ]),
      ),
    );
  }

  Widget _emptyState() => Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(children: const [
      Icon(LucideIcons.search, size: 40, color: AppColor.textSecondary),
  SizedBox(height: 12),
  Text("No borrower selected", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
  SizedBox(height: 6),
        Text("Please choose a name to view their loan details.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColor.textSecondary),
        ),
      ]),
  );

  Widget _noLoansState() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColor.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.withOpacity(0.2)),
    ),
    child: const Center(
      child: Text(
        "No unpaid loans for this borrower.",
        style: TextStyle(
          color: AppColor.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      ),
    ),
  );
}

