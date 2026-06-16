import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:sachet/models/campus_notice.dart';
import 'package:sachet/utils/utils_functions.dart';

/// 通知详情页
///
/// 使用应用内 WebView 加载通知的 detailUrl。
class NoticeDetailPage extends StatefulWidget {
  const NoticeDetailPage({
    super.key,
    required this.notice,
  });

  final CampusNotice notice;

  @override
  State<NoticeDetailPage> createState() => _NoticeDetailPageState();
}

class _NoticeDetailPageState extends State<NoticeDetailPage> {
  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.notice.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: () {
              // InAppWebView 的 controller 可通过 WebView 的 onWebViewCreated 获取
              // 这里简单通过页面重建触发刷新
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: '在浏览器中打开',
            onPressed: () => openLink(widget.notice.detailUrl),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: '复制链接',
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: widget.notice.detailUrl),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('链接已复制')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: _progress < 1 ? _progress : 0,
            backgroundColor: Colors.transparent,
          ),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri(widget.notice.detailUrl),
              ),
              onProgressChanged: (controller, progress) {
                setState(() {
                  _progress = progress / 100;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
