package com.alphatecks.qglide

import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

/**
 * Custom FCM service for handling push notifications.
 * This service handles all FCM messages including call notifications.
 */
class QGlideFirebaseMessagingService : FirebaseMessagingService() {
    
    companion object {
        private const val TAG = "QGlideFCMService"
    }
    
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        try {
            val data = remoteMessage.data
            
            // Log all incoming messages
            Log.d(TAG, "FCM message received - type: ${data["type"]}, room_id: ${data["room_id"]}")
            
            // Handle Zego call notifications
            if (isZegoCallMessage(data)) {
                Log.d(TAG, "Zego call message detected")
                // The message will be handled by Flutter's FirebaseMessaging.onMessage
                // and forwarded to CallService.handleIncomingCallFromFCM
            } else {
                Log.d(TAG, "Regular notification received")
                // Regular notification - handled by Flutter's FirebaseMessaging.onMessage
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in onMessageReceived: ${e.message}", e)
        }
    }
    
    /**
     * Check if the FCM message is a Zego call notification.
     * Zego call messages have specific data fields.
     */
    private fun isZegoCallMessage(data: Map<String, String>): Boolean {
        try {
            if (data.isEmpty()) return false
            
            val roomID = data["room_id"] ?: data["roomId"] ?: ""
            val callerID = data["caller_id"] ?: data["callerId"] ?: data["from"] ?: ""
            val type = data["type"] ?: ""
            
            // Zego call messages should have:
            // 1. room_id (room identifier)
            // 2. caller_id (caller identifier)
            // 3. type containing "call" or "zego"
            val hasRoomID = roomID.isNotEmpty()
            val hasCallerID = callerID.isNotEmpty()
            val hasCallType = type.contains("call", ignoreCase = true) || 
                             type.contains("zego", ignoreCase = true) ||
                             type.isEmpty() // If type is empty but has room_id and caller_id, assume it's a call
            
            val isZegoCall = hasRoomID && hasCallerID && (hasCallType || type.isEmpty())
            
            Log.d(TAG, "Message check - type: $type, roomID: $roomID, callerID: $callerID, isZegoCall: $isZegoCall")
            
            return isZegoCall
        } catch (e: Exception) {
            Log.e(TAG, "Error checking Zego call message: ${e.message}", e)
            return false
        }
    }
    
    override fun onNewToken(token: String) {
        // Handle token refresh
        Log.d(TAG, "FCM token refreshed: ${token.take(20)}...")
        // Token will be sent to backend via PushNotificationService
    }
}
