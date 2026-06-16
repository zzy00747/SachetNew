import 'package:html/dom.dart';
import 'package:sachet/models/campus_notice.dart';

/// 通知/新闻页面解析器接口
///
/// 每个来源（或栏目）对应一个实现类，统一输出 [CampusNotice] 列表。
abstract interface class NoticeParser {
  /// 判断该解析器是否能处理给定的 [url]
  bool canParse(String url);

  /// 该来源已知的总页数（用于分页构建）
  int get totalPages;

  /// 构建指定页码的列表页 URL
  ///
  /// [baseListUrl] 通常是栏目首页，例如 `https://tw.xtu.edu.cn/tzgg.htm`。
  /// [page] 从 1 开始。
  String buildListUrl(String baseListUrl, int page);

  /// 解析 HTML 文档，返回通知列表
  ///
  /// [document] 已由调用方解析好的 HTML 文档。
  /// [sourceUrl] 实际请求的列表页 URL，用于生成绝对链接和来源标记。
  List<CampusNotice> parse(Document document, String sourceUrl);
}
