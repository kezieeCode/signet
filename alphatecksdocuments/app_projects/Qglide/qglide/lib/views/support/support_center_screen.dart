import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/theme_cubit.dart';
import '../../utils/responsive_helper.dart';
import 'live_chat_screen.dart';
import 'support_tickets_screen.dart';

class SupportCenterScreen extends StatefulWidget {
  const SupportCenterScreen({super.key});

  @override
  State<SupportCenterScreen> createState() => _SupportCenterScreenState();
}

class _SupportCenterScreenState extends State<SupportCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'How do I book a ride?',
      'answer': 'To book a ride, simply open the app and tap on "Book a Ride". Enter your destination and select your preferred ride type. Confirm your booking and wait for your driver to arrive.',
      'isExpanded': false,
    },
    {
      'question': 'Can I schedule a ride in advance?',
      'answer': 'Yes, you can schedule a ride up to 30 days in advance. Use the "Schedule Ride" option when booking to select your preferred date and time.',
      'isExpanded': false,
    },
    {
      'question': 'How is the fare calculated?',
      'answer': 'Fares are calculated based on a combination of factors including distance, time, demand, and base fare rates. You can see the estimated fare before confirming your booking.',
      'isExpanded': false,
    },
    {
      'question': 'What payment methods are accepted?',
      'answer': 'We accept various payment methods including credit cards, debit cards, digital wallets, and cash. You can add multiple payment methods in your wallet.',
      'isExpanded': false,
    },
  ];

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
          appBar: AppBar(
            backgroundColor: themeState.backgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: themeState.textPrimary,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: Text(
              'Support Center',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: themeState.textPrimary,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                _buildSearchBar(themeState),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
                
                // Frequently Asked Questions Section
                _buildFAQSection(themeState),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
                
                // Contact Us Section
                _buildContactSection(themeState),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(ThemeState themeState) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: themeState.panelBg,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
        border: Border.all(color: themeState.fieldBorder),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: themeState.textSecondary,
            size: ResponsiveHelper.getResponsiveIconSize(context, 20),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: themeState.textPrimary,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
              ),
              decoration: InputDecoration(
                hintText: 'Search for help...',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: themeState.textSecondary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection(ThemeState themeState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequently Asked Questions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: themeState.textPrimary,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
        ..._faqs.map((faq) => _buildFAQItem(faq, themeState)).toList(),
      ],
    );
  }

  Widget _buildFAQItem(Map<String, dynamic> faq, ThemeState themeState) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveSpacing(context, 12)),
      decoration: BoxDecoration(
        color: themeState.panelBg,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
        border: Border.all(color: themeState.fieldBorder),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                faq['isExpanded'] = !faq['isExpanded'];
              });
            },
            child: Padding(
              padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      faq['question'],
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: themeState.textPrimary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    faq['isExpanded'] ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.gold,
                    size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                  ),
                ],
              ),
            ),
          ),
          if (faq['isExpanded'])
            Padding(
              padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16, vertical: 16),
              child: Text(
                faq['answer'],
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: themeState.textSecondary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContactSection(ThemeState themeState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Us',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: themeState.textPrimary,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
        _buildContactItem(
          icon: null,
          iconAsset: 'assets/icons/chat.png',
          title: 'Live Chat',
          description: 'Get instant support from our agents.',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LiveChatScreen(),
              ),
            );
          },
          themeState: themeState,
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
        _buildContactItem(
          icon: null,
          iconAsset: 'assets/icons/call.png',
          title: 'Call Support',
          description: 'Speak directly with our team.',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Call support coming soon')),
            );
          },
          themeState: themeState,
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
        _buildContactItem(
          icon: null,
          iconAsset: 'assets/icons/email.png',
          title: 'Email Us',
          description: "We'll get back to you within 24 hours.",
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Email support coming soon')),
            );
          },
          themeState: themeState,
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
        _buildSupportTicketsButton(themeState),
      ],
    );
  }

  Widget _buildContactItem({
    IconData? icon,
    String? iconAsset,
    required String title,
    required String description,
    required VoidCallback onTap,
    required ThemeState themeState,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: themeState.panelBg,
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
          border: Border.all(color: themeState.fieldBorder),
        ),
        child: Row(
          children: [
            Container(
              width: ResponsiveHelper.getResponsiveSpacing(context, 40),
              height: ResponsiveHelper.getResponsiveSpacing(context, 40),
              decoration: BoxDecoration(
                color: themeState.fieldBg,
                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 8)),
              ),
              child: iconAsset != null
                  ? Image.asset(
                      iconAsset,
                      width: ResponsiveHelper.getResponsiveIconSize(context, 20),
                      height: ResponsiveHelper.getResponsiveIconSize(context, 20),
                      color: AppColors.gold,
                    )
                  : Icon(
                      icon!,
                      color: AppColors.gold,
                      size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                    ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: themeState.textPrimary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: themeState.textSecondary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.gold,
              size: ResponsiveHelper.getResponsiveIconSize(context, 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportTicketsButton(ThemeState themeState) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const SupportTicketsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: animation.drive(
                  Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(
                    CurveTween(curve: Curves.ease),
                  ),
                ),
                child: child,
              );
            },
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.confirmation_number_outlined,
              color: Colors.black,
              size: ResponsiveHelper.getResponsiveIconSize(context, 20),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
            Text(
              'My Support Tickets',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.black,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
