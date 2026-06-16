/// 校园通知/新闻数据模型
class CampusNotice {
  const CampusNotice({
    required this.title,
    required this.date,
    required this.detailUrl,
    required this.sourceUrl,
    required this.crawlTime,
  });

  /// 通知标题
  final String title;

  /// 完整日期，格式 yyyy-MM-dd
  final String date;

  /// 详情页绝对 URL
  final String detailUrl;

  /// 列表页来源 URL
  final String sourceUrl;

  /// 本条数据被爬取的时间（ISO 8601），用于后续增量爬取去重
  final String crawlTime;

  Map<String, dynamic> toJson() => {
        'title': title,
        'date': date,
        'detailUrl': detailUrl,
        'sourceUrl': sourceUrl,
        'crawlTime': crawlTime,
      };

  factory CampusNotice.fromJson(Map<String, dynamic> json) {
    return CampusNotice(
      title: json['title'] as String? ?? '',
      date: json['date'] as String? ?? '',
      detailUrl: json['detailUrl'] as String? ?? '',
      sourceUrl: json['sourceUrl'] as String? ?? '',
      crawlTime: json['crawlTime'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'CampusNotice{title: $title, date: $date, detailUrl: $detailUrl, crawlTime: $crawlTime}';
  }
}
