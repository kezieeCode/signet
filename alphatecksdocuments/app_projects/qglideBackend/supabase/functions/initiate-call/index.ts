import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { handleCors, createResponse, createErrorResponse } from '../_shared/utils.ts'
import { sendFcmV1ToTokens } from '../_shared/fcm_v1.ts'
import { generateToken04, getZegoCredentials } from '../_shared/zego_token.ts'

interface InitiateCallRequest {
	ride_id?: string
	courier_order_id?: string
	room_id?: string // Optional: if provided, use this room_id
}

function getBearerToken(req: Request): string | null {
	const auth = req.headers.get('authorization') || req.headers.get('Authorization')
	if (!auth) return null
	const parts = auth.split(' ')
	if (parts.length === 2 && parts[0].toLowerCase() === 'bearer') return parts[1]
	return null
}

// Generate a unique room ID for Zego
function generateRoomId(): string {
	// Generate a random room ID (Zego format: typically alphanumeric, 1-128 characters)
	const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
	let roomId = ''
	for (let i = 0; i < 16; i++) {
		roomId += chars.charAt(Math.floor(Math.random() * chars.length))
	}
	return roomId
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
		const callerId = userData.user.id

		// Get Zego credentials for token generation
		const zegoCredentials = getZegoCredentials()
		if (!zegoCredentials) {
			console.error('Missing or invalid Zego credentials')
			return createErrorResponse('Zego configuration error. Please set ZEGO_APP_ID and ZEGO_SERVER_SECRET environment variables.', 500)
		}
		const { appId: zegoAppId, serverSecret: zegoServerSecret } = zegoCredentials

		// Get user profile
		const { data: callerProfile } = await admin
			.from('profiles')
			.select('user_type, full_name')
			.eq('id', callerId)
			.single()

		if (!callerProfile || !['rider', 'driver', 'courier'].includes(callerProfile.user_type)) {
			return createErrorResponse('Invalid user type', 403)
		}

		const body: InitiateCallRequest = await req.json()
		
		// Determine if this is for a ride or courier order
		let recipientId: string | null = null
		let orderType: 'ride' | 'courier_order' | 'direct' = 'direct'
		let orderId: string | null = null

		if (body.ride_id) {
			orderType = 'ride'
			orderId = body.ride_id

			// Fetch ride details
			const { data: ride, error: rideErr } = await admin
				.from('rides')
				.select('id, rider_id, driver_id, status')
				.eq('id', body.ride_id)
				.single()

			if (rideErr || !ride) {
				return createErrorResponse('Ride not found', 404)
			}

			// Verify caller is part of this ride
			const isCallerRider = callerProfile.user_type === 'rider' && ride.rider_id === callerId
			const isCallerDriver = callerProfile.user_type === 'driver' && ride.driver_id === callerId

			if (!isCallerRider && !isCallerDriver) {
				return createErrorResponse('You are not part of this ride', 403)
			}

			// Determine recipient
			recipientId = callerProfile.user_type === 'rider' ? ride.driver_id : ride.rider_id
			if (!recipientId) {
				return createErrorResponse('Recipient not found for this ride', 404)
			}
		} else if (body.courier_order_id) {
			orderType = 'courier_order'
			orderId = body.courier_order_id

			// Fetch courier order details
			const { data: order, error: orderErr } = await admin
				.from('courier_orders')
				.select('id, rider_id, courier_id, status')
				.eq('id', body.courier_order_id)
				.single()

			if (orderErr || !order) {
				return createErrorResponse('Courier order not found', 404)
			}

			// Verify caller is part of this courier order
			const isCallerRider = callerProfile.user_type === 'rider' && order.rider_id === callerId
			const isCallerCourier = callerProfile.user_type === 'courier' && order.courier_id === callerId

			if (!isCallerRider && !isCallerCourier) {
				return createErrorResponse('You are not part of this courier order', 403)
			}

			// Determine recipient
			recipientId = callerProfile.user_type === 'rider' ? order.courier_id : order.rider_id
			if (!recipientId) {
				return createErrorResponse('Recipient not found for this courier order', 404)
			}
		} else if (body.room_id) {
			// Direct call with provided room_id (no order validation)
			orderType = 'direct'
		} else {
			return createErrorResponse('ride_id, courier_order_id, or room_id is required', 400)
		}

		// Get recipient's name if recipient exists
		let recipientName = 'User'
		if (recipientId) {
			const { data: recipientProfile } = await admin
				.from('profiles')
				.select('full_name, user_type')
				.eq('id', recipientId)
				.single()

			if (recipientProfile) {
				recipientName = recipientProfile.full_name || 'User'
			}
		}

		// Generate or use provided room_id
		const roomId = body.room_id || generateRoomId()

		// Generate Zego tokens for both caller and receiver (1 hour validity)
		const callerToken = await generateToken04(zegoAppId, callerId, zegoServerSecret, 3600)
		const receiverToken = recipientId 
			? await generateToken04(zegoAppId, recipientId, zegoServerSecret, 3600) 
			: null

		// Create call log entry if order exists
		let callLogId: string | null = null
		if (orderId && recipientId) {
			const { data: callLog, error: logErr } = await admin
				.from('call_logs')
				.insert({
					ride_id: orderType === 'ride' ? orderId : null,
					courier_order_id: orderType === 'courier_order' ? orderId : null,
					caller_id: callerId,
					caller_type: callerProfile.user_type,
					recipient_id: recipientId,
					recipient_type: recipientId ? (
						callerProfile.user_type === 'rider' ? 
							(orderType === 'ride' ? 'driver' : 'courier') :
						callerProfile.user_type === 'driver' ? 'rider' :
						'rider'
					) : null,
					status: 'initiated',
					started_at: new Date().toISOString(),
					room_id: roomId,
				})
				.select('id')
				.single()

			if (logErr) {
				console.error('Error creating call log:', logErr)
			} else {
				callLogId = callLog?.id || null
			}
		}

		// Send FCM notification to recipient about incoming call with Zego token
		if (recipientId && receiverToken) {
			try {
				const { data: tokens } = await admin
					.from('fcm_tokens')
					.select('device_token')
					.eq('user_id', recipientId)
					.eq('is_active', true)

				const deviceTokens = (tokens || []).map((t: any) => t.device_token)
				if (deviceTokens.length > 0) {
					const callerName = callerProfile.full_name || (callerProfile.user_type === 'driver' ? 'Driver' : callerProfile.user_type === 'courier' ? 'Courier' : 'Rider')
					await sendFcmV1ToTokens(deviceTokens, {
						title: 'Incoming Call',
						body: `${callerName} is calling you`,
					}, {
						type: 'incoming_call',
						ride_id: orderType === 'ride' ? orderId : null,
						courier_order_id: orderType === 'courier_order' ? orderId : null,
						caller_id: callerId,
						caller_name: callerName,
						call_id: callLogId,
						room_id: roomId,
						// Include Zego credentials for receiver to join
						token: receiverToken,
						app_id: String(zegoAppId),
						user_id: recipientId,
					})
				}
			} catch (notifyErr) {
				console.error('FCM notify error:', notifyErr)
			}
		}

		// Return Zego room information with caller's token
		return createResponse({
			success: true,
			room_id: roomId,
			call_id: callLogId,
			status: 'initiated',
			caller_id: callerId,
			recipient_id: recipientId,
			recipient_name: recipientName,
			order_type: orderType,
			order_id: orderId,
			// Include Zego credentials for caller
			zego: {
				token: callerToken,
				app_id: zegoAppId,
				user_id: callerId,
				expires_in: 3600,
			},
			message: 'Call room created. Use Zego SDK to join the room.',
			instructions: {
				caller: `Join Zego room "${roomId}" using the provided token`,
				recipient: `Receiver will get token via FCM notification to join room "${roomId}"`,
			},
		}, 200)
	} catch (e) {
		console.error('initiate-call error:', e)
		return createErrorResponse(`Server error: ${e.message}`, 500)
	}
})
