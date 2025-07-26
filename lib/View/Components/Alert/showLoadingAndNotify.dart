import 'package:flutter/material.dart';
import 'package:pocketpos/View/Components/Alert/CustomNotificationDialog.dart';

Future<void> showLoadingAndNotify({
  required BuildContext context,
  required Future<void> Function() task,
  String successTitle = '🎉 Sync Complete',
  String successMessage = 'Your data has been successfully synced with the server. Everything is up to date!',

  String errorTitle = '⚠️ Sync Failed',
  String errorMessage = 'Something went wrong while syncing. Please check your connection and try again.',

}) async {
  final navigator = Navigator.of(context);

  // 🔐 Show non-dismissible loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => WillPopScope(
      onWillPop: () async => false, // disable back button
      child: const AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    ),
  );

  try {
    await task(); // 💼 Run the async task

    navigator.pop(); // ❌ Close loading

    // ✅ Show success notification
    showDialog(
      context: context,
      builder: (_) => CustomNotificationDialog(
        type: "success",
        title: successTitle,
        content: successMessage,
        onConfirm: () => navigator.pop(),
      ),
    );
  } catch (e) {
    navigator.pop(); // ❌ Close loading

    // ❗ Show error notification
    showDialog(
      context: context,
      builder: (_) => CustomNotificationDialog(
        type: "error",
        title: errorTitle,
        content: errorMessage,
        onConfirm: () => navigator.pop(),
      ),
    );
  }
}
