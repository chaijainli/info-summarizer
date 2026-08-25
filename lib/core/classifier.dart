class ClassificationResult {
  final String category;
  final List<String> matchedKeywords;

  ClassificationResult({required this.category, required this.matchedKeywords});
}

class AutoClassifier {
  static const String defaultCategory = '其他';

  Map<String, List<String>> rules = {
    '工作': ['工作', '会议', '任务', '项目', '需求', '代码', 'bug', '上线', '部署', '开发', '产品', '客户', '合同', '邮件', '周报', 'OKR', 'KPI', 'deadline'],
    '生活': ['吃饭', '超市', '逛街', '电影', '旅行', '旅游', '运动', '健身', '休息', '朋友', '聚会', '购物', '做饭', '装修'],
    '学习': ['学习', '读书', '课程', '考试', '笔记', '论文', '技术', '编程', '算法', '知识', '考证'],
    '财务': ['钱', '工资', '报销', '账单', '信用卡', '储蓄', '投资', '股票', '基金', '理财', '收入', '支出', '转账'],
    '健康': ['健康', '看病', '医院', '吃药', '体检', '睡眠', '血压', '血糖', '牙', '发烧', '运动', '锻炼'],
    '兴趣': ['游戏', '音乐', '视频', '追剧', '追星', '绘画', '手工', '摄影', '美食'],
  };

  ClassificationResult classify(String text) {
    if (text.isEmpty) {
      return ClassificationResult(category: defaultCategory, matchedKeywords: []);
    }

    Map<String, int> scores = {};
    Map<String, List<String>> matchedKeywordsMap = {};

    for (var entry in rules.entries) {
      int score = 0;
      List<String> hits = [];
      for (var keyword in entry.value) {
        if (text.contains(keyword)) {
          score++;
          hits.add(keyword);
        }
      }
      if (score > 0) {
        scores[entry.key] = score;
        matchedKeywordsMap[entry.key] = hits;
      }
    }

    if (scores.isEmpty) {
      return ClassificationResult(category: defaultCategory, matchedKeywords: []);
    }

    String bestCategory = scores.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    ).key;

    return ClassificationResult(
      category: bestCategory,
      matchedKeywords: matchedKeywordsMap[bestCategory] ?? [],
    );
  }

  void addRule(String category, List<String> keywords) {
    if (rules.containsKey(category)) {
      rules[category]!.addAll(keywords);
    } else {
      rules[category] = keywords;
    }
  }

  void removeRule(String category) {
    rules.remove(category);
  }

  List<String> get categories => rules.keys.toList();
}