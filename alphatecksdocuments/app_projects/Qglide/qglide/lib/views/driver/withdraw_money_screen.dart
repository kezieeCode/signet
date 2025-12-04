import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/theme_cubit.dart';
import '../../utils/responsive_helper.dart';

class WithdrawMoneyScreen extends StatefulWidget {
  final double availableBalance;
  final String currency;
  
  const WithdrawMoneyScreen({
    super.key,
    required this.availableBalance,
    this.currency = 'QAR',
  });

  @override
  State<WithdrawMoneyScreen> createState() => _WithdrawMoneyScreenState();
}

class _WithdrawMoneyScreenState extends State<WithdrawMoneyScreen> {
  final TextEditingController _amountController = TextEditingController();
  int _selectedMethod = 0; // 0: Bank Transfer, 1: QPay Wallet

  final List<Map<String, dynamic>> _withdrawalMethods = [
    {
      'name': 'Bank Transfer',
      'icon': Icons.account_balance,
      'details': 'QNB Account **** 5678',
      'type': 'bank',
    },
    {
      'name': 'QPay Wallet',
      'icon': Icons.account_balance_wallet,
      'details': 'Linked to +974 **** 1234',
      'type': 'qpay',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill with full available balance
    _amountController.text = '${widget.currency} ${widget.availableBalance.toStringAsFixed(2)}';
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _withdrawAllAmount() {
    setState(() {
      _amountController.text = '${widget.currency} ${widget.availableBalance.toStringAsFixed(2)}';
    });
  }

  void _processWithdrawal() {
    // Handle withdrawal logic
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdrawal Requested'),
        content: const Text('Your withdrawal request has been submitted and will be processed within 1-2 business days.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to earnings screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
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
              'Withdraw Money',
              style: TextStyle(
                color: themeState.textPrimary,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Available Balance Card
                _buildAvailableBalanceCard(themeState),
                
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
                
                // Enter Amount Section
                _buildEnterAmountSection(themeState),
                
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
                
                // Select Withdrawal Method Section
                _buildWithdrawalMethodSection(themeState),
                
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 40)),
                
                // Withdraw Button
                _buildWithdrawButton(themeState),
              ],
            ),
          ),
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
          Text(
            '${widget.currency} ${widget.availableBalance.toStringAsFixed(2)}',
            style: TextStyle(
              color: themeState.textPrimary,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 28),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnterAmountSection(ThemeState themeState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter Amount',
          style: TextStyle(
            color: themeState.textSecondary,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
            vertical: ResponsiveHelper.getResponsiveSpacing(context, 12),
          ),
          decoration: BoxDecoration(
            color: themeState.isDarkTheme ? const Color(0xFF1A2B47) : Colors.white,
            borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
            border: Border.all(
              color: themeState.isDarkTheme ? Colors.grey.shade600 : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountController,
                  style: TextStyle(
                    color: themeState.textPrimary,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter amount',
                    hintStyle: TextStyle(
                      color: themeState.textSecondary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _withdrawAllAmount,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.getResponsiveSpacing(context, 12),
                    vertical: ResponsiveHelper.getResponsiveSpacing(context, 6),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 6)),
                  ),
                  child: Text(
                    'All',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWithdrawalMethodSection(ThemeState themeState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Withdrawal Method',
          style: TextStyle(
            color: themeState.textSecondary,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
        ...List.generate(_withdrawalMethods.length, (index) {
          final method = _withdrawalMethods[index];
          final isSelected = _selectedMethod == index;
          
          return Container(
            margin: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveSpacing(context, 12)),
            child: GestureDetector(
              onTap: () => setState(() => _selectedMethod = index),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
                decoration: BoxDecoration(
                  color: themeState.isDarkTheme ? const Color(0xFF1A2B47) : Colors.white,
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                  border: isSelected 
                      ? Border.all(color: Colors.amber, width: 2)
                      : Border.all(
                          color: themeState.isDarkTheme ? Colors.grey.shade600 : Colors.grey.shade300,
                          width: 1,
                        ),
                ),
                child: Row(
                  children: [
                    // Method Icon
                    Container(
                      width: ResponsiveHelper.getResponsiveSpacing(context, 40),
                      height: ResponsiveHelper.getResponsiveSpacing(context, 40),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Colors.amber.withOpacity(0.2)
                            : (themeState.isDarkTheme ? Colors.grey.shade700 : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 8)),
                      ),
                      child: Icon(
                        method['icon'],
                        color: isSelected ? Colors.amber : themeState.textSecondary,
                        size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                    
                    // Method Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method['name'],
                            style: TextStyle(
                              color: themeState.textPrimary,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                          Text(
                            method['details'],
                            style: TextStyle(
                              color: themeState.textSecondary,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Radio Button
                    Container(
                      width: ResponsiveHelper.getResponsiveSpacing(context, 20),
                      height: ResponsiveHelper.getResponsiveSpacing(context, 20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? Colors.amber : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? Colors.amber : themeState.textSecondary,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              color: Colors.black,
                              size: ResponsiveHelper.getResponsiveIconSize(context, 12),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildWithdrawButton(ThemeState themeState) {
    final amount = _amountController.text.isNotEmpty 
        ? _amountController.text 
        : '${widget.currency} 0.00';
    
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _processWithdrawal,
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
          'Withdraw $amount',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
