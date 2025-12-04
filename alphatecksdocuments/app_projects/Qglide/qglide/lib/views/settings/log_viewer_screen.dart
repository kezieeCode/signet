import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../utils/crash_logger.dart';
import '../../utils/responsive_helper.dart';
import '../../cubits/theme_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  String _logContent = 'Loading logs...';
  String _filteredContent = '';
  bool _isLoading = true;
  String? _logFilePath;
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final content = await CrashLogger.getLogContent();
      final filePath = await CrashLogger.getLogFilePath();
      
      setState(() {
        _logContent = content;
        _filteredContent = content;
        _logFilePath = filePath;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _logContent = 'Error loading logs: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _copyLogs() async {
    final textToCopy = _searchController.text.isNotEmpty ? _filteredContent : _logContent;
    await Clipboard.setData(ClipboardData(text: textToCopy));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logs copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareLogs() async {
    try {
      final textToShare = _searchController.text.isNotEmpty ? _filteredContent : _logContent;
      await Share.share(
        textToShare,
        subject: 'QGlide App Logs',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing logs: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _clearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Logs'),
        content: const Text('Are you sure you want to clear all logs?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await CrashLogger.clearLogs();
      await _loadLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logs cleared'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return Scaffold(
          backgroundColor: themeState.backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'App Logs',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: themeState.textPrimary,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(_showSearch ? Icons.search_off : Icons.search),
                onPressed: () {
                  setState(() {
                    _showSearch = !_showSearch;
                    if (!_showSearch) {
                      _searchController.clear();
                      _filteredContent = _logContent;
                    }
                  });
                },
                tooltip: _showSearch ? 'Hide search' : 'Search logs',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadLogs,
                tooltip: 'Refresh',
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _shareLogs,
                tooltip: 'Share logs',
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: _copyLogs,
                tooltip: 'Copy logs',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _clearLogs,
                tooltip: 'Clear logs',
              ),
            ],
          ),
          body: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).primaryColor,
                  ),
                )
              : Column(
                  children: [
                    if (_logFilePath != null)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(
                          ResponsiveHelper.getResponsiveSpacing(context, 12),
                        ),
                        color: themeState.fieldBg,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Log file location:',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: themeState.textSecondary,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                            SelectableText(
                              _logFilePath!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: themeState.textSecondary,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_showSearch)
                      Container(
                        padding: EdgeInsets.all(
                          ResponsiveHelper.getResponsiveSpacing(context, 12),
                        ),
                        color: themeState.fieldBg,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search logs...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: themeState.fieldBorder),
                            ),
                            filled: true,
                            fillColor: themeState.backgroundColor,
                          ),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: themeState.textPrimary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                          ),
                        ),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadLogs,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(
                            ResponsiveHelper.getResponsiveSpacing(context, 16),
                          ),
                          child: SelectableText(
                            _filteredContent.isEmpty ? _logContent : _filteredContent,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: themeState.textPrimary,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                              fontFamily: 'monospace',
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(
                        ResponsiveHelper.getResponsiveSpacing(context, 8),
                      ),
                      color: themeState.fieldBg,
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: ResponsiveHelper.getResponsiveIconSize(context, 16),
                            color: themeState.textSecondary,
                          ),
                          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                          Expanded(
                            child: Text(
                              'Pull down to refresh • Use search to filter • Share to export',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: themeState.textSecondary,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}


