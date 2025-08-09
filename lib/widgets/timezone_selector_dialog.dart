import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class TimezoneSelectorDialog extends StatefulWidget {
  final String currentTimezone;

  const TimezoneSelectorDialog({
    super.key,
    required this.currentTimezone,
  });

  @override
  State<TimezoneSelectorDialog> createState() => _TimezoneSelectorDialogState();
}

class _TimezoneSelectorDialogState extends State<TimezoneSelectorDialog> {
  late List<String> _timezones;
  late String _searchQuery = '';
  late TextEditingController _searchController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _timezones = tz.timeZoneDatabase.locations.keys.toList()..sort();
    _searchController = TextEditingController();
    
    // Scroll to current timezone
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final index = _timezones.indexOf(widget.currentTimezone);
      if (index != -1) {
        _scrollController.animateTo(
          index * 56.0, // Approximate height of ListTile
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<String> get _filteredTimezones {
    if (_searchQuery.isEmpty) return _timezones;
    return _timezones.where((timezone) => 
      timezone.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  String _formatTimezone(String timezone) {
    final now = DateTime.now();
    final location = tz.getLocation(timezone);
    final tzDateTime = tz.TZDateTime.from(now, location);
    final offset = tzDateTime.timeZoneOffset;
    final hours = offset.inHours;
    final minutes = (offset.inMinutes % 60).abs();
    final sign = hours >= 0 ? '+' : '-';
    final time = tzDateTime.toLocal().format('HH:mm');
    return '$timezone (UTC$sign${hours.abs()}:${minutes.toString().padLeft(2, '0')}) $time';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: theme.dialogBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.dialogBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.schedule,
                color: Colors.amber,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Select Time Zone',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: TextField(
                controller: _searchController,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search timezone...',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                  prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
                  filled: true,
                  fillColor: theme.inputDecorationTheme.fillColor ?? 
                            theme.colorScheme.surface.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _filteredTimezones.length,
                itemBuilder: (context, index) {
                  final timezone = _filteredTimezones[index];
                  final isSelected = timezone == widget.currentTimezone;
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected 
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : null,
                    ),
                    child: ListTile(
                      title: Text(
                        _formatTimezone(timezone),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isSelected 
                            ? theme.colorScheme.primary
                            : theme.textTheme.bodyMedium?.color,
                          fontSize: 14,
                        ),
                      ),
                      selected: isSelected,
                      onTap: () => Navigator.pop(context, timezone),
                      trailing: isSelected 
                        ? Icon(Icons.check, color: theme.colorScheme.primary)
                        : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
}

extension on DateTime {
  String format(String pattern) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
} 