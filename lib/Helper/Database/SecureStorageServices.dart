import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

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

  Future<Map<String, String?>> readUser() async {
    return {
      'email': await _storage.read(key: 'email'),
      'userId': await _storage.read(key: 'userId'),
      'storeName': await _storage.read(key: 'storeName'),
      'ownerName': await _storage.read(key: 'ownerName'),
    };
  }

  // Save trial expiration date
  Future<void> saveTrialExpirationDate(DateTime date) async {
    await _storage.write(key: 'trialExpirationDate', value: date.toIso8601String());
  }

  // Read trial expiration date
  Future<DateTime?> readTrialExpirationDate() async {
    final dateString = await _storage.read(key: 'trialExpirationDate');
    if (dateString == null) return null;

    try {
      return DateTime.parse(dateString);
    } catch (_) {
      return null;
    }
  }
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
