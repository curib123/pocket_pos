import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:pocketpos/View/Components/Alert/CustomNotificationDialog.dart';

Future<void> showResultDialogAfterAsync({
  required BuildContext context,
  required Future<String> Function() asyncMethod,
  VoidCallback? onComplete,
}) async {
  // 🌀 Minimal clean loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(height: 4),
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 20),
            Text(
              "Please wait...",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    ),
  );

  try {
    final result = await asyncMethod();

    Navigator.of(context).pop(); // ⬅ Close loading

    // ✅ Use your custom dialog
    await showDialog(
      context: context,
      builder: (_) => CustomNotificationDialog(
        title: "Success",
        content: result,
        type: "success",
        buttonText: "OK",
        onConfirm: ()  {
          Navigator.of(context).pop();
            Phoenix.rebirth(context);

          },
      ),
    );
  } catch (error) {
    Navigator.of(context).pop(); // ⬅ Close loading

    // ❌ Use your custom error dialog
    await showDialog(
      context: context,
      builder: (_) => CustomNotificationDialog(
        title: "Something went wrong",
        content: error.toString(),
        type: "error",
        buttonText: "Close",
        onConfirm: ()  {
          Navigator.of(context).pop();
          Phoenix.rebirth(context);

        },
      ),
    );
  } finally {
    onComplete?.call();
  }
}
