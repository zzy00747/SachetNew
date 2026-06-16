import 'package:html/dom.dart';
import 'package:sachet/models/campus_notice.dart';
import 'package:sachet/services/notice_crawler/parsers/notice_parser_base.dart';

/// 湘潭大学官网栏目解析器
///
/// 覆盖：
/// - `https://www.xtu.edu.cn/index/tzgg.htm`（通知公告）
/// - `https://www.xtu.edu.cn/index/xdw.htm`（湘大要闻）
class XtuIndexParser extends NoticeParserBase {
  @override
  bool canParse(String url) {
    return url.contains('www.xtu.edu.cn/index') &&
        (url.contains('tzgg') || url.contains('xdw'));
  }

  /// 返回该来源下最大页数（实际页数在 buildListUrl 中按栏目细分）
  @override
  int get totalPages => 254;

  @override
  String buildListUrl(String baseListUrl, int page) {
    final int totalPages = _resolveTotalPages(baseListUrl);
    if (page < 1 || page > totalPages) {
      throw ArgumentError('页码必须在 1~$totalPages 之间');
    }
    if (page == 1) {
      return baseListUrl;
    }

    final Uri uri = Uri.parse(baseListUrl);
    final String pathWithoutExt = uri.path.replaceAll(RegExp(r'\.htm$'), '');
    final int reversePage = totalPages - page + 1;
    return uri.replace(path: '$pathWithoutExt/$reversePage.htm').toString();
  }

  @override
  List<CampusNotice> parse(Document document, String sourceUrl) {
    final String crawlTime = DateTime.now().toUtc().toIso8601String();
    final Element? listContainer = document.querySelector('div.list_lb');
    if (listContainer == null) {
      return [];
    }

    final List<Element> items = listContainer.querySelectorAll('li[id^="line_u17_"]');
    return items
        .map((li) => _parseItem(li, sourceUrl, crawlTime))
        .whereType<CampusNotice>()
        .toList();
  }

  CampusNotice? _parseItem(Element li, String sourceUrl, String crawlTime) {
    final Element? link = li.querySelector('a');
    if (link == null) return null;

    final String? href = link.attributes['href'];
    if (href == null || href.isEmpty) return null;

    final String detailUrl = resolveUrl(href, sourceUrl);
    final String title = cleanText(link.querySelector('h2')?.text ?? '');
    final String dateText = _normalizeDate(
      cleanText(link.querySelector('span')?.text ?? ''),
    );

    if (title.isEmpty) return null;

    return CampusNotice(
      title: title,
      date: dateText,
      detailUrl: detailUrl,
      sourceUrl: sourceUrl,
      crawlTime: crawlTime,
    );
  }

  /// 将 `yyyy.MM.dd` 转换为 `yyyy-MM-dd`
  String _normalizeDate(String rawDate) {
    return rawDate.replaceAll('.', '-');
  }

  int _resolveTotalPages(String url) {
    if (url.contains('xdw')) return 254;
    if (url.contains('tzgg')) return 37;
    return 37;
  }
}
