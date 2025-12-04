import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface BillPaymentRequest {
  amount: number
  billType: string
  accountNumber: string
  description?: string
}

interface BillPaymentResponse {
  success: boolean
  transactionId?: string
  message: string
  error?: string
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    )

    // Parse request body
    const { amount, billType, accountNumber, description }: BillPaymentRequest = await req.json()

    // Validate required fields
    if (!amount || !billType || !accountNumber) {
      const response: BillPaymentResponse = {
        success: false,
        message: 'Missing required fields',
        error: 'amount, billType, and accountNumber are required'
      }
      return new Response(JSON.stringify(response), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Validate amount
    if (amount <= 0) {
      const response: BillPaymentResponse = {
        success: false,
        message: 'Invalid amount',
        error: 'Amount must be greater than 0'
      }
      return new Response(JSON.stringify(response), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Generate transaction ID
    const transactionId = `TXN_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`

    // Insert payment record into database
    const { data, error } = await supabaseClient
      .from('bill_payments')
      .insert({
        transaction_id: transactionId,
        amount: amount,
        bill_type: billType,
        account_number: accountNumber,
        description: description || '',
        status: 'pending',
        created_at: new Date().toISOString()
      })
      .select()

    if (error) {
      console.error('Database error:', error)
      const response: BillPaymentResponse = {
        success: false,
        message: 'Failed to process payment',
        error: error.message
      }
      return new Response(JSON.stringify(response), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Simulate payment processing (replace with actual payment gateway integration)
    const paymentSuccess = Math.random() > 0.1 // 90% success rate for demo

    // Update payment status
    const { error: updateError } = await supabaseClient
      .from('bill_payments')
      .update({ 
        status: paymentSuccess ? 'completed' : 'failed',
        updated_at: new Date().toISOString()
      })
      .eq('transaction_id', transactionId)

    if (updateError) {
      console.error('Update error:', updateError)
    }

    const response: BillPaymentResponse = {
      success: paymentSuccess,
      transactionId: transactionId,
      message: paymentSuccess ? 'Payment processed successfully' : 'Payment processing failed'
    }

    return new Response(JSON.stringify(response), {
      status: paymentSuccess ? 200 : 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (error) {
    console.error('Function error:', error)
    const response: BillPaymentResponse = {
      success: false,
      message: 'Internal server error',
      error: error.message
    }
    return new Response(JSON.stringify(response), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})





