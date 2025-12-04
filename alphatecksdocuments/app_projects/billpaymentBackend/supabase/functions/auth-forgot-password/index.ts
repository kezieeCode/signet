import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { 
  corsHeaders, 
  createSupabaseAdmin,
  createSupabaseClient,
  createSuccessResponse, 
  createErrorResponse, 
  handleCors,
  validateEmail,
  validatePassword
} from '../_shared/utils.ts'

interface ForgotPasswordRequest {
  email?: string
  oldPassword?: string
  newPassword: string
  confirmPassword: string
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return handleCors()
  }

  try {
    // Parse request body
    const { email, oldPassword, newPassword, confirmPassword }: ForgotPasswordRequest = await req.json()

    // Validate required fields
    if (!newPassword || !confirmPassword) {
      return createErrorResponse('Missing required fields: newPassword, confirmPassword')
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

    const supabaseAdmin = createSupabaseAdmin()

    // Two flows: email-based OR password-based
    if (email) {
      // Email-based password reset flow
      if (!validateEmail(email)) {
        return createErrorResponse('Invalid email format')
      }

      // Find user by email
      const { data: users, error: listError } = await supabaseAdmin.auth.admin.listUsers()
      if (listError) {
        return createErrorResponse('Failed to find user', 500)
      }

      const user = users.users.find(u => u.email === email)
      if (!user) {
        return createErrorResponse('User not found with this email')
      }

      // Update user password
      const { error: updateError } = await supabaseAdmin.auth.admin.updateUserById(user.id, {
        password: newPassword
      })

      if (updateError) {
        console.error('Password update error:', updateError)
        return createErrorResponse('Failed to update password', 500)
      }

      return createSuccessResponse(null, 'Password reset successfully')

    } else if (oldPassword) {
      // Password-based reset flow (requires authentication)
      const authHeader = req.headers.get('Authorization')
      if (!authHeader) {
        return createErrorResponse('Authorization header required for password-based reset', 401)
      }

      // Extract token and verify user
      const supabaseClient = createSupabaseClient()
      const { data: { user }, error: userError } = await supabaseClient.auth.getUser()
      
      if (userError || !user) {
        return createErrorResponse('Invalid or expired token', 401)
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

    } else {
      return createErrorResponse('Either email or oldPassword must be provided')
    }

  } catch (error) {
    console.error('Forgot password function error:', error)
    return createErrorResponse('Internal server error', 500, error.message)
  }
})





