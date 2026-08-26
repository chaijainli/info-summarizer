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

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await _db.getConfig();
    final apiKey = await SecureStorage.instance.getApiKey() ?? '';
    setState(() {
      _enabled = config.enabled;
      _baseUrlController.text = config.baseUrl;
      _apiKeyController.text = apiKey;
      _modelNameController.text = config.modelName;
      _temperatureController.text = config.temperature.toStringAsFixed(1);
      _maxTokensController.text = config.maxTokens.toString();
      _systemPromptController.text = config.systemPrompt ?? '';
    });
  }

  Future<void> _saveConfig() async {
    setState(() { _isSaving = true; });

    final config = LlmConfig(
      provider: 'openai',
      baseUrl: _baseUrlController.text.trim(),
      modelName: _modelNameController.text.trim(),
      temperature: double.tryParse(_temperatureController.text) ?? 0.3,
      maxTokens: int.tryParse(_maxTokensController.text) ?? 200,
      enabled: _enabled,
      systemPrompt: _systemPromptController.text.trim().isEmpty
          ? null
          : _systemPromptController.text.trim(),
    );

    await _db.saveConfig(config);

    // API Key 使用加密存储
    await SecureStorage.instance.saveApiKey(_apiKeyController.text.trim());
    await SecureStorage.instance.saveLlmEnabled(_enabled);

    setState(() {
      _isSaving = false;
      _testResult = null;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('配置已保存（API Key 已加密）'), duration: Duration(seconds: 2))
    );
  }

  Future<void> _testConnection() async {
    setState(() { _isTesting = true; _testResult = null; });

    final config = LlmConfig(
      provider: 'openai',
      baseUrl: _baseUrlController.text.trim(),
      modelName: _modelNameController.text.trim(),
    );

    final result = await LlmService.testConnection(
      config, apiKey: _apiKeyController.text.trim(),
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

            // 基础配置
            const Text('API 配置', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),

            TextField(
              controller: _baseUrlController,
              decoration: const InputDecoration(
                labelText: 'API 地址',
                hintText: 'https://api.openai.com/v1',
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'sk-xxxxxxxxxxxxxxxxxxxx',
                prefixIcon: Icon(Icons.key),
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
              obscureText: true,
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _modelNameController,
              decoration: const InputDecoration(
                labelText: '模型名称',
                hintText: 'gpt-4o-mini',
                prefixIcon: Icon(Icons.model_training),
                border: OutlineInputBorder(),
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
                hintText: '你是专业的信息分类助手，擅长分析用户输入...',
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
                  _buildTip('Base URL 填入模型 API 地址，如 https://api.openai.com/v1'),
                  _buildTip('API Key 仅存储在本地设备，不会上传到任何服务器'),
                  _buildTip('开启后每次保存记录时自动调用大模型分类和摘要'),
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