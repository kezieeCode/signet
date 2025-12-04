import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/theme_cubit.dart';
import '../../utils/responsive_helper.dart';

class DriverSupportCenterScreen extends StatefulWidget {
  const DriverSupportCenterScreen({super.key});

  @override
  State<DriverSupportCenterScreen> createState() => _DriverSupportCenterScreenState();
}

class _DriverSupportCenterScreenState extends State<DriverSupportCenterScreen> {
  final List<Map<String, dynamic>> _faqItems = [
    {
      'question': 'How are my earnings calculated?',
      'answer': 'Your earnings are calculated based on the ride distance, time, and any applicable bonuses or promotions.',
    },
    {
      'question': 'When can I withdraw my earnings?',
      'answer': 'You can withdraw your earnings weekly. Withdrawals are processed every Monday.',
    },
    {
      'question': 'What if a rider cancels a trip?',
      'answer': 'If a rider cancels after you\'ve arrived, you\'ll receive a cancellation fee.',
    },
    {
      'question': 'How do I update my vehicle documents?',
      'answer': 'Go to Profile > Manage Vehicle to upload updated documents.',
    },
  ];

  final List<Map<String, dynamic>> _contactOptions = [
    {
      'title': 'Live Chat',
      'description': 'Get instant help from our support team',
      'icon': Icons.headset_mic,
      'iconShape': BoxShape.circle,
    },
    {
      'title': 'Submit a Ticket',
      'description': 'We\'ll get back to you via email',
      'icon': Icons.confirmation_number,
      'iconShape': BoxShape.rectangle,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return Scaffold(
          backgroundColor: themeState.isDarkTheme ? const Color(0xFF0F1B2B) : Colors.grey.shade50,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back,
                color: themeState.isDarkTheme ? Colors.white : Colors.black,
              ),
            ),
            title: Text(
              'Support Center',
              style: TextStyle(
                color: themeState.isDarkTheme ? Colors.white : Colors.black,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getResponsiveSpacing(context, 20),
                vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Divider line
                  Container(
                    height: 1,
                    color: themeState.isDarkTheme ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                  
                  // Frequently Asked Questions Section
                  _buildSectionHeader('Frequently Asked Questions', themeState),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                  
                  // FAQ Items
                  ..._faqItems.map((faq) => _buildFAQItem(faq, themeState)).toList(),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
                  
                  // Still need help? Section
                  _buildSectionHeader('Still need help?', themeState),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                  
                  // Contact Options
                  ..._contactOptions.map((option) => _buildContactOption(option, themeState)).toList(),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 40)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, ThemeState themeState) {
    return Text(
      title,
      style: TextStyle(
        color: themeState.isDarkTheme ? Colors.white : Colors.black,
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFAQItem(Map<String, dynamic> faq, ThemeState themeState) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveSpacing(context, 12)),
      padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
      decoration: BoxDecoration(
        color: themeState.isDarkTheme ? const Color(0xFF1A2B47) : Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
        border: Border.all(
          color: themeState.isDarkTheme ? Colors.grey.shade700 : Colors.grey.shade300,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              faq['question'],
              style: TextStyle(
                color: themeState.isDarkTheme ? Colors.white : Colors.black,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down,
            color: themeState.isDarkTheme ? Colors.white : Colors.black,
            size: ResponsiveHelper.getResponsiveIconSize(context, 24),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(Map<String, dynamic> option, ThemeState themeState) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveSpacing(context, 12)),
      padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
      decoration: BoxDecoration(
        color: themeState.isDarkTheme ? const Color(0xFF1A2B47) : Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
        border: Border.all(
          color: themeState.isDarkTheme ? Colors.grey.shade700 : Colors.grey.shade300,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: ResponsiveHelper.getResponsiveSpacing(context, 48),
            height: ResponsiveHelper.getResponsiveSpacing(context, 48),
            decoration: BoxDecoration(
              color: themeState.isDarkTheme ? Colors.grey.shade800 : Colors.grey.shade200,
              shape: option['iconShape'] == BoxShape.circle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: option['iconShape'] == BoxShape.rectangle 
                ? BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 8))
                : null,
            ),
            child: Icon(
              option['icon'],
              color: Colors.amber,
              size: ResponsiveHelper.getResponsiveIconSize(context, 24),
            ),
          ),
          
          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
          
          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option['title'],
                  style: TextStyle(
                    color: themeState.isDarkTheme ? Colors.white : Colors.black,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                Text(
                  option['description'],
                  style: TextStyle(
                    color: themeState.isDarkTheme ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  ),
                ),
              ],
            ),
          ),
          
          // Arrow Icon
          Icon(
            Icons.chevron_right,
            color: themeState.isDarkTheme ? Colors.white : Colors.black,
            size: ResponsiveHelper.getResponsiveIconSize(context, 24),
          ),
        ],
      ),
    );
  }
}


