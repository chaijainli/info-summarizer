import 'package:flutter/material.dart';
import '../models/record_model.dart';
import '../database/db_helper.dart';
import '../core/classifier.dart';
import '../core/summarizer.dart';
import 'history_screen.dart';
import 'detail_screen.dart';
import 'category_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _dbHelper = DatabaseHelper.instance;
  final _classifier = AutoClassifier();
  final _summarizer = TextSummarizer();

  String _autoCategory = '其他';
  List<String> _matchedKeywords = [];
  List<InfoRecord> _recentRecords = [];
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadRecentRecords();
  }

  Future<void> _loadRecentRecords() async {
    final records = await _dbHelper.getAllRecords();
    setState(() {
      _recentRecords = records.take(10).toList();
    });
  }

  void _onContentChanged(String text) {
    final result = _classifier.classify(text);
    if (_autoCategory != result.category) {
      setState(() {
        _autoCategory = result.category;
        _matchedKeywords = result.matchedKeywords;
      });
    }
  }

  Future<void> _saveRecord() async {
    String content = _contentController.text.trim();
    if (content.isEmpty) {
      _showSnackBar('请输入内容后再保存');
      return;
    }

    setState(() { _isSaving = true; });

    String title = _titleController.text.trim().isEmpty
        ? _summarizer.extractTitle(content)
        : _titleController.text.trim();

    String summary = _summarizer.summarize(content, maxLength: 200);
    String now = DateTime.now().toIso8601String();

    final record = InfoRecord(
      title: title,
      content: content,
      summary: summary,
      category: _autoCategory,
      createdAt: now,
      updatedAt: now,
    );

    await _dbHelper.insertRecord(record);

    setState(() {
      _isSaving = false;
      _titleController.clear();
      _contentController.clear();
      _autoCategory = '其他';
      _matchedKeywords = [];
    });

    _loadRecentRecords();
    _showSnackBar('已保存 · 分类：$_autoCategory');
  }

  Future<void> _shareRecord() async {
    String content = _contentController.text.trim();
    if (content.isEmpty) return;

    String summary = _summarizer.summarize(content, maxLength: 300);
    String shareText = '【信息摘要】\n$summary\n\n[分类：$_autoCategory]';
    // share_plus 可在此使用 Share.share(shareText)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('摘要已生成，可通过系统分享按钮发送'))
    );
  }

  Future<void> _editCategory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (c) => const CategoryScreen()),
    );
    if (result != null && result is String) {
      setState(() {
        _autoCategory = result;
        _matchedKeywords = [];
      });
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('信息记录助手'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: '历史记录',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const HistoryScreen()),
              ).then((_) => _loadRecentRecords());
            },
          ),
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: '分类管理',
            onPressed: _editCategory,
          ),
        ],
      ),
      body: Column(
        children: [
          // 输入区域
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: '标题（可选，留空自动提取）',
                      prefixIcon: Icon(Icons.title),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      labelText: '请输入要记录的信息...',
                      hintText: '随意输入，系统将自动分类并精简',
                      prefixIcon: Icon(Icons.note),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 8,
                    minLines: 4,
                    onChanged: _onContentChanged,
                  ),
                  const SizedBox(height: 12),

                  // 自动分类结果展示
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, size: 18),
                        const SizedBox(width: 8),
                        Text('自动分类：', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        _buildCategoryChip(_autoCategory),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _matchedKeywords.isNotEmpty
                              ? Text(
                                  '关键词：${_matchedKeywords.join(", ")}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 操作按钮
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text('保存记录'),
                          onPressed: _isSaving ? null : _saveRecord,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.share),
                          label: const Text('分享'),
                          onPressed: _shareRecord,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 最近记录预览
          if (_recentRecords.isNotEmpty)
            Container(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.history, size: 16),
                        const SizedBox(width: 6),
                        const Text('最近记录', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        TextButton(
                          child: const Text('查看全部'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (c) => const HistoryScreen()),
                            ).then((_) => _loadRecentRecords());
                          },
                        ),
                      ],
                    ),
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _recentRecords.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final record = _recentRecords[index];
                      return _buildMiniRecordCard(record);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const HistoryScreen()),
          ).then((_) => _loadRecentRecords());
        },
        child: const Icon(Icons.history),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    Color bgColor;
    switch (category) {
      case '工作': bgColor = Colors.blue[100]!; break;
      case '生活': bgColor = Colors.green[100]!; break;
      case '学习': bgColor = Colors.purple[100]!; break;
      case '财务': bgColor = Colors.orange[100]!; break;
      case '健康': bgColor = Colors.red[100]!; break;
      case '兴趣': bgColor = Colors.teal[100]!; break;
      default: bgColor = Colors.grey[100]!; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMiniRecordCard(InfoRecord record) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (c) => DetailScreen(recordId: record.id!),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            _buildCategoryChip(record.category),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    record.summary,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              record.createdAt.substring(0, 10),
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}