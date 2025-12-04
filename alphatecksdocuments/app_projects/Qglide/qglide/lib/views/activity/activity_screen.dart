import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../../l10n/app_localizations.dart';
import '../../cubits/theme_cubit.dart';
import '../../utils/responsive_helper.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../services/places_service.dart';
import '../main_navigation/main_navigation_screen.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> with TickerProviderStateMixin {
  String _selectedFilter = 'all';
  bool _isLoading = true;
  List<Map<String, dynamic>> _allRides = [];
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _fetchRideHistory();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchRideHistory() async {
    _animationController.repeat(reverse: true);
    try {
      final response = await ApiService.getRideHistory();

      if (response['success'] && response['data'] != null) {
        // Handle double nesting
        final data = response['data']['data'] ?? response['data'];
        final rides = data['rides'] ?? [];
        if (mounted) {
          setState(() {
            _allRides = List<Map<String, dynamic>>.from(rides);
            _isLoading = false;
          });
          _animationController.stop();
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _animationController.stop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _animationController.stop();
      }
    }
  }

  // Format date from ISO string to readable format
  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'N/A';
    try {
      final l10n = AppLocalizations.of(context)!;
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return l10n.today;
      } else if (difference.inDays == 1) {
        return l10n.yesterday;
      } else {
        return DateFormat('MMM dd, yyyy').format(date);
      }
    } catch (e) {
      return 'N/A';
    }
  }

  // Format time from ISO string
  String _formatTime(String? isoDate) {
    if (isoDate == null) return 'N/A';
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('h:mm a').format(date);
    } catch (e) {
      return 'N/A';
    }
  }

  List<Map<String, dynamic>> get _filteredRides {
    if (_selectedFilter == 'all') return _allRides;
    if (_selectedFilter == 'completed') {
      return _allRides.where((ride) => ride['status'] == 'completed').toList();
    }
    if (_selectedFilter == 'cancelled') {
      return _allRides.where((ride) => ride['status'] == 'cancelled').toList();
    }
    return _allRides;
  }

  Map<String, List<Map<String, dynamic>>> get _groupedRides {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var ride in _filteredRides) {
      String dateGroup = _formatDate(ride['requested_at']);
      if (!grouped.containsKey(dateGroup)) {
        grouped[dateGroup] = [];
      }
      grouped[dateGroup]!.add(ride);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return Scaffold(
          backgroundColor: themeState.backgroundColor,
          appBar: AppBar(
            backgroundColor: themeState.backgroundColor,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text(
              l10n.activity,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: themeState.textPrimary,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 24),
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              Container(
                margin: EdgeInsets.only(right: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                child: Icon(
                  Icons.filter_list,
                  color: Colors.amber,
                  size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Filter Buttons
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
                  vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildFilterButton('all', l10n.all, themeState),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                    Expanded(
                      child: _buildFilterButton('completed', l10n.completed, themeState),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                    Expanded(
                      child: _buildFilterButton('cancelled', l10n.cancelled, themeState),
                    ),
                  ],
                ),
              ),

              // Activity List
              Expanded(
                child: Stack(
                  children: [
                    // Main content - always visible
                    _filteredRides.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noRidesFound,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: themeState.textSecondary,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
                          ),
                          itemCount: _groupedRides.length,
                          itemBuilder: (context, index) {
                            String date = _groupedRides.keys.elementAt(index);
                            List<Map<String, dynamic>> rides = _groupedRides[date]!;
                      
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Date Header
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
                                  ),
                                  child: Text(
                                    date,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: themeState.textPrimary,
                                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                
                                // Rides for this date
                                ...rides.map((ride) => _buildRideCard(ride, themeState)).toList(),
                              ],
                            );
                          },
                        ),
                    
                    // Loading overlay - conditional
                    if (_isLoading)
                      Container(
                        color: Colors.black.withValues(alpha: 0.7),
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _animation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _animation.value,
                                child: Image.asset(
                                  'assets/images/logo.webp',
                                  width: 80,
                                  height: 80,
                                ),
                              );
                            },
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

  Widget _buildRideCard(Map<String, dynamic> ride, ThemeState themeState) {
    final status = ride['status'] ?? 'unknown';
    final pickupAddress = ride['pickup_address'] ?? 'Pickup location';
    final dropoffAddress = ride['dropoff_address'] ?? 'Dropoff location';
    final fare = (ride['estimated_fare'] ?? 0).toDouble();
    final requestedAt = ride['requested_at'];
    final completedAt = ride['completed_at'];
    final cancelledAt = ride['cancelled_at'];
    
    // Use completed_at if available, else cancelled_at, else requested_at
    final displayDate = completedAt ?? cancelledAt ?? requestedAt;
    final formattedTime = _formatTime(displayDate);
    
    // Status color and icon
    Color statusColor = themeState.textSecondary;
    IconData statusIcon = Icons.directions_car;
    
    if (status == 'completed') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (status == 'cancelled') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    } else if (status == 'requested') {
      statusColor = Colors.orange;
      statusIcon = Icons.access_time;
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveSpacing(context, 12)),
      padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
      decoration: BoxDecoration(
        color: themeState.fieldBg,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context, 16),
        ),
        border: Border.all(
          color: themeState.fieldBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Status icon and time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    statusIcon,
                    color: statusColor,
                    size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                  Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: statusColor,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                formattedTime,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: themeState.textSecondary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                ),
              ),
            ],
          ),
          
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
          
          // Pickup location
          Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Icon(
                Icons.my_location,
                color: Colors.amber,
                size: ResponsiveHelper.getResponsiveIconSize(context, 16),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 8)),
              Expanded(
                child: Text(
                  pickupAddress,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: themeState.textPrimary,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
          
          // Dropoff location
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on,
                color: Colors.red,
                size: ResponsiveHelper.getResponsiveIconSize(context, 16),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 8)),
              Expanded(
                child: Text(
                  dropoffAddress,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: themeState.textPrimary,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
          ),
          
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
          
          // Fare
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getResponsiveSpacing(context, 12),
                vertical: ResponsiveHelper.getResponsiveSpacing(context, 6),
              ),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveBorderRadius(context, 8),
                ),
              ),
              child: Text(
                'QAR ${fare.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.amber,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),

          // Repeat Ride button (only show for completed rides)
          if (status == 'completed')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _repeatRide(ride),
                icon: Icon(Icons.repeat, size: 18),
                label: Text('Repeat Ride'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String filterValue, String label, ThemeState themeState) {
    bool isSelected = _selectedFilter == filterValue;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filterValue;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveHelper.getResponsiveSpacing(context, 12),
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber : themeState.fieldBg,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(context, 16),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: isSelected ? Colors.black : themeState.textPrimary,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _repeatRide(Map<String, dynamic> ride) async {
    final dropoffAddress = ride['dropoff_address'];
    
    // Validate we have dropoff address
    if (dropoffAddress == null || dropoffAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to repeat this ride. Missing destination address.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Show loading indicator
    setState(() => _isLoading = true);
    _animationController.repeat(reverse: true);
    
    try {
      // Get user's current location with address
      Map<String, dynamic>? locationData = await LocationService.getCurrentLocationWithAddress();
      
      if (locationData == null) {
        throw Exception('Unable to get current location');
      }
      
      final position = locationData['position'] as Position;
      final pickupAddress = locationData['address'] as String;
      
      // Convert dropoff address to coordinates
      final dropoffCoordinates = await PlacesService.getCoordinatesFromAddress(dropoffAddress);
      
      if (dropoffCoordinates == null) {
        throw Exception('Unable to find coordinates for destination address');
      }
      
      if (mounted) {
        setState(() => _isLoading = false);
        _animationController.stop();
        
        // Navigate to home screen with pre-filled booking data
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => MainNavigationScreen(
              initialTabIndex: 0,
              prefilledBooking: {
                'pickupAddress': pickupAddress,
                'pickupLat': position.latitude,
                'pickupLng': position.longitude,
                'destinationAddress': dropoffAddress,
                'destinationLat': dropoffCoordinates.latitude,
                'destinationLng': dropoffCoordinates.longitude,
              },
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _animationController.stop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to prepare ride: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
