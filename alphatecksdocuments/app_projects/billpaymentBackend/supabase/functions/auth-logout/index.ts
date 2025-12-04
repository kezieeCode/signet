import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { 
  corsHeaders, 
  createSupabaseClient,
  createSuccessResponse, 
  createErrorResponse, 
  handleCors,
  extractToken,
  verifySession,
  deleteActiveSession
} from '../_shared/utils.ts'

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return handleCors()
  }

  try {
    // Extract JWT from Authorization header
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

    // Delete session from active_sessions table
    const sessionDeleted = await deleteActiveSession(token)
    if (!sessionDeleted) {
      console.error('Failed to delete active session')
    }

    // Sign out from Supabase Auth
    const supabaseClient = createSupabaseClient()
    const { error: signOutError } = await supabaseClient.auth.signOut()

    if (signOutError) {
      console.error('Sign out error:', signOutError)
      // Don't fail the request if sign out fails, session is already deleted
    }

    return createSuccessResponse(null, 'Logout successful')

  } catch (error) {
    console.error('Logout function error:', error)
    return createErrorResponse('Internal server error', 500, error.message)
  }
})





