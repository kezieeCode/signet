import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/theme_cubit.dart';
import '../../utils/responsive_helper.dart';

class ScheduleRideScreen extends StatefulWidget {
  final String pickupLocation;
  final String destinationLocation;
  
  const ScheduleRideScreen({
    super.key, 
    required this.pickupLocation,
    required this.destinationLocation,
  });

  @override
  State<ScheduleRideScreen> createState() => _ScheduleRideScreenState();
}

class _ScheduleRideScreenState extends State<ScheduleRideScreen> with TickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  
  // Calendar state
  late DateTime _currentMonth;
  late List<List<int>> _calendarDays;
  
  // Scroll controllers for time picker
  late ScrollController _hoursController;
  late ScrollController _minutesController;
  
  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _generateCalendar();
    
    // Initialize scroll controllers
    _hoursController = ScrollController();
    _minutesController = ScrollController();
    
    // Scroll to selected time after a frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedTime();
    });
  }
  
  void _generateCalendar() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7; // Convert to 0-6 (Sun-Sat)
    
    _calendarDays = [];
    List<int> currentWeek = [];
    
    // Add empty cells for days before the first day of the month
    for (int i = 0; i < firstWeekday; i++) {
      final prevMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 0);
      currentWeek.add(prevMonth.day - firstWeekday + i + 1);
    }
    
    // Add days of the current month
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      currentWeek.add(day);
      if (currentWeek.length == 7) {
        _calendarDays.add(List.from(currentWeek));
        currentWeek.clear();
      }
    }
    
    // Add days from next month to complete the last week
    int nextMonthDay = 1;
    while (currentWeek.length < 7) {
      currentWeek.add(nextMonthDay++);
    }
    if (currentWeek.isNotEmpty) {
      _calendarDays.add(currentWeek);
    }
  }
  
  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _generateCalendar();
    });
  }
  
  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _generateCalendar();
    });
  }
  
  void _selectDate(int day) {
    setState(() {
      _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, day);
    });
  }
  
  
  void _scrollToSelectedTime() {
    final itemHeight = ResponsiveHelper.getResponsiveSpacing(context, 40);
    final paddingTop = MediaQuery.of(context).size.height * 0.15;
    final centerOffset = (MediaQuery.of(context).size.height * 0.4) / 2;
    
    _hoursController.animateTo(
      _selectedTime.hour * itemHeight - centerOffset + paddingTop,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    _minutesController.animateTo(
      _selectedTime.minute * itemHeight - centerOffset + paddingTop,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  void _confirmSchedule() {
    // Navigate back with scheduled ride data
    Navigator.pop(context, {
      'pickupLocation': widget.pickupLocation,
      'destinationLocation': widget.destinationLocation,
      'scheduledDate': _selectedDate,
      'scheduledTime': _selectedTime,
      'status': 'scheduled',
    });
  }
  
  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
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
        leading: Container(
          margin: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 8)),
          decoration: BoxDecoration(
            color: themeState.fieldBg,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: themeState.textPrimary,
              size: ResponsiveHelper.getResponsiveIconSize(context, 20),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        title: Text(
          'Schedule a Ride',
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
          // Calendar Section
          Expanded(
            flex: 2,
            child: Container(
              margin: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
              padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 20)),
              decoration: BoxDecoration(
                color: themeState.fieldBg,
                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 32)),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  // Month Navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _previousMonth,
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: themeState.textPrimary,
                          size: ResponsiveHelper.getResponsiveIconSize(context, 18),
                        ),
                      ),
                      Text(
                        '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: themeState.textPrimary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: _nextMonth,
                        icon: Icon(
                          Icons.arrow_forward_ios,
                          color: themeState.textPrimary,
                          size: ResponsiveHelper.getResponsiveIconSize(context, 18),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
                  
                  // Days of Week Header
                  Row(
                    children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                        .map((day) => Expanded(
                              child: Text(
                                  day,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: themeState.textSecondary,
                                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ))
                        .toList(),
                  ),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                  
                  // Calendar Grid
                  Expanded(
                    child: Column(
                      children: _calendarDays.map((week) {
                        return Expanded(
                          child: Row(
                            children: week.map((day) {
                              final isCurrentMonth = day <= 31 && 
                                  (_currentMonth.month == DateTime.now().month || 
                                   (day > 15 && _currentMonth.month == DateTime.now().month + 1) ||
                                   (day < 15 && _currentMonth.month == DateTime.now().month - 1));
                              final isSelected = isCurrentMonth && 
                                  _selectedDate.day == day && 
                                  _selectedDate.month == _currentMonth.month;
                              
                              return Expanded(
                                child: GestureDetector(
                                  onTap: isCurrentMonth ? () => _selectDate(day) : null,
                                  child: Container(
                                    margin: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 1)),
                                    child: Center(
                                      child: Container(
                                        width: ResponsiveHelper.getResponsiveSpacing(context, 24),
                                        height: ResponsiveHelper.getResponsiveSpacing(context, 24),
                                        decoration: BoxDecoration(
                                          color: isSelected ? AppColors.gold : Colors.transparent,
                                          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 6)),
                                        ),
                                        child: Center(
                                          child: Text(
                                            day.toString(),
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: isSelected ? Colors.black : 
                                                     isCurrentMonth ? themeState.textPrimary : themeState.textSecondary,
                                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Time Picker Section
          Expanded(
            flex: 2,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16)),
              child: Column(
                children: [
                  // Time Picker
                  Expanded(
                    child: Row(
                      children: [
                        // Hours Column
                        Expanded(
                          child: _buildTimeColumnWithFocus(
                            'Hours',
                            List.generate(24, (index) => index),
                            _selectedTime.hour,
                            (hour) => setState(() {
                              _selectedTime = TimeOfDay(hour: hour, minute: _selectedTime.minute);
                            }),
                            _hoursController,
                            themeState,
                          ),
                        ),
                        
                        // Minutes Column
                        Expanded(
                          child: _buildTimeColumnWithFocus(
                            'Minutes',
                            List.generate(60, (index) => index),
                            _selectedTime.minute,
                            (minute) => setState(() {
                              _selectedTime = TimeOfDay(hour: _selectedTime.hour, minute: minute);
                            }),
                            _minutesController,
                            themeState,
                          ),
                        ),
                        
                        // AM/PM Column
                        Expanded(
                          child: _buildTimeColumn(
                            'Period',
                            ['AM', 'PM'],
                            _selectedTime.hour >= 12 ? 1 : 0,
                            (period) => setState(() {
                              final isPM = period == 1;
                              final currentHour = _selectedTime.hour;
                              final newHour = isPM 
                                  ? (currentHour < 12 ? currentHour + 12 : currentHour)
                                  : (currentHour >= 12 ? currentHour - 12 : currentHour);
                              _selectedTime = TimeOfDay(
                                hour: newHour,
                                minute: _selectedTime.minute,
                              );
                            }),
                            themeState,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Action Button
          Padding(
            padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 24)),
            child: Container(
              width: double.infinity,
              height: ResponsiveHelper.getResponsiveSpacing(context, 56),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 32)),
              ),
              child: TextButton(
                onPressed: _confirmSchedule,
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 32)),
                  ),
                ),
                child: Text(
                  'Set Date & Time',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }
  
  Widget _buildTimeColumnWithFocus(String title, List<dynamic> items, int selectedIndex, Function(int) onSelected, ScrollController controller, ThemeState themeState) {
    return Column(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: themeState.textSecondary,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: themeState.fieldBg,
              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification) {
                  // Calculate which item is in the center
                  final itemHeight = ResponsiveHelper.getResponsiveSpacing(context, 40);
                  final paddingTop = MediaQuery.of(context).size.height * 0.15;
                  final centerOffset = (MediaQuery.of(context).size.height * 0.4) / 2;
                  final scrollOffset = controller.offset + centerOffset - paddingTop;
                  final centerIndex = (scrollOffset / itemHeight).round().clamp(0, items.length - 1);
                  
                  if (centerIndex != selectedIndex) {
                    onSelected(centerIndex);
                  }
                }
                return false;
              },
              child: ListView.builder(
                controller: controller,
                itemCount: items.length,
                padding: EdgeInsets.symmetric(
                  vertical: MediaQuery.of(context).size.height * 0.15,
                ),
                itemBuilder: (context, index) {
                  final itemHeight = ResponsiveHelper.getResponsiveSpacing(context, 40);
                  final paddingTop = MediaQuery.of(context).size.height * 0.15;
                  final centerOffset = (MediaQuery.of(context).size.height * 0.4) / 2;
                  final itemCenter = index * itemHeight + itemHeight / 2 + paddingTop;
                  final scrollOffset = controller.offset + centerOffset;
                  final distance = (itemCenter - scrollOffset).abs() / itemHeight;
                  
                  // Convex curve calculation - creates a smooth bulge effect
                  final convexFactor = 1.0 - (distance * distance * 0.5).clamp(0.0, 0.8);
                  final isSelected = index == selectedIndex;
                  
                  // Selected items should not have convex effect
                  final scale = isSelected ? 1.0 : 0.6 + (convexFactor * 0.4); // Scale from 0.6 to 1.0
                  final opacity = isSelected ? 1.0 : 0.3 + (convexFactor * 0.7); // Opacity from 0.3 to 1.0
                  
                  return GestureDetector(
                    onTap: () {
                      onSelected(index);
                      _scrollToSelectedTime();
                    },
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        height: itemHeight,
                        margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppColors.gold 
                              : themeState.fieldBg.withOpacity(opacity * 0.3),
                          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 8)),
                          border: isSelected ? Border.all(color: AppColors.gold, width: 2) : null,
                          boxShadow: [
                            BoxShadow(
                              color: isSelected 
                                  ? AppColors.gold.withOpacity(0.4)
                                  : themeState.fieldBorder.withOpacity(opacity * 0.3),
                              blurRadius: isSelected ? 12 : (opacity * 8).clamp(0, 8),
                              spreadRadius: isSelected ? 3 : (opacity * 2).clamp(0, 2),
                              offset: Offset(0, isSelected ? 3 : opacity * 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            items[index].toString().padLeft(2, '0'),
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: isSelected 
                                  ? Colors.black 
                                  : themeState.textPrimary.withOpacity(opacity),
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeColumn(String title, List<dynamic> items, int selectedIndex, Function(int) onSelected, ThemeState themeState) {
    return Column(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: themeState.textSecondary,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: themeState.fieldBg,
              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final isSelected = index == selectedIndex;
                return GestureDetector(
                  onTap: () => onSelected(index),
                  child: Container(
                    height: ResponsiveHelper.getResponsiveSpacing(context, 40),
                    margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.gold : Colors.transparent,
                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 8)),
                    ),
                    child: Center(
                      child: Text(
                        items[index].toString().padLeft(2, '0'),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isSelected ? Colors.black : themeState.textPrimary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
  
  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
