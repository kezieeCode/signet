import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/theme_cubit.dart';
import '../../utils/responsive_helper.dart';
import '../../services/api_service.dart';
import 'redeem_points_screen.dart';

// AppColors is defined in theme_cubit.dart

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  // Rewards data from API
  bool _isLoading = true;
  bool _isLoadingHistory = true;
  int _currentPoints = 0;
  double _currentQar = 0.0;
  String _currentTier = 'bronze';
  int _tierPoints = 0;
  String _nextTier = 'silver';
  int _pointsToNextTier = 50;
  List<Map<String, dynamic>> _availableCoupons = [];
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchRewardsData();
    _fetchPointsHistory();
  }

  Future<void> _fetchRewardsData() async {
    try {
      print('💰 FETCHING REWARDS DATA...');
      final response = await ApiService.getRewards(
        includeCoupons: true,
        includeRedemptions: false,
        couponLimit: 5,
      );

      print('💰 REWARDS API RESPONSE: $response');

      if (response['success'] && response['data'] != null) {
        // Handle double nesting like before
        final data = response['data']['data'] ?? response['data'];
        
        print('💰 PARSED DATA: $data');
        print('💰 REWARD BALANCE: ${data['reward_balance']}');
        
        if (mounted) {
          setState(() {
            // Points balance - convert double to int
            final pointsBalance = data['reward_balance']?['points']?['current_balance'];
            _currentPoints = pointsBalance != null ? (pointsBalance as num).toInt() : 0;
            _currentQar = (data['reward_balance']?['qar']?['current_balance'] ?? 0).toDouble();
            
            print('💰 CURRENT POINTS: $_currentPoints');
            print('💰 CURRENT QAR: $_currentQar');
            
            // Loyalty tier
            _currentTier = data['loyalty_tier']?['current_tier'] ?? 'bronze';
            final tierPts = data['loyalty_tier']?['tier_points'];
            _tierPoints = tierPts != null ? (tierPts as num).toInt() : 0;
            _nextTier = data['loyalty_tier']?['next_tier'] ?? 'silver';
            final ptsToNext = data['loyalty_tier']?['points_to_next_tier'];
            _pointsToNextTier = ptsToNext != null ? (ptsToNext as num).toInt() : 50;
            
            // Available coupons
            _availableCoupons = List<Map<String, dynamic>>.from(data['available_coupons'] ?? []);
            
            _isLoading = false;
          });
        }
      } else {
        print('❌ REWARDS API FAILED: ${response['error']}');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('❌ REWARDS DATA ERROR: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchPointsHistory() async {
    try {
      print('📊 FETCHING POINTS HISTORY...');
      final response = await ApiService.getPointsHistory();
      
      print('📊 POINTS HISTORY RESPONSE: $response');
      
      if (response['success'] == true && response['data'] != null) {
        // Handle potential double nesting
        final outerData = response['data'];
        final data = outerData['data'] ?? outerData;
        
        print('📊 PARSED DATA: $data');
        
        // Extract transactions array
        final transactionsData = data['transactions'] as List?;
        
        print('📊 TRANSACTIONS COUNT: ${transactionsData?.length ?? 0}');
        
        if (transactionsData != null && mounted) {
          setState(() {
            _transactions = transactionsData.map((transaction) {
              // Parse date from ISO format
              String formattedDate = 'N/A';
              if (transaction['date'] != null) {
                try {
                  final DateTime dateTime = DateTime.parse(transaction['date']);
                  formattedDate = '${_monthName(dateTime.month)} ${dateTime.day}, ${dateTime.year}';
                } catch (e) {
                  formattedDate = transaction['date'].toString();
                }
              }
              
              // Determine if positive (earned) or negative (redeemed)
              final type = transaction['type'] as String;
              final isPositive = type == 'earned';
              final points = (transaction['points'] ?? 0).toDouble();
              
              return {
                'description': transaction['description'] ?? 'Transaction',
                'date': formattedDate,
                'points': points.toInt(),
                'isPositive': isPositive,
              };
            }).toList();
            
            _isLoadingHistory = false;
          });
          
          print('✅ POINTS HISTORY LOADED: ${_transactions.length} transactions');
        } else {
          print('⚠️ NO TRANSACTIONS FOUND');
          if (mounted) {
            setState(() {
              _isLoadingHistory = false;
            });
          }
        }
      } else {
        print('❌ POINTS HISTORY API FAILED: ${response['error']}');
        if (mounted) {
          setState(() {
            _isLoadingHistory = false;
          });
        }
      }
    } catch (e) {
      print('❌ POINTS HISTORY ERROR: $e');
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }
  
  String _monthName(int month) {
    const months = ['', 'January', 'February', 'March', 'April', 'May', 'June', 
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month];
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
              'My Rewards',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: themeState.textPrimary,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(
                  Icons.more_vert,
                  color: themeState.textPrimary,
                ),
                onPressed: () {
                  // Handle menu
                },
              ),
            ],
          ),
          body: _isLoading 
            ? Center(
                child: CircularProgressIndicator(
                  color: AppColors.gold,
                ),
              )
            : SingleChildScrollView(
                padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Points Balance Card
                    _buildPointsBalanceCard(themeState),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                    
                    // Current Tier & Next Tier Section
                    _buildTierSection(themeState),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                    
                    // Redeem Your Points Section
                    _buildRedeemSection(themeState),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
                    
                    // Points History Section
                    _buildPointsHistorySection(themeState),
                  ],
                ),
              ),
        );
      },
    );
  }

  Widget _buildPointsBalanceCard(ThemeState themeState) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.gold, Color(0xFFFFD700)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Circular accents
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: ResponsiveHelper.getResponsiveSpacing(context, 80),
                height: ResponsiveHelper.getResponsiveSpacing(context, 80),
                decoration: BoxDecoration(
                  color: Color(0xFF0D182E).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -25,
              left: -25,
              child: Container(
                width: ResponsiveHelper.getResponsiveSpacing(context, 100),
                height: ResponsiveHelper.getResponsiveSpacing(context, 100),
                decoration: BoxDecoration(
                  color: Color(0xFF0D182E).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Content
            Center(
              child: Padding(
                padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 24, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  Text(
                    'Your Points Balance',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Color(0xFF8B6914),
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                  Text(
                    _currentPoints.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Color(0xFF0D182E),
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 36),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                  Container(
                    padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 20)),
                    ),
                    child: Text(
                      'Equals QAR ${_currentQar.toStringAsFixed(2)}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Color(0xFF0D182E),
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

  Widget _buildTierSection(ThemeState themeState) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: themeState.panelBg,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
        border: Border.all(color: themeState.fieldBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Current Tier
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Tier',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: themeState.textSecondary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: AppColors.gold,
                        size: ResponsiveHelper.getResponsiveIconSize(context, 16),
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                      Text(
                        '${_currentTier[0].toUpperCase()}${_currentTier.substring(1)} Member',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.gold,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Next Tier
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Next Tier',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: themeState.textSecondary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                  Text(
                    '${_nextTier[0].toUpperCase()}${_nextTier.substring(1)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: themeState.textPrimary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 6)),
            child: LinearProgressIndicator(
              value: _pointsToNextTier > 0 ? (_tierPoints / _pointsToNextTier).clamp(0.0, 1.0) : 0.0,
              backgroundColor: Colors.grey.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
              minHeight: ResponsiveHelper.getResponsiveSpacing(context, 12),
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
          Text(
            'You are $_pointsToNextTier points away from ${_nextTier[0].toUpperCase()}${_nextTier.substring(1)} tier!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: themeState.textPrimary,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedeemSection(ThemeState themeState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Redeem Your Points',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: themeState.textPrimary,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {
                // Handle see all
              },
              child: Text(
                'See All',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.gold,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
        // Rewards Grid
        _availableCoupons.isEmpty
          ? Container(
              padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 24, vertical: 32),
              child: Center(
                child: Text(
                  'No coupons available at the moment',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: themeState.textSecondary,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  ),
                ),
              ),
            )
          : GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: ResponsiveHelper.getResponsiveSpacing(context, 12),
                mainAxisSpacing: ResponsiveHelper.getResponsiveSpacing(context, 12),
                childAspectRatio: 0.8,
              ),
              itemCount: _availableCoupons.length,
              itemBuilder: (context, index) {
                final coupon = _availableCoupons[index];
                return _buildRewardCard(
                  coupon['name'] ?? 'Coupon',
                  '${coupon['value']} ${coupon['currency'] ?? 'QAR'}',
                  Icons.local_offer,
                  coupon['can_redeem'] ?? false,
                  themeState,
                  code: coupon['code'],
                  description: coupon['description'],
                );
              },
            ),
      ],
    );
  }

  Widget _buildRewardCard(String title, String points, IconData icon, bool isAvailable, ThemeState themeState, {String? code, String? description}) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: themeState.panelBg,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
        border: Border.all(color: themeState.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: ResponsiveHelper.getResponsiveSpacing(context, 40),
            height: ResponsiveHelper.getResponsiveSpacing(context, 40),
            decoration: BoxDecoration(
              color: Color(0xFF0D182E),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.gold,
              size: ResponsiveHelper.getResponsiveIconSize(context, 20),
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: themeState.textPrimary,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
          // Points
          Text(
            points,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: themeState.textSecondary,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
            ),
          ),
          Spacer(),
          // Redeem Button
          GestureDetector(
            onTap: isAvailable ? () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RedeemPointsScreen()),
              );
            } : null,
            child: Container(
              width: double.infinity,
              padding: ResponsiveHelper.getResponsivePadding(context, vertical: 8),
              decoration: BoxDecoration(
                color: isAvailable ? AppColors.gold : themeState.fieldBg,
                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 8)),
              ),
              child: Text(
                'Redeem',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isAvailable ? Colors.black : themeState.textSecondary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsHistorySection(ThemeState themeState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Points History',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: themeState.textPrimary,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
        
        // Show loading indicator while fetching
        if (_isLoadingHistory)
          Center(
            child: Padding(
              padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 40)),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
              ),
            ),
          )
        // Show empty state if no transactions
        else if (_transactions.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 40)),
              child: Column(
                children: [
                  Icon(
                    Icons.history,
                    size: ResponsiveHelper.getResponsiveIconSize(context, 64),
                    color: themeState.textSecondary.withOpacity(0.5),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                  Text(
                    'No transaction history yet',
                    style: TextStyle(
                      color: themeState.textSecondary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        // Show transactions
        else
          ..._transactions.map((transaction) => _buildTransactionCard(transaction, themeState)).toList(),
      ],
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction, ThemeState themeState) {
    final bool isPositive = transaction['isPositive'] as bool;
    final int points = transaction['points'] as int;
    final String description = transaction['description'] as String;
    final String date = transaction['date'] as String;

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveSpacing(context, 16)),
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: themeState.panelBg,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
        border: Border.all(color: themeState.fieldBorder),
      ),
      child: Row(
        children: [
          // Icon Section
          Container(
            width: ResponsiveHelper.getResponsiveSpacing(context, 40),
            height: ResponsiveHelper.getResponsiveSpacing(context, 40),
            decoration: BoxDecoration(
              color: themeState.fieldBg,
              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 8)),
            ),
            child: Icon(
              isPositive ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: isPositive ? Colors.green : Colors.red,
              size: ResponsiveHelper.getResponsiveIconSize(context, 24),
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
          // Description Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: themeState.textPrimary,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                Text(
                  date,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: themeState.textSecondary,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                  ),
                ),
              ],
            ),
          ),
          // Points Section
          Text(
            '${isPositive ? '+' : '-'}${points} pts',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isPositive ? Colors.green : Colors.red,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
