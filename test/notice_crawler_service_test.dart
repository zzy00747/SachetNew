import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sachet/models/campus_notice.dart';
import 'package:sachet/services/notice_crawler/notice_crawler_service.dart';

const String _tzggSampleHtml = r'''
<!DOCTYPE html>
<html lang="zh-CN">
<head><meta charset="UTF-8"><title>通知公告</title></head>
<body>
  <ul class="text-list2">
    <li>
      <a href="info/1012/3521.htm">
        <div class="date2">
          <p>02</p>
          <span>2026-06</span>
        </div>
        <div class="text-list-info">
          <h3>关于在全校公开选拔2026年团属校级 学生组织负责人的通知</h3>
          <p>各二级团组织、同学们：为顺利完成各团属校级学生组织换届工作...</p>
        </div>
      </a>
    </li>
    <li>
      <a href="info/1012/3515.htm">
        <div class="date2">
          <p>28</p>
          <span>2026-05</span>
        </div>
        <div class="text-list-info">
          <h3>关于2026年“中国茅台·国之栋梁” 本硕博优才计划（研究生）...</h3>
          <p>根据2026年“中国茅台·国之栋梁”本硕博优才计划（研究生）支持标准...</p>
        </div>
      </a>
    </li>
  </ul>
</body>
</html>
''';

const String _xnxwSampleHtml = r'''
<!DOCTYPE html>
<html lang="zh-CN">
<head><meta charset="UTF-8"><title>校内新闻</title></head>
<body>
  <div class="text-list">
    <li>
      <a href="info/1011/3530.htm">
        <h3>【校团委】电影鉴赏｜托举·守望·照见——《给阿嬷的情书》一...</h3>
        <p>有这样一部电影，其制作成本不高，全素人出演...</p>
        <span>2026-06-15</span>
      </a>
    </li>
    <li>
      <a href="info/1011/3527.htm">
        <h3>【校团委】刘征峰｜不焦虑，不盲从，他把跨界走成稳路</h3>
        <p>“明知任务当前，却只想刷手机”——这种拖延与焦虑的博弈...</p>
        <span>2026-06-07</span>
      </a>
    </li>
  </div>
</body>
</html>
''';

const String _xtuIndexSampleHtml = r'''
<!DOCTYPE html>
<html lang="zh-CN">
<head><meta charset="UTF-8"><title>通知公告</title></head>
<body>
  <div class="list_lb">
    <ul>
      <li id="line_u17_0">
        <a href="../info/1369/24401.htm" target="_blank" title="关于做好湘潭大学2026年国家留基委青年骨干教师出国研修项目申报的通知">
          <span>2026.06.08</span>
          <h2>关于做好湘潭大学2026年国家留基委青年骨干教师出国研修项目申报的通知</h2>
        </a>
      </li>
      <li id="line_u17_1">
        <a href="../info/1367/24233.htm" target="_blank" title="关于开展2026年湘潭大学大型仪器开放共享评价考核工作的通知">
          <span>2026.05.07</span>
          <h2>关于开展2026年湘潭大学大型仪器开放共享评价考核工作的通知</h2>
        </a>
      </li>
    </ul>
  </div>
</body>
</html>
''';

const String _jwcArticleListSampleHtml = r'''
<!DOCTYPE html>
<html lang="zh-CN">
<head><meta charset="UTF-8"><title>通知公告</title></head>
<body>
  <div class="articleList">
    <UL>
      <li><span>2026-06-15</span><a href="info/1071/4919.htm" title="关于开展2026年上学期新增文化素质课程申报工作的通知">关于开展2026年上学期新增文化素质课程申报工作的通知</a></li>
      <li><span>2026-06-08</span><a href="info/1071/4913.htm" title="2026年湖南省教师人工智能应用案例征集活动校内遴选结果公示">2026年湖南省教师人工智能应用案例征集活动校内遴选结果公示</a></li>
    </UL>
  </div>
</body>
</html>
''';

http.Response _utf8Response(String body, {int statusCode = 200}) {
  return http.Response.bytes(
    utf8.encode(body),
    statusCode,
    headers: {'content-type': 'text/html; charset=utf-8'},
  );
}

void main() {
  group('NoticeCrawlerService - 通知公告（tzgg）', () {
    late NoticeCrawlerService crawler;

    setUp(() {
      final http.Client mockClient = MockClient((request) async {
        final String url = request.url.toString();
        if (url == 'https://tw.xtu.edu.cn/tzgg.htm') {
          return _utf8Response(_tzggSampleHtml);
        }
        if (url == 'https://tw.xtu.edu.cn/tzgg/19.htm') {
          return _utf8Response(_tzggSampleHtml);
        }
        return _utf8Response('Not Found', statusCode: 404);
      });
      crawler = NoticeCrawlerService(client: mockClient);
    });

    tearDown(() => crawler.dispose());

    test('应正确解析通知列表并清洗文本', () async {
      final List<CampusNotice> notices = await crawler.fetchNotices(
        'https://tw.xtu.edu.cn/tzgg.htm',
      );

      expect(notices, hasLength(2));

      final CampusNotice first = notices.first;
      expect(first.title, '关于在全校公开选拔2026年团属校级 学生组织负责人的通知');
      expect(first.date, '2026-06-02');
      expect(first.detailUrl, 'https://tw.xtu.edu.cn/info/1012/3521.htm');
      expect(first.sourceUrl, 'https://tw.xtu.edu.cn/tzgg.htm');
      expect(first.crawlTime, isNotEmpty);
    });

    test('第二页 URL 应使用反向编号', () async {
      final List<CampusNotice> notices = await crawler.fetchNotices(
        'https://tw.xtu.edu.cn/tzgg.htm',
        page: 2,
      );
      expect(notices, hasLength(2));
    });

    test('页码超出范围时应抛出 ArgumentError', () {
      expect(
        () => crawler.fetchNotices('https://tw.xtu.edu.cn/tzgg.htm', page: 21),
        throwsArgumentError,
      );
    });
  });

  group('NoticeCrawlerService - 校内新闻（xnxw）', () {
    late NoticeCrawlerService crawler;

    setUp(() {
      final http.Client mockClient = MockClient((request) async {
        final String url = request.url.toString();
        if (url == 'https://tw.xtu.edu.cn/xnxw.htm') {
          return _utf8Response(_xnxwSampleHtml);
        }
        return _utf8Response('Not Found', statusCode: 404);
      });
      crawler = NoticeCrawlerService(client: mockClient);
    });

    tearDown(() => crawler.dispose());

    test('应正确解析校内新闻列表', () async {
      final List<CampusNotice> notices = await crawler.fetchNotices(
        'https://tw.xtu.edu.cn/xnxw.htm',
      );

      expect(notices, hasLength(2));

      final CampusNotice first = notices.first;
      expect(first.title, startsWith('【校团委】电影鉴赏'));
      expect(first.date, '2026-06-15');
      expect(first.detailUrl, 'https://tw.xtu.edu.cn/info/1011/3530.htm');
      expect(first.sourceUrl, 'https://tw.xtu.edu.cn/xnxw.htm');
      expect(first.crawlTime, isNotEmpty);
    });
  });

  group('NoticeCrawlerService - 湘潭大学官网（index）', () {
    late NoticeCrawlerService crawler;

    setUp(() {
      final http.Client mockClient = MockClient((request) async {
        final String url = request.url.toString();
        if (url == 'https://www.xtu.edu.cn/index/tzgg.htm' ||
            url == 'https://www.xtu.edu.cn/index/tzgg/36.htm') {
          return _utf8Response(_xtuIndexSampleHtml);
        }
        return _utf8Response('Not Found', statusCode: 404);
      });
      crawler = NoticeCrawlerService(client: mockClient);
    });

    tearDown(() => crawler.dispose());

    test('应正确解析官网通知公告列表并转换日期格式', () async {
      final List<CampusNotice> notices = await crawler.fetchNotices(
        'https://www.xtu.edu.cn/index/tzgg.htm',
      );

      expect(notices, hasLength(2));

      final CampusNotice first = notices.first;
      expect(first.title,
          '关于做好湘潭大学2026年国家留基委青年骨干教师出国研修项目申报的通知');
      expect(first.date, '2026-06-08');
      expect(first.detailUrl,
          'https://www.xtu.edu.cn/info/1369/24401.htm');
      expect(first.sourceUrl, 'https://www.xtu.edu.cn/index/tzgg.htm');
      expect(first.crawlTime, isNotEmpty);
    });
  });

  group('NoticeCrawlerService - 教务处（jwc）', () {
    late NoticeCrawlerService crawler;

    setUp(() {
      final http.Client mockClient = MockClient((request) async {
        final String url = request.url.toString();
        if (url == 'https://jwc.xtu.edu.cn/tzgg.htm' ||
            url == 'https://jwc.xtu.edu.cn/tzgg/68.htm') {
          return _utf8Response(_jwcArticleListSampleHtml);
        }
        return _utf8Response('Not Found', statusCode: 404);
      });
      crawler = NoticeCrawlerService(client: mockClient);
    });

    tearDown(() => crawler.dispose());

    test('应正确解析教务处通知公告列表', () async {
      final List<CampusNotice> notices = await crawler.fetchNotices(
        'https://jwc.xtu.edu.cn/tzgg.htm',
      );

      expect(notices, hasLength(2));

      final CampusNotice first = notices.first;
      expect(first.title, '关于开展2026年上学期新增文化素质课程申报工作的通知');
      expect(first.date, '2026-06-15');
      expect(first.detailUrl, 'https://jwc.xtu.edu.cn/info/1071/4919.htm');
      expect(first.sourceUrl, 'https://jwc.xtu.edu.cn/tzgg.htm');
      expect(first.crawlTime, isNotEmpty);
    });
  });

  group('NoticeCrawlerService 真实网络请求', () {
    test(
      '应能爬取湘潭大学团委通知公告列表',
      () async {
        final NoticeCrawlerService liveCrawler = NoticeCrawlerService();
        final List<CampusNotice> notices = await liveCrawler.fetchNotices(
          'https://tw.xtu.edu.cn/tzgg.htm',
        );

        expect(notices, isNotEmpty);
        for (final CampusNotice notice in notices) {
          expect(notice.title, isNotEmpty);
          expect(notice.date, isNotEmpty);
          expect(notice.detailUrl, startsWith('https://tw.xtu.edu.cn/'));
          expect(notice.crawlTime, isNotEmpty);
        }

        liveCrawler.dispose();
      },
      skip: '需要真实网络环境，默认跳过',
    );

    test(
      '应能爬取湘潭大学团委校内新闻列表',
      () async {
        final NoticeCrawlerService liveCrawler = NoticeCrawlerService();
        final List<CampusNotice> notices = await liveCrawler.fetchNotices(
          'https://tw.xtu.edu.cn/xnxw.htm',
        );

        expect(notices, isNotEmpty);
        for (final CampusNotice notice in notices) {
          expect(notice.title, isNotEmpty);
          expect(notice.date, isNotEmpty);
          expect(notice.detailUrl, startsWith('https://tw.xtu.edu.cn/'));
          expect(notice.crawlTime, isNotEmpty);
        }

        liveCrawler.dispose();
      },
      skip: '需要真实网络环境，默认跳过',
    );

    test(
      '应能爬取湘潭大学官网通知公告列表',
      () async {
        final NoticeCrawlerService liveCrawler = NoticeCrawlerService();
        final List<CampusNotice> notices = await liveCrawler.fetchNotices(
          'https://www.xtu.edu.cn/index/tzgg.htm',
        );

        expect(notices, isNotEmpty);
        for (final CampusNotice notice in notices) {
          expect(notice.title, isNotEmpty);
          expect(notice.date, isNotEmpty);
          expect(notice.detailUrl, isNotEmpty);
          expect(notice.crawlTime, isNotEmpty);
        }

        liveCrawler.dispose();
      },
      skip: '需要真实网络环境，默认跳过',
    );

    test(
      '应能爬取湘潭大学教务处通知公告列表',
      () async {
        final NoticeCrawlerService liveCrawler = NoticeCrawlerService();
        final List<CampusNotice> notices = await liveCrawler.fetchNotices(
          'https://jwc.xtu.edu.cn/tzgg.htm',
        );

        expect(notices, isNotEmpty);
        for (final CampusNotice notice in notices) {
          expect(notice.title, isNotEmpty);
          expect(notice.date, isNotEmpty);
          expect(notice.detailUrl, startsWith('https://jwc.xtu.edu.cn/'));
          expect(notice.crawlTime, isNotEmpty);
        }

        liveCrawler.dispose();
      },
      skip: '需要真实网络环境，默认跳过',
    );
  });
}
