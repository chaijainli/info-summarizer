import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _dbHelper = DatabaseHelper.instance;

  final Map<String, int> _categoryCounts = {};
  bool _isLoading = true;

  // 内置分类及颜色
  final Map<String, Color> _builtInCategories = {
    '工作': Colors.blue,
    '生活': Colors.green,
    '学习': Colors.purple,
    '财务': Colors.orange,
    '健康': Colors.red,
    '兴趣': Colors.teal,
    '其他': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final cats = await _dbHelper.getCategories();
    setState(() {
      for (var c in cats) {
        _categoryCounts[c['category']] = c['count'];
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分类统计'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 总数统计
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: _builtInCategories.entries.map((entry) {
                int count = _categoryCounts[entry.key] ?? 0;
                return Expanded(
                  child: _buildStatCard(entry.key, count, entry.value),
                );
              }).toList(),
            ),
          ),
          const Divider(),

          // 分类卡片列表
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _builtInCategories.length,
                      itemBuilder: (context, index) {
                        String cat = _builtInCategories.keys.elementAt(index);
                        Color color = _builtInCategories[cat]!;
                        int count = _categoryCounts[cat] ?? 0;
                        return _buildCategoryListTile(cat, count, color);
                      },
                    ),
            ),
          ),

          // 底部操作
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('完成查看'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String category, int count, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(
            category,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryListTile(String category, int count, Color color) {
    String description = _getCategoryDescription(category);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(
            category[0],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count 条',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        onTap: () {
          Navigator.pop(context, category);
        },
      ),
    );
  }

  String _getCategoryDescription(String category) {
    switch (category) {
      case '工作':
        return '会议、任务、项目、代码、产品、客户等';
      case '生活':
        return '吃饭、逛街、旅行、聚会、购物等';
      case '学习':
        return '读书、课程、考试、笔记、技术等';
      case '财务':
        return '工资、报销、账单、投资、理财等';
      case '健康':
        return '看病、体检、睡眠、血压、运动等';
      case '兴趣':
        return '游戏、音乐、视频、摄影、手工等';
      default:
        return '无法归类的其他信息';
    }
  }
}