## Paystack Wallet Funding - API Endpoint Samples

### 1. Generate Funding Account

**Endpoint:** 
```
POST https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/generate-funding-account
```

**Headers:**
```
Content-Type: application/json
Authorization: Bearer YOUR_JWT_TOKEN_FROM_LOGIN
```

**Request Body:** 
```json
None (user info from JWT token)
```

**cURL Example:**
```bash
curl -X POST 'https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/generate-funding-account' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN'
```

**Response:**
```json
{
  "success": true,
  "data": {
    "account_number": "0541234567890",
    "bank_name": "Wema Bank",
    "account_name": "John Doe BillPay",
    "message": "Transfer money to this account to fund your wallet"
  },
  "message": "Funding account created successfully"
}
```

### 2. Check Wallet Balance (After Funding)

**Endpoint:**
```
GET https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/auth-user
```

**Headers:**
```
Content-Type: application/json
Authorization: Bearer YOUR_JWT_TOKEN
```

**cURL Example:**
```bash
curl -X GET 'https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/auth-user' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN'
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "user-id",
    "first_name": "John",
    "last_name": "Doe",
    "username": "johndoe",
    "email": "john@example.com",
    "phone": "+1234567890",
    "wallet_balance": 100.50
  },
  "message": "User data retrieved successfully"
}
```

## Flutter/Dart Complete Example

```dart
class PaystackFundingService {
  static const String baseUrl = 'https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1';
  
  // Generate funding account
  static Future<Map<String, dynamic>> generateFundingAccount(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/generate-funding-account'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    return jsonDecode(response.body);
  }
  
  // Get current user (with wallet balance)
  static Future<Map<String, dynamic>> getCurrentUser(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth-user'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    return jsonDecode(response.body);
  }
}

// Usage in your app
final token = 'YOUR_JWT_TOKEN_FROM_LOGIN';

// Step 1: Generate funding account
final accountResult = await PaystackFundingService.generateFundingAccount(token);
final accountNumber = accountResult['data']['account_number'];
final bankName = accountResult['data']['bank_name'];

// Display to user
print('Transfer money to:');
print('Bank: $bankName');
print('Account: $accountNumber');

// Step 2: After user transfers money, check balance
final userEconomic = await PaystackFundingService.getCurrentUser(token);
final walletBalance = userData['data']['wallet_balance'];
print('Your wallet balance: \$$walletBalance');
```
