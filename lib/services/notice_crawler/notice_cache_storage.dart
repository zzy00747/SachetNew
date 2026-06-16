import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:sachet/models/campus_notice.dart';
import 'package:sachet/utils/storage/path_provider_utils.dart';

/// 通知数据本地缓存
///
/// 按来源 URL 分别存储为 JSON 文件，文件名为 URL 的 MD5 摘要，
/// 存放于应用支持目录下的 `notices/` 文件夹中。
class NoticeCacheStorage {
  static const String _folder = 'notices';

  /// 加载指定来源的缓存通知列表
  Future<List<CampusNotice>> load(String sourceUrl) async {
    final String fileName = _fileNameFor(sourceUrl);
    final File file = await CachedDataStorage().getFile(_folder, fileName);

    if (!file.existsSync()) {
      return [];
    }

    final String contents = await CachedDataStorage().readDataViaFile(file);
    if (contents.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(contents) as List<dynamic>;
      return jsonList
          .map((json) => CampusNotice.fromJson(json as Map<String, dynamic>))
          .where((notice) => notice.detailUrl.isNotEmpty)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 保存指定来源的通知列表到本地缓存
  Future<void> save(String sourceUrl, List<CampusNotice> notices) async {
    final String fileName = _fileNameFor(sourceUrl);
    final String value = jsonEncode(
      notices.map((notice) => notice.toJson()).toList(),
    );

    await CachedDataStorage().writeFileToAppSupportDir(
      fileName: fileName,
      folder: _folder,
      value: value,
    );
  }

  /// 根据 URL 生成缓存文件名
  String _fileNameFor(String sourceUrl) {
    final String digest = md5.convert(utf8.encode(sourceUrl)).toString();
    return 'notices_$digest.json';
  }
}
