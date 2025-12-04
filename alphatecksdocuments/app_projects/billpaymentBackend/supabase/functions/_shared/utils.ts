// Shared utilities for authentication Edge Functions
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// CORS headers for all responses
export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-admin-session, x-admin-token',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
}

// Standard response interface
export interface ApiResponse<T = any> {
  success: boolean
  data?: T
  message: string
  error?: string
}

// User profile interface
export interface UserProfile {
  id: string
  first_name: string
  last_name: string
  username: string
  email: string
  phone?: string
  wallet_balance: number
}

// Session interface
export interface SessionData {
  id: string
  user_id: string
  token_hash: string
  expires_at: string
}

// Create Supabase client with service role for admin operations
export function createSupabaseAdmin() {
  return createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    }
  )
}

// Create Supabase client with anon key
export function createSupabaseClient() {
  return createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? ''
  )
}

// Extract JWT token from Authorization header
export function extractToken(authHeader: string | null): string | null {
  if (!authHeader) return null
  const parts = authHeader.split(' ')
  if (parts.length !== 2 || parts[0] !== 'Bearer') return null
  return parts[1]
}

// Hash token for storage (simple hash for demo - use proper hashing in production)
export function hashToken(token: string): string {
  // Simple hash for demo - in production use proper cryptographic hashing
  return btoa(token).replace(/[^a-zA-Z0-9]/g, '')
}

// Verify if session exists and is valid
export async function verifySession(token: string): Promise<{ valid: boolean; userId?: string; sessionId?: string }> {
  try {
    const supabase = createSupabaseAdmin()
    const tokenHash = hashToken(token)
    
    // Check if session exists and is not expired
    const { data: session, error } = await supabase
      .from('active_sessions')
      .select('id, user_id, expires_at')
      .eq('token_hash', tokenHash)
      .gt('expires_at', new Date().toISOString())
      .single()
    
    if (error || !session) {
      return { valid: false }
    }
    
    return { 
      valid: true, 
      userId: session.user_id, 
      sessionId: session.id 
    }
  } catch (error) {
    console.error('Session verification error:', error)
    return { valid: false }
  }
}

// Get user profile with wallet balance
export async function getUserProfile(userId: string): Promise<UserProfile | null> {
  try {
    const supabase = createSupabaseAdmin()
    
    // Get user from auth.users
    const { data: authUser, error: authError } = await supabase.auth.admin.getUserById(userId)
    if (authError || !authUser.user) {
      return null
    }
    
    // Get profile from profiles table
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single()
    
    if (profileError) {
      return null
    }
    
    // Calculate wallet balance
    const walletBalance = await getWalletBalance(userId)
    
    return {
      id: userId,
      first_name: profile.first_name,
      last_name: profile.last_name,
      username: profile.username,
      email: authUser.user.email || '',
      phone: profile.phone,
      wallet_balance: walletBalance
    }
  } catch (error) {
    console.error('Get user profile error:', error)
    return null
  }
}

// Calculate wallet balance from transactions
export async function getWalletBalance(userId: string): Promise<number> {
  try {
    const supabase = createSupabaseAdmin()
    
    const { data, error } = await supabase
      .rpc('get_user_wallet_balance', { user_uuid: userId })
    
    if (error) {
      console.error('Wallet balance calculation error:', error)
      return 0
    }
    
    return parseFloat(data) || 0
  } catch (error) {
    console.error('Get wallet balance error:', error)
    return 0
  }
}

// Create wallet transaction
export async function createWalletTransaction(
  userId: string, 
  amount: number, 
  type: 'credit' | 'debit', 
  transactionType: string = 'payment',
  referenceId?: string,
  description?: string
): Promise<boolean> {
  try {
    const supabase = createSupabaseAdmin()
    
    // Get current balance
    const currentBalance = await getWalletBalance(userId)
    const balanceAfter = type === 'credit' 
      ? currentBalance + amount 
      : currentBalance - amount
    
    // Insert transaction
    const { error } = await supabase
      .from('wallet_transactions')
      .insert({
        user_id: userId,
        amount: Math.abs(amount),
        type,
        transaction_type: transactionType,
        balance_after: balanceAfter,
        reference_id: referenceId,
        description
      })
    
    return !error
  } catch (error) {
    console.error('Create wallet transaction error:', error)
    return false
  }
}

// Create active session
export async function createActiveSession(userId: string, token: string): Promise<boolean> {
  try {
    const supabase = createSupabaseAdmin()
    const tokenHash = hashToken(token)
    const expiresAt = new Date()
    expiresAt.setDate(expiresAt.getDate() + 7) // 7 days expiry
    
    const { error } = await supabase
      .from('active_sessions')
      .insert({
        user_id: userId,
        token_hash: tokenHash,
        expires_at: expiresAt.toISOString()
      })
    
    return !error
  } catch (error) {
    console.error('Create active session error:', error)
    return false
  }
}

// Delete active session
export async function deleteActiveSession(token: string): Promise<boolean> {
  try {
    const supabase = createSupabaseAdmin()
    const tokenHash = hashToken(token)
    
    const { error } = await supabase
      .from('active_sessions')
      .delete()
      .eq('token_hash', tokenHash)
    
    return !error
  } catch (error) {
    console.error('Delete active session error:', error)
    return false
  }
}

// Validate password strength
export function validatePassword(password: string): { valid: boolean; error?: string } {
  if (!password || password.length < 6) {
    return { valid: false, error: 'Password must be at least 6 characters long' }
  }
  return { valid: true }
}

// Validate email format
export function validateEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return emailRegex.test(email)
}

// Validate phone format (basic validation)
export function validatePhone(phone: string): boolean {
  const phoneRegex = /^\+?[\d\s\-\(\)]{10,}$/
  return phoneRegex.test(phone)
}

// Create success response
export function createSuccessResponse<T>(data: T, message: string = 'Success'): Response {
  const response: ApiResponse<T> = {
    success: true,
    data,
    message
  }
  
  return new Response(JSON.stringify(response), {
    status: 200,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  })
}

// Create error response
export function createErrorResponse(message: string, status: number = 400, error?: string): Response {
  const response: ApiResponse = {
    success: false,
    message,
    error
  }
  
  return new Response(JSON.stringify(response), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  })
}

// Handle CORS preflight requests
export function handleCors(): Response {
  return new Response('ok', { headers: corsHeaders })
}

export interface AdminContext {
  id: string
  email: string
  full_name?: string
}

export async function verifyAdminSession(token: string): Promise<{ valid: boolean; admin?: AdminContext }> {
  const cleanedToken = token?.trim()
  if (!cleanedToken) {
    return { valid: false }
  }

  try {
    const supabase = createSupabaseAdmin()
    const tokenHash = hashToken(cleanedToken)
    const nowIso = new Date().toISOString()

    const { data: session, error: sessionError } = await supabase
      .from('admin_sessions')
      .select('admin_id, expires_at')
      .eq('token_hash', tokenHash)
      .gt('expires_at', nowIso)
      .single()

    if (sessionError || !session) {
      return { valid: false }
    }

    const { data: admin, error: adminError } = await supabase
      .from('admin_users')
      .select('id, email, full_name')
      .eq('id', session.admin_id)
      .single()

    if (adminError || !admin) {
      return { valid: false }
    }

    return {
      valid: true,
      admin: {
        id: admin.id,
        email: admin.email,
        full_name: admin.full_name ?? undefined
      }
    }
  } catch (error) {
    console.error('Verify admin session error:', error)
    return { valid: false }
  }
}





