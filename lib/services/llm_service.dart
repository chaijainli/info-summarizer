import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/llm_config_model.dart';
import '../core/classification_result.dart';

class LlmService {
  /// 调用 LLM 对文本进行分类
  static Future<ClassificationResult?> classifyWithLlm(
    LlmConfig config,
    String text,
    List<String> availableCategories, {
    String apiKey = '',
  }) async {
    if (apiKey.isEmpty) return null;
    final prompt = _buildClassifyPrompt(text, availableCategories);
    return _callLlm(config, prompt, apiKey: apiKey);
  }

  /// 调用 LLM 对文本进行精简摘要
  static Future<String?> summarizeWithLlm(
    LlmConfig config,
    String text, {
    String apiKey = '',
  }) async {
    if (apiKey.isEmpty) return null;
    final prompt = _buildSummarizePrompt(text);
    final result = await _callLlmRaw(config, prompt, apiKey: apiKey);
    return result;
  }

  /// 调用 LLM 提取 10 字以内标题
  static Future<String?> extractTitleWithLlm(
    LlmConfig config,
    String text, {
    String apiKey = '',
  }) async {
    if (apiKey.isEmpty) return null;
    final prompt = _buildTitlePrompt(text);
    final result = await _callLlmRaw(config, prompt, apiKey: apiKey);
    if (result == null || result.trim().isEmpty) return null;
    return result.trim();
  }

  /// 测试 API 连通性
  static Future<String> testConnection(
    LlmConfig config, {
    String apiKey = '',
  }) async {
    if (apiKey.isEmpty) {
      return 'API Key 不能为空';
    }

    final url = Uri.parse('${config.baseUrl.trim()}/chat/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      'model': config.modelName,
      'messages': [
        {'role': 'system', 'content': 'You are a helpful assistant.'},
        {'role': 'user', 'content': '说你好'},
      ],
      'max_tokens': 10,
    });

    try {
      final response = await http.post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return '连接成功，模型 ${config.modelName} 可用';
      } else {
        final error = _parseError(response);
        return '请求失败 (${response.statusCode}): $error';
      }
    } catch (e) {
      return '连接失败: ${e.toString()}';
    }
  }

  /// 调用 LLM，返回 ClassificationResult
  static Future<ClassificationResult?> _callLlm(
    LlmConfig config,
    String prompt, {
    required String apiKey,
  }) async {
    final raw = await _callLlmRaw(config, prompt, apiKey: apiKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final data = jsonDecode(raw);
      final category = data['category']?.toString() ?? '';
      if (category.isNotEmpty) {
        return ClassificationResult(category: category, matchedKeywords: []);
      }
    } catch (_) {
      final text = raw.trim().replaceAll('`', '');
      return ClassificationResult(category: text, matchedKeywords: []);
    }
    return null;
  }

  /// 调用 LLM，返回原始文本
  static Future<String?> _callLlmRaw(
    LlmConfig config,
    String prompt, {
    required String apiKey,
  }) async {
    final url = Uri.parse('${config.baseUrl.trim()}/chat/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final messages = <Map<String, String>>[];
    if (config.systemPrompt?.isNotEmpty == true) {
      messages.add({'role': 'system', 'content': config.systemPrompt!});
    }
    messages.add({'role': 'user', 'content': prompt});

    final body = jsonEncode({
      'model': config.modelName,
      'messages': messages,
      'temperature': config.temperature,
      'max_tokens': config.maxTokens,
    });

    try {
      final response = await http.post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final choices = data['choices'] as List?;
        if (choices?.isNotEmpty ?? false) {
          return choices![0]['message']?['content'] ?? '';
        }
        return null;
      } else {
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  /// 构建分类提示词
  static String _buildClassifyPrompt(
    String text,
    List<String> categories,
  ) {
    final categoryList = categories.join('、');
    return '''你是一个信息分类助手。根据用户输入的文本，判断它属于以下哪个分类：
$categoryList

要求：
1. 只从上述分类中选择一个最匹配的
2. 如果都不匹配，返回"其他"
3. 只输出 JSON 格式，不要其他文字

格式：
{"category": "分类名"}

待分类文本：
$text''';
  }

  /// 构建摘要提示词
  static String _buildSummarizePrompt(String text) {
    return '''你是一个专业的文本摘要助手。请对以下用户输入的信息进行精简摘要。

要求：
1. 提炼核心要点，去掉冗余、口语化表达
2. 保持原意，不要编造信息
3. 输出简洁的摘要文本，不超过100字
4. 只输出摘要内容，不要其他解释

原始文本：
$text''';
  }

  /// 构建标题提取提示词
  static String _buildTitlePrompt(String text) {
    return '''你是一个专业的标题生成助手。请根据以下文本的全部内容，提炼一个简洁标题。

要求：
1. 综合全文内容，不要只看第一行
2. 标题不超过10个汉字
3. 概括核心信息，言简意赅
4. 只输出标题文字，不要引号、不要其他解释

原始文本：
$text''';
  }

  /// 解析错误信息
  static String _parseError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      final error = data['error'] as Map<String, dynamic>?;
      return error?['message']?.toString() ?? '未知错误';
    } catch (_) {
      return response.body;
    }
  }
}