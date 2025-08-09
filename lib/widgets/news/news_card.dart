import 'package:flutter/material.dart';
import '../../config/theme/colors.dart';
import '../../services/home_service.dart';
import 'news_detail_dialog.dart';

class NewsCard extends StatelessWidget {
  final dynamic news;
  final bool isDark;

  const NewsCard({
    Key? key,
    required this.news,
    required this.isDark,
  }) : super(key: key);

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

  Future<void> _showNewsDetail(BuildContext context) async {
    final homeService = HomeService();
    try {
      final newsDetail = await homeService.getNewsById(news['id']);
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => NewsDetailDialog(
            news: newsDetail,
            isDark: isDark,
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

  @override
  Widget build(BuildContext context) {
    final type = news['type'] as String;
    final typeColor = _getTypeColor(type);
    final typeLabel = _formatTypeLabel(type);

    return GestureDetector(
      onTap: () => _showNewsDetail(context),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    SafeJetColors.secondaryHighlight.withOpacity(0.15),
                    SafeJetColors.primaryAccent.withOpacity(0.05),
                  ]
                : [
                    SafeJetColors.lightCardBackground,
                    SafeJetColors.lightCardBackground,
                  ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? SafeJetColors.secondaryHighlight.withOpacity(0.2)
                : SafeJetColors.lightCardBorder,
          ),
        ),
        child: Padding(
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
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                news['title'],
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                news['shortDescription'],
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 