import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/record_model.dart';
import '../database/db_helper.dart';
import 'home_screen.dart';

class DetailScreen extends StatefulWidget {
  final int recordId;

  const DetailScreen({super.key, required this.recordId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _dbHelper = DatabaseHelper.instance;
  InfoRecord? _record;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecord();
  }

  Future<void> _loadRecord() async {
    final record = await _dbHelper.getRecordById(widget.recordId);
    setState(() {
      _record = record;
      _isLoading = false;
    });
  }

  Color _categoryColor(String category) {
    switch (category) {
      case '工作': return Colors.blue;
      case '生活': return Colors.green;
      case '学习': return Colors.purple;
      case '财务': return Colors.orange;
      case '健康': return Colors.red;
      case '兴趣': return Colors.teal;
      default: return Colors.grey;
    }
  }

  Future<void> _deleteRecord() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条记录吗？此操作不可恢复。'),
        actions: [
          TextButton(child: const Text('取消'), onPressed: () => Navigator.pop(context, false)),
          TextButton(
            child: const Text('删除', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteRecord(widget.recordId);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (c) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _shareRecord() async {
    if (_record == null) return;
    String shareText = '【${_record!.title}】\n\n摘要：${_record!.summary}\n\n原文：${_record!.content}\n\n分类：${_record!.category}';
    // 可通过 share_plus 实现系统分享
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('内容已复制，可手动分享：\n${_record!.summary}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_record == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('记录详情')),
        body: const Center(child: Text('记录不存在或已被删除')),
      );
    }

    final record = _record!;

    return Scaffold(
      appBar: AppBar(
        title: Text(record.title),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _shareRecord),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteRecord,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 分类标签
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _categoryColor(record.category),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    record.category,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '创建于 ${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.parse(record.createdAt))}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const Divider(height: 24),

            // 摘要区域
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.summarize, size: 18),
                      const SizedBox(width: 8),
                      const Text('智能摘要', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    record.summary,
                    style: const TextStyle(fontSize: 14, height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 原文区域
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.article, size: 18),
                      const SizedBox(width: 8),
                      const Text('原始内容', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    record.content,
                    style: const TextStyle(fontSize: 14, height: 1.7),
                    maxLines: null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 底部操作
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('返回记录页面'),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}