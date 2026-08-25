import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/record_model.dart';
import '../database/db_helper.dart';
import '../core/fuzzy_search.dart';
import '../utils/debounce.dart';
import 'detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _dbHelper = DatabaseHelper.instance;
  final _searchFocus = FocusNode();
  final _searchDebouncer = SearchDebouncer();
  final _suggestionCache = SearchSuggestionCache();

  List<InfoRecord> _allRecords = [];
  List<SearchMatch> _searchResults = [];
  String _searchQuery = '';
  String _displayQuery = '';
  String _filterCategory = '';
  String _filterPeriod = '全部';
  bool _isLoading = true;

  final List<String> _periods = ['全部', '今天', '最近7天', '最近30天'];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() { _isLoading = true; });
    final records = await _dbHelper.getAllRecords();
    setState(() {
      _allRecords = records;
      _applyFilters();
      _isLoading = false;
    });
  }

  void _applyFilters() {
    List<InfoRecord> filtered = _allRecords;

    // 按分类筛选
    if (_filterCategory.isNotEmpty) {
      filtered = filtered.where((r) => r.category == _filterCategory).toList();
    }

    // 按时间筛选
    if (_filterPeriod != '全部') {
      final now = DateTime.now();
      DateTime cutoff;
      switch (_filterPeriod) {
        case '今天':
          cutoff = DateTime(now.year, now.month, now.day);
          break;
        case '最近7天':
          cutoff = now.subtract(const Duration(days: 7));
          break;
        case '最近30天':
          cutoff = now.subtract(const Duration(days: 30));
          break;
        default:
          cutoff = now.subtract(const Duration(days: 365));
      }
      filtered = filtered.where((r) {
        try {
          return DateTime.parse(r.createdAt).isAfter(cutoff);
        } catch (_) {
          return true;
        }
      }).toList();
    }

    // 模糊搜索（使用防抖后的查询值）
    final query = _displayQuery;
    setState(() {
      _searchResults = FuzzySearch.search(filtered, query);
    });
  }

  Map<String, int> _buildCategoryMap() {
    Map<String, int> map = {};
    for (var r in _allRecords) {
      map[r.category] = (map[r.category] ?? 0) + 1;
    }
    return map;
  }

  Future<void> _showFilterBottomSheet() async {
    Map<String, int> categoryMap = _buildCategoryMap();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('筛选条件', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(height: 24),

                  const Text('时间范围', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _periods.map((p) {
                      return ChoiceChip(
                        label: Text(p),
                        selected: p == _filterPeriod,
                        onSelected: (selected) {
                          setState(() { _filterPeriod = p; });
                          _applyFilters();
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  const Text('分类', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('全部'),
                        selected: _filterCategory.isEmpty,
                        onSelected: (selected) {
                          setState(() { _filterCategory = ''; });
                          _applyFilters();
                        },
                      ),
                      ...categoryMap.keys.map((cat) {
                        return ChoiceChip(
                          label: Text('${cat} (${categoryMap[cat]})'),
                          selected: cat == _filterCategory,
                          onSelected: (selected) {
                            setState(() { _filterCategory = cat; });
                            _applyFilters();
                          },
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child: const Text('重置'),
                        onPressed: () {
                          setState(() {
                            _filterCategory = '';
                            _filterPeriod = '全部';
                            _searchQuery = '';
                          });
                          _applyFilters();
                        },
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        child: const Text('确认'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteRecord(InfoRecord record) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除「${record.title}」吗？'),
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
      await _dbHelper.deleteRecord(record.id!);
      _loadRecords();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已删除')),
      );
    }
  }

  /// 搜索建议：基于当前输入显示匹配的高频关键词（带缓存）
  List<String> _getSuggestions() {
    if (_displayQuery.isEmpty) return [];
    final topKws = FuzzySearch.getTopKeywords(_allRecords, limit: 30);
    return _suggestionCache.get(query: _displayQuery, allKeywords: topKws);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('历史记录'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏 + 建议
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                TextField(
                  focusNode: _searchFocus,
                  decoration: InputDecoration(
                    hintText: '搜索记录...（空格分隔多个关键词）',
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _displayQuery = '';
                              });
                              _applyFilters();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                      _displayQuery = val; // 实时更新显示（建议），防抖后触发搜索
                    });
                    // 防抖 300ms 后再执行搜索
                    _searchDebouncer.run(val, (query) {
                      if (!mounted) return;
                      setState(() { _displayQuery = query; });
                      _applyFilters();
                    }, delay: const Duration(milliseconds: 300));
                  },
                ),

                // 搜索建议
                if (_displayQuery.isNotEmpty && !_isLoading)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _getSuggestions().map((suggestion) {
                        return ActionChip(
                          label: Text(suggestion, style: const TextStyle(fontSize: 11)),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '${_searchQuery} $suggestion';
                              _displayQuery = _searchQuery;
                            });
                            _applyFilters();
                          },
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),

          // 筛选标签 + 结果数
          if (_filterCategory.isNotEmpty || _filterPeriod != '全部' || _displayQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  if (_displayQuery.isNotEmpty)
                    ...[
                      Chip(
                        label: Text('搜索: "$_displayQuery"'),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () {
                          setState(() {
                            _searchQuery = '';
                            _displayQuery = '';
                          });
                          _applyFilters();
                        },
                      ),
                      const SizedBox(width: 4),
                    ],
                  if (_filterCategory.isNotEmpty)
                    ...[
                      Chip(
                        label: Text('分类: $_filterCategory'),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () {
                          setState(() { _filterCategory = ''; });
                          _applyFilters();
                        },
                      ),
                      const SizedBox(width: 4),
                    ],
                  if (_filterPeriod != '全部')
                    ...[
                      Chip(
                        label: Text('时间: $_filterPeriod'),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () {
                          setState(() { _filterPeriod = '全部'; });
                          _applyFilters();
                        },
                      ),
                      const SizedBox(width: 4),
                    ],
                  const Spacer(),
                  Text(
                    '共 ${_searchResults.length} 条',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

          // 搜索结果列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final match = _searchResults[index];
                          return _buildRecordCard(match);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            '暂无记录',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 4),
          Text(
            _displayQuery.isNotEmpty
                ? '未找到匹配的记录，试试其他关键词'
                : '开始输入信息，系统会自动分类并记录',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(SearchMatch match) {
    final record = match.record;
    final keywords = match.matchedKeywords;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _categoryColor(record.category),
          child: Text(
            record.category.isNotEmpty ? record.category[0] : '其',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        title: _buildHighlightedText(record.title, keywords,
            isTitle: true),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 相关性指示器
            if (keywords.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.search, size: 10, color: Colors.orange[700]),
                  const SizedBox(width: 4),
                  Text(
                    '匹配: ${keywords.join(", ")}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            _buildHighlightedText(record.summary, keywords,
                maxLines: 2),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.category, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 2),
                Text(record.category,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                const SizedBox(width: 12),
                Icon(Icons.schedule, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 2),
                Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(
                      DateTime.parse(record.createdAt)),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(Icons.delete, color: Colors.grey[400]),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => DetailScreen(recordId: record.id!)),
          );
        },
        onLongPress: () => _deleteRecord(record),
      ),
    );
  }

  /// 带高亮标记的 RichText
  Widget _buildHighlightedText(
    String text,
    List<String> keywords, {
    bool isTitle = false,
    int maxLines = 1,
  }) {
    if (keywords.isEmpty || text.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          fontWeight: isTitle ? FontWeight.bold : null,
          fontSize: isTitle ? 14 : 12,
          color: isTitle ? null : Colors.grey[700],
        ),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    // 构建 RichText 高亮匹配关键词
    final parts = _splitByKeywords(text, keywords);
    return RichText(
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(
          fontWeight: isTitle ? FontWeight.bold : null,
          fontSize: isTitle ? 14 : 12,
          color: isTitle ? null : Colors.grey[700],
        ),
        children: parts,
      ),
    );
  }

  /// 将文本按关键词拆分，生成带样式的 TextSpan 列表
  List<TextSpan> _splitByKeywords(String text, List<String> keywords) {
    if (keywords.isEmpty) return [TextSpan(text: text)];

    final spans = <TextSpan>[];
    int pos = 0;
    final lowerText = text.toLowerCase();

    while (pos < text.length) {
      bool matched = false;

      for (var kw in keywords) {
        final lowerKw = kw.toLowerCase();
        if (lowerText.startsWith(lowerKw, pos)) {
          spans.add(TextSpan(
            text: text.substring(pos, pos + kw.length),
            style: const TextStyle(
              backgroundColor: Color(0xFFFFEB3B),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ));
          pos += kw.length;
          matched = true;
          break;
        }
      }

      if (!matched) {
        int nextPos = pos + 1;
        // 找到下一个匹配位置
        for (var kw in keywords) {
          int idx = lowerText.indexOf(kw.toLowerCase(), pos + 1);
          if (idx != -1 && idx < nextPos) {
            nextPos = idx;
          }
        }
        if (nextPos > pos) {
          spans.add(TextSpan(text: text.substring(pos, nextPos)));
          pos = nextPos;
        } else {
          break;
        }
      }
    }

    return spans;
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }
}