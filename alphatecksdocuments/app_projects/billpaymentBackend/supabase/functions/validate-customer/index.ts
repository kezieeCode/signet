import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import {
  corsHeaders,
  createErrorResponse,
  createSuccessResponse,
  handleCors,
  extractToken,
  verifySession
} from '../_shared/utils.ts'

const PAYSTACK_SECRET_KEY = Deno.env.get('PAYSTACK_SECRET_KEY') ?? ''

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return handleCors()
  }

  try {
    // Extract and verify JWT token
    const authHeader = req.headers.get('Authorization')
    const token = extractToken(authHeader)

    if (!token) {
      return createErrorResponse('Authorization token required', 401)
    }

    // Verify session
    const sessionVerification = await verifySession(token)
    if (!sessionVerification.valid || !sessionVerification.userId) {
      return createErrorResponse('Invalid or expired session', 401)
    }

    // Get user profile
    const { createSupabaseClient } = await import('../_shared/utils.ts')
    const supabaseClient = createSupabaseClient()
    const { data: userProfile, error: profileError } = await supabaseClient
      .from('profiles')
      .select('*')
      .eq('id', sessionVerification.userId)
      .single()

    if (profileError || !userProfile) {
      return createErrorResponse('User profile not found', 404)
    }

    // First, get or create customer to get customer_code
    const customerPayload = {
      email: userProfile.email,
      first_name: userProfile.first_name,
      last_name: userProfile.last_name
    }

    console.log('Creating/getting customer...')
    const customerResponse = await fetch('https://api.paystack.co/customer', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${PAYSTACK_SECRET_KEY}`
      },
      body: JSON.stringify(customerPayload)
    })

    const customerData = await customerResponse.json()
    console.log('Customer response:', JSON.stringify(customerData))

    if (!customerData.status) {
      return createErrorResponse({
        error: 'Failed to create/get customer',
        paystack_error: customerData.message
      }, 500)
    }

    const customerCode = customerData.data.customer_code
    console.log('Customer code:', customerCode)

    // Now validate the customer
    const validationPayload = {
      country: "NG",
      type: "bank_account",
      account_number: "1306010669",  // User's account number
      bvn: "2274207010",             // User's BVN
      bank_code: "007",              // Wema Bank code
      first_name: userProfile.first_name,
      last_name: userProfile.last_name
    }

    console.log('Validating customer with payload:', JSON.stringify(validationPayload))

    const validationResponse = await fetch(`https://api.paystack.co/customer/${customerCode}/identification`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${PAYSTACK_SECRET_KEY}`
      },
      body: JSON.stringify(validationPayload)
    })

    const validationData = await validationResponse.json()
    console.log('Validation response:', JSON.stringify(validationData, null, 2))

    return createSuccessResponse({
      customer_code: customerCode,
      customer_id: customerData.data.id,
      validation_request: validationPayload,
      validation_response: validationData,
      validation_success: validationData.status,
      message: validationData.message || 'Validation completed'
    }, 'Customer validation completed')

  } catch (error) {
    console.error('Validate customer function error:', error)
    return createErrorResponse('Internal server error', 500, error.message)
  }
})




