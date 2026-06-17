import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sachet/models/campus_notice.dart';
import 'package:sachet/providers/notice_crawler_provider.dart';
import 'package:sachet/services/notice_crawler/notice_cache_storage.dart';
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
  </ul>
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

/// 不读写真实文件的缓存存根，便于单元测试。
class _FakeNoticeCacheStorage implements NoticeCacheStorage {
  final Map<String, List<CampusNotice>> _data = <String, List<CampusNotice>>{};

  @override
  Future<List<CampusNotice>> load(String sourceUrl) async {
    return List<CampusNotice>.from(_data[sourceUrl] ?? <CampusNotice>[]);
  }

  @override
  Future<void> save(String sourceUrl, List<CampusNotice> notices) async {
    _data[sourceUrl] = List<CampusNotice>.from(notices);
  }
}

void main() {
  group('NoticeCrawlerProvider', () {
    late NoticeCrawlerService crawler;
    late _FakeNoticeCacheStorage cacheStorage;

    setUp(() {
      final http.Client mockClient = MockClient((request) async {
        final String url = request.url.toString();
        if (url == 'https://tw.xtu.edu.cn/tzgg.htm') {
          return _utf8Response(_tzggSampleHtml);
        }
        return _utf8Response('Not Found', statusCode: 404);
      });
      crawler = NoticeCrawlerService(client: mockClient);
      cacheStorage = _FakeNoticeCacheStorage();
    });

    tearDown(() => crawler.dispose());

    test('init 在缓存为空时应完成刷新并结束加载状态', () async {
      final NoticeCrawlerProvider provider = NoticeCrawlerProvider(
        crawler: crawler,
        cacheStorage: cacheStorage,
      );

      expect(provider.isRefreshing, isFalse);
      expect(provider.notices, isEmpty);

      final Future<void> initFuture = provider.init();
      expect(provider.isRefreshing, isTrue);

      await initFuture;

      expect(provider.isRefreshing, isFalse);
      expect(provider.notices, hasLength(1));
      expect(provider.notices.first.title,
          '关于在全校公开选拔2026年团属校级 学生组织负责人的通知');
      expect(provider.errorMessage, isNull);
    });

    test('init 有缓存时仍会自动刷新并合并结果', () async {
      const CampusNotice cachedNotice = CampusNotice(
        title: '缓存通知',
        date: '2026-06-01',
        detailUrl: 'https://tw.xtu.edu.cn/info/1012/3500.htm',
        sourceUrl: 'https://tw.xtu.edu.cn/tzgg.htm',
        crawlTime: '2026-06-01T00:00:00.000',
      );
      await cacheStorage.save('https://tw.xtu.edu.cn/tzgg.htm', [cachedNotice]);

      final NoticeCrawlerProvider provider = NoticeCrawlerProvider(
        crawler: crawler,
        cacheStorage: cacheStorage,
      );

      await provider.init();

      expect(provider.isRefreshing, isFalse);
      // 缓存一条 + 网络一条，合并后共两条，按日期降序排列
      expect(provider.notices, hasLength(2));
      expect(provider.notices.first.date, '2026-06-02');
      expect(provider.notices.last.date, '2026-06-01');
    });

    test('refresh 应能重复调用且不会导致加载状态卡住', () async {
      final NoticeCrawlerProvider provider = NoticeCrawlerProvider(
        crawler: crawler,
        cacheStorage: cacheStorage,
      );

      await provider.init();
      expect(provider.isRefreshing, isFalse);
      expect(provider.notices, hasLength(1));

      await provider.refresh();
      expect(provider.isRefreshing, isFalse);
      expect(provider.notices, hasLength(1));
    });
  });
}
