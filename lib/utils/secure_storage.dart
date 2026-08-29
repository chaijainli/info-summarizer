import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:typed_data';

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
  static const String _baseUrlKey = 'llm_base_url';
  static const String _modelKey = 'llm_model_name';
  static const String _llmEnabledKey = 'llm_enabled';

  /// 内置大模型的 API Key（SiliconFlow）
  /// 以密文形式存放，只有持有 _keyParts 才能还原，反编译后不会看到明文
  static const String _builtinApiKeyCipher =
      'SHGz2Nh4Bw/SoDu5HJ5K23UDBNawtNv2BBxZec5kZfdEiz30v1yiW6yttUCUI4pWT96p';

  /// 内置大模型的 Base URL（SiliconFlow）
  static const String _builtinBaseUrlCipher =
      'U27qwt4yRUXFuSb4H55X3HUZENOksM+qAwsObo4=';

  /// 内置大模型的 Model ID（SiliconFlow）
  static const String _builtinModelCipher =
      'am373IJZHQ/K+mLuLg==';

  /// 解密密钥片段，分散存放以提高逆向难度
  static const String _part1 = 'x9kQ2mP7rT4vL8sN';
  static const String _part2 = 'b3Hf6Jd1Gy5cZ0wE';
  static const String _part3 = 'oU8iA4sD2fG6hJ0k';

  /// 内置 Key 密文校验值，用于快速判断解码是否成功
  static const String _builtinApiPrefix = 'sk-';
  static const String _builtinUrlPrefix = 'https://';
  static const String _builtinModelPrefix = 'Qwen/Qwen3-8B';

  /// 保存 LLM API Key（加密后存储）
  Future<void> saveApiKey(String apiKey) async {
    final value = apiKey.trim().isEmpty ? '' : _encode(apiKey.trim());
    await _storage.write(key: _apiKeyKey, value: value);
  }

  /// 读取 LLM API Key（优先用户设置，否则回退到内置）
  Future<String?> getApiKey() async {
    final stored = await _storage.read(key: _apiKeyKey);
    if (stored != null && stored.isNotEmpty) {
      final decrypted = _decode(stored);
      if (decrypted.isNotEmpty) {
        return decrypted;
      }
      return null;
    }
    return _builtinApiKey();
  }

  /// 保存 Base URL（加密后存储）
  Future<void> saveBaseUrl(String baseUrl) async {
    final value = baseUrl.trim().isEmpty ? '' : _encode(baseUrl.trim());
    await _storage.write(key: _baseUrlKey, value: value);
  }

  /// 读取 Base URL（优先用户设置，否则回退到内置）
  Future<String?> getBaseUrl() async {
    final stored = await _storage.read(key: _baseUrlKey);
    if (stored != null && stored.isNotEmpty) {
      final decrypted = _decode(stored);
      if (decrypted.isNotEmpty) {
        return decrypted;
      }
      return null;
    }
    return _builtinBaseUrl();
  }

  /// 保存 Model Name（加密后存储）
  Future<void> saveModelName(String modelName) async {
    final value = modelName.trim().isEmpty ? '' : _encode(modelName.trim());
    await _storage.write(key: _modelKey, value: value);
  }

  /// 读取 Model Name（优先用户设置，否则回退到内置）
  Future<String?> getModelName() async {
    final stored = await _storage.read(key: _modelKey);
    if (stored != null && stored.isNotEmpty) {
      final decrypted = _decode(stored);
      if (decrypted.isNotEmpty) {
        return decrypted;
      }
      return null;
    }
    return _builtinModel();
  }

  /// 还原内置 API Key，失败时返回 null
  String? _builtinApiKey() {
    try {
      final result = _decode(_builtinApiKeyCipher);
      if (result.startsWith(_builtinApiPrefix)) {
        return result;
      }
      print('内置 API Key 解密结果异常，请检查 _builtinApiKeyCipher');
      return null;
    } catch (e) {
      print('内置 API Key 解密失败：$e');
      return null;
    }
  }

  /// 还原内置 Base URL，失败时返回 null
  String? _builtinBaseUrl() {
    try {
      final result = _decode(_builtinBaseUrlCipher);
      if (result.startsWith(_builtinUrlPrefix)) {
        return result;
      }
      print('内置 Base URL 解密结果异常，请检查 _builtinBaseUrlCipher');
      return null;
    } catch (e) {
      print('内置 Base URL 解密失败：$e');
      return null;
    }
  }

  /// 还原内置 Model Name，失败时返回 null
  String? _builtinModel() {
    try {
      final result = _decode(_builtinModelCipher);
      if (result == _builtinModelPrefix) {
        return result;
      }
      print('内置 Model Name 解密结果异常，请检查 _builtinModelCipher');
      return null;
    } catch (e) {
      print('内置 Model Name 解密失败：$e');
      return null;
    }
  }

  /// 加密：SHA-256 密钥流 XOR
  String _encode(String plain) {
    final plainBytes = utf8.encode(plain);
    final secretBytes = _secretStream(plainBytes.length);
    final out = Uint8List(plainBytes.length);
    for (var i = 0; i < plainBytes.length; i++) {
      out[i] = plainBytes[i] ^ secretBytes[i];
    }
    return base64Encode(out);
  }

  /// 解密：SHA-256 密钥流 XOR
  String _decode(String cipher) {
    final cipherBytes = base64Decode(cipher);
    final secretBytes = _secretStream(cipherBytes.length);
    final out = Uint8List(cipherBytes.length);
    for (var i = 0; i < cipherBytes.length; i++) {
      out[i] = cipherBytes[i] ^ secretBytes[i];
    }
    return utf8.decode(out);
  }

  /// 生成可任意长度的密钥流（SHA-256 多次迭代拼接）
  List<int> _secretStream(int length) {
    final key = sha256.convert(
      utf8.encode(_part1 + _part2 + _part3),
    ).bytes;

    final result = <int>[];
    var counter = 0;
    while (result.length < length) {
      result.addAll(sha256.convert([...key, counter & 0xFF]).bytes);
      counter++;
    }
    return result.sublist(0, length);
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
