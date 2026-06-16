import 'package:html/dom.dart';
import 'package:sachet/services/notice_crawler/parsers/notice_parser.dart';

/// 解析器基类，提供通用工具方法
abstract class NoticeParserBase implements NoticeParser {
  /// 将相对 URL 解析为绝对 URL
  String resolveUrl(String href, String sourceUrl) {
    final Uri sourceUri = Uri.parse(sourceUrl);
    return sourceUri.resolve(href).toString();
  }

  /// 从详情页 URL 中提取数字 ID
  String extractIdFromUrl(String detailUrl) {
    final Uri uri = Uri.parse(detailUrl);
    final String fileName =
        uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
    final RegExp regExp = RegExp(r'(\d+)');
    final Match? match = regExp.firstMatch(fileName);
    return match?.group(1) ?? '';
  }

  /// 清洗文本：去除首尾空白、压缩连续空白、移除零宽字符
  String cleanText(String text) {
    return text
        .replaceAll(RegExp(r'[\s\u00A0\u200B-\u200D\uFEFF]+'), ' ')
        .trim();
  }

  /// 查找日期元素中的 <span> 文本（常用于 h3/p/span 结构）
  String? findDateSpanText(Element container) {
    final List<Element> spans = container.querySelectorAll('span');
    for (final Element span in spans) {
      final String text = cleanText(span.text);
      if (RegExp(r'^\d{4}-\d{2}(-\d{2})?$').hasMatch(text)) {
        return text;
      }
    }
    return null;
  }
}
