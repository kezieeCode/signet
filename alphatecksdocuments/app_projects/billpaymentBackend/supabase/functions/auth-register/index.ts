import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { 
  corsHeaders, 
  createSupabaseAdmin, 
  createSupabaseClient,
  createSuccessResponse, 
  createErrorResponse, 
  handleCors,
  validatePassword,
  validateEmail,
  validatePhone,
  createActiveSession,
  createWalletTransaction,
  UserProfile
} from '../_shared/utils.ts'

interface RegisterRequest {
  firstName: string
  lastName: string
  username: string
  email: string
  phone: string
  password: string
}

interface RegisterResponse {
  user: UserProfile
  token: string
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return handleCors()
  }

  try {
    // Parse request body
    const { firstName, lastName, username, email, phone, password }: RegisterRequest = await req.json()

    // Validate required fields
    if (!firstName || !lastName || !username || !email || !password) {
      return createErrorResponse('Missing required fields: firstName, lastName, username, email, password')
    }

    // Validate email format
    if (!validateEmail(email)) {
      return createErrorResponse('Invalid email format')
    }

    // Validate password strength
    const passwordValidation = validatePassword(password)
    if (!passwordValidation.valid) {
      return createErrorResponse(passwordValidation.error || 'Invalid password')
    }

    // Validate phone if provided
    if (phone && !validatePhone(phone)) {
      return createErrorResponse('Invalid phone format')
    }

    // Check if username already exists
    const supabaseAdmin = createSupabaseAdmin()
    const { data: existingProfile } = await supabaseAdmin
      .from('profiles')
      .select('username')
      .eq('username', username)
      .single()

    if (existingProfile) {
      return createErrorResponse('Username already exists')
    }

    // Check if email already exists
    const { data: existingUser } = await supabaseAdmin.auth.admin.listUsers()
    const emailExists = existingUser.users.some(user => user.email === email)
    
    if (emailExists) {
      return createErrorResponse('Email already exists')
    }

    // Create user in Supabase Auth
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true // Skip email confirmation
    })

    if (authError || !authData.user) {
      console.error('Auth user creation error:', authError)
      return createErrorResponse('Failed to create user account', 500)
    }

    const userId = authData.user.id

    // Create user profile
    const { error: profileError } = await supabaseAdmin
      .from('profiles')
      .insert({
        id: userId,
        first_name: firstName,
        last_name: lastName,
        username,
        phone: phone || null
      })

    if (profileError) {
      console.error('Profile creation error:', profileError)
      // Clean up auth user if profile creation fails
      await supabaseAdmin.auth.admin.deleteUser(userId)
      return createErrorResponse('Failed to create user profile', 500)
    }

    // Create initial wallet transaction (0 balance)
    const walletCreated = await createWalletTransaction(
      userId, 
      0, 
      'credit', 
      'initial_balance', 
      'INIT_' + userId,
      'Initial wallet balance'
    )

    if (!walletCreated) {
      console.error('Failed to create initial wallet transaction')
    }

    // Sign in to get token
    const supabaseClient = createSupabaseClient()
    const { data: signInData, error: signInError } = await supabaseClient.auth.signInWithPassword({
      email,
      password
    })

    if (signInError || !signInData.session) {
      console.error('Sign in error:', signInError)
      return createErrorResponse('Failed to create user session', 500)
    }

    // Create active session record
    const sessionCreated = await createActiveSession(userId, signInData.session.access_token)
    if (!sessionCreated) {
      console.error('Failed to create active session')
    }

    // Get user profile with wallet balance
    const userProfile: UserProfile = {
      id: userId,
      first_name: firstName,
      last_name: lastName,
      username,
      email,
      phone: phone || undefined,
      wallet_balance: 0
    }

    const response: RegisterResponse = {
      user: userProfile,
      token: signInData.session.access_token
    }

    return createSuccessResponse(response, 'User registered successfully')

  } catch (error) {
    console.error('Register function error:', error)
    return createErrorResponse('Internal server error', 500, error.message)
  }
})