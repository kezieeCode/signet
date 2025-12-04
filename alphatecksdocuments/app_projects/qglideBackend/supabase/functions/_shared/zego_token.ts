// Zego Token04 Generation - Official Format
// Includes room login (1) and publish stream (2) privileges

// PKCS5/PKCS7 padding for AES
function pkcs5Pad(data: Uint8Array, blockSize: number): Uint8Array {
	const padding = blockSize - (data.length % blockSize)
	const padded = new Uint8Array(data.length + padding)
	padded.set(data)
	padded.fill(padding, data.length)
	return padded
}

// Convert number to 4-byte big-endian array
function int32ToBytes(num: number): Uint8Array {
	const arr = new Uint8Array(4)
	arr[0] = (num >> 24) & 0xff
	arr[1] = (num >> 16) & 0xff
	arr[2] = (num >> 8) & 0xff
	arr[3] = num & 0xff
	return arr
}

/**
 * Generate Zego Token using official token04 format with AES-128-CBC
 * This includes room login (1) and publish stream (2) privileges
 * 
 * @param appId - Zego App ID from console
 * @param userId - User identifier
 * @param serverSecret - 32-character server secret from Zego console
 * @param effectiveTimeInSeconds - Token validity in seconds (default 1 hour)
 * @param payload - Optional payload string
 * @returns Promise<string> - The generated token starting with "04"
 */
export async function generateToken04(
	appId: number,
	userId: string,
	serverSecret: string,
	effectiveTimeInSeconds: number = 3600,
	payload: string = ''
): Promise<string> {
	if (!serverSecret || serverSecret.length !== 32) {
		throw new Error('serverSecret must be 32 characters')
	}

	const createTime = Math.floor(Date.now() / 1000)
	const expireTime = createTime + effectiveTimeInSeconds
	const nonce = Math.floor(Math.random() * 2147483647)

	// CRITICAL: Privilege must include room login (1) and publish (2)
	const tokenInfo = {
		app_id: appId,
		user_id: userId,
		nonce: nonce,
		ctime: createTime,
		expire: expireTime,
		payload: payload,
		privilege: {
			1: 1,  // loginRoom: enabled
			2: 1   // publishStream: enabled
		}
	}

	const tokenInfoJson = JSON.stringify(tokenInfo)
	const encoder = new TextEncoder()
	const tokenInfoBytes = encoder.encode(tokenInfoJson)

	// Generate random 16-byte IV for AES-CBC
	const iv = crypto.getRandomValues(new Uint8Array(16))

	// Use serverSecret as AES key (first 16 bytes for AES-128)
	const keyBytes = encoder.encode(serverSecret).slice(0, 16)

	// Import key for AES-CBC encryption
	const cryptoKey = await crypto.subtle.importKey(
		'raw',
		keyBytes,
		{ name: 'AES-CBC' },
		false,
		['encrypt']
	)

	// Apply PKCS5 padding
	const paddedData = pkcs5Pad(tokenInfoBytes, 16)

	// Encrypt with AES-CBC
	const encrypted = await crypto.subtle.encrypt(
		{ name: 'AES-CBC', iv: iv },
		cryptoKey,
		paddedData
	)
	const encryptedBytes = new Uint8Array(encrypted)

	// Build token binary: expireTime(4 bytes) + ivLength(2 bytes) + iv + encryptedLength(2 bytes) + encrypted
	const expireTimeBytes = int32ToBytes(expireTime)
	const ivLength = new Uint8Array([0, iv.length])
	const encryptedLength = new Uint8Array([(encryptedBytes.length >> 8) & 0xff, encryptedBytes.length & 0xff])

	const tokenBinary = new Uint8Array(
		expireTimeBytes.length + ivLength.length + iv.length + encryptedLength.length + encryptedBytes.length
	)
	
	let offset = 0
	tokenBinary.set(expireTimeBytes, offset)
	offset += expireTimeBytes.length
	tokenBinary.set(ivLength, offset)
	offset += ivLength.length
	tokenBinary.set(iv, offset)
	offset += iv.length
	tokenBinary.set(encryptedLength, offset)
	offset += encryptedLength.length
	tokenBinary.set(encryptedBytes, offset)

	// Base64 encode and prepend version "04"
	const base64Token = btoa(String.fromCharCode(...tokenBinary))
	const token = '04' + base64Token

	return token
}

/**
 * Get Zego credentials from environment variables
 * @returns Object with appId, serverSecret, or null if not configured
 */
export function getZegoCredentials(): { appId: number; serverSecret: string } | null {
	const zegoAppId = Deno.env.get('ZEGO_APP_ID')
	const zegoServerSecret = Deno.env.get('ZEGO_SERVER_SECRET')

	if (!zegoAppId || !zegoServerSecret) {
		return null
	}

	const appId = parseInt(zegoAppId, 10)
	if (isNaN(appId)) {
		return null
	}

	if (zegoServerSecret.length !== 32) {
		return null
	}

	return { appId, serverSecret: zegoServerSecret }
}
