import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/theme_cubit.dart';
import '../../utils/responsive_helper.dart';
import '../main_navigation/main_navigation_screen.dart';

class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  int _selectedTabIndex = 0; // 0: Open, 1: Closed

  final List<Map<String, dynamic>> _openTickets = [
    {
      'id': 'QG-8A4B2C',
      'title': 'Lost Item in Ride',
      'status': 'Open',
      'statusColor': Colors.green,
      'description': 'I think I left my wallet in the back seat of my last trip to the Pearl. Can you help me contact the driver?',
      'lastUpdate': '2 hours ago',
    },
    {
      'id': 'QG-9F1D5E',
      'title': 'Incorrect Fare Charged',
      'status': 'In Progress',
      'statusColor': Colors.orange,
      'description': 'The final fare was much higher than the estimate. The driver took a longer route than necessary.',
      'lastUpdate': '1 day ago',
    },
  ];

  final List<Map<String, dynamic>> _closedTickets = [
    {
      'id': 'QG-7C3E9A',
      'title': 'Driver Issue',
      'status': 'Resolved',
      'statusColor': Colors.blue,
      'description': 'Driver was unprofessional and took a very long route.',
      'lastUpdate': '3 days ago',
    },
    {
      'id': 'QG-5B8D2F',
      'title': 'Payment Problem',
      'status': 'Closed',
      'statusColor': Colors.grey,
      'description': 'Payment was charged twice for the same ride.',
      'lastUpdate': '1 week ago',
    },
  ];

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
              'Support Tickets',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: themeState.textPrimary,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // Tab selector
              Container(
                margin: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
                decoration: BoxDecoration(
                  color: themeState.panelBg,
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 8)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTabIndex = 0;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: ResponsiveHelper.getResponsiveSpacing(context, 12),
                          ),
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 0 ? AppColors.gold : Colors.transparent,
                            borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 8)),
                          ),
                          child: Text(
                            'Open',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _selectedTabIndex == 0 ? Colors.black : themeState.textPrimary,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTabIndex = 1;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: ResponsiveHelper.getResponsiveSpacing(context, 12),
                          ),
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 1 ? AppColors.gold : Colors.transparent,
                            borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 8)),
                          ),
                          child: Text(
                            'Closed',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _selectedTabIndex == 1 ? Colors.black : themeState.textPrimary,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Tickets list
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
                  ),
                  itemCount: _selectedTabIndex == 0 ? _openTickets.length : _closedTickets.length,
                  itemBuilder: (context, index) {
                    final tickets = _selectedTabIndex == 0 ? _openTickets : _closedTickets;
                    final ticket = tickets[index];
                    return _buildTicketCard(ticket, themeState);
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              // Handle create new ticket
            },
            backgroundColor: AppColors.gold,
            child: Icon(
              Icons.add,
              color: Colors.black,
              size: ResponsiveHelper.getResponsiveIconSize(context, 24),
            ),
          ),
          bottomNavigationBar: _buildBottomNavigationBar(themeState),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar(ThemeState themeState) {
    return Container(
      decoration: BoxDecoration(
        color: themeState.panelBg,
        border: Border(
          top: BorderSide(
            color: themeState.fieldBorder,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Container(
          height: ResponsiveHelper.getResponsiveSpacing(context, 80),
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
            vertical: ResponsiveHelper.getResponsiveSpacing(context, 8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, 'Home', 0, themeState),
              _buildNavItem(Icons.history, 'Activity', 1, themeState),
              _buildNavItem(Icons.account_balance_wallet_outlined, 'Wallet', 2, themeState),
              _buildNavItem(Icons.person_outline, 'Profile', 3, themeState),
              _buildNavItem(Icons.settings_outlined, 'Settings', 4, themeState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData outlinedIcon, String label, int index, ThemeState themeState) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        // Immediate feedback
      },
      onTap: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => MainNavigationScreen(initialTabIndex: index),
          ),
          (route) => false,
        );
        // Navigate to main navigation screen with selected tab
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getResponsiveSpacing(context, 12),
          vertical: ResponsiveHelper.getResponsiveSpacing(context, 8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              outlinedIcon,
              color: themeState.textSecondary,
              size: ResponsiveHelper.getResponsiveIconSize(context, 24),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: themeState.textSecondary,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket, ThemeState themeState) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveSpacing(context, 16)),
      padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
      decoration: BoxDecoration(
        color: themeState.panelBg,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and status row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  ticket['title'],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: themeState.textPrimary,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: ResponsiveHelper.getResponsiveSpacing(context, 8),
                    height: ResponsiveHelper.getResponsiveSpacing(context, 8),
                    decoration: BoxDecoration(
                      color: ticket['statusColor'],
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 6)),
                  Text(
                    ticket['status'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ticket['statusColor'],
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
          
          // Ticket number
          Text(
            'Ticket #${ticket['id']}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: themeState.textSecondary,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
            ),
          ),
          
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
          
          // Description
          Text(
            ticket['description'],
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: themeState.textPrimary,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
            ),
          ),
          
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
          
          // Bottom row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last update: ${ticket['lastUpdate']}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: themeState.textSecondary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Handle view details
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Details',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.gold,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.gold,
                      size: ResponsiveHelper.getResponsiveIconSize(context, 12),
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
}
