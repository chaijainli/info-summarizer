import '../models/record_model.dart';

class SearchMatch {
  final InfoRecord record;
  final double relevance; // 0.0 ~ 1.0
  final List<String> matchedKeywords;

  SearchMatch({
    required this.record,
    required this.relevance,
    required this.matchedKeywords,
  });
}

class FuzzySearch {
  /// 模糊搜索：多关键词匹配 + 相关性评分
  /// 空格分隔多个关键词，记录包含的关键词越多，relevance 越高
  static List<SearchMatch> search(
    List<InfoRecord> records,
    String query,
  ) {
    if (query.isEmpty) {
      return records.map((r) => SearchMatch(
        record: r,
        relevance: 1.0,
        matchedKeywords: [],
      )).toList();
    }

    // 按空格分词
    final keywords = query
        .split(RegExp(r'\s+'))
        .where((k) => k.isNotEmpty)
        .toList();

    if (keywords.isEmpty) {
      return records.map((r) => SearchMatch(
        record: r,
        relevance: 1.0,
        matchedKeywords: [],
      )).toList();
    }

    final results = <SearchMatch>[];

    for (var record in records) {
      final searchableText =
          '${record.title} ${record.content} ${record.summary} ${record.category}'.toLowerCase();

      final matched = <String>[];
      for (var kw in keywords) {
        if (searchableText.contains(kw.toLowerCase())) {
          matched.add(kw);
        }
      }

      if (matched.isNotEmpty) {
        final relevance = matched.length / keywords.length;
        results.add(SearchMatch(
          record: record,
          relevance: relevance,
          matchedKeywords: matched,
        ));
      }
    }

    // 按相关性降序排列
    results.sort((a, b) => b.relevance.compareTo(a.relevance));
    return results;
  }

  /// 高亮文本：给匹配关键词加 HTML 标签
  static String highlight(String text, List<String> keywords) {
    if (keywords.isEmpty || text.isEmpty) return text;

    String result = text;
    for (var kw in keywords) {
      if (kw.isEmpty) continue;
      result = result.replaceAll(
        RegExp(RegExp.escape(kw), caseSensitive: false),
        '<mark>$kw</mark>',
      );
    }
    return result;
  }

  /// 统计高频词（用于搜索建议）
  static Map<String, int> getTopKeywords(List<InfoRecord> records, {int limit = 20}) {
    final wordCount = <String, int>{};

    for (var record in records) {
      // 对分类和标题做简单分词
      final tokens = _tokenize('${record.category} ${record.title}');
      for (var token in tokens) {
        if (token.length >= 2) {
          wordCount[token] = (wordCount[token] ?? 0) + 1;
        }
      }
    }

    final sorted = wordCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final result = <String, int>{};
    for (int i = 0; i < sorted.length && i < limit; i++) {
      result[sorted[i].key] = sorted[i].value;
    }
    return result;
  }

  /// 简单中文分词（按 2-4 字切分）
  static List<String> _tokenize(String text) {
    final tokens = <String>[];
    for (int i = 0; i <= text.length - 2; i++) {
      final two = text.substring(i, i + 2);
      if (_isChinese(two[0]) && _isChinese(two[1])) {
        tokens.add(two);
        if (i + 3 <= text.length && _isChinese(text[i + 2]) && _isChinese(text[i + 3])) {
          tokens.add(text.substring(i, i + 4));
        } else if (i + 3 <= text.length && _isChinese(text[i + 2])) {
          tokens.add(text.substring(i, i + 3));
        }
      }
    }
    return tokens;
  }

  static bool _isChinese(String ch) {
    final code = ch.codeUnitAt(0);
    return code > 0x4E00 && code < 0x9FFF;
  }
}