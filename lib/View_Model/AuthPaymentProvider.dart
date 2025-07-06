import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:paninda/View/Components/HelperClass/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthMode { signIn, signUp }

class AuthPaymentProvider with ChangeNotifier {
  final _supabaseService = SupabaseService();
  final _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AuthMode _authMode = AuthMode.signIn;
  AuthMode get authMode => _authMode;

  /// ✅ Switch auth mode
  void setAuthMode(AuthMode mode) {
    _authMode = mode;
    notifyListeners();
  }

  /// ✅ Sign Up
  Future<String?> signUp({
    required String email,
    required String password,
    required String storeName,
    required String ownerName,
  }) async {
    _authMode = AuthMode.signUp;
    _isLoading = true;
    notifyListeners();
    try {
      return await _supabaseService.signUp(
        email: email,
        password: password,
        storeName: storeName,
        ownerName: ownerName,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ Sign In & Save Details
  Future<void> signIn(String email, String password) async {
    _authMode = AuthMode.signIn;
    _isLoading = true;
    notifyListeners();
    try {
      await _supabaseService.signIn(email, password);
      await fetchAndSaveUserDetails(email);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ Fetch User Details & Save to Storage
  Future<void> fetchAndSaveUserDetails(String email) async {
    final userDetails = await _supabaseService.fetchUserDetails(email);
    await saveUserDetails(userDetails);
    await saveUserEmail(email);
  }

  /// ✅ Save User Details to Secure Storage
  Future<void> saveUserDetails(Map<String, dynamic> userDetails) async {
    await _storage.write(key: 'storeName', value: userDetails['storeName'] ?? '');
    await _storage.write(key: 'ownerName', value: userDetails['ownerName'] ?? '');
  }

  Future<void> saveUserEmail(String email) async {
    await _storage.write(key: 'email', value: email);
  }

  /// ✅ Read User Details
  Future<Map<String, String?>> readUserDetails() async {
    final storeName = await _storage.read(key: 'storeName');
    final ownerName = await _storage.read(key: 'ownerName');
    final email = await _storage.read(key: 'email');
    return {
      'storeName': storeName,
      'ownerName': ownerName,
      'email': email,
    };
  }

  /// ✅ Save Trial Info to Storage
  Future<void> saveTrialInfo(Map<String, dynamic> trialInfo) async {
    await _storage.write(key: 'trialEndDate', value: trialInfo['trialEndDate']?.toString() ?? '');
    await _storage.write(key: 'isTrial', value: trialInfo['isTrial'].toString());
    await _storage.write(key: 'remainingDays', value: trialInfo['remainingDays'].toString());
  }

  /// ✅ Read Trial Info from Storage
  Future<Map<String, dynamic>> readTrialInfo() async {
    final trialEndDate = await _storage.read(key: 'trialEndDate');
    final isTrial = await _storage.read(key: 'isTrial');
    final remainingDays = await _storage.read(key: 'remainingDays');

    return {
      'trialEndDate': trialEndDate,
      'isTrial': isTrial == 'true',
      'remainingDays': int.tryParse(remainingDays ?? '0') ?? 0,
    };
  }

  /// ✅ Fetch Trial Info (Online & Save Offline)
  Future<Map<String, dynamic>?> fetchTrialInfo() async {
    final trialInfo = await _supabaseService.getTrialInfo();
    if (trialInfo != null) {
      await saveTrialInfo(trialInfo);
    }
    return trialInfo;
  }

  /// ✅ Get Trial Info from Offline Storage
  Future<Map<String, dynamic>> getTrialInfoOffline() async {
    return await readTrialInfo();
  }

  /// ✅ Logout & Clear Storage
  Future<void> logout() async {
    await _supabaseService.signOut();
    await clearUserDetails();
  }

  Future<void> clearUserDetails() async {
    await _storage.deleteAll();
  }

  /// ✅ Activation & Trial Status Checkers
  Future<bool> checkActivationStatus() async {
    return await _supabaseService.isUserActiveOrOnTrial();
  }

  Future<bool> checkActiveStatus() async {
    return await _supabaseService.isActive();
  }

  Future<bool> checkTrialStatus() async {
    return await _supabaseService.isTrial();
  }

  /// ✅ Update Activation & Trial Status (Now Auto-uses Current User)
  Future<void> activateAccount() async {
    await _supabaseService.activateUser();
  }

  Future<void> setActiveStatus(bool isActive) async {
    await _supabaseService.setActiveStatus(isActive);
  }

  Future<void> setTrialStatus(bool isTrial) async {
    await _supabaseService.setTrialStatus(isTrial);
  }
}
