import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { 
  corsHeaders, 
  createSupabaseClient,
  createSuccessResponse, 
  createErrorResponse, 
  handleCors,
  validateEmail,
  createActiveSession,
  getUserProfile,
  UserProfile
} from '../_shared/utils.ts'

interface LoginRequest {
  email: string
  password: string
}

interface LoginResponse {
  user: UserProfile
  token: string
  wallet_balance: number
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return handleCors()
  }

  try {
    // Parse request body
    const { email, password }: LoginRequest = await req.json()

    // Validate required fields
    if (!email || !password) {
      return createErrorResponse('Missing required fields: email, password')
    }

    // Validate email format
    if (!validateEmail(email)) {
      return createErrorResponse('Invalid email format')
    }

    // Attempt to sign in
    const supabaseClient = createSupabaseClient()
    const { data: signInData, error: signInError } = await supabaseClient.auth.signInWithPassword({
      email,
      password
    })

    if (signInError || !signInData.session) {
      return createErrorResponse('Invalid email or password', 401)
    }

    const userId = signInData.user.id

    // Create active session record
    const sessionCreated = await createActiveSession(userId, signInData.session.access_token)
    if (!sessionCreated) {
      console.error('Failed to create active session')
    }

    // Get user profile with wallet balance
    const userProfile = await getUserProfile(userId)
    if (!userProfile) {
      return createErrorResponse('Failed to retrieve user profile', 500)
    }

    const response: LoginResponse = {
      user: userProfile,
      token: signInData.session.access_token,
      wallet_balance: userProfile.wallet_balance
    }

    return createSuccessResponse(response, 'Login successful')

  } catch (error) {
    console.error('Login function error:', error)
    return createErrorResponse('Internal server error', 500, error.message)
  }
})