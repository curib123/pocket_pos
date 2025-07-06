import 'package:flutter/material.dart';
import 'package:paninda/Model/loan_person_model.dart';
import 'package:paninda/Model/product_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final _client = Supabase.instance.client;

  /// ✅ AUTH METHODS

  Future<String?> signUp({
    required String email,
    required String password,
    required String storeName,
    required String ownerName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user != null) {
      final trialEndDate = DateTime.now().add(const Duration(days: 7));
      try {
        await _client.from('profiles').insert({
          'id': user.id,
          'email': email,
          'store_name': storeName,
          'owner_name': ownerName,
          'trial_end_date': trialEndDate.toUtc().toIso8601String(),
          'is_trial': false,
          'is_active': false,
        });
        print("✅ Profile inserted successfully.");
      } catch (e) {
        print("❌ Error inserting profile: $e");
      }
      return user.id;
    }
    return null;
  }

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// ✅ Fetch User Details for Secure Storage
  Future<Map<String, dynamic>> fetchUserDetails(String email) async {
    final response = await _client
        .from('profiles')
        .select('store_name, owner_name')
        .eq('email', email)
        .maybeSingle();

    return {
      'storeName': response?['store_name'] ?? '',
      'ownerName': response?['owner_name'] ?? '',
    };
  }

  /// ✅ STATUS CHECK METHODS

  Future<bool> isUserActiveOrOnTrial() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final data = await _client
        .from('profiles')
        .select('is_active, is_trial, trial_end_date')
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) return false;

    final trialEndDate = DateTime.tryParse(data['trial_end_date'] ?? '');
    final now = DateTime.now().toUtc();

    final isTrialActive =
        data['is_trial'] == true && trialEndDate != null && now.isBefore(trialEndDate);
    final isActive = data['is_active'] == true;

    return isActive || isTrialActive;
  }

  Future<bool> isActive() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final data = await _client
        .from('profiles')
        .select('is_active')
        .eq('id', user.id)
        .maybeSingle();

    return data?['is_active'] == true;
  }

  Future<bool> isTrial() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final data = await _client
        .from('profiles')
        .select('is_trial, trial_end_date')
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) return false;

    final trialEndDate = DateTime.tryParse(data['trial_end_date'] ?? '');
    final now = DateTime.now().toUtc();

    return data['is_trial'] == true && trialEndDate != null && now.isBefore(trialEndDate);
  }

  /// ✅ Get Trial End Date & Remaining Days (Auto-disable trial if expired)
  Future<Map<String, dynamic>?> getTrialInfo() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final data = await _client
        .from('profiles')
        .select('trial_end_date, is_trial')
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) return null;

    final trialEndDate = DateTime.tryParse(data['trial_end_date'] ?? '');
    if (trialEndDate == null) return null;

    final now = DateTime.now().toUtc();
    int remainingDays = trialEndDate.difference(now).inDays;

    if (remainingDays <= 0 && data['is_trial'] == true) {
      await _client.from('profiles').update({'is_trial': false}).eq('id', user.id);
      remainingDays = 0;
    }

    return {
      'trialEndDate': trialEndDate,
      'remainingDays': remainingDays > 0 ? remainingDays : 0,
      'isTrial': remainingDays > 0 && data['is_trial'] == true,
    };
  }

  /// ✅ Activation & Status Setters
  Future<void> activateUser() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception("No logged-in user.");

    await _client.from('profiles').update({
      'is_active': true,
      'is_trial': false,
    }).eq('id', user.id);
  }

  Future<void> setActiveStatus(bool isActive) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception("No logged-in user.");

    await _client.from('profiles').update({'is_active': isActive}).eq('id', user.id);
  }

  Future<void> setTrialStatus(bool isTrial) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception("No logged-in user.");

    await _client.from('profiles').update({'is_trial': isTrial}).eq('id', user.id);
  }

  /// ✅ CRUD METHODS (Admin / Profile Management)
  Future<List<Map<String, dynamic>>> getAllProfiles() async {
    final response = await _client.from('profiles').select('*');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getProfileById(String id) async {
    final response = await _client
        .from('profiles')
        .select('*')
        .eq('id', id)
        .maybeSingle();
    return response;
  }

  /// ✅ Products (Auto User ID)
  Future<void> insertProducts(List<Product> products) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception("No logged-in user.");

    final data = {
      'user_id': user.id,
      'product_data': products.map((p) => p.toMap()).toList(),
    };

    debugPrint('Upserting products for user ${user.id}...');
    try {
      await _client.from('products').upsert(data, onConflict: 'user_id');
      debugPrint('Products upserted.');
    } catch (e) {
      debugPrint('Error upserting products: $e');
      throw Exception('Upsert failed: $e');
    }
  }

  Future<List<Product>> getProductsByUser() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception("No logged-in user.");

    try {
      final data = await _client
          .from('products')
          .select('product_data')
          .eq('user_id', user.id)
          .single();

      if (data == null || data['product_data'] == null) return [];

      final productsJsonList =
      (data['product_data'] as List<dynamic>).cast<Map<String, dynamic>>();

      return productsJsonList.map((json) => mapProductFromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching products: $e');
      return [];
    }
  }

  /// ✅ Loans (Auto User ID)
  Future<void> insertLoans(List<LoanPerson> loans) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception("No logged-in user.");

    final data = {
      'user_id': user.id,
      'loan_data': loans.map((loan) => loan.toMap()).toList(),
    };

    debugPrint('Upserting loans for user ${user.id}...');
    try {
      await _client.from('loans').upsert(data, onConflict: 'user_id');
      debugPrint('Loans upserted.');
    } catch (e) {
      debugPrint('Error upserting loans: $e');
      throw Exception('Upsert failed: $e');
    }
  }

  Future<List<LoanPerson>> getLoansByUser() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception("No logged-in user.");

    try {
      final data = await _client
          .from('loans')
          .select('loan_data')
          .eq('user_id', user.id)
          .single();

      if (data == null || data['loan_data'] == null) return [];

      final loansJsonList =
      (data['loan_data'] as List<dynamic>).cast<Map<String, dynamic>>();

      return loansJsonList.map((json) => LoanPerson.fromMap(json)).toList();
    } catch (e) {
      debugPrint('Error fetching loans: $e');
      return [];
    }
  }
}
