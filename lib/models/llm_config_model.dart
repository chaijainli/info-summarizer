class LlmConfig {
  final String provider;
  final String baseUrl;
  final String apiKey;
  final String modelName;
  final double temperature;
  final int maxTokens;
  final bool enabled;
  final String? systemPrompt;

  LlmConfig({
    required this.provider,
    required this.baseUrl,
    required this.apiKey,
    required this.modelName,
    this.temperature = 0.3,
    this.maxTokens = 200,
    this.enabled = false,
    this.systemPrompt,
  });

  Map<String, dynamic> toMap() {
    return {
      'provider': provider,
      'base_url': baseUrl,
      'api_key': apiKey,
      'model_name': modelName,
      'temperature': temperature,
      'max_tokens': maxTokens,
      'enabled': enabled ? 1 : 0,
      'system_prompt': systemPrompt ?? '',
    };
  }

  factory LlmConfig.fromMap(Map<String, dynamic> map) {
    return LlmConfig(
      provider: map['provider'] ?? 'openai',
      baseUrl: map['base_url'] ?? '',
      apiKey: map['api_key'] ?? '',
      modelName: map['model_name'] ?? '',
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.3,
      maxTokens: (map['max_tokens'] as int?) ?? 200,
      enabled: (map['enabled'] as int?) == 1,
      systemPrompt: map['system_prompt']?.isNotEmpty == true
          ? map['system_prompt']
          : null,
    );
  }

  factory LlmConfig.empty() {
    return LlmConfig(
      provider: 'openai',
      baseUrl: 'https://api.openai.com/v1',
      apiKey: '',
      modelName: 'gpt-4o-mini',
    );
  }
}