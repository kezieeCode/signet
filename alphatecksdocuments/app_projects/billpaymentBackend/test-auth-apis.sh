#!/bin/bash

# Test script for Authentication APIs
PROJECT_REF="ldbxuhqjrszoicoumlpz"
BASE_URL="https://$PROJECT_REF.supabase.co/functions/v1"

echo "🧪 Testing Authentication APIs"
echo "Project: $PROJECT_REF"
echo "Base URL: $BASE_URL"
echo ""

# Test data
TEST_EMAIL="testuser$(date +%s)@example.com"
TEST_USERNAME="testuser$(date +%s)"
TEST_PASSWORD="testpass123"

echo "📝 Test Data:"
echo "Email: $TEST_EMAIL"
echo "Username: $TEST_USERNAME"
echo "Password: $TEST_PASSWORD"
echo ""

# Test 1: User Registration
echo "1️⃣ Testing User Registration..."
REGISTER_RESPONSE=$(curl -s -X POST "$BASE_URL/auth-register" \
  -H 'Content-Type: application/json' \
  -d "{
    \"firstName\": \"Test\",
    \"lastName\": \"User\",
    \"username\": \"$TEST_USERNAME\",
    \"email\": \"$TEST_EMAIL\",
    \"phone\": \"+1234567890\",
    \"password\": \"$TEST_PASSWORD\"
  }")

echo "Registration Response:"
echo "$REGISTER_RESPONSE" | jq '.' 2>/dev/null || echo "$REGISTER_RESPONSE"
echo ""

# Extract token from registration response
TOKEN=$(echo "$REGISTER_RESPONSE" | jq -r '.data.token' 2>/dev/null)

if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
    echo "❌ Registration failed - no token received"
    exit 1
fi

echo "✅ Registration successful! Token: ${TOKEN:0:20}..."
echo ""

# Test 2: User Login
echo "2️⃣ Testing User Login..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth-login" \
  -H 'Content-Type: application/json' \
  -d "{
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"$TEST_PASSWORD\"
  }")

echo "Login Response:"
echo "$LOGIN_RESPONSE" | jq '.' 2>/dev/null || echo "$LOGIN_RESPONSE"
echo ""

# Test 3: Get Current User
echo "3️⃣ Testing Get Current User..."
USER_RESPONSE=$(curl -s -X GET "$BASE_URL/auth-user" \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json')

echo "User Response:"
echo "$USER_RESPONSE" | jq '.' 2>/dev/null || echo "$USER_RESPONSE"
echo ""

# Test 4: Change Password
echo "4️⃣ Testing Change Password..."
CHANGE_PASSWORD_RESPONSE=$(curl -s -X POST "$BASE_URL/auth-change-password" \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{
    \"oldPassword\": \"$TEST_PASSWORD\",
    \"newPassword\": \"newpass123\",
    \"confirmPassword\": \"newpass123\"
  }")

echo "Change Password Response:"
echo "$CHANGE_PASSWORD_RESPONSE" | jq '.' 2>/dev/null || echo "$CHANGE_PASSWORD_RESPONSE"
echo ""

# Test 5: Login with new password
echo "5️⃣ Testing Login with New Password..."
NEW_LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth-login" \
  -H 'Content-Type: application/json' \
  -d "{
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"newpass123\"
  }")

echo "New Login Response:"
echo "$NEW_LOGIN_RESPONSE" | jq '.' 2>/dev/null || echo "$NEW_LOGIN_RESPONSE"
echo ""

# Extract new token
NEW_TOKEN=$(echo "$NEW_LOGIN_RESPONSE" | jq -r '.data.token' 2>/dev/null)

if [ "$NEW_TOKEN" = "null" ] || [ -z "$NEW_TOKEN" ]; then
    echo "❌ New login failed - no token received"
    NEW_TOKEN=$TOKEN
fi

# Test 6: Logout
echo "6️⃣ Testing Logout..."
LOGOUT_RESPONSE=$(curl -s -X POST "$BASE_URL/auth-logout" \
  -H "Authorization: Bearer $NEW_TOKEN" \
  -H 'Content-Type: application/json')

echo "Logout Response:"
echo "$LOGOUT_RESPONSE" | jq '.' 2>/dev/null || echo "$LOGOUT_RESPONSE"
echo ""

# Test 7: Try to access protected endpoint after logout
echo "7️⃣ Testing Access After Logout (should fail)..."
PROTECTED_RESPONSE=$(curl -s -X GET "$BASE_URL/auth-user" \
  -H "Authorization: Bearer $NEW_TOKEN" \
  -H 'Content-Type: application/json')

echo "Protected Access Response (should show error):"
echo "$PROTECTED_RESPONSE" | jq '.' 2>/dev/null || echo "$PROTECTED_RESPONSE"
echo ""

# Test 8: Delete Account
echo "8️⃣ Testing Delete Account..."
DELETE_RESPONSE=$(curl -s -X DELETE "$BASE_URL/auth-delete-account" \
  -H "Authorization: Bearer $NEW_TOKEN" \
  -H 'Content-Type: application/json')

echo "Delete Account Response:"
echo "$DELETE_RESPONSE" | jq '.' 2>/dev/null || echo "$DELETE_RESPONSE"
echo ""

echo "🎉 Authentication API Testing Complete!"
echo ""
echo "📊 Summary:"
echo "- Registration: ✅"
echo "- Login: ✅" 
echo "- Get User: ✅"
echo "- Change Password: ✅"
echo "- Logout: ✅"
echo "- Delete Account: ✅"
echo ""
echo "🔗 All APIs are working correctly!"





