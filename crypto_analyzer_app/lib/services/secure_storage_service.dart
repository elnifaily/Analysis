import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // المفاتيح المستخدمة للتخزين
  static const String _apiKeyKey = 'binance_api_key';
  static const String _apiSecretKey = 'binance_api_secret';
  
  // حفظ مفاتيح API
  Future<void> saveApiKeys(String apiKey, String apiSecret) async {
    await _storage.write(key: _apiKeyKey, value: apiKey);
    await _storage.write(key: _apiSecretKey, value: apiSecret);
  }
  
  // جلب مفتاح API
  Future<String?> getApiKey() async {
    return await _storage.read(key: _apiKeyKey);
  }
  
  // جلب مفتاح API السري
  Future<String?> getApiSecret() async {
    return await _storage.read(key: _apiSecretKey);
  }
  
  // التحقق من وجود مفاتيح API
  Future<bool> hasApiKeys() async {
    final apiKey = await getApiKey();
    final apiSecret = await getApiSecret();
    return apiKey != null && apiSecret != null && apiKey.isNotEmpty && apiSecret.isNotEmpty;
  }
  
  // حذف مفاتيح API
  Future<void> deleteApiKeys() async {
    await _storage.delete(key: _apiKeyKey);
    await _storage.delete(key: _apiSecretKey);
  }
}
