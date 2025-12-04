#!/bin/bash

# Test script for Airtime Purchase API
PROJECT_REF="ldbxuhqjrszoicoumlpz"
BASE_URL="https://$PROJECT_REF.supabase.co/functions/v1"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxkYnh1aHFqcnN6b2ljb3VtbHB6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEwMzUyODYsImV4cCI6MjA3NjYxMTI4Nn0.B6xVJ-zzZX2BiI4WfMu8CkfG5uJ-6wGFoiQg-ULdUp8"

echo "🧪 Testing Airtime Purchase API"
echo "Project: $PROJECT_REF"
echo "Base URL: $BASE_URL"
echo ""

# Test Data
MOBILE_NUMBER="+254712345678"
NETWORK_PROVIDER="SAFARICOM"
AMOUNT=10.00

echo "📱 Test Data:"
echo "Mobile Number: $MOBILE_NUMBER"
echo "Network Provider: $NETWORK_PROVIDER"
echo "Amount: $AMOUNT KES"
echo ""

# Test API
echo "🚀 Testing API call..."
RESPONSE=$(curl -s -X POST "$BASE_URL/purchase-airtime" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $ANON_KEY" \
  -d "{
    \"mobileNumber\": \"$MOBILE_NUMBER\",
    \"networkProvider\": \"$NETWORK_PROVIDER\",
    \"amount\": $AMOUNT
  }")

echo "📥 Response:"
echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
echo ""

echo "✅ Test complete!"
