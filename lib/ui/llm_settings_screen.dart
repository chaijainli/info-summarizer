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
  final _temperatureController = TextEditingController();
  final _maxTokensController = TextEditingController();
  final _systemPromptController = TextEditingController();

  final _db = LlmConfigDb.instance;
  bool _enabled = false;
  bool _isTesting = false;
  bool _isSaving = false;
  String? _testResult;

  // 内置配置（不可见，但用于保存和测试）
  late Future<String?> _builtinApiKeyFuture;
  late Future<String?> _builtinBaseUrlFuture;
  late Future<String?> _builtinModelFuture;

  @override
  void initState() {
    super.initState();
    _loadBuiltinConfigs();
    _loadConfig();
  }

  void _loadBuiltinConfigs() {
    _builtinApiKeyFuture = SecureStorage.instance.getApiKey();
    _builtinBaseUrlFuture = SecureStorage.instance.getBaseUrl();
    _builtinModelFuture = SecureStorage.instance.getModelName();
  }

  Future<void> _loadConfig() async {
    final config = await _db.getConfig();
    setState(() {
      _enabled = config.enabled;
      _temperatureController.text = config.temperature.toStringAsFixed(1);
      _maxTokensController.text = config.maxTokens.toString();
      _systemPromptController.text = config.systemPrompt ?? '';
    });
  }

  Future<void> _saveConfig() async {
    if (_isSaving) return;
    
    setState(() { _isSaving = true; });

    try {
      final apiKey = await _builtinApiKeyFuture;
      final baseUrl = await _builtinBaseUrlFuture;
      final modelName = await _builtinModelFuture;

      if (apiKey == null || baseUrl == null || modelName == null) {
        throw Exception('内置大模型配置未正确加载');
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
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('配置已保存成功'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
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

    final apiKey = await _builtinApiKeyFuture;
    final baseUrl = await _builtinBaseUrlFuture;
    final modelName = await _builtinModelFuture;

    if (apiKey == null || baseUrl == null || modelName == null) {
      setState(() {
        _isTesting = false;
        _testResult = '错误：内置大模型配置未正确加载';
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

            // 内置信息提示
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
                      Icon(Icons.lock_outline, size: 18, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        '已集成 SiliconFlow 大模型',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'API 地址、密钥和模型 ID 已加密内置，无需手动配置。',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

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
                  _buildTip('已集成 SiliconFlow 大模型服务（Qwen/Qwen3-8B）'),
                  _buildTip('所有敏感信息均已加密存储，不会明文显示'),
                  _buildTip('开启后每次保存记录时自动调用大模型分类和摘要'),
                  _buildTip('大模型不可用时会自动降级为本地关键词分类'),
                  _buildTip('可自定义 Temperature、Max Tokens 等参数'),
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
    _temperatureController.dispose();
    _maxTokensController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }
}
