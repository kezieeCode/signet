import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
}

interface AirtimeRequest {
  mobileNumber: string
  networkProvider: string
  amount: number
}

interface AirtimeResponse {
  success: boolean
  transactionId?: string
  message: string
  error?: string
}

const AFRICASTALKING_API_KEY = "atsk_3e17ca4bbcfa5c78a08986939273ecffbd4e0236930277aed2bb170e70069e6142562768"
const AFRICASTALKING_USERNAME = "sandbox" // Change to your actual username in production

function createSuccessResponse(data: any, message: string = 'Success') {
  return new Response(JSON.stringify({
    success: true,
    data,
    message
  }), {
    status: 200,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  })
}

function createErrorResponse(message: string, status: number = 400, error?: string) {
  return new Response(JSON.stringify({
    success: false,
    message,
    error
  }), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  })
}

function handleCors() {
  return new Response('ok', { headers: corsHeaders })
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return handleCors()
  }

  try {
    // Parse request body
    const { mobileNumber, networkProvider, amount }: AirtimeRequest = await req.json()

    // Validate required fields
    if (!mobileNumber || !networkProvider || !amount) {
      return createErrorResponse('Missing required fields: mobileNumber, networkProvider, amount')
    }

    // Validate amount
    if (amount <= 0) {
      return createErrorResponse('Amount must be greater than 0')
    }

    // Validate mobile number format (basic validation)
    if (!mobileNumber.startsWith('+')) {
      return createErrorResponse('Mobile number must include country code (e.g., +254...)')
    }

    // Generate transaction ID
    const transactionId = `AT_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`

    // Call Africa's Talking Airtime API
    // Encode the recipients array properly
    const recipients = encodeURIComponent(JSON.stringify([{
      phoneNumber: mobileNumber,
      amount: `KES ${amount}`
    }]))
    
    const airtimePayload = `username=${AFRICASTALKING_USERNAME}&recipients=${recipients}`

    const response = await fetch('https://api.sandbox.africastalking.com/version1/airtime/send', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'ApiKey': AFRICASTALKING_API_KEY,
        'Accept': 'application/json'
      },
      body: airtimePayload
    })

    const responseText = await response.text()
    console.log('Africa\'s Talking response:', responseText)
    
    let atResponse
    try {
      atResponse = JSON.parse(responseText)
    } catch (e) {
      return createErrorResponse('Invalid response from Africa\'s Talking', 500, responseText)
    }

    if (!atResponse.errorMessage && atResponse.responses) {
      // Success response from Africa's Talking
      const successResponse = {
        success: true,
        transactionId: transactionId,
        mobileNumber: mobileNumber,
        networkProvider: networkProvider,
        amount: amount,
        status: 'completed',
        message: 'Airtime purchase successful',
        africastalkingResponse: atResponse
      }

      return createSuccessResponse(successResponse, 'Airtime purchase successful')
    } else {
      // Error from Africa's Talking
      return createErrorResponse(
        'Airtime purchase failed', 
        400, 
        atResponse.errorMessage || 'Unknown error from Africa\'s Talking'
      )
    }

  } catch (error) {
    console.error('Purchase airtime function error:', error)
    return createErrorResponse('Internal server error', 500, error.message)
  }
})
