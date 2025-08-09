import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme/colors.dart';
import '../../config/theme/theme_provider.dart';
import '../../widgets/p2p_app_bar.dart';
import '../../providers/auto_response_provider.dart';

class P2PAutoResponseScreen extends StatefulWidget {
  const P2PAutoResponseScreen({super.key});

  @override
  State<P2PAutoResponseScreen> createState() => _P2PAutoResponseScreenState();
}

class _P2PAutoResponseScreenState extends State<P2PAutoResponseScreen> {
  final List<Map<String, dynamic>> _responses = [
    {
      'id': '1',
      'message': 'I have made the payment, please check.',
      'type': 'Payment',
      'icon': Icons.payment,
      'color': const Color(0xFF4CAF50),
    },
    {
      'id': '2',
      'message': 'Please provide your payment details.',
      'type': 'Request',
      'icon': Icons.request_page,
      'color': Color(0xFF2196F3),
    },
    {
      'id': '3',
      'message': 'Payment received, releasing crypto now.',
      'type': 'Confirmation',
      'icon': Icons.check_circle,
      'color': Color(0xFF9C27B0),
    },
    {
      'id': '4',
      'message': 'Thank you for trading with me!',
      'type': 'Thanks',
      'icon': Icons.favorite,
      'color': Color(0xFFE91E63),
    },
  ];

  final _messageController = TextEditingController();
  final _typeController = TextEditingController();
  IconData? _selectedIcon;
  Color _selectedColor = const Color(0xFF4CAF50);

  final List<Map<String, dynamic>> _availableIcons = [
    {'icon': Icons.payment, 'label': 'Payment'},
    {'icon': Icons.request_page, 'label': 'Request'},
    {'icon': Icons.check_circle, 'label': 'Confirmation'},
    {'icon': Icons.favorite, 'label': 'Thanks'},
    {'icon': Icons.warning, 'label': 'Warning'},
    {'icon': Icons.info, 'label': 'Info'},
  ];

  final List<Color> _availableColors = [
    const Color(0xFF4CAF50),
    const Color(0xFF2196F3),
    const Color(0xFF9C27B0),
    const Color(0xFFE91E63),
    const Color(0xFFFFC107),
    const Color(0xFF607D8B),
  ];

  final List<String> _responseTypes = [
    'Payment',
    'Request',
    'Confirmation',
    'Thanks',
  ];

  final Map<String, Map<String, dynamic>> _responseTypeConfig = {
    'Payment': {
      'icon': 'payment',
      'color': '#4CAF50',
      'iconData': Icons.payment,
    },
    'Request': {
      'icon': 'request_page',
      'color': '#2196F3',
      'iconData': Icons.request_page,
    },
    'Confirmation': {
      'icon': 'check_circle',
      'color': '#9C27B0',
      'iconData': Icons.check_circle,
    },
    'Thanks': {
      'icon': 'favorite',
      'color': '#E91E63',
      'iconData': Icons.favorite,
    },
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AutoResponseProvider>().loadResponses();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: P2PAppBar(
        title: 'Quick Responses',
        hasNotification: false,
        onThemeToggle: () {
          themeProvider.toggleTheme();
        },
      ),
      body: Column(
        children: [
          _buildHeader(isDark),
          Expanded(
            child: Consumer<AutoResponseProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return _buildShimmerLoading(isDark);
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          provider.error!,
                          style: TextStyle(color: SafeJetColors.error),
                        ),
                        ElevatedButton(
                          onPressed: () => provider.loadResponses(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
              padding: const EdgeInsets.all(16),
                  itemCount: provider.responses.length,
              itemBuilder: (context, index) {
                return FadeInUp(
                  duration: const Duration(milliseconds: 300),
                  delay: Duration(milliseconds: index * 100),
                      child: _buildResponseCard(provider.responses[index], isDark),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddResponseDialog(isDark),
        backgroundColor: SafeJetColors.secondaryHighlight,
        icon: const Icon(Icons.add),
        label: const Text('New Response'),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? SafeJetColors.primaryAccent.withOpacity(0.1)
            : SafeJetColors.lightCardBackground,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? SafeJetColors.primaryAccent.withOpacity(0.2)
                : SafeJetColors.lightCardBorder,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SafeJetColors.secondaryHighlight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.quickreply,
                  color: SafeJetColors.secondaryHighlight,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Responses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Manage your automated chat responses',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResponseCard(Map<String, dynamic> response, bool isDark) {
    final type = response['type'] as String;
    final config = _responseTypeConfig[type] ?? _responseTypeConfig['Payment']!;
    final color = _hexToColor(config['color'] as String);
    final icon = config['iconData'] as IconData;

    return Dismissible(
      key: Key(response['id']),
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: SafeJetColors.error.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 8),
            Icon(
          Icons.delete_outline,
          color: Colors.white,
            ),
          ],
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1A1F2E) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Delete Response'),
              content: const Text(
                'Are you sure you want to delete this response?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: SafeJetColors.error,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        context.read<AutoResponseProvider>().deleteResponse(response['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Response deleted'),
            backgroundColor: isDark ? const Color(0xFF1A1F2E) : Colors.black87,
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                context.read<AutoResponseProvider>().addResponse(response);
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark
              ? SafeJetColors.primaryAccent.withOpacity(0.1)
              : SafeJetColors.lightCardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? SafeJetColors.primaryAccent.withOpacity(0.2)
                : SafeJetColors.lightCardBorder,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showEditResponseDialog(response, isDark),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                      IconButton(
                        onPressed: () => _showEditResponseDialog(response, isDark),
                            icon: Icon(
                              Icons.edit_outlined,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                            iconSize: 20,
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            onPressed: () async {
                              final shouldDelete = await showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: isDark ? const Color(0xFF1A1F2E) : Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: const Text('Delete Response'),
                                    content: const Text(
                                      'Are you sure you want to delete this response?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(
                                            color: isDark ? Colors.white70 : Colors.black54,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        style: TextButton.styleFrom(
                                          foregroundColor: SafeJetColors.error,
                                        ),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (shouldDelete == true) {
                                if (context.mounted) {
                                  context.read<AutoResponseProvider>().deleteResponse(response['id']);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Response deleted'),
                                      backgroundColor: isDark ? const Color(0xFF1A1F2E) : Colors.black87,
                                      action: SnackBarAction(
                                        label: 'Undo',
                                        onPressed: () {
                                          context.read<AutoResponseProvider>().addResponse(response);
                                        },
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: Icon(
                              Icons.delete_outline,
                              color: SafeJetColors.error.withOpacity(0.7),
                            ),
                        iconSize: 20,
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    response['message'],
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddResponseDialog(bool isDark) {
    _messageController.clear();
    _typeController.clear();
    
    _showResponseDialog(
      isDark,
      isEdit: false,
      onSave: (message, type) {
        context.read<AutoResponseProvider>().addResponse({
            'id': DateTime.now().toString(),
            'message': message,
            'type': type,
        });
      },
    );
  }

  void _showEditResponseDialog(Map<String, dynamic> response, bool isDark) {
    _messageController.text = response['message'];
    _typeController.text = response['type'];
    
    _showResponseDialog(
      isDark,
      isEdit: true,
      onSave: (message, type) {
        context.read<AutoResponseProvider>().updateResponse(
          response['id'],
          {
            'id': response['id'],
            'message': message,
            'type': type,
          },
        );
      },
    );
  }

  void _showResponseDialog(
    bool isDark, {
    required bool isEdit,
    required Function(String message, String type) onSave,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog.fullscreen(
          child: Scaffold(
            backgroundColor: isDark ? const Color(0xFF1A1F2E) : Colors.white,
            appBar: AppBar(
              backgroundColor: isDark ? const Color(0xFF1A1F2E) : Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.close,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                isEdit ? 'Edit Response' : 'New Response',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (_messageController.text.isNotEmpty && 
                        _typeController.text.isNotEmpty) {
                      onSave(_messageController.text, _typeController.text);
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    isEdit ? 'Save' : 'Add',
                    style: TextStyle(
                      color: _selectedColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preview
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getSelectedColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getSelectedIcon(),
                            color: _getSelectedColor(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getSelectedColor().withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _typeController.text.isEmpty 
                                      ? 'Type' 
                                      : _typeController.text,
                  style: TextStyle(
                                    color: _getSelectedColor(),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                  ),
                ),
                const SizedBox(height: 8),
                              Text(
                                _messageController.text.isEmpty 
                                    ? 'Your message will appear here'
                                    : _messageController.text,
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Type Field
                Text(
                    'Response Type',
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                  Container(
                            decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _typeController.text.isNotEmpty ? _typeController.text : null,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      dropdownColor: isDark 
                          ? const Color(0xFF1A1F2E)
                          : Colors.white,
                      items: _responseTypeConfig.keys.map((type) {
                        final config = _responseTypeConfig[type]!;
                        return DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              Icon(
                                config['iconData'] as IconData, 
                                color: _hexToColor(config['color'] as String),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                type,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _typeController.text = value;
                          setDialogState(() {});
                        }
                      },
                      hint: Text(
                        'Select response type',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Message Field
                  Text(
                    'Message',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _messageController,
                    maxLines: 3,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Enter your response message',
                      filled: true,
                      fillColor: isDark 
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleDelete(Map<String, dynamic> response) {
    // ... your existing delete dialog code ...
    // When confirmed:
    context.read<AutoResponseProvider>().deleteResponse(response['id']);
  }

  Widget _buildShimmerLoading(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildShimmerCard(isDark),
      ),
    );
  }

  Widget _buildShimmerCard(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 80,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    for (var config in _responseTypeConfig.values) {
      if (config['icon'] == iconName) {
        return config['iconData'] as IconData;
      }
    }
    return Icons.message;
  }

  String _getIconString(IconData icon) {
    for (var config in _responseTypeConfig.values) {
      if (config['iconData'] == icon) {
        return config['icon'] as String;
      }
    }
    return 'message';
  }

  Color _getSelectedColor() {
    if (_typeController.text.isEmpty) return const Color(0xFF4CAF50);
    final config = _responseTypeConfig[_typeController.text];
    if (config == null) return const Color(0xFF4CAF50);
    return _hexToColor(config['color'] as String);
  }

  IconData _getSelectedIcon() {
    if (_typeController.text.isEmpty) return Icons.message;
    final config = _responseTypeConfig[_typeController.text];
    if (config == null) return Icons.message;
    return config['iconData'] as IconData;
  }

  Color _hexToColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
  }
} 