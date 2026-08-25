class TextSummarizer {
  final Set<String> fillerWords = {
    '的', '了', '是', '在', '有', '和', '就', '都', '也', '很', '要', '会',
    '不', '我', '你', '他', '她', '它', '们', '这', '那', '这个', '那个',
    '一个', '一些', '一下', '比较', '确实', '大概', '可能', '应该',
    '嗯', '啊', '哦', '哈', '嘿', '呀', '呢', '吧', '嘛',
    '其实', '然后', '所以', '但是', '因为', '如果', '虽然', '或者',
    '而且', '另外', '总之', '基本上',
  };

  /// 精简文本：去除冗余行、清理行首序号、合并多余空格
  String summarize(String text, {int? maxLength}) {
    if (text.isEmpty) return '';

    List<String> lines = text.split('\n');

    // 去空行和纯标点行
    lines = lines
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !_isNoiseLine(l))
        .toList();

    // 清理每行
    List<String> cleanedLines = [];
    for (var line in lines) {
      String cleaned = _cleanLine(line);
      if (cleaned.isNotEmpty) {
        cleanedLines.add(cleaned);
      }
    }

    String result = cleanedLines.join('\n');

    // 超长截断
    if (maxLength != null && result.length > maxLength) {
      result = _extractKeySentences(result, maxLength);
    }

    return result;
  }

  /// 从文本中提取标题
  String extractTitle(String text, {int maxLength = 20}) {
    if (text.isEmpty) return '未命名记录';

    List<String> lines = text.split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    String firstLine = lines.isNotEmpty ? lines.first : text;

    // 去掉行首序号
    RegExp numPattern = RegExp(r'^[\d一二三四五六七八九十]+[\.、\s．]+');
    RegExp cnNumPattern = RegExp(r'^[（(][\d一二三四五六七八九十]+[）)]\s*');
    firstLine = firstLine.replaceFirst(numPattern, '');
    firstLine = firstLine.replaceFirst(cnNumPattern, '');

    String title = firstLine.trim();

    if (title.length > maxLength) {
      title = title.substring(0, maxLength) + '…';
    }

    return title.isNotEmpty ? title : '未命名记录';
  }

  bool _isNoiseLine(String line) {
    if (line.length <= 1) return true;
    RegExp noisePattern = RegExp(r'^[。\s\-_=/★☆●○★☆※]+$', caseSensitive: false);
    return noisePattern.hasMatch(line);
  }

  String _cleanLine(String line) {
    // 去掉行首装饰符
    RegExp prefixPattern = RegExp(r'^[\s\-\*_=:|]+');
    RegExp suffixPattern = RegExp(r'[\s\-\*_=:|]+$');
    line = line.replaceFirst(prefixPattern, '');
    line = line.replaceFirst(suffixPattern, '');

    // 去掉序号
    line = line.replaceFirst(
      RegExp(r'^[\d一二三四五六七八九十]+[\.、\s．]+'), '');
    line = line.replaceFirst(
      RegExp(r'^[（(][\d一二三四五六七八九十]+[）)]\s*'), '');

    // 合并多余空格
    line = line.replaceAll(RegExp(r'\s+'), ' ').trim();

    return line;
  }

  String _extractKeySentences(String text, int maxLength) {
    List<String> sentences =
        text.split(RegExp(r'(?<=[。！？!?.])\s*'));

    if (sentences.length <= 1) {
      return text.length > maxLength ? text.substring(0, maxLength) + '…' : text;
    }

    int keepCount = (sentences.length / 2).ceil();
    keepCount = keepCount > 1 ? keepCount : 1;

    String result = sentences.sublist(0, keepCount).join('');
    return result.length > maxLength ? result.substring(0, maxLength) + '…' : result;
  }
}