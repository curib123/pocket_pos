import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

class InternetChecker {
  /// Checks if device has real internet access.
  static Future<bool> hasInternet() async {
    try {
      // Step 1: Check network connection type
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false; // No Wi-Fi or mobile data
      }

      // Step 2: Try to lookup a known address
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true; // Device has internet access
      }
      return false;
    } on SocketException {
      return false; // DNS lookup failed or no route
    }
  }
}
