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

    // Get customers from Paystack
    const customersResponse = await fetch('https://api.paystack.co/customer?perPage=20', {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${PAYSTACK_SECRET_KEY}`
      }
    })

    const customersData = await customersResponse.json()
    
    console.log('Paystack customers response status:', customersData.status)
    console.log('Number of customers:', customersData.data?.length || 0)
    
    if (!customersData.status) {
      console.error('Paystack customers fetch error:', customersData.message)
      return createErrorResponse(
        'Failed to fetch customers from Paystack', 
        500,
        customersData.message || 'Unknown error'
      )
    }

    // Format customer data for easy viewing
    const formattedCustomers = customersData.data.map((customer: any) => ({
      id: customer.id,
      customer_code: customer.customer_code,
      email: customer.email,
      first_name: customer.first_name,
      last_name: customer.last_name,
      phone: customer.phone,
      risk_action: customer.risk_action,
      international_format_phone: customer.international_format_phone,
      metadata: customer.metadata,
      created: customer.createdAt
    }))

    return createSuccessResponse({
      total: customersData.data?.length || 0,
      customers: formattedCustomers,
      raw_response: customersData.data
    }, 'Customers retrieved successfully')

  } catch (error) {
    console.error('Check customers function error:', error)
    return createErrorResponse('Internal server error', 500, error.message)
  }
})

