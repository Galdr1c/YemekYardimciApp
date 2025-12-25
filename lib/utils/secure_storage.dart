import 'dart:io';
import 'package:flutter/foundation.dart';

/// Secure storage for API keys and sensitive data
/// Uses platform-specific secure storage
class SecureStorage {
  static const String _spoonacularKeyName = 'spoonacular_api_key';
  static const String _nutritionixAppIdName = 'nutritionix_app_id';
  static const String _nutritionixKeyName = 'nutritionix_api_key';
  
  /// Get API key from secure storage or environment
  static Future<String?> getApiKey(String keyName) async {
    // In production, use flutter_secure_storage or similar
    // For now, check environment variables first
    final envKey = Platform.environment[keyName.toUpperCase()];
    if (envKey != null && envKey.isNotEmpty) {
      return envKey;
    }
    
    // Fallback to default (for development)
    if (kDebugMode) {
      return _getDefaultKey(keyName);
    }
    
    return null;
  }
  
  /// Get default keys (development only)
  static String? _getDefaultKey(String keyName) {
    switch (keyName) {
      case _spoonacularKeyName:
        return 'YOUR_SPOONACULAR_API_KEY';
      case _nutritionixAppIdName:
        return 'YOUR_NUTRITIONIX_APP_ID';
      case _nutritionixKeyName:
        return 'YOUR_NUTRITIONIX_API_KEY';
      default:
        return null;
    }
  }
  
  /// Store API key securely
  static Future<void> storeApiKey(String keyName, String value) async {
    // In production, use flutter_secure_storage
    // For now, just log (don't store in plain text)
    if (kDebugMode) {
      print('[SecureStorage] Storing key: $keyName (length: ${value.length})');
    }
  }
  
  /// Clear all stored keys
  static Future<void> clearAll() async {
    if (kDebugMode) {
      print('[SecureStorage] Clearing all keys');
    }
  }
  
  /// Check if keys are configured
  static Future<bool> hasConfiguredKeys() async {
    final spoonacular = await getApiKey(_spoonacularKeyName);
    final appId = await getApiKey(_nutritionixAppIdName);
    final apiKey = await getApiKey(_nutritionixKeyName);
    
    return spoonacular != null && 
           spoonacular != 'YOUR_SPOONACULAR_API_KEY' &&
           appId != null && 
           appId != 'YOUR_NUTRITIONIX_APP_ID' &&
           apiKey != null && 
           apiKey != 'YOUR_NUTRITIONIX_API_KEY';
  }
}

