import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../cubits/theme_cubit.dart';
import '../../utils/responsive_helper.dart';
import 'self_drive_requirement_screen.dart';
import 'booking_summary_screen.dart';

class BookCarScreen extends StatefulWidget {
  final Map<String, dynamic> car;

  const BookCarScreen({
    super.key,
    required this.car,
  });

  @override
  State<BookCarScreen> createState() => _BookCarScreenState();
}

class _BookCarScreenState extends State<BookCarScreen> {
  String _rentType = 'Self Drive'; // 'Self Drive' or 'With Driver'
  DateTime? _pickupDate;
  TimeOfDay? _pickupTime;
  DateTime? _returnDate;
  TimeOfDay? _returnTime;

  @override
  void initState() {
    super.initState();
    // Set default dates to today
    _pickupDate = DateTime.now();
    _returnDate = DateTime.now();
    // Set default times to 10:00 AM
    _pickupTime = const TimeOfDay(hour: 10, minute: 0);
    _returnTime = const TimeOfDay(hour: 10, minute: 0);
  }

  Future<void> _selectPickupDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _pickupDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.gold,
              onPrimary: Colors.black,
              surface: Colors.white,
              onSurface: const Color(0xFF0D182E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _pickupDate) {
      setState(() {
        _pickupDate = picked;
        // If return date is before pickup date, update return date
        if (_returnDate != null && _returnDate!.isBefore(picked)) {
          _returnDate = picked;
        }
      });
    }
  }

  Future<void> _selectPickupTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _pickupTime ?? const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.gold,
              onPrimary: Colors.black,
              surface: Colors.white,
              onSurface: const Color(0xFF0D182E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _pickupTime) {
      setState(() {
        _pickupTime = picked;
      });
    }
  }

  Future<void> _selectReturnDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _returnDate ?? _pickupDate ?? DateTime.now(),
      firstDate: _pickupDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.gold,
              onPrimary: Colors.black,
              surface: Colors.white,
              onSurface: const Color(0xFF0D182E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _returnDate) {
      setState(() {
        _returnDate = picked;
      });
    }
  }

  Future<void> _selectReturnTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _returnTime ?? const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.gold,
              onPrimary: Colors.black,
              surface: Colors.white,
              onSurface: const Color(0xFF0D182E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _returnTime) {
      setState(() {
        _returnTime = picked;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select Date';
    return DateFormat('dd MMM').format(date);
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Select Time';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute$period';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return Scaffold(
          backgroundColor: themeState.isDarkTheme ? themeState.backgroundColor : Colors.white,
          appBar: AppBar(
            backgroundColor: themeState.isDarkTheme ? themeState.backgroundColor : Colors.white,
            elevation: 0,
            leading: Container(
              margin: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 8)),
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
                  Icons.arrow_back,
                  color: themeState.isDarkTheme 
                    ? themeState.textPrimary 
                    : const Color(0xFF0D182E),
                  size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            title: Text(
              'Book Car',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: themeState.isDarkTheme 
                  ? themeState.textPrimary 
                  : const Color(0xFF0D182E),
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Car Image
                Center(
                  child: Container(
                    width: double.infinity,
                    height: ResponsiveHelper.getResponsiveSpacing(context, 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getResponsiveBorderRadius(context, 12),
                      ),
                      border: Border.all(
                        color: themeState.isDarkTheme 
                          ? themeState.fieldBorder 
                          : const Color(0xFF0D182E).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getResponsiveBorderRadius(context, 12),
                      ),
                      child: Image.asset(
                        widget.car['image'] as String,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: themeState.fieldBg,
                            child: Icon(
                              Icons.image_not_supported,
                              color: themeState.textSecondary,
                              size: ResponsiveHelper.getResponsiveIconSize(context, 48),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                
                // Car Name
                Center(
                  child: Text(
                    '${widget.car['model']} ${widget.car['year']}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: themeState.isDarkTheme 
                        ? themeState.textPrimary 
                        : const Color(0xFF0D182E),
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                
                // Divider
                Divider(
                  color: themeState.fieldBorder,
                  thickness: 1,
                ),
                
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                
                // Rent Type Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rent type',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: themeState.isDarkTheme 
                          ? themeState.textPrimary 
                          : const Color(0xFF0D182E),
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(
                      Icons.people,
                      color: themeState.isDarkTheme 
                        ? themeState.textSecondary 
                        : const Color(0xFF4A5568),
                      size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                    ),
                  ],
                ),
                
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                
                // Rent Type Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildRentTypeButton(
                        'Self Drive',
                        _rentType == 'Self Drive',
                        themeState,
                        () {
                          setState(() {
                            _rentType = 'Self Drive';
                          });
                        },
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                    Expanded(
                      child: _buildRentTypeButton(
                        'With Driver',
                        _rentType == 'With Driver',
                        themeState,
                        () {
                          setState(() {
                            _rentType = 'With Driver';
                          });
                        },
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                
                // Info Banner
                if (_rentType == 'With Driver')
                  Container(
                    padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 12)),
                    decoration: BoxDecoration(
                      color: themeState.isDarkTheme 
                        ? themeState.fieldBg 
                        : AppColors.gold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getResponsiveBorderRadius(context, 8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: ResponsiveHelper.getResponsiveSpacing(context, 24),
                          height: ResponsiveHelper.getResponsiveSpacing(context, 24),
                          decoration: BoxDecoration(
                            color: themeState.isDarkTheme 
                              ? themeState.textPrimary 
                              : const Color(0xFF0D182E),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.info,
                            color: themeState.isDarkTheme 
                              ? themeState.backgroundColor 
                              : Colors.white,
                            size: ResponsiveHelper.getResponsiveIconSize(context, 16),
                          ),
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                        Expanded(
                          child: Text(
                            'Additional \$20/hr Driver cost will be added if you choose with driver option',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: themeState.isDarkTheme 
                                ? themeState.textPrimary 
                                : const Color(0xFF0D182E),
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                
                // Pick Up Date & Time Section
                Text(
                  'Pick Up Date & Time',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: themeState.isDarkTheme 
                      ? themeState.textPrimary 
                      : const Color(0xFF0D182E),
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildDateTimeField(
                        label: 'Date',
                        value: _formatDate(_pickupDate),
                        icon: Icons.calendar_today,
                        onTap: _selectPickupDate,
                        themeState: themeState,
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                    Expanded(
                      child: _buildDateTimeField(
                        label: 'Time',
                        value: _formatTime(_pickupTime),
                        icon: Icons.access_time,
                        onTap: _selectPickupTime,
                        themeState: themeState,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                
                // Return Date & Time Section
                Text(
                  'Return Date & Time',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: themeState.isDarkTheme 
                      ? themeState.textPrimary 
                      : const Color(0xFF0D182E),
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildDateTimeField(
                        label: 'Date',
                        value: _formatDate(_returnDate),
                        icon: Icons.calendar_today,
                        onTap: _selectReturnDate,
                        themeState: themeState,
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                    Expanded(
                      child: _buildDateTimeField(
                        label: 'Time',
                        value: _formatTime(_returnTime),
                        icon: Icons.access_time,
                        onTap: _selectReturnTime,
                        themeState: themeState,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
            decoration: BoxDecoration(
              color: themeState.isDarkTheme ? themeState.panelBg : Colors.white,
              border: Border(
                top: BorderSide(
                  color: themeState.fieldBorder,
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                  child: ElevatedButton(
                  onPressed: () {
                    // Validate dates and times
                    if (_pickupDate == null || _pickupTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select pickup date and time'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    if (_returnDate == null || _returnTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select return date and time'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    if (_returnDate!.isBefore(_pickupDate!)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Return date must be after pickup date'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    // If Self Drive is selected, navigate to requirement screen
                    if (_rentType == 'Self Drive') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SelfDriveRequirementScreen(
                            car: widget.car,
                            pickupDate: _pickupDate!,
                            pickupTime: _pickupTime!,
                            returnDate: _returnDate!,
                            returnTime: _returnTime!,
                          ),
                        ),
                      );
                    } else {
                      // Navigate directly to booking summary for "With Driver"
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BookingSummaryScreen(
                            car: widget.car,
                            pickupDate: _pickupDate!,
                            pickupTime: _pickupTime!,
                            returnDate: _returnDate!,
                            returnTime: _returnTime!,
                            rentType: 'With Driver',
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getResponsiveBorderRadius(context, 12),
                      ),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.black,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRentTypeButton(
    String label,
    bool isSelected,
    ThemeState themeState,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold
              : (themeState.isDarkTheme 
                  ? themeState.fieldBg 
                  : Colors.white),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(context, 12),
          ),
          border: isSelected
              ? null
              : Border.all(
                  color: themeState.isDarkTheme 
                    ? themeState.fieldBorder 
                    : AppColors.gold,
                  width: 1,
                ),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: isSelected
                  ? Colors.black
                  : (themeState.isDarkTheme 
                      ? themeState.textPrimary 
                      : const Color(0xFF0D182E)),
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    required ThemeState themeState,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 12)),
        decoration: BoxDecoration(
          color: themeState.isDarkTheme ? themeState.fieldBg : Colors.white,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(context, 12),
          ),
          border: Border.all(
            color: themeState.isDarkTheme 
              ? themeState.fieldBorder 
              : const Color(0xFF0D182E).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: themeState.isDarkTheme 
                  ? themeState.textSecondary 
                  : const Color(0xFF4A5568),
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: themeState.isDarkTheme 
                        ? themeState.textPrimary 
                        : const Color(0xFF0D182E),
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  icon,
                  color: themeState.isDarkTheme 
                    ? themeState.textSecondary 
                    : const Color(0xFF4A5568),
                  size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

