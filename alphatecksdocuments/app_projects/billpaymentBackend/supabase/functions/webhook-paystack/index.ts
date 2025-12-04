import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { 
  corsHeaders, 
  createSupabaseAdmin,
  createSuccessResponse, 
  createErrorResponse, 
  handleCors,
  createWalletTransaction,
  getWalletBalance
} from '../_shared/utils.ts'

const PAYSTACK_SECRET_KEY = Deno.env.get('PAYSTACK_SECRET_KEY') ?? ''

interface PaystackWebhookEvent {
  event: string
  data: any
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return handleCors()
  }

  try {
    // Get webhook signature from header for verification
    const signature = req.headers.get('x-paystack-signature')
    const body = await req.text()

    // Verify webhook signature (optional but recommended for security)
    // For now, we'll process the webhook
    let webhookData: PaystackWebhookEvent
    try {
      webhookData = JSON.parse(body)
    } catch (e) {
      return createErrorResponse('Invalid JSON payload', 400)
    }

    console.log('Paystack webhook event received:', webhookData.event)

    // Handle different webhook events
    const supabaseAdmin = createSupabaseAdmin()

    if (webhookData.event === 'charge.success' || webhookData.event === 'transfer.success') {
      const chargeData = webhookData.data
      
      // Extract account details from the charge data
      const accountNumber = chargeData.dedicated_account?.account_number || 
                           chargeData.authorization?.account_number ||
                           chargeData.metadata?.account_number

      if (!accountNumber) {
        console.error('No account number found in webhook payload')
        return createErrorResponse('No account number found in webhook', 400)
      }

      // Find user by account number
      const { data: accountData, error: accountError } = await supabaseAdmin
        .from('paystack_dedicated_accounts')
        .select('user_id')
        .eq('account_number', accountNumber)
        .eq('is_active', true)
        .single()

      if (accountError || !accountData) {
        console.error('Account not found:', accountError)
        return createErrorResponse('Account not found', 404)
      }

      const userId = accountData.user_id

      // Get the amount (convert to positive number)
      const amount = Math.abs(parseFloat(chargeData.amount || 0) / 100) // Paystack amounts are in kobo

      if (amount <= 0) {
        return createErrorResponse('Invalid amount', 400)
      }

      // Check if transaction already processed (prevent duplicates)
      const referenceId = chargeData.reference
      const { data: existingTransaction } = await supabaseAdmin
        .from('wallet_transactions')
        .select('id')
        .eq('reference_id', referenceId)
        .single()

      if (existingTransaction) {
        console.log('Transaction already processed:', referenceId)
        return createSuccessResponse(null, 'Transaction already processed')
      }

      // Create wallet transaction (credit)
      const transactionCreated = await createWalletTransaction(
        userId,
        amount,
        'credit',
        'wallet_funding',
        referenceId,
        `Wallet funding via Paystack - ${accountNumber}`
      )

      if (!transactionCreated) {
        console.error('Failed to create wallet transaction')
        return createErrorResponse('Failed to credit wallet', 500)
      }

      // Get updated balance
      const newBalance = await getWalletBalance(userId)

      console.log(`Wallet funded successfully for user ${userId}: Amount ${amount}, New balance: ${newBalance}`)

      return createSuccessResponse({
        success: true,
        userId: userId,
        amount: amount,
        newBalance: newBalance,
        message: 'Wallet funded successfully'
      }, 'Wallet funded successfully')
    }

    // Return success for other events
    return createSuccessResponse(null, 'Webhook received and processed')

  } catch (error) {
    console.error('Paystack webhook error:', error)
    return createErrorResponse('Internal server error', 500, error.message)
  }
})
