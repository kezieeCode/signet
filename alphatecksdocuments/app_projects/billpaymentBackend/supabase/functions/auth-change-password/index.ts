import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { 
  corsHeaders, 
  createSupabaseClient,
  createSuccessResponse, 
  createErrorResponse, 
  handleCors,
  validatePassword,
  extractToken,
  verifySession
} from '../_shared/utils.ts'

interface ChangePasswordRequest {
  oldPassword: string
  newPassword: string
  confirmPassword: string
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return handleCors()
  }

  try {
    // Extract and verify JWT token from Authorization header
    const authHeader = req.headers.get('Authorization')
    const token = extractToken(authHeader)
    
    if (!token) {
      return createErrorResponse('Authorization token required', 401)
    }

    // Verify session exists in active_sessions
    const sessionVerification = await verifySession(token)
    if (!sessionVerification.valid) {
      return createErrorResponse('Invalid or expired session', 401)
    }

    // Parse request body
    const { oldPassword, newPassword, confirmPassword }: ChangePasswordRequest = await req.json()

    // Validate required fields
    if (!oldPassword || !newPassword || !confirmPassword) {
      return createErrorResponse('Missing required fields: oldPassword, newPassword, confirmPassword')
    }

    // Validate password strength
    const passwordValidation = validatePassword(newPassword)
    if (!passwordValidation.valid) {
      return createErrorResponse(passwordValidation.error || 'Invalid password')
    }

    // Validate password confirmation
    if (newPassword !== confirmPassword) {
      return createErrorResponse('New password and confirmation do not match')
    }

    // Create Supabase client with the provided token
    const supabaseClient = createSupabaseClient()
    
    // Get current user
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser()
    if (userError || !user) {
      return createErrorResponse('Invalid user session', 401)
    }

    // Verify old password by attempting to sign in
    const { error: verifyError } = await supabaseClient.auth.signInWithPassword({
      email: user.email!,
      password: oldPassword
    })

    if (verifyError) {
      return createErrorResponse('Current password is incorrect', 401)
    }

    // Update password
    const { error: updateError } = await supabaseClient.auth.updateUser({
      password: newPassword
    })

    if (updateError) {
      console.error('Password update error:', updateError)
      return createErrorResponse('Failed to update password', 500)
    }

    return createSuccessResponse(null, 'Password changed successfully')

  } catch (error) {
    console.error('Change password function error:', error)
    return createErrorResponse('Internal server error', 500, error.message)
  }
})





