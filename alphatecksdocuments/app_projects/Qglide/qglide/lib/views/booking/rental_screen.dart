import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/theme_cubit.dart';
import '../../utils/responsive_helper.dart';
import '../main_navigation/main_navigation_screen.dart';
import 'car_details_screen.dart';

class RentalScreen extends StatefulWidget {
  const RentalScreen({super.key});

  @override
  State<RentalScreen> createState() => _RentalScreenState();
}

class _RentalScreenState extends State<RentalScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedBrand = 'All';
  final List<String> _brands = ['All', 'Toyota', 'Honda', 'BMW', 'Mercedes Benz'];
  
  // Sample car data - in production, this would come from an API
  final List<Map<String, dynamic>> _cars = [
    {
      'model': 'Toyota Prado',
      'year': '2020',
      'image': 'assets/images/prado.png',
      'location': 'Owerri, Imo state',
      'price': 'N30,000/hr',
      'rating': 4.4,
      'maxSpeed': '180km/h',
      'engineType': 'V8',
      'passengers': '5',
      'description': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.',
      'carClass': 'Premium',
      'ownerName': 'Julia Roberts',
      'ownerRole': 'Owner',
    },
    {
      'model': 'Toyota Camry',
      'year': '2018',
      'image': 'assets/images/corolla.png',
      'location': 'Owerri, Imo state',
      'price': 'N30,000/hr',
      'rating': 4.4,
      'maxSpeed': '200km/h',
      'engineType': 'V6',
      'passengers': '5',
      'description': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.',
      'carClass': 'Standard',
      'ownerName': 'John Doe',
      'ownerRole': 'Owner',
    },
    {
      'model': 'Lexus Rx350',
      'year': '2020',
      'image': 'assets/images/lexus.png',
      'location': 'Owerri, Imo state',
      'price': 'N30,000/hr',
      'rating': 4.4,
      'maxSpeed': '220km/h',
      'engineType': 'V6',
      'passengers': '5',
      'description': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.',
      'carClass': 'Premium',
      'ownerName': 'Sarah Johnson',
      'ownerRole': 'Owner',
    },
    {
      'model': 'Mercedes Benz C300',
      'year': '2024',
      'image': 'assets/images/benz.png',
      'location': 'Trans Ekulu, Enugu State',
      'price': 'N30,000/hr',
      'rating': 4.4,
      'maxSpeed': '250km/h',
      'engineType': 'V6',
      'passengers': '5',
      'description': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.',
      'carClass': 'Luxury',
      'ownerName': 'Michael Brown',
      'ownerRole': 'Owner',
    },
    {
      'model': 'Toyota Camry',
      'year': '2018',
      'image': 'assets/images/corolla.png',
      'location': 'Owerri, Imo state',
      'price': 'N30,000/hr',
      'rating': 4.4,
      'maxSpeed': '200km/h',
      'engineType': 'V6',
      'passengers': '5',
      'description': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.',
      'carClass': 'Standard',
      'ownerName': 'Emily Davis',
      'ownerRole': 'Owner',
    },
    {
      'model': 'Toyota Prado',
      'year': '2020',
      'image': 'assets/images/prado.png',
      'location': 'Owerri, Imo state',
      'price': 'N30,000/hr',
      'rating': 4.4,
      'maxSpeed': '180km/h',
      'engineType': 'V8',
      'passengers': '5',
      'description': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.',
      'carClass': 'Premium',
      'ownerName': 'David Wilson',
      'ownerRole': 'Owner',
    },
  ];

  List<Map<String, dynamic>> get _filteredCars {
    if (_selectedBrand == 'All') {
      return _cars;
    }
    return _cars.where((car) {
      final model = car['model'] as String;
      return model.toLowerCase().contains(_selectedBrand.toLowerCase());
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return Scaffold(
          backgroundColor: themeState.backgroundColor,
          bottomNavigationBar: _buildBottomNavigationBar(themeState),
          appBar: AppBar(
            backgroundColor: themeState.backgroundColor,
            elevation: 0,
            leading: Container(
              margin: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 8)),
              decoration: BoxDecoration(
                color: themeState.fieldBg,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: AppColors.gold,
                  size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            title: Text(
              'Car Rental',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: themeState.isDarkTheme 
                  ? themeState.textPrimary 
                  : const Color(0xFF0D182E), // Dark blue text
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
          ),
          body: Container(
            color: themeState.isDarkTheme ? themeState.backgroundColor : Colors.white,
            child: Column(
              children: [
                // Search Bar and Filter
                Padding(
                  padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: themeState.isDarkTheme ? themeState.fieldBg : Colors.white,
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(context, 12),
                            ),
                            border: Border.all(
                              color: themeState.isDarkTheme 
                                ? themeState.fieldBorder 
                                : AppColors.gold.withOpacity(0.3),
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: themeState.isDarkTheme 
                                ? themeState.textPrimary 
                                : const Color(0xFF0D182E), // Dark blue text
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search',
                              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: themeState.isDarkTheme 
                                  ? themeState.textSecondary 
                                  : const Color(0xFF4A5568), // Lighter dark blue for hint
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: themeState.isDarkTheme 
                                  ? themeState.textSecondary 
                                  : const Color(0xFF4A5568),
                                size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
                                vertical: ResponsiveHelper.getResponsiveSpacing(context, 14),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                      Container(
                        width: ResponsiveHelper.getResponsiveSpacing(context, 48),
                        height: ResponsiveHelper.getResponsiveSpacing(context, 48),
                        decoration: BoxDecoration(
                          color: themeState.isDarkTheme ? themeState.fieldBg : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: themeState.isDarkTheme 
                              ? themeState.fieldBorder 
                              : AppColors.gold.withOpacity(0.3),
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.tune,
                            color: themeState.isDarkTheme 
                              ? themeState.textPrimary 
                              : const Color(0xFF0D182E), // Dark blue
                            size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                          ),
                          onPressed: () {
                            // Filter action
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // Top Brands Section
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top Brands',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: themeState.isDarkTheme 
                          ? themeState.textPrimary 
                          : const Color(0xFF0D182E), // Dark blue text
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _brands.map((brand) {
                          final isSelected = _selectedBrand == brand;
                          return Padding(
                            padding: EdgeInsets.only(
                              right: ResponsiveHelper.getResponsiveSpacing(context, 12),
                            ),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedBrand = brand;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
                                  vertical: ResponsiveHelper.getResponsiveSpacing(context, 10),
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                    ? (themeState.isDarkTheme 
                                        ? themeState.textPrimary 
                                        : AppColors.gold) // Yellow for selected in light mode
                                    : (themeState.isDarkTheme 
                                        ? themeState.fieldBg 
                                        : Colors.white), // White for unselected in light mode
                                  borderRadius: BorderRadius.circular(
                                    ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                                  ),
                                ),
                                child: Text(
                                  brand,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isSelected 
                                      ? (themeState.isDarkTheme 
                                          ? themeState.backgroundColor 
                                          : Colors.black) // Black text on yellow
                                      : (themeState.isDarkTheme 
                                          ? themeState.textPrimary 
                                          : const Color(0xFF0D182E)), // Dark blue text
                                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),

              // Car Listings
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
                  ),
                  itemCount: _filteredCars.length,
                  itemBuilder: (context, index) {
                    final car = _filteredCars[index];
                    return _buildCarCard(car, themeState);
                  },
                ),
              ),
            ],
          ),
          ),
        );
      },
    );
  }

  Widget _buildCarCard(Map<String, dynamic> car, ThemeState themeState) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CarDetailsScreen(car: car),
          ),
        );
      },
      borderRadius: BorderRadius.circular(
        ResponsiveHelper.getResponsiveBorderRadius(context, 12),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveSpacing(context, 16)),
        decoration: BoxDecoration(
          color: themeState.isDarkTheme ? themeState.panelBg : Colors.white,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(context, 12),
          ),
        ),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Car Image
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(
                ResponsiveHelper.getResponsiveBorderRadius(context, 12),
              ),
              bottomLeft: Radius.circular(
                ResponsiveHelper.getResponsiveBorderRadius(context, 12),
              ),
            ),
            child: Image.asset(
              car['image'] as String,
              width: ResponsiveHelper.getResponsiveSpacing(context, 120),
              height: ResponsiveHelper.getResponsiveSpacing(context, 120),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: ResponsiveHelper.getResponsiveSpacing(context, 120),
                  height: ResponsiveHelper.getResponsiveSpacing(context, 120),
                  color: themeState.fieldBg,
                  child: Icon(
                    Icons.image_not_supported,
                    color: themeState.textSecondary,
                  ),
                );
              },
            ),
          ),
          
          // Car Details
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Model, Year, and Favorite Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${car['model']} ${car['year']}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: themeState.isDarkTheme 
                              ? themeState.textPrimary 
                              : const Color(0xFF0D182E), // Dark blue text
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.favorite_border,
                          color: themeState.isDarkTheme 
                            ? themeState.textSecondary 
                            : const Color(0xFF4A5568), // Lighter dark blue for icon
                          size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                        ),
                        onPressed: () {
                          // Favorite action
                        },
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                  
                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: themeState.isDarkTheme 
                          ? themeState.textSecondary 
                          : const Color(0xFF4A5568), // Lighter dark blue for icon
                        size: ResponsiveHelper.getResponsiveIconSize(context, 16),
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                      Expanded(
                        child: Text(
                          car['location'] as String,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: themeState.isDarkTheme 
                              ? themeState.textSecondary 
                              : const Color(0xFF4A5568), // Lighter dark blue for location
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                  
                  // Price and Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price Button
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveHelper.getResponsiveSpacing(context, 12),
                          vertical: ResponsiveHelper.getResponsiveSpacing(context, 6),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold, // Use app gold color
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context, 8),
                          ),
                        ),
                        child: Text(
                          car['price'] as String,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black, // Black text on gold
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      
                      // Rating
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: AppColors.gold,
                            size: ResponsiveHelper.getResponsiveIconSize(context, 16),
                          ),
                          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                          Text(
                            car['rating'].toString(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: themeState.isDarkTheme 
                                ? themeState.textPrimary 
                                : const Color(0xFF0D182E), // Dark blue text
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
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
      onTap: () {
        // Navigate to main navigation screen with selected tab
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => MainNavigationScreen(initialTabIndex: index),
          ),
          (route) => false, // Remove all previous routes
        );
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
}

