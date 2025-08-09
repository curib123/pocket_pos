import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // 🔐 Save user data
  Future<void> saveUser({
    required String email,
    required String userId,
    required String storeName,
    required String ownerName,
  }) async {
    await _storage.write(key: 'email', value: email);
    await _storage.write(key: 'userId', value: userId);
    await _storage.write(key: 'storeName', value: storeName);
    await _storage.write(key: 'ownerName', value: ownerName);
  }

  // 📥 Read user data
  Future<Map<String, String?>> readUser() async {
    return {
      'email': await _storage.read(key: 'email'),
      'userId': await _storage.read(key: 'userId'),
      'storeName': await _storage.read(key: 'storeName'),
      'ownerName': await _storage.read(key: 'ownerName'),
    };
  }

  // 💾 Save trial & purchase flags
  Future<void> saveTrialAndPurchaseFlags({
    required bool isTrial,
    required bool isPurchase,
  }) async {
    await _storage.write(key: 'is_trial', value: isTrial.toString());
    await _storage.write(key: 'is_purchase', value: isPurchase.toString());
  }

// 📂 Read trial & purchase flags
  Future<Map<String, bool>> readTrialAndPurchaseFlags() async {
    final trialStr = await _storage.read(key: 'is_trial');
    final purchaseStr = await _storage.read(key: 'is_purchase');

    return {
      'is_trial': trialStr == 'true',
      'is_purchase': purchaseStr == 'true',
    };
  }

  // 🕒 Save trial expiration date
  Future<void> saveTrialExpirationDate(DateTime date) async {
    await _storage.write(key: 'trialExpirationDate', value: date.toIso8601String());
  }

  // ⏳ Read trial expiration date
  Future<DateTime?> readTrialExpirationDate() async {
    final dateString = await _storage.read(key: 'trialExpirationDate');
    if (dateString == null) return null;

    try {
      return DateTime.parse(dateString);
    } catch (_) {
      return null;
    }
  }

  // 🧼 Wipe everything
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

// 🔐 Save Supabase Key
  Future<void> saveSupabaseKey(String key) async {
    await _storage.write(key: 'supabaseKey', value: key);
  }

// 🔍 Read Supabase Key
  Future<String?> readSupabaseKey() async {
    return await _storage.read(key: 'supabaseKey');
  }

}
