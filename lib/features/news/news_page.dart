import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../shared/routes/expanding_route.dart';
import 'news_repository.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  List<Article>? _articles;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetch(offset: 0);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore) {
        _fetch(offset: _articles?.length ?? 0);
      }
    }
  }

  void _fetch({required int offset}) {
    if (offset > 0) {
      setState(() => _isLoadingMore = true);
    }
    NewsRepository().fetchNutritionNews(offset: offset).then((val) {
      if (mounted) {
        setState(() {
          _articles = val;
          _isLoadingMore = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildList(),
    );
  }

  Widget _buildList() {
    if (_articles == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.black),
      );
    }
    if (_articles!.isEmpty) {
      return const Center(
        child: Text('Belum ada catatan. Coba periksa koneksi atau API Key.'),
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: Colors.transparent,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
          ),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
          title: const Text('Catatan Nutrisi'),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // If it's a separator index (odd)
                if (index.isOdd) {
                  return const Divider(height: 32, thickness: 0.5, color: Colors.black12);
                }
                
                // Actual item index (even)
                final itemIndex = index ~/ 2;
                
                if (itemIndex == _articles!.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator(color: Colors.black)),
                  );
                }
                final a = _articles![itemIndex];
                return _ArticleItemTile(article: a);
              },
              childCount: (_articles!.length + (_isLoadingMore ? 1 : 0)) * 2 - 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _ArticleItemTile extends StatefulWidget {
  const _ArticleItemTile({required this.article});
  final Article article;

  @override
  State<_ArticleItemTile> createState() => _ArticleItemTileState();
}

class _ArticleItemTileState extends State<_ArticleItemTile> {
  final GlobalKey _tileKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final a = widget.article;
    return InkWell(
      key: _tileKey,
      onTap: () {
        context.expandTo(
          tileKey: _tileKey,
          page: ArticleWebViewPage(article: a),
          tileColor: Colors.white,
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      a.category,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '·',
                      style: TextStyle(color: Colors.black38),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      a.date,
                      style: const TextStyle(
                        color: Colors.black38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  a.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (a.imageUrl.isNotEmpty) ...[
            const SizedBox(width: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: a.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.black12),
                errorWidget: (context, url, error) => Container(
                  color: Colors.black12,
                  child: const Icon(
                    Icons.broken_image,
                    size: 24,
                    color: Colors.black38,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ponytail: single file WebView to avoid boilerplate
class ArticleWebViewPage extends StatefulWidget {
  const ArticleWebViewPage({super.key, required this.article});
  final Article article;

  @override
  State<ArticleWebViewPage> createState() => _ArticleWebViewPageState();
}

class _ArticleWebViewPageState extends State<ArticleWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.article.sourceUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(widget.article.title),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
