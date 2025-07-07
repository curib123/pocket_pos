import 'dart:io';
import 'package:flutter/material.dart';
import 'package:paninda/View/Components/HelperClass/supabase_payment_helper.dart';

class PaymentProvider with ChangeNotifier {
  final SupabasePaymentHelper _paymentHelper = SupabasePaymentHelper();

  bool _isLoading = false;
  List<Map<String, dynamic>> _payments = [];

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get payments => _payments;

  /// Submit payment using Helper (Removed reference, added method)
  Future<void> submitPayment({
    required String paymentMethod,
    required File proofImage,
  }) async {
    _setLoading(true);
    try {
      await _paymentHelper.submitPayment(
        paymentMethod: paymentMethod,
        proofImage: proofImage,
      );
      await fetchPayments();
    } finally {
      _setLoading(false);
    }
  }

  /// Get Payment Proof URL by Payment ID (Optional if needed)
  Future<String?> getLatestPaymentProofUrl() async {
   return await _paymentHelper.getLatestPaymentProofUrl();
  }


  /// Fetch payments using Helper
  Future<void> fetchPayments() async {
    _setLoading(true);
    try {
      _payments = await _paymentHelper.fetchPayments();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Delete payment using Helper
  Future<void> deletePayment(String paymentId) async {
    _setLoading(true);
    try {
      await _paymentHelper.deletePayment(paymentId);
      await fetchPayments();
    } finally {
      _setLoading(false);
    }
  }

  /// Update payment using Helper (Removed reference, added method)
  Future<void> updatePayment({
    required String paymentId,
    String? newMethod,
    String? newStatus,
  }) async {
    _setLoading(true);
    try {
      await _paymentHelper.updatePayment(
        paymentId: paymentId,
        newMethod: newMethod,
        newStatus: newStatus,
      );
      await fetchPayments();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
