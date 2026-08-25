import 'dart:async';

/// 防抖工具类：在 Flutter 环境中管理 Timer
class Debouncer {
  Timer? _timer;

  /// 延迟执行的防抖方法
  void debounce(Function() action, {Duration delay = const Duration(milliseconds: 300)}) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// 在 dispose 时调用，防止内存泄漏
  void dispose() {
    _timer?.cancel();
  }
}

/// 一次性防抖：每次调用都会重置 timer，适合搜索场景
class SearchDebouncer {
  Timer? _timer;

  void run(String query, Function(String) onSearchComplete,
      {Duration delay = const Duration(milliseconds: 300)}) {
    _timer?.cancel();
    _timer = Timer(delay, () => onSearchComplete(query));
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// 节流工具：首次调用立即执行，期间（含异步操作）忽略后续调用
class Throttler {
  Timer? _timer;
  bool _isWaiting = false;

  void throttle(Function() action, {Duration interval = const Duration(seconds: 3)}) {
    if (_isWaiting) return;
    _isWaiting = true;
    action();
    _timer = Timer(interval, () {
      _isWaiting = false;
    });
  }

  /// 异步节流：等待异步操作完成后再允许下一次调用
  void throttleAsync(Future<void> Function() action,
      {Duration minInterval = const Duration(seconds: 1)}) {
    if (_isWaiting) return;
    _isWaiting = true;
    action().then((_) {
      _timer = Timer(minInterval, () {
        _isWaiting = false;
      });
    }).catchError((_) {
      _isWaiting = false;
    });
  }

  void dispose() {
    _timer?.cancel();
    _isWaiting = false;
  }
}

/// 搜索建议缓存，避免频繁重新计算高频词
class SearchSuggestionCache {
  Map<String, int>? _cachedKeywords;
  List<String>? _cachedSuggestions;
  String _lastQuery = '';
  DateTime? _cachedAt;
  static const Duration _cacheTtl = Duration(minutes: 5);

  List<String> get({
    required String query,
    required Map<String, int> allKeywords,
    int limit = 5,
  }) {
    // 如果关键词池变化或缓存过期，重新计算
    if (_cachedKeywords != allKeywords ||
        _lastQuery.isEmpty ||
        _cachedAt == null ||
        DateTime.now().difference(_cachedAt!) > _cacheTtl) {
      _cachedKeywords = allKeywords;
      _lastQuery = query;
      _cachedAt = DateTime.now();
      _cachedSuggestions = allKeywords.keys
          .where((kw) => kw.contains(query))
          .take(limit)
          .toList();
    }

    // 如果查询变了，从缓存关键词中重新筛选
    if (_lastQuery != query) {
      _lastQuery = query;
      _cachedSuggestions = _cachedKeywords!.keys
          .where((kw) => kw.contains(query))
          .take(limit)
          .toList();
    }

    return _cachedSuggestions ?? [];
  }

  void invalidate() {
    _cachedKeywords = null;
    _cachedSuggestions = null;
    _lastQuery = '';
    _cachedAt = null;
  }
}