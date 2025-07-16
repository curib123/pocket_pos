import 'package:flutter/material.dart';
import 'package:mobile_stock_inventory/Helper/AppColor.dart';

class CustomPillToggle extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CustomPillToggle({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  _CustomPillToggleState createState() => _CustomPillToggleState();
}

class _CustomPillToggleState extends State<CustomPillToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconScale;
  late Animation<Color?> _backgroundColor;
  late Animation<Color?> _textColor;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _iconScale = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _backgroundColor = ColorTween(
      begin: Colors.transparent,
      end: AppColor.primary,
    ).animate(_controller);

    _textColor = ColorTween(
      begin: AppColor.textPrimary,
      end: Colors.white,
    ).animate(_controller);

    if (widget.isSelected) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(CustomPillToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildIcon() {
    return ScaleTransition(
      scale: _iconScale,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: widget.isSelected
            ? const Icon(Icons.check_circle, key: ValueKey('selected'), color: Colors.white, size: 18)
            : const Icon(Icons.radio_button_unchecked, key: ValueKey('unselected'), color: AppColor.primary, size: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: _backgroundColor.value,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: AppColor.primary,
              width: 1.5,
            ),
            boxShadow: widget.isSelected
                ? [
              BoxShadow(
                color: AppColor.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  color: _textColor.value,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
