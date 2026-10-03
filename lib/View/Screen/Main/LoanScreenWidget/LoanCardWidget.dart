import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:nextpos/Helper/Classes_Methods/AppColor.dart';
import 'package:nextpos/Model/loan_item.dart';
import 'package:nextpos/Provider/CurrencyProvider.dart';
import 'package:nextpos/View/Components/Custom/CustomButton.dart';
import 'package:provider/provider.dart';

typedef LoanActionCallback = void Function(LoanItem loan);

class LoanCardWidget extends StatelessWidget {
  final LoanItem loan;
  final LoanActionCallback? onEdit;
  final LoanActionCallback? onPay;

  const LoanCardWidget({
    required this.loan,
    this.onEdit,
    this.onPay,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dueAmount = loan.amount - loan.paid;
    final isDue = dueAmount > 0;
    final formattedDate = DateFormat('MMMM d, y').format(loan.loanDate);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: Consumer<CurrencyProvider>(
        builder: (context, currencyProvider, _) {
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with due dot
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          loan.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColor.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isDue)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.redAccent.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Info Chips
                  Wrap(
                    spacing: 20,
                    runSpacing: 10,
                    children: [
                      _InfoChip(
                        icon: Icons.pending_outlined,
                        label: "Due Amount",
                        value: currencyProvider.formatAmount(dueAmount),
                        valueColor: isDue ? Colors.redAccent[600] : Colors.green.shade600,
                        iconColor: isDue ? Colors.redAccent[600] : Colors.green.shade600,
                        labelColor: AppColor.textSecondary,
                      ),
                      _InfoChip(
                        icon: Icons.payment_outlined,
                        label: "Paid",
                        value: currencyProvider.formatAmount(loan.paid),
                        labelColor: AppColor.textSecondary,
                        valueColor: AppColor.textPrimary,
                        iconColor: Colors.grey.shade500,
                      ),
                      _InfoChip(
                        icon: Icons.calendar_today_outlined,
                        label: "Date",
                        value: formattedDate,
                        labelColor: AppColor.textSecondary,
                        iconColor: Colors.blueGrey,
                        valueColor: AppColor.textPrimary,
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 100,
                        child: CustomButton(
                          text: "Edit",
                          icon: LucideIcons.edit3,
                          isSlimmer: true,
                          onPressed: onEdit != null ? () => onEdit!(loan) : () {},
                          isDisabled: onEdit == null,
                          isFilled: false,
                          textColor: AppColor.primary,
                          borderColor: AppColor.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      SizedBox(
                        width: 100,
                        child: CustomButton(
                          text: "Pay Now",
                          icon: LucideIcons.wallet2,
                          isSlimmer: true,
                          onPressed: (isDue && onPay != null) ? () => onPay!(loan) : () {},
                          isDisabled: !isDue || onPay == null,
                          isFilled: true,
                          borderColor: AppColor.textSecondary,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Color? iconColor;
  final Color? labelColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor ?? AppColor.textSecondary),
          const SizedBox(width: 6),
          Text(
            "$label:",
            style: TextStyle(
              color: labelColor ?? AppColor.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColor.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
