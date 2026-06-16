import 'package:html/dom.dart';
import 'package:sachet/models/campus_notice.dart';
import 'package:sachet/services/notice_crawler/parsers/notice_parser_base.dart';

/// 湘潭大学团委 - 通知公告（`tzgg.htm`）解析器
class TwTzggParser extends NoticeParserBase {
  /// 通知公告栏目已知的总页数
  static const int _totalPages = 20;

  @override
  bool canParse(String url) {
    return url.contains('tw.xtu.edu.cn') && url.contains('tzgg');
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
    final Element? listUl = document.querySelector('ul.text-list2');
    if (listUl == null) {
      return [];
    }

    final List<Element> items = listUl.querySelectorAll('li');
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

    final Element? dateBox = link.querySelector('div.date2');
    final String day = cleanText(dateBox?.querySelector('p')?.text ?? '');
    final String month = cleanText(dateBox?.querySelector('span')?.text ?? '');

    final Element? infoBox = link.querySelector('div.text-list-info');
    final String title = cleanText(infoBox?.querySelector('h3')?.text ?? '');

    if (title.isEmpty) return null;

    return CampusNotice(
      title: title,
      date: _normalizeDate(day, month),
      detailUrl: detailUrl,
      sourceUrl: sourceUrl,
      crawlTime: crawlTime,
    );
  }

  String _normalizeDate(String day, String month) {
    final String d = day.padLeft(2, '0');
    if (RegExp(r'^\d{4}-\d{2}$').hasMatch(month)) {
      return '$month-$d';
    }
    return month;
  }
}
