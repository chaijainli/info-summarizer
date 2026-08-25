import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 安全存储封装：使用 Android Keystore / iOS Keychain 加密存储敏感数据
/// API Key 等设备端敏感配置通过此层存取，不在 SQLite 中明文保存
class SecureStorage {
  static final SecureStorage instance = SecureStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  SecureStorage._();

  static const String _apiKeyKey = 'llm_api_key';
  static const String _llmEnabledKey = 'llm_enabled';

  /// 保存 LLM API Key（加密）
  Future<void> saveApiKey(String apiKey) async {
    await _storage.write(key: _apiKeyKey, value: apiKey);
  }

  /// 读取 LLM API Key
  Future<String?> getApiKey() async {
    return await _storage.read(key: _apiKeyKey);
  }

  /// 保存 LLM 启用状态
  Future<void> saveLlmEnabled(bool enabled) async {
    await _storage.write(key: _llmEnabledKey, value: enabled ? '1' : '0');
  }

  /// 读取 LLM 启用状态
  Future<bool> getLlmEnabled() async {
    final value = await _storage.read(key: _llmEnabledKey);
    return value == '1';
  }

  /// 清除所有安全存储数据
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}