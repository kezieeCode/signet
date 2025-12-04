import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import {
  corsHeaders,
  createErrorResponse,
  createSuccessResponse,
  handleCors,
  validateEmail,
  createSupabaseAdmin,
  hashToken
} from '../_shared/utils.ts'

import bcryptjs from "https://esm.sh/bcryptjs@2.4.3"

interface AdminLoginRequest {
  email: string
  password: string
}

interface AdminLoginResponse {
  token: string
  admin: {
    id: string
    email: string
    full_name?: string
    role: 'admin'
    expires_at: string
  }
}

function generateToken(): string {
  const randomBytes = crypto.getRandomValues(new Uint8Array(32))
  return btoa(String.fromCharCode(...randomBytes)).replace(/[^a-zA-Z0-9]/g, '')
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return handleCors()
  }

  try {
    const { email, password }: AdminLoginRequest = await req.json()

    if (!email || !password) {
      return createErrorResponse('Missing required fields: email, password')
    }

    if (!validateEmail(email)) {
      return createErrorResponse('Invalid email format')
    }

    const supabaseAdmin = createSupabaseAdmin()

    const { data: adminUser, error: adminError } = await supabaseAdmin
      .from('admin_users')
      .select('id, email, password_hash, full_name')
      .eq('email', email.toLowerCase())
      .single()

    if (adminError || !adminUser) {
      console.error('Admin lookup failed:', adminError)
      return createErrorResponse('Invalid email or password', 401)
    }

    const passwordMatches = bcryptjs.compareSync(password, adminUser.password_hash)
    if (!passwordMatches) {
      return createErrorResponse('Invalid email or password', 401)
    }

    const token = generateToken()
    const tokenHash = hashToken(token)
    const expiresAt = new Date(Date.now() + 60 * 60 * 1000).toISOString() // 1 hour

    const { error: sessionError } = await supabaseAdmin
      .from('admin_sessions')
      .insert({
        admin_id: adminUser.id,
        token_hash: tokenHash,
        expires_at: expiresAt
      })

    if (sessionError) {
      console.error('Failed to create admin session:', sessionError)
      return createErrorResponse('Failed to create admin session', 500)
    }

    const response: AdminLoginResponse = {
      token,
      admin: {
        id: adminUser.id,
        email: adminUser.email,
        full_name: adminUser.full_name ?? undefined,
        role: 'admin',
        expires_at: expiresAt
      }
    }

    return createSuccessResponse(response, 'Admin login successful')
  } catch (error) {
    console.error('Admin login error:', error)
    return createErrorResponse('Internal server error', 500, error instanceof Error ? error.message : String(error))
  }
})
