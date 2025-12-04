#!/bin/bash

# Test script for deployed Supabase Edge Function
PROJECT_REF="ldbxuhqjrszoicoumlpz"
FUNCTION_NAME="bill-payment"
API_URL="https://$PROJECT_REF.supabase.co/functions/v1/$FUNCTION_NAME"

echo "🧪 Testing deployed Edge Function..."
echo "Project: $PROJECT_REF"
echo "Function: $FUNCTION_NAME"
echo "URL: $API_URL"
echo ""

# Test data
TEST_DATA='{
  "amount": 150.00,
  "billType": "electricity",
  "accountNumber": "ELC123456789",
  "description": "Test payment from deployment script"
}'

echo "📤 Sending test request..."
echo "Data: $TEST_DATA"
echo ""

# Note: You'll need to replace YOUR_ANON_KEY with your actual anon key
echo "⚠️  IMPORTANT: Replace YOUR_ANON_KEY with your actual Supabase anon key"
echo ""
echo "Test command:"
echo "curl -X POST '$API_URL' \\"
echo "  -H 'Authorization: Bearer YOUR_ANON_KEY' \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '$TEST_DATA'"
echo ""
echo "🔑 Get your anon key from: https://supabase.com/dashboard/project/$PROJECT_REF/settings/api"
echo "📊 View function logs at: https://supabase.com/dashboard/project/$PROJECT_REF/functions"
echo "🗄️  View database at: https://supabase.com/dashboard/project/$PROJECT_REF/editor"





