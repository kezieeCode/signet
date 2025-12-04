import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../l10n/app_localizations.dart';
import '../../cubits/theme_cubit.dart';
import '../../utils/responsive_helper.dart';
import '../../services/api_service.dart';
import '../rewards/rewards_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  // Points data from API
  bool _isLoadingPoints = true;
  int _currentPoints = 0;
  int _tierPoints = 0;
  int _pointsToNextTier = 50;
  String _nextTier = 'silver';
  
  @override
  void initState() {
    super.initState();
    _fetchPointsData();
  }

  Future<void> _fetchPointsData() async {
    try {
      final response = await ApiService.getRewards(
        includeCoupons: false,
        includeRedemptions: false,
        couponLimit: 0,
      );

      if (response['success'] && response['data'] != null) {
        // Handle double nesting
        final data = response['data']['data'] ?? response['data'];
        if (mounted) {
          setState(() {
            // Convert doubles to ints properly
            final pointsBalance = data['reward_balance']?['points']?['current_balance'];
            _currentPoints = pointsBalance != null ? (pointsBalance as num).toInt() : 0;
            
            final tierPts = data['loyalty_tier']?['tier_points'];
            _tierPoints = tierPts != null ? (tierPts as num).toInt() : 0;
            
            final ptsToNext = data['loyalty_tier']?['points_to_next_tier'];
            _pointsToNextTier = ptsToNext != null ? (ptsToNext as num).toInt() : 50;
            
            _nextTier = data['loyalty_tier']?['next_tier'] ?? 'silver';
            _isLoadingPoints = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingPoints = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPoints = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        final base = ResponsiveHelper.getBaseScale(context);
        
        return Scaffold(
          backgroundColor: themeState.backgroundColor,
          appBar: AppBar(
            backgroundColor: themeState.backgroundColor,
            elevation: 0,
            title: Text(
              l10n.myWallet,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: themeState.textPrimary,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                fontWeight: FontWeight.w800,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(
                  Icons.more_vert,
                  color: themeState.textPrimary,
                  size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                ),
                onPressed: () {
                  // Handle more options
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Balance Card
                _buildBalanceCard(base, themeState, l10n),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
                
                // Action Buttons
                _buildActionButtons(base, themeState),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
                
                // Reward Points Section
                _buildRewardPoints(base, themeState, l10n),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
                
                // Payment Methods Section
                _buildPaymentMethods(base, themeState),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
                
                // Recent Transactions
                _buildRecentTransactions(base, themeState),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildBalanceCard(double base, ThemeState themeState, AppLocalizations l10n) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 20)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: themeState.panelBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Circular accent in top right
            Positioned(
              top: -ResponsiveHelper.getResponsiveSpacing(context, 20),
              right: -ResponsiveHelper.getResponsiveSpacing(context, 20),
              child: Container(
                width: ResponsiveHelper.getResponsiveSpacing(context, 80),
                height: ResponsiveHelper.getResponsiveSpacing(context, 80),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Circular accent in bottom left
            Positioned(
              bottom: -ResponsiveHelper.getResponsiveSpacing(context, 25),
              left: -ResponsiveHelper.getResponsiveSpacing(context, 25),
              child: Container(
                width: ResponsiveHelper.getResponsiveSpacing(context, 100),
                height: ResponsiveHelper.getResponsiveSpacing(context, 100),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Main content
            Padding(
              padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(
                l10n.totalBalance,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: themeState.textPrimary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
              Text(
                'QAR 1,250.75',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: themeState.textPrimary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 32),
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
                        horizontal: ResponsiveHelper.getResponsiveSpacing(context, 20),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 30)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add,
                            color: Colors.black,
                            size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                          ),
                          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                          Text(
                            l10n.topUp,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.black,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
                        horizontal: ResponsiveHelper.getResponsiveSpacing(context, 20),
                      ),
                      decoration: BoxDecoration(
                        color: themeState.panelBg,
                        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 30)),
                        border: Border.all(color: themeState.fieldBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/icons/send.png',
                            width: ResponsiveHelper.getResponsiveIconSize(context, 20),
                            height: ResponsiveHelper.getResponsiveIconSize(context, 20),
                            color: themeState.isDarkTheme ? null : Colors.black,
                          ),
                          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 20)),
                          Text(
                            l10n.send,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: themeState.textPrimary,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(double base, ThemeState themeState) {
    return SizedBox.shrink(); // Remove this section as it's now part of balance card
  }


  Widget _buildRewardPoints(double base, ThemeState themeState, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 20)),
      decoration: BoxDecoration(
        color: themeState.panelBg,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
        border: Border.all(color: themeState.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.loyaltyPoints,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: themeState.textSecondary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                    _isLoadingPoints
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.gold,
                            strokeWidth: 2,
                          ),
                        )
                      : RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${_currentPoints.toString()} ',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.gold,
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(
                                text: l10n.points,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: themeState.textSecondary,
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
              Container(
                width: ResponsiveHelper.getResponsiveSpacing(context, 40),
                height: ResponsiveHelper.getResponsiveSpacing(context, 40),
                decoration: BoxDecoration(
                  color: themeState.panelBg,
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 30)),
                  border: Border.all(color: themeState.fieldBorder),
                ),
                child: Icon(
                  Icons.star,
                  color: AppColors.gold,
                  size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
          // Progress bar
          _isLoadingPoints
            ? Container(
                height: 12,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 6)),
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.grey.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                  ),
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 6)),
                child: LinearProgressIndicator(
                  value: _pointsToNextTier > 0 ? (_tierPoints / _pointsToNextTier).clamp(0.0, 1.0) : 0.0,
                  backgroundColor: Colors.grey.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                  minHeight: ResponsiveHelper.getResponsiveSpacing(context, 12),
                ),
              ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
          _isLoadingPoints
            ? SizedBox.shrink()
            : Text(
                '$_pointsToNextTier points away from ${_nextTier[0].toUpperCase()}${_nextTier.substring(1)} tier!',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: themeState.textSecondary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  fontWeight: FontWeight.w400,
                ),
              ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RewardsScreen()),
              );
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveHelper.getResponsiveSpacing(context, 12),
              ),
              decoration: BoxDecoration(
                color: themeState.panelBg,
                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 30)),
                border: Border.all(color: themeState.fieldBorder),
              ),
              child: Text(
                l10n.redeemRewards,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.gold,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods(double base, ThemeState themeState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Methods',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: themeState.textPrimary,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
        // Visa Card
        Container(
          padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 8)),
                ),
                child: Center(
                  child: Text(
                    'VISA',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.black,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visa •••• 4567',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: themeState.textPrimary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 2)),
                    Text(
                      'Expires 12/26',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: themeState.textSecondary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: themeState.textSecondary,
                size: ResponsiveHelper.getResponsiveIconSize(context, 20),
              ),
            ],
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
        // Apple Pay
        Container(
          padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
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
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 8)),
                ),
                child: Center(
                  child: Icon(
                    Icons.apple,
                    color: Colors.white,
                    size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apple Pay',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: themeState.textPrimary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 2)),
                    Text(
                      'Linked to Visa',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: themeState.textSecondary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: themeState.textSecondary,
                size: ResponsiveHelper.getResponsiveIconSize(context, 20),
              ),
            ],
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
        // Add Payment Method
        Container(
          padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
          decoration: BoxDecoration(
            color: themeState.panelBg,
            borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
            border: Border.all(
              color: themeState.fieldBorder,
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: ResponsiveHelper.getResponsiveSpacing(context, 40),
                height: ResponsiveHelper.getResponsiveSpacing(context, 40),
                decoration: BoxDecoration(
                  color: themeState.fieldBg,
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 8)),
                  border: Border.all(
                    color: themeState.fieldBorder,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Icon(
                  Icons.add,
                  color: themeState.textPrimary,
                  size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
              Text(
                'Add Payment Method',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: themeState.textPrimary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(double base, ThemeState themeState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Transactions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: themeState.textPrimary,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
        _buildTransactionItem(
          base: base,
          themeState: themeState,
          icon: Icons.keyboard_arrow_down,
          title: 'Wallet Top Up',
          date: 'Today, 09:15 AM',
          amount: '+ QAR 100.00',
          isExpense: false,
        ),
      ],
    );
  }

  Widget _buildTransactionItem({
    required double base,
    required ThemeState themeState,
    required IconData icon,
    required String title,
    required String date,
    required String amount,
    required bool isExpense,
  }) {
    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
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
              color: themeState.panelBg,
              shape: BoxShape.circle,
              border: Border.all(color: themeState.fieldBorder),
            ),
            child: Icon(
              icon,
              color: isExpense ? Colors.red : Colors.green,
              size: ResponsiveHelper.getResponsiveIconSize(context, 20),
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: themeState.textPrimary,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                Text(
                  date,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: themeState.textSecondary,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isExpense ? Colors.red : Colors.green,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
