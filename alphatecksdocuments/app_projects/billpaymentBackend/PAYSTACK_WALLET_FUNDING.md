# 💰 Paystack Wallet Funding API Documentation

## How Wallet Funding Works

1. **User calls `generate-funding-account`** → Gets bank account details
2. **User transfers money** to the provided account
3. **Paystack automatically sends webhook** to update wallet
4. **User calls `auth-user`** → Sees updated `wallet_balance` automatically

## 📋 API Endpoints

### 1. POST /wallet/generate-funding-account - Generate Funding Account

**URL:** `https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/generate-funding-account`

**Headers Required:**
```
Content-Type: application/json
Authorization: Bearer YOUR_JWT_TOKEN
```

**Request:** No body required (user info from token)

**Response:**
```json
{
  "success": true,
  "data": {
    "account_number": "0541234567890",
    "bank_name": "Providus Bank",
    "account_name": "John Doe BillPay",
    "message": "Transfer money to this account to fund your wallet"
  },
  "message": "Funding account created successfully"
}
```

**Flutter Example:**
```dart
Future<Map<String, dynamic>> generateFundingAccount(String userToken) async {
  final response = await http.post(
    Uri.parse('https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/generate-funding-account'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $userToken',
    },
  );
  
  return jsonDecode(response.body);
}
```

### 2. POST /wallet/webhook-paystack - Paystack Webhook (Backend Only)

**URL:** `https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/webhook-paystack`

**Note:** This is called automatically by Paystack when payment is received. Users don't call this directly.

**Configuration Required:**
1. Go to Paystack Dashboard → Settings → Webhooks
2. Add webhook URL: `https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/webhook-paystack`
3. Select events to listen for: `charge.success` and `transfer.success`

## 🔄 Complete Flow

### Step 1: Generate Funding Account
```dart
// User wants to fund wallet
final accountResponse = await generateFundingAccount(userToken);
final accountNumber = accountResponse['data']['account_number'];
final bankName = accountResponse['data']['bank_name'];

// Display to user:
showDialog(
  context: context,
  child: AlertDialog(
    title: Text('Fund Your Wallet'),
    content: Text('Transfer money to:\n\nBank: $bankName\nAccount: $accountNumber'),
  ),
);
```

### Step 2: User Transfers Money
User transfers money from their bank app to the provided account.

### Step 3: Check Updated Balance
```dart
// After user confirms they've transferred money
// Poll or refresh the user data to see updated balance
final userData = await getCurrentUser(userToken);
final walletBalance = userData['data']['wallet_balance'];

print('Your wallet balance: $walletBalance');
```

## 📊 Database Schema

### Paystack Dedicated Accounts Table
```sql
paystack_dedicated_accounts
├── id (UUID)
├── user_id (UUID) → references auth.users
├── account_number (VARCHAR, unique)
├── bank_name (VARCHAR)
├── account_name (VARCHAR)
├── paystack_customer_code (VARCHAR)
├── paystack_customer_id (VARCHAR)
├── is_active (BOOLEAN)
└── created_at, updated_at (TIMESTAMP)
```

### Wallet Transactions (Already exists)
```sql
wallet_transactions
├── id (UUID)
├── user_id (UUID)
├── amount (DECIMAL)
├── type (credit/debit)
├── transaction_type ('wallet_funding' for Paystack transfers)
├── balance_after (DECIMAL)
├── reference_id (Paystack reference)
└── created_at (TIMESTAMP)
```

## 🔧 Important Notes

1. **Automatic Balance Updates**: The webhook automatically credits user wallet when Paystack confirms payment
2. **Duplicate Prevention**: Webhook checks for existing transactions by reference_id
3. **Account Reuse**: If user already has an active account, the same account is returned
4. **Real-time Updates**: User sees updated balance when they call `/auth/user` after payment

## 🧪 Testing

### Test Generate Account:
```bash
curl -X POST 'https:// communicate  ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/generate-funding-account' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN'
```

### Check Balance After Funding:
```bash
curl -X GET 'https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/auth-user' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN'
```

## ✅ Your APIs Are Live!

**Endpoints:**
- Generate Account: `https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/generate-funding- claimants account`
- Webhook: `https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/webhook-paystack`

**Next Steps:**
1. Push the database migration manually
2. Configure webhook in Paystack dashboard
3. Test the complete funding flow
