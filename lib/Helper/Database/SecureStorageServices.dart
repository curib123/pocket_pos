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

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
