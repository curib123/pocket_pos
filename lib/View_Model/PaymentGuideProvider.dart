import 'package:flutter/material.dart';
import 'package:paninda/View/Components/HelperClass/payment_guide_helper.dart';

class PaymentGuideProvider with ChangeNotifier {
  final PaymentGuideHelper _helper = PaymentGuideHelper();

  bool _isLoading = false;
  List<Map<String, dynamic>> _guides = [];
  String? _errorMessage;

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get guides => _guides;
  String? get errorMessage => _errorMessage;


  /// Load all payment guides from Supabase
  Future<void> loadGuides() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _guides = await _helper.fetchPaymentGuides();
    } catch (e) {
      _errorMessage = e.toString();
      _guides = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Insert new payment guide, then refresh list
  Future<void> addGuide({
    required String methodName,
    required String instruction,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _helper.insertPaymentGuide(
        methodName: methodName,
        instruction: instruction,
      );
      await loadGuides();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
