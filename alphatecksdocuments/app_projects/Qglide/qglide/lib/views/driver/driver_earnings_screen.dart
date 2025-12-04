import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/theme_cubit.dart';
import '../../cubits/driver_cubit.dart';
import '../../utils/responsive_helper.dart';
import '../../services/api_service.dart';
import 'withdraw_money_screen.dart';
import 'driver_profile_screen.dart';

class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen> {
  int _selectedPeriod = 1; // 0: Daily, 1: Weekly, 2: Monthly
  
  // Loading and data state
  bool _isLoading = true;
  bool _isLoadingTrips = true;
  
  // Today's earnings (displayed)
  double _todayNetAmount = 0.0;
  int _todayRidesCompleted = 0;
  String _currency = 'QAR';
  
  // Completed trips from API
  List<Map<String, dynamic>> _completedTrips = [];

  final List<Map<String, dynamic>> _bottomNavItems = [
    {'label': 'Home', 'icon': Icons.home},
    {'label': 'Earnings', 'icon': Icons.pie_chart},
    {'label': 'Profile', 'icon': Icons.person},
  ];

  @override
  void initState() {
    super.initState();
    _fetchDriverEarnings();
    _fetchCompletedTrips();
  }
  
  Future<void> _fetchDriverEarnings() async {
    try {
      final response = await ApiService.getDriverEarnings();
      
      if (response['success'] == true && response['data'] != null) {
        // Handle potential double nesting
        final outerData = response['data'];
        final data = outerData['data'] ?? outerData;
        
        if (mounted) {
          setState(() {
            // Today's earnings
            final today = data['today'] ?? {};
            final todayEarnings = today['earnings'] ?? {};
            _todayNetAmount = (todayEarnings['net_amount'] ?? 0).toDouble();
            _todayRidesCompleted = today['rides_completed'] ?? 0;
            _currency = todayEarnings['currency'] ?? 'QAR';
            
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _fetchCompletedTrips() async {
    try {
      final response = await ApiService.getDriverCompletedTrips();
      
      if (response['success'] == true && response['data'] != null) {
        // Handle potential double nesting
        final outerData = response['data'];
        final data = outerData['data'] ?? outerData;
        
        // Extract trips array
        final trips = data['trips'] as List?;
        
        if (trips != null && mounted) {
          setState(() {
            _completedTrips = trips.map((trip) {
              // Parse date
              String formattedDate = 'N/A';
              if (trip['completed_at'] != null) {
                try {
                  final DateTime dateTime = DateTime.parse(trip['completed_at']);
                  formattedDate = '${_monthName(dateTime.month)} ${dateTime.day}, ${_formatTime(dateTime)}';
                } catch (e) {
                  formattedDate = trip['completed_at'].toString();
                }
              }
              
              // Calculate fare
              final fare = (trip['fare'] ?? 0).toDouble();
              final currency = trip['currency'] ?? 'QAR';
              
              // Calculate distance
              final distance = (trip['distance'] ?? 0).toDouble();
              
              return {
                'destination': trip['dropoff_address'] ?? 'Unknown',
                'date': formattedDate,
                'earnings': '+ $currency ${fare.toStringAsFixed(2)}',
                'distance': '${distance.toStringAsFixed(1)} km',
                'icon': Icons.location_on,
                'type': 'ride',
              };
            }).toList();
            
            _isLoadingTrips = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingTrips = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTrips = false;
        });
      }
    }
  }
  
  String _monthName(int month) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month];
  }
  
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return BlocBuilder<DriverCubit, DriverState>(
          builder: (context, driverState) {
            return Scaffold(
              backgroundColor: themeState.isDarkTheme ? const Color(0xFF0D182E) : Colors.grey.shade100,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: themeState.textPrimary,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Earnings',
                  style: TextStyle(
                    color: themeState.textPrimary,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.calendar_today,
                      color: themeState.textPrimary,
                    ),
                    onPressed: () {
                      // Handle calendar selection
                    },
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Available Balance Card
                    _buildAvailableBalanceCard(themeState),
                    
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                    
                    // Time Period Selection
                    _buildTimePeriodSelector(themeState),
                    
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                    
                    // This Week Summary
                    _buildThisWeekSummary(themeState),
                    
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                    
                    // Completed Trips Header
                    Text(
                      'Completed Trips',
                      style: TextStyle(
                        color: themeState.textPrimary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                    
                    // Completed Trips List
                    _buildCompletedTripsList(themeState),
                  ],
                ),
              ),
              bottomNavigationBar: _buildBottomNavigation(themeState, driverState),
            );
          },
        );
      },
    );
  }

  Widget _buildAvailableBalanceCard(ThemeState themeState) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 24)),
      decoration: BoxDecoration(
        color: themeState.isDarkTheme ? const Color(0xFF1A2B47) : Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Balance',
            style: TextStyle(
              color: themeState.textSecondary,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
          _isLoading
              ? const CircularProgressIndicator()
              : Text(
                  '$_currency ${_todayNetAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: themeState.textPrimary,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 32),
                    fontWeight: FontWeight.bold,
                  ),
                ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
          Center(
            child: Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WithdrawMoneyScreen(
                        availableBalance: _todayNetAmount,
                        currency: _currency,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Withdraw Money',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePeriodSelector(ThemeState themeState) {
    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 4)),
      decoration: BoxDecoration(
        color: themeState.isDarkTheme ? const Color(0xFF1A2B47) : Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
      ),
      child: Row(
        children: [
          _buildPeriodTab('Daily', 0, themeState),
          _buildPeriodTab('Weekly', 1, themeState),
          _buildPeriodTab('Monthly', 2, themeState),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(String label, int index, ThemeState themeState) {
    final isSelected = _selectedPeriod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = index),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveHelper.getResponsiveSpacing(context, 12),
          ),
          decoration: BoxDecoration(
            color: isSelected 
                ? (themeState.isDarkTheme ? const Color(0xFF0D182E) : Colors.grey.shade200)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 8)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? themeState.textPrimary : themeState.textSecondary,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThisWeekSummary(ThemeState themeState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'This Week',
              style: TextStyle(
                color: themeState.textPrimary,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Oct 1 - Oct 7',
              style: TextStyle(
                color: themeState.textSecondary,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Earnings', 
                _isLoading ? '...' : '$_currency ${_todayNetAmount.toStringAsFixed(2)}', 
                themeState
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
            Expanded(
              child: _buildSummaryCard(
                'Completed Trips', 
                _isLoading ? '...' : '$_todayRidesCompleted', 
                themeState
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, ThemeState themeState) {
    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 20)),
      decoration: BoxDecoration(
        color: themeState.isDarkTheme ? const Color(0xFF1A2B47) : Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: themeState.textSecondary,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
          Text(
            value,
            style: TextStyle(
              color: themeState.textPrimary,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedTripsList(ThemeState themeState) {
    if (_isLoadingTrips) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 40)),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
          ),
        ),
      );
    }
    
    if (_completedTrips.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 40)),
          child: Column(
            children: [
              Icon(
                Icons.inbox_outlined,
                size: ResponsiveHelper.getResponsiveIconSize(context, 64),
                color: themeState.textSecondary.withOpacity(0.5),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
              Text(
                'No completed trips yet',
                style: TextStyle(
                  color: themeState.textSecondary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _completedTrips.length,
      separatorBuilder: (context, index) => SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
      itemBuilder: (context, index) {
        final trip = _completedTrips[index];
        return _buildTripItem(trip, themeState);
      },
    );
  }

  Widget _buildTripItem(Map<String, dynamic> trip, ThemeState themeState) {
    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
      decoration: BoxDecoration(
        color: themeState.isDarkTheme ? const Color(0xFF1A2B47) : Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Trip Icon
          Container(
            width: ResponsiveHelper.getResponsiveSpacing(context, 40),
            height: ResponsiveHelper.getResponsiveSpacing(context, 40),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 8)),
            ),
            child: Icon(
              trip['icon'],
              color: Colors.amber,
              size: ResponsiveHelper.getResponsiveIconSize(context, 20),
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
          
          // Trip Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip['destination'],
                  style: TextStyle(
                    color: themeState.textPrimary,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                Text(
                  trip['date'],
                  style: TextStyle(
                    color: themeState.textSecondary,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Earnings and Distance
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                trip['earnings'],
                style: TextStyle(
                  color: Colors.green,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
              Text(
                trip['distance'],
                style: TextStyle(
                  color: themeState.textSecondary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(ThemeState themeState, DriverState driverState) {
    return Container(
      decoration: BoxDecoration(
        color: themeState.isDarkTheme ? const Color(0xFF1A2B47) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.getResponsiveSpacing(context, 20),
            vertical: ResponsiveHelper.getResponsiveSpacing(context, 8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _bottomNavItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == 1; // Earnings tab is selected
              
              return InkWell(
                onTap: () {
                  context.read<DriverCubit>().setBottomNavIndex(index);
                  if (index == 0) {
                    Navigator.pop(context); // Go back to home
                  } else if (index == 2) {
                    // Navigate to Profile screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DriverProfileScreen()),
                    ).then((_) {
                      context.read<DriverCubit>().setBottomNavIndex(1); // Reset to earnings
                    });
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item['icon'],
                      color: isSelected ? Colors.amber : themeState.textSecondary,
                      size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                    Text(
                      item['label'],
                      style: TextStyle(
                        color: isSelected ? Colors.amber : themeState.textSecondary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
