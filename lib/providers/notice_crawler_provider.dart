import 'package:flutter/foundation.dart';
import 'package:sachet/models/campus_notice.dart';
import 'package:sachet/services/notice_crawler/notice_cache_storage.dart';
import 'package:sachet/services/notice_crawler/notice_crawler_service.dart';

/// 通知爬虫 Provider
///
/// 管理通知列表、分页加载、下拉刷新、本地缓存与增量爬取。
class NoticeCrawlerProvider extends ChangeNotifier {
  NoticeCrawlerProvider({
    NoticeCrawlerService? crawler,
    NoticeCacheStorage? cacheStorage,
  })  : _crawler = crawler ?? NoticeCrawlerService(),
        _cacheStorage = cacheStorage ?? NoticeCacheStorage();

  final NoticeCrawlerService _crawler;
  final NoticeCacheStorage _cacheStorage;

  /// 7 个默认来源
  static const List<String> defaultSources = [
    'https://tw.xtu.edu.cn/tzgg.htm',
    'https://tw.xtu.edu.cn/xnxw.htm',
    'https://www.xtu.edu.cn/index/tzgg.htm',
    'https://www.xtu.edu.cn/index/xdw.htm',
    'https://jwc.xtu.edu.cn/xkjs/tzgg.htm',
    'https://jwc.xtu.edu.cn/tzgg.htm',
    'https://jwc.xtu.edu.cn/xkjs/jsjs.htm',
  ];

  /// 当前选中的来源 URL
  String _selectedSourceUrl = defaultSources.first;
  String get selectedSourceUrl => _selectedSourceUrl;

  /// 通知列表（按 date 降序排列）
  List<CampusNotice> _notices = [];
  List<CampusNotice> get notices => List.unmodifiable(_notices);

  /// 当前加载到的页码
  int _currentPage = 1;

  /// 是否正在下拉刷新
  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  /// 是否正在加载更多
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  /// 是否还有更多数据
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  /// 错误信息
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// 上次刷新时间
  DateTime? _lastRefreshTime;

  /// 切换来源
  Future<void> selectSource(String sourceUrl) async {
    if (_selectedSourceUrl == sourceUrl) return;

    _selectedSourceUrl = sourceUrl;
    _notices = [];
    _currentPage = 1;
    _hasMore = true;
    _errorMessage = null;
    notifyListeners();

    await _loadCacheAndRefreshIfNeeded();
  }

  /// 初始化：加载本地缓存，必要时自动刷新
  Future<void> init() async {
    await _loadCacheAndRefreshIfNeeded();
  }

  /// 下拉刷新：重新爬取第一页并增量合并
  Future<void> refresh() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<CampusNotice> freshNotices = await _crawler.fetchNotices(
        _selectedSourceUrl,
        page: 1,
      );

      _notices = _mergeNotices(freshNotices, _notices);
      _currentPage = 1;
      _hasMore = freshNotices.isNotEmpty;
      _lastRefreshTime = DateTime.now();

      await _cacheStorage.save(_selectedSourceUrl, _notices);
    } catch (e) {
      _errorMessage = '刷新失败：$e';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// 加载更多：滑到底部时触发
  Future<void> loadMore() async {
    if (_isLoadingMore || _isRefreshing || !_hasMore) return;

    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final int nextPage = _currentPage + 1;
      final List<CampusNotice> moreNotices = await _crawler.fetchNotices(
        _selectedSourceUrl,
        page: nextPage,
      );

      if (moreNotices.isEmpty) {
        _hasMore = false;
      } else {
        _notices = _mergeNotices(_notices, moreNotices);
        _currentPage = nextPage;
        _hasMore = moreNotices.isNotEmpty;
        await _cacheStorage.save(_selectedSourceUrl, _notices);
      }
    } catch (e) {
      _errorMessage = '加载更多失败：$e';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// 加载缓存，若缓存为空或超过 30 分钟未刷新则自动刷新
  Future<void> _loadCacheAndRefreshIfNeeded() async {
    _isRefreshing = true;
    notifyListeners();

    try {
      final List<CampusNotice> cached =
          await _cacheStorage.load(_selectedSourceUrl);
      _notices = cached;

      final bool shouldRefresh = cached.isEmpty ||
          _lastRefreshTime == null ||
          DateTime.now().difference(_lastRefreshTime!) >
              const Duration(minutes: 30);

      if (shouldRefresh) {
        await refresh();
      } else {
        _isRefreshing = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = '加载缓存失败：$e';
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// 合并通知列表，以 detailUrl 为唯一键
  ///
  /// [newNotices] 中的项会覆盖 [existingNotices] 中同 detailUrl 的项，
  /// 并插入到列表前部；[existingNotices] 中剩余的项保留在后面。
  List<CampusNotice> _mergeNotices(
    List<CampusNotice> newNotices,
    List<CampusNotice> existingNotices,
  ) {
    final Map<String, CampusNotice> merged = {};

    for (final CampusNotice notice in existingNotices) {
      merged[notice.detailUrl] = notice;
    }

    for (final CampusNotice notice in newNotices) {
      merged[notice.detailUrl] = notice;
    }

    final List<CampusNotice> result = merged.values.toList();
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  @override
  void dispose() {
    _crawler.dispose();
    super.dispose();
  }
}
