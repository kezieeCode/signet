# Airtime Purchase API

## Africa's Talking API Integration

### API Endpoint
**POST:** `https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/purchase-airtime`

### Function Code
The function is created at: `supabase/functions/purchase-airtime/index.ts`

### Request Body
```json
{
  "mobileNumber": "+254712345678",
  "networkProvider": "SAFARICOM",
  "amount": 50.00
}
```

### Response
```json
{
  "success": true,
  "data": {
    "success": true,
    "transactionId": "AT_1703123456789_abc123def",
    "mobileNumber": "+254712345678",
    "networkProvider": "SAFARICOM",
    "amount": 50.00,
    "status": "completed",
    "message": "Airtime purchase successful",
    "africastalkingResponse": { /* Africa's Talking response */ }
  },
  "message": "Airtime purchase successful"
}
```

### Flutter/Dart Usage
```dart
Future<void> purchaseAirtime({
  required String mobileNumber,
  required String networkProvider,
  required double amount,
}) async {
  final response = await http.post(
    Uri.parse('https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/purchase-airtime'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer YOUR_ANON_KEY',
    },
    body: jsonEncode({
      'mobileNumber': mobileNumber,
      'networkProvider': networkProvider,
      'amount': amount,
    }),
  );
  
  final result = jsonDecode(response.body);
  print('Airtime purchase result: $result');
}
```

### Deploy the Function
Run this command to deploy:
```bash
supabase functions deploy purchase-airtime
```

### Important Notes
1. Using **sandbox** environment - change `AFRICASTALKING_USERNAME` to your production username when ready
2. API key is embedded in the function - consider using environment variables in production
3. Mobile number must include country code (e.g., +254 for Kenya)
4. Amount is in the currency of the phone number's country
