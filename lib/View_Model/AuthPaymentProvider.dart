import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:paninda/View/Components/HelperClass/supabase_service.dart';

enum AuthMode { signIn, signUp }

class AuthPaymentProvider with ChangeNotifier {
  final _supabaseService = SupabaseService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AuthMode _authMode = AuthMode.signIn;
  AuthMode get authMode => _authMode;

  /// Switch auth mode
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

  /// ✅ Fetch User Details & Save to Storage (Including Email)
  Future<void> fetchAndSaveUserDetails(String email) async {
    final userDetails = await getUserDetails(email);
    await saveUserDetails(userDetails);
    await saveUserEmail(email);
  }

  /// ✅ Fetch User Details from Supabase
  Future<Map<String, dynamic>> getUserDetails(String email) async {
    return await _supabaseService.fetchUserDetails(email);
  }

  /// ✅ Save User Details to Secure Storage
  Future<void> saveUserDetails(Map<String, dynamic> userDetails) async {
    await _storage.write(key: 'storeName', value: userDetails['storeName'] ?? '');
    await _storage.write(key: 'ownerName', value: userDetails['ownerName'] ?? '');
  }

  /// ✅ Save Email to Secure Storage
  Future<void> saveUserEmail(String email) async {
    await _storage.write(key: 'email', value: email);
  }

  /// ✅ Read User Details (Store, Owner, Email)
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

  /// ✅ Clear All Stored User Data
  Future<void> clearUserDetails() async {
    await _storage.deleteAll();
  }

  /// ✅ Logout User
  Future<void> logout() async {
    await _supabaseService.signOut();
    await clearUserDetails();
  }

  /// ✅ Check Both (Active OR Trial)
  Future<bool> checkActivationStatus() async {
    return await _supabaseService.isUserActiveOrOnTrial();
  }

  /// ✅ Check Only Active
  Future<bool> checkActiveStatus() async {
    return await _supabaseService.isActive();
  }

  /// ✅ Check Only Trial
  Future<bool> checkTrialStatus() async {
    return await _supabaseService.isTrial();
  }

  /// ✅ Activate Account (Ends Trial)
  Future<void> activateAccount(String userId) async {
    await _supabaseService.activateUser(userId);
  }

  /// ✅ Update Activation Only
  Future<void> setActiveStatus(String userId, bool isActive) async {
    await _supabaseService.setActiveStatus(userId, isActive);
  }

  /// ✅ Update Trial Only
  Future<void> setTrialStatus(String userId, bool isTrial) async {
    await _supabaseService.setTrialStatus(userId, isTrial);
  }
}
