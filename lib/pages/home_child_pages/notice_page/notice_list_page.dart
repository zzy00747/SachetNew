import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/campus_notice.dart';
import 'package:sachet/models/enums/nav_type.dart';
import 'package:sachet/providers/notice_crawler_provider.dart';
import 'package:sachet/providers/screen_nav_provider.dart';
import 'package:sachet/providers/settings_provider.dart';
import 'package:sachet/utils/app_global.dart';
import 'package:sachet/pages/home_child_pages/notice_page/notice_detail_page.dart';
import 'package:sachet/widgets/utils_widgets/nav_drawer.dart';

/// 校园通知列表页
///
/// 支持下拉刷新、底部加载更多、来源切换。
class NoticeListPage extends StatefulWidget {
  const NoticeListPage({super.key});

  @override
  State<NoticeListPage> createState() => _NoticeListPageState();
}

class _NoticeListPageState extends State<NoticeListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NoticeCrawlerProvider>().init();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      context.read<NoticeCrawlerProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: AppGlobal.startupPage == '/notice',
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        if (SettingsProvider.navigationType == NavType.navigationDrawer.type) {
          Navigator.of(context).pushReplacementNamed(AppGlobal.startupPage);
        }
        context.read<ScreenNavProvider>().setCurrentPageToStartupPage();
      },
      child: Scaffold(
        drawer: SettingsProvider.navigationType == NavType.navigationDrawer.type
            ? myNavDrawer
            : null,
        appBar: AppBar(
          title: const Text('校园通知'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '刷新',
              onPressed: () {
                context.read<NoticeCrawlerProvider>().refresh();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            _buildSourceSelector(),
            Expanded(
              child: Consumer<NoticeCrawlerProvider>(
                builder: (context, provider, child) {
                  if (provider.notices.isEmpty && provider.isRefreshing) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.notices.isEmpty &&
                      provider.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(provider.errorMessage!),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => provider.refresh(),
                            child: const Text('重试'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (provider.notices.isEmpty) {
                    return const Center(child: Text('暂无通知'));
                  }

                  return RefreshIndicator(
                    onRefresh: () => provider.refresh(),
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: provider.notices.length + 1,
                      itemBuilder: (context, index) {
                        if (index == provider.notices.length) {
                          return _buildLoadMoreFooter(provider);
                        }

                        final CampusNotice notice = provider.notices[index];
                        return _buildNoticeCard(notice);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceSelector() {
    return Consumer<NoticeCrawlerProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DropdownMenu<String>(
            initialSelection: provider.selectedSourceUrl,
            requestFocusOnTap: false,
            expandedInsets: EdgeInsets.zero,
            onSelected: (String? value) {
              if (value != null) {
                provider.selectSource(value);
              }
            },
            dropdownMenuEntries: NoticeCrawlerProvider.defaultSources
                .map((url) => DropdownMenuEntry<String>(
                      value: url,
                      label: _sourceLabel(url),
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildNoticeCard(CampusNotice notice) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NoticeDetailPage(notice: notice),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notice.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    notice.date,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreFooter(NoticeCrawlerProvider provider) {
    if (provider.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (!provider.hasMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('没有更多了')),
      );
    }

    return const SizedBox.shrink();
  }

  String _sourceLabel(String url) {
    if (url.contains('tw.xtu.edu.cn/tzgg')) return '团委通知公告';
    if (url.contains('tw.xtu.edu.cn/xnxw')) return '团委校内新闻';
    if (url.contains('www.xtu.edu.cn/index/tzgg')) return '官网通知公告';
    if (url.contains('www.xtu.edu.cn/index/xdw')) return '官网湘大要闻';
    if (url.contains('jwc.xtu.edu.cn/xkjs/tzgg')) return '教务处学科竞赛';
    if (url.contains('jwc.xtu.edu.cn/xkjs/jsjs')) return '教务处竞赛介绍';
    if (url.contains('jwc.xtu.edu.cn/tzgg')) return '教务处通知公告';
    return url;
  }
}
