import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/responsive_helper.dart';

class AddPaymentMethodDialog extends StatefulWidget {
  const AddPaymentMethodDialog({super.key});

  @override
  State<AddPaymentMethodDialog> createState() => _AddPaymentMethodDialogState();
}

class _AddPaymentMethodDialogState extends State<AddPaymentMethodDialog> {
  static const Color background = Color(0xFF0D182E);
  static const Color gold = Color(0xFFD4AF37);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB7C0D1);
  static const Color fieldBg = Color(0x112A3550);
  static const Color fieldBorder = Color(0xFF233147);

  int _selectedPaymentType = 0; // 0: Card, 1: PayPal, 2: Apple Pay
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardholderController = TextEditingController();
  bool _saveCard = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardholderController.dispose();
    super.dispose();
  }


  void _addPaymentMethod() {
    if (_selectedPaymentType == 0) {
      // Card validation
      if (_cardNumberController.text.isEmpty ||
          _expiryController.text.isEmpty ||
          _cvvController.text.isEmpty ||
          _cardholderController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all card details')),
        );
        return;
      }

      // Create card data object
      final cardData = {
        'type': 'card',
        'cardNumber': _cardNumberController.text.replaceAll(' ', ''),
        'expiryDate': _expiryController.text,
        'cvv': _cvvController.text,
        'cardholderName': _cardholderController.text,
        'saveCard': _saveCard,
        'addedAt': DateTime.now().toIso8601String(),
      };

      // Save card if toggle is enabled
      if (_saveCard) {
        _saveCardToStorage(cardData);
      }

      // TODO: Process payment method with backend
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_saveCard 
            ? 'Card added and saved successfully!' 
            : 'Card added successfully!'),
        ),
      );
    } else if (_selectedPaymentType == 1) {
      // PayPal
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PayPal payment method added successfully!')),
      );
    } else if (_selectedPaymentType == 2) {
      // Apple Pay
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Apple Pay payment method added successfully!')),
      );
    }

    Navigator.pop(context);
  }

  void _saveCardToStorage(Map<String, dynamic> cardData) {
    // In a real app, you would save this to secure storage or backend
    // For now, we'll simulate saving to local storage}
    
    // TODO: Implement secure storage using packages like:
    // - flutter_secure_storage for local secure storage
    // - Or send to backend API for server-side storage
    
    // Example of what you might do:
    // await SecureStorage.write(key: 'saved_cards', value: jsonEncode(cardData));
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Payment Method',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textPrimary,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: textPrimary,
                    size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
            // Payment Method Selection
            Row(
              children: [
                Expanded(
                  child: _paymentTypeButton(
                    'Card',
                    Icons.credit_card,
                    0,
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                Expanded(
                  child: _paymentTypeButton(
                    'PayPal',
                    Icons.paypal,
                    1,
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                Expanded(
                  child: _paymentTypeButton(
                    'Apple Pay',
                    Icons.apple,
                    2,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
            // Card Details (only show if Card is selected)
            if (_selectedPaymentType == 0) ...[
              // Card Number
              Text(
                'Card Number',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textPrimary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
              Container(
                decoration: BoxDecoration(
                  color: fieldBg,
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                  border: Border.all(color: fieldBorder),
                ),
                padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                child: Row(
                  children: [
                    Icon(
                      Icons.credit_card,
                      color: textSecondary,
                      size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                    Expanded(
                      child: TextField(
                        controller: _cardNumberController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(19),
                          CardNumberInputFormatter(),
                        ],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: textPrimary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                        ),
                        decoration: InputDecoration(
                          hintText: '1234 5678 9012 3456',
                          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: textSecondary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
              // Expiry Date and CVV
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expiry Date',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: textPrimary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                        Container(
                          decoration: BoxDecoration(
                            color: fieldBg,
                            borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                            border: Border.all(color: fieldBorder),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_month,
                                color: textSecondary,
                                size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                              ),
                              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                              Expanded(
                                child: TextField(
                                  controller: _expiryController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                    ExpiryDateInputFormatter(),
                                  ],
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: textPrimary,
                                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'MM/YY',
                                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: textSecondary,
                                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CVV',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: textPrimary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                        Container(
                          decoration: BoxDecoration(
                            color: fieldBg,
                            borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                            border: Border.all(color: fieldBorder),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lock,
                                color: textSecondary,
                                size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                              ),
                              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                              Expanded(
                                child: TextField(
                                  controller: _cvvController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(3),
                                  ],
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: textPrimary,
                                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '123',
                                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: textSecondary,
                                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                    ),
                                    border: InputBorder.none,
                                  ),
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
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
              // Cardholder Name
              Text(
                'Cardholder Name',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textPrimary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
              Container(
                decoration: BoxDecoration(
                  color: fieldBg,
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                  border: Border.all(color: fieldBorder),
                ),
                padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: textSecondary,
                      size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                    Expanded(
                      child: TextField(
                        controller: _cardholderController,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: textPrimary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                        ),
                        decoration: InputDecoration(
                          hintText: 'John Doe',
                          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: textSecondary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
              // Save Card Toggle
              Row(
                children: [
                  Icon(
                    Icons.shield,
                    color: gold,
                    size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Save this card',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: textPrimary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'For faster checkout next time',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: textSecondary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _saveCard,
                    onChanged: (value) => setState(() => _saveCard = value),
                    activeColor: gold,
                    inactiveThumbColor: textSecondary,
                    inactiveTrackColor: fieldBorder,
                  ),
                ],
              ),
            ],
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addPaymentMethod,
                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                  foregroundColor: Colors.black,
                  padding: ResponsiveHelper.getResponsiveButtonPadding(context, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Add Payment Method',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: fieldBorder),
                  backgroundColor: fieldBg,
                  foregroundColor: textPrimary,
                  padding: ResponsiveHelper.getResponsiveButtonPadding(context, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
          ],
        ),
      ),
    );
  }

  Widget _paymentTypeButton(String label, IconData icon, int index) {
    final isSelected = _selectedPaymentType == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentType = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
        decoration: BoxDecoration(
          color: isSelected ? gold : fieldBg,
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
          border: Border.all(
            color: isSelected ? gold : fieldBorder,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : textPrimary,
              size: ResponsiveHelper.getResponsiveIconSize(context, 24),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected ? Colors.black : textPrimary,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Custom input formatters
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.length <= 4) return newValue;
    
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.length <= 2) return newValue;
    
    return TextEditingValue(
      text: '${text.substring(0, 2)}/${text.substring(2)}',
      selection: TextSelection.collapsed(offset: text.length + 1),
    );
  }
}