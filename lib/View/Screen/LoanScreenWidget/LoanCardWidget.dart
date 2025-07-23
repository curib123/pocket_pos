import 'package:flutter/material.dart';
import 'package:pocketpos/Helper/AppColor.dart';
import 'package:pocketpos/Model/loan_item.dart';
import 'package:pocketpos/View/Components/Custom/CustomButton.dart';



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

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0, // Flat style, no shadow
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          margin: const EdgeInsets.symmetric(vertical: 10 ),
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
              // Title with due indicator dot
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
                    icon: Icons.person_outline,
                    label: "Borrower",
                    value: loan.borrowerName,
                    labelColor: AppColor.textSecondary,
                    valueColor: AppColor.textPrimary,
                    iconColor: Colors.grey.shade500,
                  ),
                  _InfoChip(
                    icon: Icons.monetization_on_outlined,
                    label: "Amount",
                    value: "${loan.amount.toStringAsFixed(2)}",
                    labelColor: AppColor.textSecondary,
                    valueColor: AppColor.textPrimary,
                    iconColor: Colors.grey.shade500,
                  ),
                  _InfoChip(
                    icon: Icons.payment_outlined,
                    label: "Paid",
                    value: "${loan.paid.toStringAsFixed(2)}",
                    labelColor: AppColor.textSecondary,
                    valueColor: AppColor.textPrimary,
                    iconColor: Colors.grey.shade500,
                  ),
                  _InfoChip(
                    icon: Icons.pending_outlined,
                    label: "Due",
                    value: "${dueAmount.toStringAsFixed(2)}",
                    valueColor: isDue ? Colors.redAccent[600] : Colors.green.shade600,
                    iconColor: isDue ? Colors.redAccent[600] : Colors.green.shade600,
                    labelColor: AppColor.textSecondary,
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Buttons row with your CustomButton slim style
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 80,
                    child: CustomButton(
                      text: "Edit",
                      icon: Icons.edit_outlined,
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
                    width: 80,
                    child: CustomButton(
                      text: "Pay",
                      icon: Icons.payment,
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
