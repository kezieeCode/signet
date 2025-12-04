#!/bin/bash

# Direct Deployment Script for Supabase Edge Function
# This bypasses Docker and CLI authentication issues

PROJECT_REF="ldbxuhqjrszoicoumlpz"
FUNCTION_NAME="bill-payment"

echo "🚀 Deploying Edge Function to Supabase..."
echo "Project: $PROJECT_REF"
echo "Function: $FUNCTION_NAME"

# Check if function file exists
if [ ! -f "supabase/functions/$FUNCTION_NAME/index.ts" ]; then
    echo "❌ Function file not found: supabase/functions/$FUNCTION_NAME/index.ts"
    exit 1
fi

echo "📋 Manual deployment steps:"
echo ""
echo "1. Go to: https://supabase.com/dashboard/project/$PROJECT_REF/functions"
echo "2. Click 'Create a new function'"
echo "3. Name: $FUNCTION_NAME"
echo "4. Copy the content from: supabase/functions/$FUNCTION_NAME/index.ts"
echo ""
echo "📄 Function content:"
echo "----------------------------------------"
cat "supabase/functions/$FUNCTION_NAME/index.ts"
echo "----------------------------------------"
echo ""
echo "✅ After deployment, test with:"
echo "curl -X POST 'https://$PROJECT_REF.supabase.co/functions/v1/$FUNCTION_NAME' \\"
echo "  -H 'Authorization: Bearer YOUR_ANON_KEY' \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"amount\": 100.00, \"billType\": \"electricity\", \"accountNumber\": \"TEST123456\"}'"





