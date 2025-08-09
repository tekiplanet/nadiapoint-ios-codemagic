import 'package:flutter/material.dart';
import '../../config/theme/colors.dart';
import '../../services/home_service.dart';
import '../../widgets/news/news_card.dart';

class AllNewsScreen extends StatefulWidget {
  final bool isDark;

  const AllNewsScreen({
    Key? key,
    required this.isDark,
  }) : super(key: key);

  @override
  State<AllNewsScreen> createState() => _AllNewsScreenState();
}

class _AllNewsScreenState extends State<AllNewsScreen> {
  final _homeService = HomeService();
  final _scrollController = ScrollController();
  List<dynamic> _news = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNews();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!_isLoading && _hasMore) {
        _loadMoreNews();
      }
    }
  }

  Future<void> _loadNews() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _homeService.getPaginatedNews();
      if (mounted) {
        setState(() {
          _news = response['items'] as List<dynamic>;
          _hasMore = response['hasMore'] as bool;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreNews() async {
    if (_isLoading || !_hasMore) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final response = await _homeService.getPaginatedNews(page: _page + 1);
      if (mounted) {
        setState(() {
          _news.addAll(response['items'] as List<dynamic>);
          _hasMore = response['hasMore'] as bool;
          _page++;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDark
          ? SafeJetColors.primaryBackground
          : SafeJetColors.lightBackground,
      appBar: AppBar(
        title: const Text('News & Updates'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: widget.isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _error != null
          ? Center(
              child: Text(
                _error!,
                style: TextStyle(
                  color: widget.isDark ? Colors.white : Colors.black,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadNews,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _news.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _news.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final news = _news[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: NewsCard(
                      news: news,
                      isDark: widget.isDark,
                    ),
                  );
                },
              ),
            ),
    );
  }
} 