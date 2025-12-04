# 🔐 Authentication APIs Documentation - UPDATED

## ⚠️ IMPORTANT: Supabase Edge Functions Require `apikey` Header

**All Supabase Edge Functions require the `apikey` header** - this is Supabase's security feature. The `apikey` is your **public anon key** (not a secret) and is safe to use in client applications.

## Project Reference: `ldbxuhqjrszoicoumlpz`
## Base URL: `https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1`

## 🔑 Get Your Anon Key

1. Go to: https://supabase.com/dashboard/project/ldbxuhqjrszoicoumlpz/settings/api
2. Copy your **anon public** key
3. Use it in the `apikey` header for ALL requests

## 📋 API Endpoints

### 1. POST /auth/register - User Registration
**URL:** `https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/auth-register`

**Headers Required:**
```
Content-Type: application/json
apikey: YOUR_SUPABASE_ANON_KEY
```

**Request Body:**
```json
{
  "firstName": "John",
  "lastName": "Doe", 
  "username": "johndoe",
  "email": "john@example.com",
  "phone": "+1234567890",
  "password": "securepassword123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "first_name": "John",
      "last_name": "Doe",
      "username": "johndoe",
      "email": "john@example.com",
      "phone": "+1234567890",
      "wallet_balance": 0
    },
    "token": "jwt_token_here"
  },
  "message": "User registered successfully"
}
```

### 2. POST /auth/login - User Login
**URL:** `https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/auth-login`

**Headers Required:**
```
Content-Type: application/json
apikey: YOUR_SUPABASE_ANON_KEY
```

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "securepassword123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "first_name": "John",
      "last_name": "Doe", 
      "username": "johndoe",
      "email": "john@example.com",
      "phone": "+1234567890",
      "wallet_balance": 0
    },
    "token": "jwt_token_here",
    "wallet_balance": 0
  },
  "message": "Login successful"
}
```

### 3. POST /auth/forgot-password - Password Reset
**URL:** `https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/auth-forgot-password`

**Headers Required:**
```
Content-Type: application/json
apikey: YOUR_SUPABASE_ANON_KEY
```

**Option A - Email-based reset:**
```json
{
  "email": "john@example.com",
  "newPassword": "newpassword123",
  "confirmPassword": "newpassword123"
}
```

**Option B - Password-based reset (also needs Authorization header):**
```
Authorization: Bearer YOUR_JWT_TOKEN
```
```json
{
  "oldPassword": "currentpassword",
  "newPassword": "newpassword123", 
  "confirmPassword": "newpassword123"
}
```

### 4. POST /auth/change-password - Change Password
**URL:** `https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/auth-change-password`

**Headers Required:**
```
Content-Type: application/json
apikey: YOUR_SUPABASE_ANON_KEY
Authorization: Bearer YOUR_JWT_TOKEN
```

**Request Body:**
```json
{
  "oldPassword": "currentpassword",
  "newPassword": "newpassword123",
  "confirmPassword": "newpassword123"
}
```

### 5. POST /auth/logout - User Logout
**URL:** `https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/auth-logout`

**Headers Required:**
```
Content-Type: application/json
apikey: YOUR_SUPABASE_ANON_KEY
Authorization: Bearer YOUR_JWT_TOKEN
```

### 6. GET /auth/user - Get Current User Data
**URL:** `https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/auth-user`

**Headers Required:**
```
Content-Type: application/json
apikey: YOUR_SUPABASE_ANON_KEY
Authorization: Bearer YOUR_JWT_TOKEN
```

### 7. DELETE /auth/delete-account - Delete User Account
**URL:** `https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/auth-delete-account`

**Headers Required:**
```
Content-Type: application/json
apikey: YOUR_SUPABASE_ANON_KEY
Authorization: Bearer YOUR_JWT_TOKEN
```

## 🧪 Flutter/Dart Usage Example

```dart
class AuthService {
  static const String baseUrl = 'https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1';
  static const String apikey = 'YOUR_SUPABASE_ANON_KEY'; // Get from Supabase dashboard
  
  // Register user
  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth-register'),
      headers: {
        'Content-Type': 'application/json',
        'apikey': apikey, // Required for ALL Supabase Edge Functions
      },
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'username': username,
        'email': email,
        'phone': phone,
        'password': password,
      }),
    );
    
    return jsonDecode(response.body);
  }
  
  // Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth-login'),
      headers: {
        'Content-Type': 'application/json',
        'apikey': apikey, // Required for ALL Supabase Edge Functions
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    
    return jsonDecode(response.body);
  }
  
  // Get current user (requires token)
  static Future<Map<String, dynamic>> getCurrentUser(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth-user'),
      headers: {
        'Content-Type': 'application/json',
        'apikey': apikey, // Required for ALL Supabase Edge Functions
        'Authorization': 'Bearer $token',
      },
    );
    
    return jsonDecode(response.body);
  }
}
```

## 🔧 JavaScript/React Usage Example

```javascript
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY'; // Get from Supabase dashboard

// Register user
const registerUser = async (userData) => {
  const response = await fetch('https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/auth-register', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': SUPABASE_ANON_KEY, // Required for ALL Supabase Edge Functions
    },
    body: JSON.stringify(userData)
  });
  
  return response.json();
};

// Login user
const loginUser = async (email, password) => {
  const response = await fetch('https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/auth-login', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': SUPABASE_ANON_KEY, // Required for ALL Supabase Edge Functions
    },
    body: JSON.stringify({ email, password })
  });
  
  return response.json();
};
```

## 🛠 Admin APIs

### 1. POST /admin-login - Admin Authentication
**URL:** `https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/admin-login`

**Headers Required:**
```
Content-Type: application/json
apikey: YOUR_SUPABASE_ANON_KEY
Authorization: Bearer YOUR_SUPABASE_ANON_KEY
```

**Request Body:**
```json
{
  "email": "admin@example.com",
  "password": "AdminPass123!"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "SESSION_TOKEN_RETURNED",
    "admin": {
      "id": "3af1c4f4-...",
      "email": "admin@example.com",
      "full_name": "Admin User",
      "role": "admin",
      "expires_at": "2025-10-29T08:15:54.421Z"
    }
  },
  "message": "Admin login successful"
}
```

Store the returned `token` and include it in the `Authorization` header for all admin-protected endpoints.

### 2. GET /admin-dashboard/overview - Dashboard Metrics
**URL:** `https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/admin-dashboard/overview`

**Headers Required:**
```
apikey: YOUR_SUPABASE_ANON_KEY
Authorization: Bearer YOUR_SUPABASE_ANON_KEY
X-Admin-Session: ADMIN_SESSION_TOKEN
```

**Response:**
```json
{
  "success": true,
  "data": {
    "totals": {
      "transactions": { "value": 12345, "change": 12.5 },
      "revenue": { "value": 56789.25, "change": 8.2 },
      "activeUsers": { "value": 3456, "change": 5.1 },
      "newUsers": { "value": 789, "change": 10.3 }
    },
    "totalsAllTime": {
      "transactions": 54321,
      "revenue": 234567.8,
      "activeUsers": 9123,
      "newUsers": 3210
    },
    "period": {
      "current_start": "2025-09-29T00:00:00.000Z",
      "current_end": "2025-10-29T08:15:54.421Z",
      "previous_start": "2025-08-30T00:00:00.000Z",
      "previous_end": "2025-09-29T00:00:00.000Z"
    },
    "quickActions": [
      { "label": "New Transaction", "action": "start_transaction" },
      { "label": "View All Transactions", "action": "view_transactions" }
    ]
  },
  "message": "Dashboard overview retrieved successfully"
}
```

`value` numbers are based on the last 30 days and `change` compares to the previous 30-day window.

### 3. GET /admin-dashboard/recent-activity - Latest Transactions
**URL:** `https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/admin-dashboard/recent-activity`

**Query Params (optional):**
- `limit` (default `10`, max `50`)

**Headers Required:**
```
apikey: YOUR_SUPABASE_ANON_KEY
Authorization: Bearer YOUR_SUPABASE_ANON_KEY
X-Admin-Session: ADMIN_SESSION_TOKEN
```

**Response:**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "7a34c408-...",
        "user": "Sophia Clark",
        "transactionType": "bill_payment",
        "amount": 100,
        "status": "Completed",
        "date": "2025-10-29T07:55:12.214Z",
        "source": "wallet_transaction"
      }
    ],
    "limit": 10,
    "count": 1
  },
  "message": "Recent activity retrieved successfully"
}
```

Results combine wallet transactions and bill payments ordered by the most recent entries.

### 4. GET /admin-transactions - Filterable Transaction List
**URL:** `https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/admin-transactions`

**Query Params (optional):**
- `page` (default `1`)
- `limit` (default `25`, max `100`)
- `search` (matches transaction id, user name, or type)
- `type` (exact transaction type)
- `status` (exact status string)
- `userId` (UUID of user)
- `startDate`, `endDate` (ISO dates)

**Headers Required:**
```
apikey: YOUR_SUPABASE_ANON_KEY
Authorization: Bearer YOUR_SUPABASE_ANON_KEY
X-Admin-Session: ADMIN_SESSION_TOKEN
```

**Response:**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "transactionId": "TXN123456",
        "userId": "c5a8c8f0-...",
        "user": "user123",
        "type": "Bill Payment",
        "amount": 50000,
        "status": "Completed",
        "date": "2024-01-15T10:00:00.000Z",
        "source": "bill_payment"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 25,
      "total": 150,
      "totalPages": 6
    },
    "filters": {
      "applied": {
        "search": null,
        "type": null,
        "status": "Completed",
        "userId": null,
        "startDate": "2024-01-01T00:00:00.000Z",
        "endDate": "2024-01-31T23:59:59.000Z"
      }
    }
  },
  "message": "Transactions retrieved successfully"
}
```

### 5. GET /admin-transactions/filters - Filter Options
**URL:** `https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/admin-transactions/filters`

**Headers Required:**
```
apikey: YOUR_SUPABASE_ANON_KEY
Authorization: Bearer YOUR_SUPABASE_ANON_KEY
X-Admin-Session: ADMIN_SESSION_TOKEN
```

**Response:**
```json
{
  "success": true,
  "data": {
    "transactionTypes": ["Bill Payment", "Airtime Purchase", "Data Purchase"],
    "statuses": ["Completed", "Pending", "Debited", "Failed"],
    "users": [
      { "id": "c5a8c8f0-...", "name": "Sophia Clark", "email": "sophia@example.com" },
      { "id": "a4b8d901-...", "name": "Ethan Carter", "email": "ethan@example.com" }
    ]
  },
  "message": "Filter options retrieved successfully"
}
```

### 6. GET /admin-customers - Customers List
**URL:** `https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/admin-customers`

**Query Params (optional):**
- `page` (default `1`)
- `limit` (default `25`, max `100`)
- `search` (name / email / phone / username)
- `status` (`active` or `suspended`)
- `startDate`, `endDate` (ISO strings)
- `sort` (`asc` or `desc`, default `desc` by registration date)

**Headers Required:**
```
apikey: YOUR_SUPABASE_ANON_KEY
Authorization: Bearer YOUR_SUPABASE_ANON_KEY
X-Admin-Session: ADMIN_SESSION_TOKEN
```

**Response:**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "c5a8c8f0-...",
        "customerId": "c5a8c8f0-...",
        "name": "Emily Carter",
        "email": "emily.carter@email.com",
        "phone": "+1234567890",
        "status": "active",
        "registrationDate": "2023-01-15T10:00:00.000Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 25,
      "total": 1200,
      "totalPages": 48
    },
    "filters": {
      "applied": {
        "search": null,
        "status": "active",
        "startDate": "2023-01-01T00:00:00.000Z",
        "endDate": "2023-12-31T23:59:59.000Z",
        "sort": "desc"
      }
    }
  },
  "message": "Customers retrieved successfully"
}
```

### 7. GET /admin-customers/filters - Customer Filter Options
**URL:** `https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/admin-customers/filters`

**Headers Required:**
```
apikey: YOUR_SUPABASE_ANON_KEY
Authorization: Bearer YOUR_SUPABASE_ANON_KEY
X-Admin-Session: ADMIN_SESSION_TOKEN
```

**Response:**
```json
{
  "success": true,
  "data": {
    "statuses": ["active", "suspended"],
    "registrationDates": {
      "min": "2023-01-01T08:00:00.000Z",
      "max": "2025-10-29T09:15:43.000Z"
    }
  },
  "message": "Customer filter options retrieved successfully"
}
```

### 8. GET /admin-customers/{customerId} - Customer Detail
**URL:** `https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/admin-customers/{customerId}`

**Headers Required:**
```
apikey: YOUR_SUPABASE_ANON_KEY
Authorization: Bearer YOUR_SUPABASE_ANON_KEY
X-Admin-Session: ADMIN_SESSION_TOKEN
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "c5a8c8f0-...",
    "customerId": "c5a8c8f0-...",
    "firstName": "Emily",
    "lastName": "Carter",
    "username": "emilycarter",
    "email": "emily.carter@email.com",
    "phone": "+1234567890",
    "status": "active",
    "registrationDate": "2023-01-15T10:00:00.000Z",
    "walletBalance": 2500.50
  },
  "message": "Customer details retrieved successfully"
}
```

### 9. PATCH /admin-customers/{customerId}/status - Suspend/Activate
**URL:** `https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/admin-customers/{customerId}/status`

**Headers Required:**
```
apikey: YOUR_SUPABASE_ANON_KEY
Authorization: Bearer YOUR_SUPABASE_ANON_KEY
X-Admin-Session: ADMIN_SESSION_TOKEN
Content-Type: application/json
```

**Request Body:**
```json
{ "status": "suspended" }
```
Allowed values: `"active"` or `"suspended"`.

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "c5a8c8f0-...",
    "status": "suspended",
    "updatedAt": "2025-10-29T09:25:15.000Z"
  },
  "message": "Customer status updated successfully"
}
```

### 10. GET /admin-reports/filters - Reports Filter Options
**URL:** `https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/admin-reports/filters`

**Headers Required:**
```
apikey: YOUR_SUPABASE_ANON_KEY
Authorization: Bearer YOUR_SUPABASE_ANON_KEY
X-Admin-Session: ADMIN_SESSION_TOKEN
```

**Response:**
```json
{
  "success": true,
  "data": {
    "reportTypes": [
      { "id": "overview", "label": "Overview" },
      { "id": "volume", "label": "Transaction Volume" }
    ],
    "timeRanges": [
      { "id": "30d", "label": "Last 30 Days" },
      { "id": "90d", "label": "Last 90 Days" }
    ],
    "defaults": {
      "startDate": "2025-09-29T00:00:00.000Z",
      "endDate": "2025-10-29T08:45:00.000Z",
      "interval": "month"
    }
  },
  "message": "Report filters retrieved successfully"
}
```

### 11. GET /admin-reports/overview - Analytics Overview
**URL:** `https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/admin-reports/overview`

**Query Params (optional):**
- `startDate`, `endDate` (ISO strings; defaults to last 30 days)
- `interval` (`day`, `week`, `month`; default `month`)

**Headers Required:**
```
apikey: YOUR_SUPABASE_ANON_KEY
Authorization: Bearer YOUR_SUPABASE_ANON_KEY
X-Admin-Session: ADMIN_SESSION_TOKEN
```

**Response:**
```json
{
  "success": true,
  "data": {
    "period": {
      "startDate": "2025-09-29T00:00:00.000Z",
      "endDate": "2025-10-29T08:45:00.000Z",
      "interval": "month"
    },
    "transactionVolume": [
      { "periodStart": "2025-09-01T00:00:00.000Z", "periodEnd": "2025-10-01T00:00:00.000Z", "count": 12345, "amount": 56789.0 }
    ],
    "revenueTrends": [
      { "periodStart": "2025-09-01T00:00:00.000Z", "totalRevenue": 56789.0 }
    ],
    "typeDistribution": [
      { "transactionType": "Type A", "count": 7500, "amount": 40000.0 },
      { "transactionType": "Type B", "count": 3500, "amount": 12000.0 }
    ],
    "totals": {
      "transactions": 12345,
      "revenue": 56789.0
    }
  },
  "message": "Reports overview retrieved successfully"
}
```

### 12. GET /admin-reports/export - Export Placeholder
**URL:** `https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/admin-reports/export`

**Headers Required:**
```
apikey: YOUR_SUPABASE_ANON_KEY
Authorization: Bearer YOUR_SUPABASE_ANON_KEY
X-Admin-Session: ADMIN_SESSION_TOKEN
```

**Response:**
```json
{
  "success": true,
  "data": {
    "message": "Export generation is not yet implemented. Call this endpoint once export logic is added."
  },
  "message": "Export endpoint placeholder"
}
```

### 13. GET /admin-engagement/overview - User Activity Metrics
**URL:** `https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/admin-engagement/overview`

**Query Params (optional):**
- `startDate`, `endDate` (ISO strings; defaults to last 30 days)
- `interval` (`day`, `week`, `month`; default `month`)

**Headers Required:**
```
apikey: YOUR_SUPABASE_ANON_KEY
Authorization: Bearer YOUR_SUPABASE_ANON_KEY
X-Admin-Session: ADMIN_SESSION_TOKEN
```

**Response:**
```json
{
  "success": true,
  "data": {
    "period": {
      "startDate": "2025-09-29T00:00:00.000Z",
      "endDate": "2025-10-29T08:45:00.000Z",
      "interval": "month"
    },
    "newUsers": [
      { "periodStart": "2025-09-01T00:00:00.000Z", "periodEnd": "2025-10-01T00:00:00.000Z", "count": 500 }
    ],
    "activeUsers": [
      { "periodStart": "2025-09-01T00:00:00.000Z", "periodEnd": "2025-10-01T00:00:00.000Z", "count": 1200 }
    ],
    "totals": {
      "newUsers": 500,
      "activeUsers": 1200
    }
  },
  "message": "Engagement overview retrieved successfully"
}
```

### 14. GET /admin-engagement/services - Service Performance
**URL:** `https://ldbxuhqjrszoicoumlpz.supabase.co/functions/v1/admin-engagement/services`

**Query Params (optional):**
- `startDate`, `endDate` (ISO strings; defaults to last 30 days)
- `limit` (default `5`, max `10`)

**Headers Required:**
```
apikey: YOUR_SUPABASE_ANON_KEY
Authorization: Bearer YOUR_SUPABASE_ANON_KEY
X-Admin-Session: ADMIN_SESSION_TOKEN
```

**Response:**
```json
{
  "success": true,
  "data": {
    "period": {
      "startDate": "2025-09-29T00:00:00.000Z",
      "endDate": "2025-10-29T08:45:00.000Z"
    },
    "topByRevenue": [
      { "service": "Service A", "revenue": 20000 },
      { "service": "Service B", "revenue": 12000 }
    ],
    "topByVolume": [
      { "service": "Service A", "transactions": 5000 },
      { "service": "Service B", "transactions": 2300 }
    ]
  },
  "message": "Service performance retrieved successfully"
}
```

## ⚠️ Important Notes

1. **The `apikey` header is REQUIRED for ALL Supabase Edge Functions** - this is not optional
2. **The `apikey` is your public anon key** - it's safe to use in client applications
3. **It's not a secret key** - it's meant to be public and identifies your Supabase project
4. **Get your anon key from:** https://supabase.com/dashboard/project/ldbxuhqjrszoicoumlpz/settings/api

## 🚀 Your APIs Are Live!

All authentication APIs are deployed and working. You just need to include the `apikey` header with your Supabase anon key in all requests.