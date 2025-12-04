import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../cubits/theme_cubit.dart';
import '../../utils/responsive_helper.dart';

class BookingSummaryScreen extends StatefulWidget {
  final Map<String, dynamic> car;
  final DateTime pickupDate;
  final TimeOfDay pickupTime;
  final DateTime returnDate;
  final TimeOfDay returnTime;
  final String rentType;

  const BookingSummaryScreen({
    super.key,
    required this.car,
    required this.pickupDate,
    required this.pickupTime,
    required this.returnDate,
    required this.returnTime,
    required this.rentType,
  });

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  String _cardNumber = '****23456';
  String _expiryDate = '03/08';

  int _calculateTotalHours() {
    final pickup = DateTime(
      widget.pickupDate.year,
      widget.pickupDate.month,
      widget.pickupDate.day,
      widget.pickupTime.hour,
      widget.pickupTime.minute,
    );
    final returnDateTime = DateTime(
      widget.returnDate.year,
      widget.returnDate.month,
      widget.returnDate.day,
      widget.returnTime.hour,
      widget.returnTime.minute,
    );
    final difference = returnDateTime.difference(pickup);
    return difference.inHours;
  }

  double _calculateTotal() {
    final priceString = widget.car['price'] as String;
    // Extract numeric value from price string (e.g., "N30,000/hr" -> 30000)
    final priceMatch = RegExp(r'[\d,]+').firstMatch(priceString);
    if (priceMatch == null) return 0.0;
    final priceValue = priceMatch.group(0)?.replaceAll(',', '') ?? '0';
    final hourlyPrice = double.tryParse(priceValue) ?? 0.0;
    
    final totalHours = _calculateTotalHours();
    var total = hourlyPrice * totalHours;
    
    // Add driver cost if "With Driver" is selected ($20/hr)
    if (widget.rentType == 'With Driver') {
      total += 20 * totalHours;
    }
    
    return total;
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM, yyyy').format(date);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute$period';
  }

  String _formatCurrency(double amount) {
    // Format as Naira (N) with commas
    return 'N${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  @override
  Widget build(BuildContext context) {
    final totalHours = _calculateTotalHours();
    final total = _calculateTotal();
    final priceString = widget.car['price'] as String;

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
              'Booking Summary',
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
                // Vehicle Details Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Car Image
                    Container(
                      width: ResponsiveHelper.getResponsiveSpacing(context, 100),
                      height: ResponsiveHelper.getResponsiveSpacing(context, 100),
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
                                size: ResponsiveHelper.getResponsiveIconSize(context, 32),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                    // Car Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Premium Tag
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveHelper.getResponsiveSpacing(context, 12),
                              vertical: ResponsiveHelper.getResponsiveSpacing(context, 6),
                            ),
                            decoration: BoxDecoration(
                              color: themeState.isDarkTheme 
                                ? themeState.textPrimary 
                                : AppColors.gold.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(
                                ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                              ),
                            ),
                            child: Text(
                              widget.car['carClass']?.toString().toUpperCase() ?? 'PREMIUM',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: themeState.isDarkTheme 
                                  ? themeState.backgroundColor 
                                  : const Color(0xFF0D182E),
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                          // Car Name
                          Text(
                            '${widget.car['model']} ${widget.car['year']}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: themeState.isDarkTheme 
                                ? themeState.textPrimary 
                                : const Color(0xFF0D182E),
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                          // Price
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: priceString.split('/')[0],
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: themeState.isDarkTheme 
                                      ? themeState.textPrimary 
                                      : const Color(0xFF0D182E),
                                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: '/hr',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: themeState.isDarkTheme 
                                      ? themeState.textSecondary 
                                      : const Color(0xFF4A5568),
                                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                
                // Booking Information Section
                _buildInfoRow(
                  'Pick Up Date & Time',
                  '${_formatDate(widget.pickupDate)} | ${_formatTime(widget.pickupTime)}',
                  themeState,
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                _buildInfoRow(
                  'Return Date & Time',
                  '${_formatDate(widget.returnDate)} | ${_formatTime(widget.returnTime)}',
                  themeState,
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                _buildInfoRow(
                  'Rent Type',
                  widget.rentType,
                  themeState,
                ),
                
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                
                // Cost Summary Section
                Text(
                  'Cost Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: themeState.isDarkTheme 
                      ? themeState.textPrimary 
                      : const Color(0xFF0D182E),
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                
                _buildInfoRow(
                  'Amount',
                  priceString,
                  themeState,
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                _buildInfoRow(
                  'Total Hours',
                  totalHours.toString(),
                  themeState,
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                _buildInfoRow(
                  'Total',
                  _formatCurrency(total),
                  themeState,
                  isTotal: true,
                ),
                
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                
                // Payment Method Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Card Logo (Mastercard)
                        Container(
                          width: ResponsiveHelper.getResponsiveSpacing(context, 40),
                          height: ResponsiveHelper.getResponsiveSpacing(context, 40),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: ResponsiveHelper.getResponsiveSpacing(context, 20),
                              height: ResponsiveHelper.getResponsiveSpacing(context, 20),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _cardNumber,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: themeState.isDarkTheme 
                                  ? themeState.textPrimary 
                                  : const Color(0xFF0D182E),
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                            Text(
                              'Expires $_expiryDate',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: themeState.isDarkTheme 
                                  ? themeState.textSecondary 
                                  : const Color(0xFF4A5568),
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        // Change payment method action
                      },
                      child: Text(
                        'Change',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: themeState.isDarkTheme 
                            ? AppColors.gold 
                            : const Color(0xFF0D182E),
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                          fontWeight: FontWeight.w600,
                        ),
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
                    // TODO: Process booking and navigate to confirmation
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

  Widget _buildInfoRow(String label, String value, ThemeState themeState, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: themeState.isDarkTheme 
              ? themeState.textPrimary 
              : const Color(0xFF0D182E),
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: themeState.isDarkTheme 
              ? themeState.textPrimary 
              : const Color(0xFF0D182E),
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

