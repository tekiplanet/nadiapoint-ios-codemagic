import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import '../../config/theme/colors.dart';
import '../../services/home_service.dart';
import '../../screens/news/all_news_screen.dart';
import './news_detail_dialog.dart';
import 'package:shimmer/shimmer.dart';

class NewsCarousel extends StatefulWidget {
  final bool isDark;

  const NewsCarousel({
    Key? key,
    required this.isDark,
  }) : super(key: key);

  @override
  State<NewsCarousel> createState() => _NewsCarouselState();
}

class _NewsCarouselState extends State<NewsCarousel> {
  final _homeService = HomeService();
  List<Map<String, dynamic>> _news = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _homeService.getRecentNews();
      if (mounted) {
        setState(() {
          _news = response;
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

  Future<void> _showNewsDetail(
      BuildContext context, Map<String, dynamic> news) async {
    try {
      final newsDetail = await _homeService.getNewsById(news['id']);
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => NewsDetailDialog(
            news: newsDetail,
            isDark: widget.isDark,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load news details: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'announcement':
        return Colors.blue;
      case 'marketupdate':
        return Colors.green;
      case 'alert':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'announcement':
        return 'Announcement';
      case 'marketupdate':
        return 'Market Update';
      case 'alert':
        return 'Alert';
      default:
        return type;
    }
  }

  Widget _buildNewsShimmer() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) => Shimmer.fromColors(
          baseColor: widget.isDark ? Colors.grey[900]! : Colors.grey[300]!,
          highlightColor: widget.isDark ? Colors.grey[800]! : Colors.grey[100]!,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 80, height: 16, color: Colors.white),
                const SizedBox(height: 12),
                Container(width: 180, height: 20, color: Colors.white),
                const SizedBox(height: 8),
                Container(
                    width: double.infinity, height: 14, color: Colors.white),
                const SizedBox(height: 8),
                Container(
                    width: double.infinity, height: 14, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _error != null) {
      // Show shimmer for both loading and error
      return _buildNewsShimmer();
    }

    if (_news.isEmpty) {
      return const Center(child: Text('No news available'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'News & Updates',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AllNewsScreen(
                        isDark: widget.isDark,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'See All',
                      style: TextStyle(
                        color: SafeJetColors.secondaryHighlight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: SafeJetColors.secondaryHighlight,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: FlutterCarousel(
            items: _news.map((news) {
              final type = news['type'] as String;
              final typeColor = _getTypeColor(type);
              final typeLabel = _formatTypeLabel(type);

              return GestureDetector(
                onTap: () => _showNewsDetail(context, news),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.isDark
                          ? [
                              SafeJetColors.secondaryHighlight
                                  .withOpacity(0.15),
                              SafeJetColors.primaryAccent.withOpacity(0.05),
                            ]
                          : [
                              SafeJetColors.lightCardBackground,
                              SafeJetColors.lightCardBackground,
                            ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: widget.isDark
                          ? SafeJetColors.secondaryHighlight.withOpacity(0.2)
                          : SafeJetColors.lightCardBorder,
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(news['createdAt']),
                            style: TextStyle(
                              color: widget.isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        news['title'],
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        news['shortDescription'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: widget.isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            options: CarouselOptions(
              height: 200,
              viewportFraction: 0.9,
              enableInfiniteScroll: _news.length > 1,
              autoPlay: _news.length > 1,
              autoPlayInterval: const Duration(seconds: 5),
              enlargeCenterPage: true,
              slideIndicator: CircularSlideIndicator(),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
