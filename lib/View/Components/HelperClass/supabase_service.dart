import 'package:flutter/material.dart';
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
      final trialEndDate = DateTime.now().add(const Duration(days: 30));
      try {
        await _client.from('profiles').insert({
          'id': user.id,
          'email': email,
          'store_name': storeName,
          'owner_name': ownerName,
          'trial_end_date': trialEndDate.toUtc().toIso8601String(),
          'is_trial': true,
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

  /// ✅ Activation & Status Setters
  Future<void> activateUser(String userId) async {
    await _client.from('profiles').update({
      'is_active': true,
      'is_trial': false,
    }).eq('id', userId);
  }

  Future<void> setActiveStatus(String userId, bool isActive) async {
    await _client.from('profiles').update({
      'is_active': isActive,
    }).eq('id', userId);
  }

  Future<void> setTrialStatus(String userId, bool isTrial) async {
    await _client.from('profiles').update({
      'is_trial': isTrial,
    }).eq('id', userId);
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

  Future<void> updateProfile({
    required String id,
    String? email,
    bool? isActive,
    bool? isTrial,
    String? paymentRef,
    DateTime? trialEndDate,
    String? storeName,
    String? ownerName,
  }) async {
    final updateData = <String, dynamic>{};
    if (email != null) updateData['email'] = email;
    if (isActive != null) updateData['is_active'] = isActive;
    if (isTrial != null) updateData['is_trial'] = isTrial;
    if (paymentRef != null) updateData['payment_ref'] = paymentRef;
    if (trialEndDate != null) {
      updateData['trial_end_date'] = trialEndDate.toUtc().toIso8601String();
    }
    if (storeName != null) updateData['store_name'] = storeName;
    if (ownerName != null) updateData['owner_name'] = ownerName;

    if (updateData.isNotEmpty) {
      await _client.from('profiles').update(updateData).eq('id', id);
    }
  }

  Future<void> deleteProfile(String id) async {
    await _client.from('profiles').delete().eq('id', id);
  }


  /// Insert or Update entire product list as JSON array in product_data
  Future<void> insertProducts(List<Product> products, String userId) async {

    final data = {
      'user_id': userId,
      'product_data': products.map((p) => p.toMap()).toList(),
    };

    debugPrint('Upserting products for user $userId...');
    debugPrint('Product Data: ${data['product_data']}');

    try {
      final response = await _client
          .from('products')
          .upsert(data, onConflict: 'user_id');

      debugPrint('Upsert successful: $response');
    } catch (e) {
      debugPrint('Error upserting products: $e');
      throw Exception('Upsert failed: $e');
    }
  }

  /// Fetch list of products for user (from JSON array)
  Future<List<Product>> getProductsByUser(String userId) async {
    debugPrint('Fetching products for userId: $userId...');

    try {
      final data = await _client
          .from('products')
          .select('product_data')
          .eq('user_id', userId)
          .single();

      if (data == null || data['product_data'] == null) {
        debugPrint('No products found.');
        return [];
      }

      final productsJsonList = (data['product_data'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      final products = productsJsonList
          .map((json) => mapProductFromJson(json))
          .toList();

      debugPrint('Fetched ${products.length} products from database.');
      return products;
    } catch (e) {
      debugPrint('Error fetching products: $e');
      return [];
    }
  }



}
