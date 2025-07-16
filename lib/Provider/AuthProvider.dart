import 'package:flutter/material.dart';
import 'package:mobile_stock_inventory/Helper/Database/SecureStorageServices.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SecureStorageService _storage = SecureStorageService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> signUp({
    required String email,
    required String password,
    required String storeName,
    required String ownerName,
  }) async {
    _setLoading(true);
    print('[AuthProvider] Signing up user...');

    try {
      final res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final userId = res.user?.id;
      print('[AuthProvider] SignUp response: userId=$userId');

      if (userId != null) {
        await _supabase.from('stores').insert({
          'id': userId,
          'email': email,
          'store_name': storeName,
          'owner_name': ownerName,
        });
        print('[AuthProvider] Inserted user data to stores table');

        await _storage.saveUser(
          email: email,
          userId: userId,
          storeName: storeName,
          ownerName: ownerName,
        );
        print('[AuthProvider] User data saved in secure storage');
      }
    } catch (e) {
      print('[AuthProvider] SignUp Error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    print('[AuthProvider] Signing in user...');

    try {
      final res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = res.user;
      print('[AuthProvider] SignIn response: userId=${user?.id}');

      if (user != null) {
        final data = await _supabase
            .from('stores')
            .select()
            .eq('id', user.id)
            .single();

        print('[AuthProvider] Fetched store data: $data');

        await _storage.saveUser(
          email: user.email ?? '',
          userId: user.id,
          storeName: data['store_name'],
          ownerName: data['owner_name'],
        );
        print('[AuthProvider] User data saved in secure storage');
      }
    } catch (e) {
      print('[AuthProvider] SignIn Error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    print('[AuthProvider] Signing out...');
    await _supabase.auth.signOut();
    await _storage.clearAll();
    print('[AuthProvider] Cleared secure storage');
    notifyListeners();
  }

  Future<Map<String, String?>> getStoredUser() async {
    print('[AuthProvider] Reading stored user...');
    final data = await _storage.readUser();
    print('[AuthProvider] Stored user: $data');
    return data;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
