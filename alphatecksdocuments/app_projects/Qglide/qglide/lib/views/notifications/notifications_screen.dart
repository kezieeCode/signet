import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../cubits/theme_cubit.dart';
import '../../services/api_service.dart';
import '../../utils/responsive_helper.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _todayNotifications = [];
  List<Map<String, dynamic>> _yesterdayNotifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getRiderNotifications();

      if (response['success'] && mounted) {
        final data = response['data'];
        
        if (data is Map && data.containsKey('notifications')) {
          final notifications = data['notifications'] as List;
          
          final List<Map<String, dynamic>> today = [];
          final List<Map<String, dynamic>> yesterday = [];
          
          for (var notif in notifications) {
            final mappedNotif = _mapNotification(notif);
            final timestamp = notif['created_at'] ?? notif['timestamp'] ?? '';
            
            // Check if notification is from today or yesterday
            if (_isToday(timestamp)) {
              today.add(mappedNotif);
            } else if (_isYesterday(timestamp)) {
              yesterday.add(mappedNotif);
            }
          }
          
          setState(() {
            _todayNotifications = today;
            _yesterdayNotifications = yesterday;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _mapNotification(Map<String, dynamic> notif) {
    final type = (notif['type'] ?? '').toString().toLowerCase();
    final isHighPriority = notif['priority'] == 'high' || type == 'promotion' || type == 'promo';
    
    return {
      'id': notif['id'] ?? '',
      'title': notif['title'] ?? 'Notification',
      'description': notif['message'] ?? notif['description'] ?? '',
      'timestamp': _formatTimestamp(notif['created_at'] ?? notif['timestamp'] ?? ''),
      'icon': _getIconForType(type),
      'iconColor': _getColorForType(type),
      'iconBgColor': _getColorForType(type),
      'hasSpecialBorder': isHighPriority,
    };
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'ride':
      case 'trip':
        return Icons.directions_car;
      case 'promotion':
      case 'promo':
      case 'offer':
        return Icons.local_offer;
      case 'parcel':
      case 'delivery':
        return Icons.local_shipping;
      case 'wallet':
      case 'payment':
        return Icons.account_balance_wallet;
      case 'security':
      case 'alert':
        return Icons.security;
      case 'system':
      case 'update':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'ride':
      case 'trip':
        return Colors.lightBlue;
      case 'promotion':
      case 'promo':
      case 'offer':
        return Colors.yellow;
      case 'parcel':
      case 'delivery':
        return Colors.orange;
      case 'wallet':
      case 'payment':
        return Colors.purple;
      case 'security':
      case 'alert':
        return Colors.green;
      case 'system':
      case 'update':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(String timestamp) {
    if (timestamp.isEmpty) return 'Just now';
    
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} min ago';
      } else if (difference.inHours < 24 && dateTime.day == now.day) {
        return DateFormat('h:mm a').format(dateTime);
      } else if (difference.inHours < 48 && dateTime.day == now.subtract(const Duration(days: 1)).day) {
        return 'Yesterday, ${DateFormat('h:mm a').format(dateTime)}';
      } else {
        return DateFormat('MMM d, h:mm a').format(dateTime);
      }
    } catch (e) {
      return timestamp;
    }
  }

  bool _isToday(String timestamp) {
    if (timestamp.isEmpty) return true;
    
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      return dateTime.year == now.year &&
             dateTime.month == now.month &&
             dateTime.day == now.day;
    } catch (e) {
      return false;
    }
  }

  bool _isYesterday(String timestamp) {
    if (timestamp.isEmpty) return false;
    
    try {
      final dateTime = DateTime.parse(timestamp);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      return dateTime.year == yesterday.year &&
             dateTime.month == yesterday.month &&
             dateTime.day == yesterday.day;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return Scaffold(
          backgroundColor: themeState.backgroundColor,
          appBar: AppBar(
            backgroundColor: themeState.backgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: AppColors.gold,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: Text(
              'Notifications',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: themeState.textPrimary,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(
                  Icons.more_vert,
                  color: themeState.textPrimary,
                ),
                onPressed: () {
                  // Handle more options
                },
              ),
            ],
          ),
          body: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.gold,
                  ),
                )
              : _todayNotifications.isEmpty && _yesterdayNotifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: ResponsiveHelper.getResponsiveIconSize(context, 80),
                            color: themeState.textSecondary,
                          ),
                          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                          Text(
                            'No notifications yet',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: themeState.textPrimary,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                          Text(
                            'We\'ll notify you when something arrives',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: themeState.textSecondary,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Today section
                          if (_todayNotifications.isNotEmpty) ...[
                            Text(
                              'Today',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: themeState.textPrimary,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                            ..._todayNotifications.map((notification) => _buildNotificationCard(notification, themeState)),
                            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                          ],
                          
                          // Yesterday section
                          if (_yesterdayNotifications.isNotEmpty) ...[
                            Text(
                              'Yesterday',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: themeState.textPrimary,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                            ..._yesterdayNotifications.map((notification) => _buildNotificationCard(notification, themeState)),
                          ],
                        ],
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, ThemeState themeState) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveSpacing(context, 16)),
      decoration: BoxDecoration(
        color: themeState.panelBg,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
        border: notification['hasSpecialBorder'] 
          ? Border(
              left: BorderSide(
                color: AppColors.gold,
                width: 4,
              ),
            )
          : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: ResponsiveHelper.getResponsiveSpacing(context, 48),
              height: ResponsiveHelper.getResponsiveSpacing(context, 48),
              decoration: BoxDecoration(
                color: notification['iconBgColor'].withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notification['icon'],
                color: notification['iconColor'],
                size: ResponsiveHelper.getResponsiveIconSize(context, 24),
              ),
            ),
            
            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with special indicator
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification['title'],
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: themeState.textPrimary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (notification['hasSpecialBorder']) ...[
                        Container(
                          width: ResponsiveHelper.getResponsiveSpacing(context, 8),
                          height: ResponsiveHelper.getResponsiveSpacing(context, 8),
                          decoration: BoxDecoration(
                            color: notification['iconColor'],
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                  
                  // Description
                  Text(
                    notification['description'],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: themeState.textPrimary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    ),
                  ),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                  
                  // Timestamp
                  Text(
                    notification['timestamp'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: themeState.textSecondary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
