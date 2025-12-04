import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { 
  corsHeaders, 
  createSupabaseAdmin,
  createSuccessResponse, 
  createErrorResponse, 
  handleCors,
  extractToken,
  verifySession
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

    // Verify session
    const sessionVerification = await verifySession(token)
    if (!sessionVerification.valid || !sessionVerification.userId) {
      return createErrorResponse('Invalid or expired session', 401)
    }

    const userId = sessionVerification.userId
    const supabaseAdmin = createSupabaseAdmin()

    // Delete from active_sessions
    const { error: sessionsError } = await supabaseAdmin
      .from('active_sessions')
      .delete()
      .eq('user_id', userId)

    if (sessionsError) {
      console.error('Delete sessions error:', sessionsError)
    }

    // Delete from wallet_transactions
    const { error: transactionsError } = await supabaseAdmin
      .from('wallet_transactions')
      .delete()
      .eq('user_id', userId)

    if (transactionsError) {
      console.error('Delete transactions error:', transactionsError)
    }

    // Delete from profiles
    const { error: profilesError } = await supabaseAdmin
      .from('profiles')
      .delete()
      .eq('id', userId)

    if (profilesError) {
      console.error('Delete profile error:', profilesError)
    }

    // Delete auth user using admin API
    const { error: deleteUserError } = await supabaseAdmin.auth.admin.deleteUser(userId)

    if (deleteUserError) {
      console.error('Delete auth user error:', deleteUserError)
      return createErrorResponse('Failed to delete user account', 500)
    }

    return createSuccessResponse(null, 'Account deleted successfully')

  } catch (error) {
    console.error('Delete account function error:', error)
    return createErrorResponse('Internal server error', 500, error.message)
  }
})





