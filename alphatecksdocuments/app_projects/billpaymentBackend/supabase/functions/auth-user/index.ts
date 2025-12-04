import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { 
  corsHeaders, 
  createSuccessResponse, 
  createErrorResponse, 
  handleCors,
  extractToken,
  verifySession,
  getUserProfile,
  UserProfile
} from '../_shared/utils.ts'

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

    // Verify session in active_sessions
    const sessionVerification = await verifySession(token)
    if (!sessionVerification.valid || !sessionVerification.userId) {
      return createErrorResponse('Invalid or expired session', 401)
    }

    // Get user from auth.users and profiles table
    const userProfile = await getUserProfile(sessionVerification.userId)
    if (!userProfile) {
      return createErrorResponse('User profile not found', 404)
    }

    // Return user details (username, email, phone, wallet balance)
    const response: UserProfile = {
      id: userProfile.id,
      first_name: userProfile.first_name,
      last_name: userProfile.last_name,
      username: userProfile.username,
      email: userProfile.email,
      phone: userProfile.phone,
      wallet_balance: userProfile.wallet_balance
    }

    return createSuccessResponse(response, 'User data retrieved successfully')

  } catch (error) {
    console.error('Get user function error:', error)
    return createErrorResponse('Internal server error', 500, error.message)
  }
})





