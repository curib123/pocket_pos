import 'package:flutter/material.dart';
import 'package:mobile_pos_inventory/Helper/AppColor.dart';

class CustomFlatDropdown<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final List<T> items;
  final Function(T?) onChanged;
  final Color iconColor;
  final Widget Function(T val) itemBuilder;
  final IconData? prefixIcon;
  final bool readOnly; // ✅ New property

  const CustomFlatDropdown({
    super.key,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemBuilder,
    this.iconColor = Colors.grey,
    this.prefixIcon,
    this.readOnly = false, // ✅ Default to false
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: AppColor.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (prefixIcon != null) ...[
            Icon(prefixIcon, color: iconColor),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: iconColor),
                onChanged: readOnly ? null : onChanged, // ✅ Disable if readOnly
                hint: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    hint,
                    style: const TextStyle(color: AppColor.textSecondary, fontSize: 14),
                  ),
                ),
                selectedItemBuilder: (context) {
                  return items.map((item) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: itemBuilder(item),
                    );
                  }).toList();
                },
                items: items.map((item) {
                  return DropdownMenuItem<T>(
                    value: item,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: itemBuilder(item),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
