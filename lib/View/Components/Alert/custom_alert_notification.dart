import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';

enum AlertType { success, warning, error }

void showCustomAlertBox(BuildContext context, String message, AlertType type) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => _CustomAlertDialog(message: message, type: type),
  );
}

class _CustomAlertDialog extends StatefulWidget {
  final String message;
  final AlertType type;

  const _CustomAlertDialog({
    super.key,
    required this.message,
    required this.type,
  });

  @override
  State<_CustomAlertDialog> createState() => _CustomAlertDialogState();
}

class _CustomAlertDialogState extends State<_CustomAlertDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  Color _getColor() {
    switch (widget.type) {
      case AlertType.success:
        return Colors.green.shade600;
      case AlertType.warning:
        return Colors.orange.shade800;
      case AlertType.error:
        return Colors.red.shade600;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case AlertType.success:
        return LucideIcons.checkCircle2;
      case AlertType.warning:
        return LucideIcons.alertTriangle;
      case AlertType.error:
        return LucideIcons.xOctagon;
    }
  }

  String _getButtonText() {
    switch (widget.type) {
      case AlertType.success:
        return "Great!";
      case AlertType.warning:
        return "Got it";
      case AlertType.error:
        return "Dismiss";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_getColor().withOpacity(0.15), _getColor().withOpacity(0.25)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  _getIcon(),
                  color: _getColor(),
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade900,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getColor(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: Text(
                    _getButtonText(),
                    style:  TextStyle(fontWeight: FontWeight.w600, fontSize: 15,color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
