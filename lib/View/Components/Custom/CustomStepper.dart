import 'package:flutter/material.dart';
import 'package:pocketpos/View/Components/Custom/CustomTextField.dart';

class CustomStepperField extends StatefulWidget {
  final int value;
  final int min;
  final int max;
  final bool useTextInput;
  final Function(int) onChanged;
  final Color themeColor;

  const CustomStepperField({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.useTextInput,
    required this.themeColor,
  });

  @override
  State<CustomStepperField> createState() => _CustomStepperFieldState();
}

class _CustomStepperFieldState extends State<CustomStepperField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final safeValue = widget.value > 0 ? widget.value : widget.min;
    _controller = TextEditingController(text: safeValue.toString());
  }

  @override
  void didUpdateWidget(CustomStepperField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final safeValue = widget.value > 0 ? widget.value : widget.min;
      _controller.text = safeValue.toString();
    }
  }

  void _changeValue(int delta) {
    final next = widget.value + delta;
    if (next > widget.max || next < widget.min) return;
    if (next != widget.value) widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return widget.useTextInput
        ? SizedBox(
      child: CustomTextField(
        label: '',
        controller: _controller,
        keyboardType: TextInputType.number,
        onChanged: (val) {
          final parsed = int.tryParse(val.trim());
          if (parsed != null) {
            final clamped = parsed.clamp(widget.min, widget.max);
            _controller.text = clamped.toString();
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length),
            );
            widget.onChanged(clamped);
          }
        },
      ),
    )
        : Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[850]
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.25)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepButton(
            icon: Icons.remove,
            onTap: widget.value > widget.min
                ? () => _changeValue(-1)
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              (widget.value > 0 ? widget.value : widget.min).toString(),
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ),
          _buildStepButton(
            icon: Icons.add,
            onTap: widget.value < widget.max
                ? () => _changeValue(1)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStepButton({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap == null
              ? Colors.grey.withOpacity(0.15)
              : Colors.grey.withOpacity(0.18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: onTap == null ? Colors.grey : widget.themeColor,
        ),
      ),
    );
  }
}
