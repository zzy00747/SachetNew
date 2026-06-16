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
      expect(first.id, '3521');
      expect(first.title, '关于在全校公开选拔2026年团属校级 学生组织负责人的通知');
      expect(first.summary, startsWith('各二级团组织、同学们'));
      expect(first.day, '02');
      expect(first.month, '2026-06');
      expect(first.date, '2026-06-02');
      expect(first.detailUrl, 'https://tw.xtu.edu.cn/info/1012/3521.htm');
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
      expect(first.id, '3530');
      expect(first.title, startsWith('【校团委】电影鉴赏'));
      expect(first.date, '2026-06-15');
      expect(first.day, '15');
      expect(first.month, '2026-06');
      expect(first.detailUrl, 'https://tw.xtu.edu.cn/info/1011/3530.htm');
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
          expect(notice.detailUrl, startsWith('https://tw.xtu.edu.cn/'));
          expect(notice.id, isNotEmpty);
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
          expect(notice.detailUrl, startsWith('https://tw.xtu.edu.cn/'));
          expect(notice.id, isNotEmpty);
        }

        liveCrawler.dispose();
      },
      skip: '需要真实网络环境，默认跳过',
    );
  });
}
