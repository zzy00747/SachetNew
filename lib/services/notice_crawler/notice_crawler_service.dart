import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:sachet/models/campus_notice.dart';
import 'package:sachet/services/notice_crawler/parsers/notice_parser.dart';
import 'package:sachet/services/notice_crawler/parsers/tw_tzgg_parser.dart';
import 'package:sachet/services/notice_crawler/parsers/tw_xnxw_parser.dart';

/// 校园通知/新闻爬虫服务
///
/// 支持多个来源，每个来源由独立的 [NoticeParser] 解析。
/// 默认已注册湘潭大学团委的「通知公告」和「校内新闻」解析器。
class NoticeCrawlerService {
  NoticeCrawlerService({
    http.Client? client,
    List<NoticeParser>? parsers,
  })  : _client = client ?? http.Client(),
        _parsers = parsers ??
            <NoticeParser>[
              TwTzggParser(),
              TwXnxwParser(),
            ];

  final http.Client _client;
  final List<NoticeParser> _parsers;

  /// 默认读取超时
  static const Duration _timeout = Duration(seconds: 15);

  /// 获取指定来源、指定页码的通知列表
  ///
  /// [baseListUrl] 栏目首页 URL，例如：
  /// - `https://tw.xtu.edu.cn/tzgg.htm`
  /// - `https://tw.xtu.edu.cn/xnxw.htm`
  ///
  /// [page] 从 1 开始，默认为 1（最新一页）。
  Future<List<CampusNotice>> fetchNotices(
    String baseListUrl, {
    int page = 1,
  }) async {
    final NoticeParser parser = _selectParser(baseListUrl);
    final String listUrl = parser.buildListUrl(baseListUrl, page);
    final String html = await _fetchHtml(listUrl);
    final document = parse(html, encoding: 'utf-8');

    return parser.parse(document, listUrl);
  }

  /// 获取指定来源的多页通知
  ///
  /// [pages] 页码列表，例如 `[1, 2, 3]`。
  Future<List<CampusNotice>> fetchNoticesMultiPage(
    String baseListUrl,
    List<int> pages,
  ) async {
    final List<CampusNotice> result = [];
    for (final int page in pages) {
      final List<CampusNotice> pageNotices =
          await fetchNotices(baseListUrl, page: page);
      result.addAll(pageNotices);
    }
    return result;
  }

  /// 获取所有已注册解析器支持的来源首页
  List<String> get supportedSources =>
      _parsers.map((parser) => parser.runtimeType.toString()).toList();

  NoticeParser _selectParser(String url) {
    try {
      return _parsers.firstWhere((parser) => parser.canParse(url));
    } on StateError {
      throw UnsupportedError('暂不支持该 URL 的解析：$url');
    }
  }

  /// 拉取原始 HTML
  Future<String> _fetchHtml(String url) async {
    final Uri uri = Uri.parse(url);
    final http.Response response = await _client.get(uri).timeout(_timeout);

    if (response.statusCode != 200) {
      throw HttpException(
        '请求失败：$url，状态码 ${response.statusCode}',
        response.statusCode,
      );
    }

    return response.body;
  }

  void dispose() {
    _client.close();
  }
}

/// 简单的 HTTP 异常封装
class HttpException implements Exception {
  const HttpException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}
