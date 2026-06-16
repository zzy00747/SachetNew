import 'package:html/dom.dart';
import 'package:sachet/models/campus_notice.dart';
import 'package:sachet/services/notice_crawler/parsers/notice_parser_base.dart';

/// 湘潭大学团委 - 校内新闻（`xnxw.htm`）解析器
class TwXnxwParser extends NoticeParserBase {
  /// 校内新闻栏目已知的总页数
  static const int _totalPages = 78;

  @override
  bool canParse(String url) {
    return url.contains('tw.xtu.edu.cn') && url.contains('xnxw');
  }

  @override
  int get totalPages => _totalPages;

  @override
  String buildListUrl(String baseListUrl, int page) {
    if (page < 1 || page > _totalPages) {
      throw ArgumentError('页码必须在 1~$_totalPages 之间');
    }
    if (page == 1) {
      return baseListUrl;
    }

    final Uri uri = Uri.parse(baseListUrl);
    final String pathWithoutExt = uri.path.replaceAll(RegExp(r'\.htm$'), '');
    final int reversePage = _totalPages - page + 1;
    return uri.replace(path: '$pathWithoutExt/$reversePage.htm').toString();
  }

  @override
  List<CampusNotice> parse(Document document, String sourceUrl) {
    final String crawlTime = DateTime.now().toUtc().toIso8601String();
    // 校内新闻的列表项直接位于 <body> 下的多个 <li> 中，
    // 先尝试从外层容器查找，再回退到 body 下所有 li。
    final Element? listContainer =
        document.querySelector('div.text-list') ?? document.body;
    if (listContainer == null) {
      return [];
    }

    final List<Element> items = listContainer.querySelectorAll('li');
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

    final String title = cleanText(link.querySelector('h3')?.text ?? '');

    if (title.isEmpty) return null;

    // 日期在 <a> 内的 <span> 中，格式通常为 yyyy-MM-dd
    final String dateText = findDateSpanText(link) ?? '';

    return CampusNotice(
      title: title,
      date: dateText,
      detailUrl: detailUrl,
      sourceUrl: sourceUrl,
      crawlTime: crawlTime,
    );
  }
}
