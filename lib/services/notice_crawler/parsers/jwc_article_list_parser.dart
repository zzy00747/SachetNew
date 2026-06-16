import 'package:html/dom.dart';
import 'package:sachet/models/campus_notice.dart';
import 'package:sachet/services/notice_crawler/parsers/notice_parser_base.dart';

/// 湘潭大学教务处栏目解析器
///
/// 覆盖：
/// - `https://jwc.xtu.edu.cn/tzgg.htm`（通知公告）
/// - `https://jwc.xtu.edu.cn/xkjs/tzgg.htm`（学科竞赛通知公告）
/// - `https://jwc.xtu.edu.cn/xkjs/jsjs.htm`（竞赛介绍）
class JwcArticleListParser extends NoticeParserBase {
  @override
  bool canParse(String url) {
    return url.contains('jwc.xtu.edu.cn') &&
        (url.contains('/tzgg') || url.contains('/jsjs'));
  }

  /// 返回该来源下最大页数（实际页数在 buildListUrl 中按栏目细分）
  @override
  int get totalPages => 69;

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
    final Element? listContainer = document.querySelector('div.articleList');
    if (listContainer == null) {
      return [];
    }

    final List<Element> items = listContainer.querySelectorAll('ul > li');
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
    final String title = cleanText(link.text);
    final String dateText = cleanText(li.querySelector('span')?.text ?? '');

    if (title.isEmpty) return null;

    return CampusNotice(
      title: title,
      date: dateText,
      detailUrl: detailUrl,
      sourceUrl: sourceUrl,
      crawlTime: crawlTime,
    );
  }

  int _resolveTotalPages(String url) {
    if (url.contains('/xkjs/jsjs')) return 3;
    if (url.contains('/xkjs/tzgg')) return 23;
    if (url.contains('/tzgg')) return 69;
    return 69;
  }
}
