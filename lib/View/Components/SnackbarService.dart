import 'package:flutter/material.dart';

class SnackbarService {
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
  GlobalKey<ScaffoldMessengerState>();

  static void showSuccess(String message) {
    _showSnackbar(message, Colors.green);
  }

  static void showError(String message) {
    _showSnackbar(message, Colors.red);
  }

  static void showWarning(String message) {
    _showSnackbar(message, Colors.orange);
  }

  static void showInfo(String message) {
    _showSnackbar(message, Colors.blue); // You can use lightBlue or any other variant
  }

  static void _showSnackbar(String message, Color color) {
    final messenger = messengerKey.currentState;
    if (messenger != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
