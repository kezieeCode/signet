import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { handleCors, createResponse, createErrorResponse } from '../_shared/utils.ts'
import { generateToken04, getZegoCredentials } from '../_shared/zego_token.ts'

function getBearerToken(req: Request): string | null {
	const auth = req.headers.get('authorization') || req.headers.get('Authorization')
	if (!auth) return null
	const parts = auth.split(' ')
	if (parts.length === 2 && parts[0].toLowerCase() === 'bearer') return parts[1]
	return null
}

Deno.serve(async (req: Request) => {
	const cors = await handleCors(req)
	if (cors) return cors

	if (req.method !== 'POST') {
		return createErrorResponse('Method not allowed. Use POST.', 405)
	}

	try {
		const token = getBearerToken(req)
		if (!token) return createErrorResponse('Unauthorized', 401)

		const supabaseUrl = Deno.env.get('SUPABASE_URL')!
		const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
		const admin = createClient(supabaseUrl, supabaseServiceKey)

		const { data: userData, error: userErr } = await admin.auth.getUser(token)
		if (userErr || !userData.user) return createErrorResponse('Unauthorized', 401)
		const userId = userData.user.id

		// Get Zego credentials from environment variables
		const zegoCredentials = getZegoCredentials()
		if (!zegoCredentials) {
			console.error('Missing or invalid Zego credentials')
			return createErrorResponse('Zego configuration error. Please set ZEGO_APP_ID (number) and ZEGO_SERVER_SECRET (32 characters) environment variables.', 500)
		}

		const { appId, serverSecret } = zegoCredentials

		// Generate user ID string (use Supabase user ID)
		const zegoUserId = userId

		// Generate token (default 1 hour expiration, can be customized)
		const body = await req.json().catch(() => ({}))
		const expiration = body.expiration || 3600 // Default 1 hour in seconds

		const zegoToken = await generateToken04(appId, zegoUserId, serverSecret, expiration)

		// Return in format expected by frontend
		return createResponse({
			success: true,
			data: {
				token: zegoToken,
				app_id: appId,
				user_id: zegoUserId,
				expires_in: expiration,
			}
		}, 200)
	} catch (e) {
		console.error('generate-zego-token error:', e)
		return createErrorResponse(`Server error: ${e.message}`, 500)
	}
})
