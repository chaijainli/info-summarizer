class ClassificationResult {
  final String category;
  final List<String> matchedKeywords;
  final bool isFromLlm;

  ClassificationResult({
    required this.category,
    required this.matchedKeywords,
    this.isFromLlm = false,
  });
}