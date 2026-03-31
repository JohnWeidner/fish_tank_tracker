import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// {@template secure_storage}
/// Wrapper around [FlutterSecureStorage] for storing sensitive values.
/// {@endtemplate}
class SecureStorage {
  /// {@macro secure_storage}
  const SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _apiKeyKey = 'gemini_api_key';
  static const _legacyApiKeyKey = 'anthropic_api_key';

  /// Reads the stored Gemini API key, or `null` if not set.
  Future<String?> getApiKey() => _storage.read(key: _apiKeyKey);

  /// Deletes the legacy Anthropic API key if present.
  ///
  /// Call once at app startup to clean up orphaned keys.
  Future<void> cleanupLegacyKey() async {
    if (await _storage.containsKey(key: _legacyApiKeyKey)) {
      await _storage.delete(key: _legacyApiKeyKey);
    }
  }

  /// Stores the Gemini API key.
  Future<void> setApiKey(String key) =>
      _storage.write(key: _apiKeyKey, value: key);

  /// Deletes the stored Gemini API key.
  Future<void> deleteApiKey() => _storage.delete(key: _apiKeyKey);

  /// Whether an API key is currently stored.
  Future<bool> hasApiKey() => _storage.containsKey(key: _apiKeyKey);
}
