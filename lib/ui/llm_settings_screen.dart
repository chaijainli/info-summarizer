import 'package:flutter/material.dart';
import '../models/llm_config_model.dart';
import '../database/llm_config_db.dart';
import '../services/llm_service.dart';
import '../utils/secure_storage.dart';

class LlmSettingsScreen extends StatefulWidget {
  const LlmSettingsScreen({super.key});

  @override
  State<LlmSettingsScreen> createState() => _LlmSettingsScreenState();
}

class _LlmSettingsScreenState extends State<LlmSettingsScreen> {
  final _baseUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _modelNameController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _maxTokensController = TextEditingController();
  final _systemPromptController = TextEditingController();

  final _db = LlmConfigDb.instance;
  bool _enabled = false;
  bool _isTesting = false;
  bool _isSaving = false;
  String? _testResult;
  
  // 跟踪是否使用了内置配置
  bool _usingBuiltin = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await _db.getConfig();
    
    // 检查是否有用户配置
    final userApiKey = await SecureStorage.instance.getApiKey();
    final userBaseUrl = await SecureStorage.instance.getBaseUrl();
    final userModelName = await SecureStorage.instance.getModelName();
    
    // 如果用户没有配置任何一项，则使用内置配置
    _usingBuiltin = (userApiKey == null || userApiKey.isEmpty) &&
                    (userBaseUrl == null || userBaseUrl.isEmpty) &&
                    (userModelName == null || userModelName.isEmpty);
    
    setState(() {
      _enabled = config.enabled;
      _baseUrlController.text = config.baseUrl;
      _apiKeyController.text = userApiKey ?? '';
      _modelNameController.text = config.modelName;
      _temperatureController.text = config.temperature.toStringAsFixed(1);
      _maxTokensController.text = config.maxTokens.toString();
      _systemPromptController.text = config.systemPrompt ?? '';
    });
  }

  Future<void> _saveConfig() async {
    if (_isSaving) return;
    
    setState(() { _isSaving = true; });

    try {
      // 获取 API Key（优先用户设置，否则使用内置）
      String? apiKey;
      if (_apiKeyController.text.trim().isNotEmpty) {
        apiKey = _apiKeyController.text.trim();
        await SecureStorage.instance.saveApiKey(apiKey);
      } else {
        apiKey = await SecureStorage.instance.getApiKey(); // 回退到内置
      }

      // 获取 Base URL（优先用户设置，否则使用内置）
      String? baseUrl;
      if (_baseUrlController.text.trim().isNotEmpty) {
        baseUrl = _baseUrlController.text.trim();
        await SecureStorage.instance.saveBaseUrl(baseUrl);
      } else {
        baseUrl = await SecureStorage.instance.getBaseUrl(); // 回退到内置
      }

      // 获取 Model Name（优先用户设置，否则使用内置）
      String? modelName;
      if (_modelNameController.text.trim().isNotEmpty) {
        modelName = _modelNameController.text.trim();
        await SecureStorage.instance.saveModelName(modelName);
      } else {
        modelName = await SecureStorage.instance.getModelName(); // 回退到内置
      }

      if (apiKey == null || baseUrl == null || modelName == null) {
        throw Exception('大模型配置不完整，请检查');
      }

      final config = LlmConfig(
        provider: 'openai',
        baseUrl: baseUrl,
        modelName: modelName,
        temperature: double.tryParse(_temperatureController.text) ?? 0.3,
        maxTokens: int.tryParse(_maxTokensController.text) ?? 200,
        enabled: _enabled,
        systemPrompt: _systemPromptController.text.trim().isEmpty
            ? null
            : _systemPromptController.text.trim(),
      );

      await _db.saveConfig(config);
      await SecureStorage.instance.saveLlmEnabled(_enabled);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('配置已保存成功${apiKey != _apiKeyController.text.trim() ? '（使用内置 API Key）' : ''}'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Text('保存失败：${e.toString()}'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
    
    // 在状态重置后再测试连接
    if (mounted) {
      await _testConnection();
    }
  }

  Future<void> _testConnection() async {
    setState(() { _isTesting = true; _testResult = null; });

    // 获取 API Key（优先用户设置，否则使用内置）
    String? apiKey;
    if (_apiKeyController.text.trim().isNotEmpty) {
      apiKey = _apiKeyController.text.trim();
    } else {
      apiKey = await SecureStorage.instance.getApiKey();
    }

    // 获取 Base URL（优先用户设置，否则使用内置）
    String? baseUrl;
    if (_baseUrlController.text.trim().isNotEmpty) {
      baseUrl = _baseUrlController.text.trim();
    } else {
      baseUrl = await SecureStorage.instance.getBaseUrl();
    }

    // 获取 Model Name（优先用户设置，否则使用内置）
    String? modelName;
    if (_modelNameController.text.trim().isNotEmpty) {
      modelName = _modelNameController.text.trim();
    } else {
      modelName = await SecureStorage.instance.getModelName();
    }

    if (apiKey == null || baseUrl == null || modelName == null) {
      setState(() {
        _isTesting = false;
        _testResult = '错误：大模型配置不完整，请先填写或使用内置配置';
      });
      return;
    }

    final config = LlmConfig(
      provider: 'openai',
      baseUrl: baseUrl,
      modelName: modelName,
    );

    final result = await LlmService.testConnection(
      config, apiKey: apiKey,
    );

    setState(() {
      _isTesting = false;
      _testResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('大模型配置'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 开关
            SwitchListTile(
              title: const Text('启用大模型'),
              subtitle: const Text('开启后，每次输入将由大模型自动分类和摘要'),
              value: _enabled,
              onChanged: (val) => setState(() { _enabled = val; }),
              secondary: const Icon(Icons.smart_toy),
            ),
            const Divider(),

            // 提示当前配置状态
            if (_usingBuiltin)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          '未配置大模型',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '当前将使用内置的 SiliconFlow 大模型（Qwen/Qwen3-8B）。\n'
                      '你也可以在下方填写自己的 API 配置来覆盖内置配置。',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),

            // API 配置
            const Text('API 配置', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),

            TextField(
              controller: _baseUrlController,
              decoration: InputDecoration(
                labelText: 'API 地址',
                hintText: _usingBuiltin ? '留空使用内置配置（SiliconFlow）' : 'https://api.openai.com/v1',
                prefixIcon: const Icon(Icons.link),
                border: const OutlineInputBorder(),
                helperText: _usingBuiltin ? '可选：留空将使用内置 SiliconFlow API' : null,
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: _usingBuiltin ? '留空使用内置配置' : 'sk-xxxxxxxxxxxxxxxxxxxx',
                prefixIcon: const Icon(Icons.key),
                border: const OutlineInputBorder(),
                helperText: _usingBuiltin ? '可选：留空将使用内置 API Key' : null,
              ),
              maxLines: 1,
              obscureText: true,
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _modelNameController,
              decoration: InputDecoration(
                labelText: '模型名称',
                hintText: _usingBuiltin ? '留空使用内置配置（Qwen/Qwen3-8B）' : 'gpt-4o-mini',
                prefixIcon: const Icon(Icons.model_training),
                border: const OutlineInputBorder(),
                helperText: _usingBuiltin ? '可选：留空将使用内置模型' : null,
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 20),

            // 高级配置
            const Text('高级设置', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _temperatureController,
                    decoration: const InputDecoration(
                      labelText: 'Temperature',
                      hintText: '0.3',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 1,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxTokensController,
                    decoration: const InputDecoration(
                      labelText: 'Max Tokens',
                      hintText: '200',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 1,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _systemPromptController,
              decoration: const InputDecoration(
                labelText: '系统提示词（可选）',
                hintText: '你是专业的信息分类助手...',
                prefixIcon: Icon(Icons.message),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // 测试按钮
            ElevatedButton.icon(
              icon: _isTesting
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.science),
              label: Text(_isTesting ? '测试中...' : '测试连接'),
              onPressed: _isTesting ? null : _testConnection,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.purple,
              ),
            ),
            const SizedBox(height: 12),

            // 测试结果
            if (_testResult != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _testResult!.startsWith('连接成功')
                      ? Colors.green[50]
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _testResult!.startsWith('连接成功')
                        ? Colors.green[200]!
                        : Colors.red[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testResult!.startsWith('连接成功')
                          ? Icons.check_circle
                          : Icons.error,
                      color: _testResult!.startsWith('连接成功')
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testResult!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // 保存按钮
            ElevatedButton.icon(
              icon: _isSaving
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(_isSaving ? '保存中...' : '保存配置'),
              onPressed: _isSaving ? null : _saveConfig,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 20),

            // 使用说明
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, size: 18),
                      SizedBox(width: 8),
                      Text('使用说明', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildTip('支持 OpenAI 兼容接口（OpenAI、DeepSeek、通义千问等）'),
                  _buildTip('已集成 SiliconFlow 大模型作为默认配置（Qwen/Qwen3-8B）'),
                  _buildTip('留空 API 字段将自动使用内置配置，填写后则使用自定义配置'),
                  _buildTip('所有敏感信息均已加密存储，不会明文显示'),
                  _buildTip('大模型不可用时会自动降级为本地关键词分类'),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.blue[700], fontSize: 12)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12, height: 1.5)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelNameController.dispose();
    _temperatureController.dispose();
    _maxTokensController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }
}
