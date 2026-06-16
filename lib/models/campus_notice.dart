/// 校园通知公告数据模型
class CampusNotice {
  const CampusNotice({
    required this.id,
    required this.title,
    required this.summary,
    required this.date,
    required this.day,
    required this.month,
    required this.detailUrl,
    required this.sourceUrl,
  });

  /// 通知唯一标识（通常取自详情页 URL 中的数字 ID）
  final String id;

  /// 通知标题
  final String title;

  /// 通知摘要/正文预览
  final String summary;

  /// 完整日期，格式 yyyy-MM-dd（若只有月份则补当月首日）
  final String date;

  /// 日期中的「日」
  final String day;

  /// 日期中的「月」，格式 yyyy-MM
  final String month;

  /// 详情页绝对 URL
  final String detailUrl;

  /// 列表页来源 URL
  final String sourceUrl;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'date': date,
        'day': day,
        'month': month,
        'detailUrl': detailUrl,
        'sourceUrl': sourceUrl,
      };

  @override
  String toString() {
    return 'CampusNotice{id: $id, title: $title, date: $date, detailUrl: $detailUrl}';
  }
}
