import 'package:flutter/material.dart';
import 'package:mobile_pos_inventory/Helper/AppColor.dart';

class CustomFlatDropdown<T> extends StatelessWidget {
  final String hint;
  final String? label;
  final String? helperText;
  final T? value;
  final List<T> items;
  final Function(T?) onChanged;
  final Color iconColor;
  final Widget Function(T val) itemBuilder;
  final IconData? prefixIcon;
  final bool readOnly;

  const CustomFlatDropdown({
    super.key,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemBuilder,
    this.label,
    this.helperText,
    this.iconColor = Colors.grey,
    this.prefixIcon,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
        ],
        Container(
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
                  child: DropdownButton<T?>(
                    value: value,
                    isExpanded: true,
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: iconColor),
                    onChanged: readOnly ? null : onChanged,
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
        ),
        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              helperText!,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
      ],
    );
  }
}
