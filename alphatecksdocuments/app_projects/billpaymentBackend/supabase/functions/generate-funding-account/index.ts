import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { 
  corsHeaders, 
  createSupabaseAdmin,
  createSuccessResponse, 
  createErrorResponse, 
  handleCors,
  extractToken,
  verifySession,
  getUserProfile
} from '../_shared/utils.ts'

const PAYSTACK_SECRET_KEY = Deno.env.get('PAYSTACK_SECRET_KEY') ?? ''

interface FundingAccountResponse {
  account_number: string
  bank_name: string
  account_name: string
  message: string
  customer_id?: string
  customer_code?: string
}

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

    const userId = sessionVerification.userId
    const supabaseAdmin = createSupabaseAdmin()

    // Get user profile
    const userProfile = await getUserProfile(userId)
    if (!userProfile) {
      return createErrorResponse('User profile not found', 404)
    }

    // Check if user already has an active Paystack dedicated account
    const { data: existingAccount } = await supabaseAdmin
      .from('paystack_dedicated_accounts')
      .select('*')
      .eq('user_id', userId)
      .eq('is_active', true)
      .single()

    // If user already has an active account, return it
    if (existingAccount) {
      const response: FundingAccountResponse = {
        account_number: existingAccount.account_number,
        bank_name: existingAccount.bank_name,
        account_name: existingAccount.account_name,
        message: 'Existing funding account retrieved'
      }
      return createSuccessResponse(response, 'Funding account retrieved successfully')
    }

    // Create Paystack customer first
    const customerPayload = {
      email: userProfile.email,
      first_name: userProfile.first_name,
      last_name: userProfile.last_name
    }

    const customerResponse = await fetch('https://api.paystack.co/customer', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${PAYSTACK_SECRET_KEY}`
      },
      body: JSON.stringify(customerPayload)
    })

    const customerData = await customerResponse.json()

    console.log('Paystack customer creation response:', JSON.stringify(customerData))
    console.log('Customer creation status:', customerData.status)

    if (!customerData.status) {
      console.error('Paystack customer creation error:', customerData.message)
      return createErrorResponse(
        'Failed to create Paystack customer',
        500,
        JSON.stringify({
          paystack_error: customerData.message || 'Unknown error',
          customer_email: userProfile.email
        })
      )
    }

    console.log('Customer data structure:', JSON.stringify(customerData.data, null, 2))
    console.log('Customer data keys:', Object.keys(customerData.data || {}))
    
    // Validate customer data exists
    if (!customerData.data) {
      console.error('No customer data returned from Paystack')
      return createErrorResponse(
        'Failed to create Paystack customer: no data returned',
        500,
        JSON.stringify({
          customer_email: userProfile.email,
          response_status: customerData.status
        })
      )
    }
    
    const customerCode = customerData.data.customer_code
    const customerId = customerData.data.id
    const customerEmail = customerData.data.email
    
    console.log('Customer code:', customerCode)
    console.log('Customer ID:', customerId, 'Type:', typeof customerId)
    console.log('Customer email:', customerEmail)

    // Validate required customer fields
    if (!customerId || !customerEmail) {
      console.error('Invalid customer data - missing ID or email:', { customerId, customerEmail })
      return createErrorResponse(
        'Failed to get valid customer ID from Paystack',
        500,
        JSON.stringify({ customer_id: customerId, customer_email: customerEmail })
      )
    }

    // Ensure customer ID is a number
    const numericCustomerId = typeof customerId === 'number' ? customerId : parseInt(customerId, 10)
    if (isNaN(numericCustomerId)) {
      console.error('Customer ID is not a valid number:', customerId)
      return createErrorResponse(
        'Invalid customer ID format',
        500,
        JSON.stringify({ customer_id: customerId, expected_format: 'number' })
      )
    }

    console.log('Final customer ID to use:', numericCustomerId)

    // Validate customer identity before creating DVA
    console.log('Validating customer identity...')
    const validationPayload = {
      country: "NG",
      type: "bank_account",
      account_number: "1306010669",  // User's account number
      bvn: "2274207010",             // User's BVN
      bank_code: "007",              // Wema Bank code
      first_name: userProfile.first_name,
      last_name: userProfile.last_name
    }

    const validationResponse = await fetch(`https://api.paystack.co/customer/${customerCode}/identification`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${PAYSTACK_SECRET_KEY}`
      },
      body: JSON.stringify(validationPayload)
    })

    const validationData = await validationResponse.json()
    console.log('Customer validation response:', JSON.stringify(validationData))

    if (!validationData.status) {
      console.warn('Customer validation failed, but continuing with DVA creation:', validationData.message)
      // Don't fail here - some customers might not need validation or validation might fail
    } else {
      console.log('Customer validation successful')
    }

    // Create Paystack dedicated virtual account
    // Paystack requires: numeric customer ID and preferred_bank
    let dvaPayload = {
      customer: numericCustomerId,  // Use numeric customer ID, not customer_code
      preferred_bank: "wema-bank"  // Required parameter
    }
    console.log('DVA Payload:', JSON.stringify(dvaPayload))

    let dvaResponse = await fetch('https://api.paystack.co/dedicated_account', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${PAYSTACK_SECRET_KEY}`
      },
      body: JSON.stringify(dvaPayload)
    })

    let dvaData = await dvaResponse.json()
    
    console.log('Full Paystack DVA response:', JSON.stringify(dvaData, null, 2))
    console.log('DVA Status:', dvaData.status)
    console.log('DVA Message:', dvaData.message)
    console.log('DVA Response code:', dvaData.data?.response_code)
    console.log('DVA Response message:', dvaData.data?.response_message)
    
    // No fallback needed - the numeric customer ID approach should work
    
    // Check if DVA creation failed
    if (!dvaData.status) {
      console.error('Paystack DVA creation failed:', JSON.stringify(dvaData))
      return createErrorResponse(
        'Failed to create dedicated account',
        500,
        JSON.stringify({
          paystack_error: dvaData.message || 'Unknown Paystack error',
          customer_id: numericCustomerId,
          dva_payload_used: dvaPayload
        })
      )
    }

    console.log('DVA Data:', JSON.stringify(dvaData.data))
    const accountDetails = dvaData.data.dedicated_account
    console.log('Account Details:', JSON.stringify(accountDetails))

    // Get customer info from response
    let responseCustomerId: string
    let responseCustomerCode: string
    
    if (dvaData.data.customer) {
      responseCustomerId = dvaData.data.customer.id?.toString() || customerId.toString()
      responseCustomerCode = dvaData.data.customer.customer_code || customerCode
    } else {
      responseCustomerId = customerId.toString()
      responseCustomerCode = customerCode || ""
    }
    
    // Store account details in database
    const { error: dbError } = await supabaseAdmin
      .from('paystack_dedicated_accounts')
      .insert({
        user_id: userId,
        account_number: accountDetails.account_number,
        bank_name: accountDetails.bank.name,
        account_name: accountDetails.account_name,
        paystack_customer_code: responseCustomerCode,
        paystack_customer_id: responseCustomerId,
        is_active: true
      })

    if (dbError) {
      console.error('Database insertion error:', dbError)
      return createErrorResponse(
        'Failed to store account details',
        500,
        JSON.stringify({
          customer_id: responseCustomerId,
          account_number: accountDetails.account_number,
          db_error: dbError.message
        })
      )
    }

    const response: FundingAccountResponse = {
      account_number: accountDetails.account_number,
      bank_name: accountDetails.bank.name,
      account_name: accountDetails.account_name,
      message: 'Transfer money to this account to fund your wallet'
    }

    // Log customer ID in response for debugging
    console.log('Response includes customer ID:', responseCustomerId)

    return createSuccessResponse({
      ...response,
      customer_id: responseCustomerId,
      customer_code: responseCustomerCode
    }, 'Funding account created successfully')

  } catch (error) {
    console.error('Generate funding account function error:', error)
    return createErrorResponse('Internal server error', 500, error.message)
  }
})
