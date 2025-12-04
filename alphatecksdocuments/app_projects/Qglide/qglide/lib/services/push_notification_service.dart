import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' hide Priority;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
import 'call_service.dart';
import '../utils/crash_logger.dart';

// Background message handler (must be top-level function)
// This runs in a separate isolate, so Firebase must be initialized here
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // CRITICAL: Initialize Firebase in the background isolate
    // This is required for release builds when app is killed
    // In a background isolate, Firebase won't be initialized, so we must initialize it
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (firebaseError) {
      // Firebase might already be initialized or initialization failed
      // Log but don't crash - notification might still be processable
      if (kDebugMode) {
        print('⚠️ Firebase initialization check failed: $firebaseError');
      }
      // Try to continue - Firebase might be initialized in another way
    }
    
    if (kDebugMode) {
      print('🔔 Background Message Received: ${message.messageId}');
      print('   Title: ${message.notification?.title}');
      print('   Body: ${message.notification?.body}');
      print('   Data: ${message.data}');
    }
    
    // Safely check if this is a Zego Cloud call notification
    try {
      final data = message.data;
      if (data.isNotEmpty) {
        final roomID = data['room_id']?.toString() ?? data['roomId']?.toString();
        final callerID = data['caller_id']?.toString() ?? data['callerId']?.toString() ?? data['from']?.toString();
        final type = data['type']?.toString() ?? '';
        
        if ((roomID != null && roomID.isNotEmpty && callerID != null && callerID.isNotEmpty) ||
            (type.contains('call') || type.contains('zego'))) {
          if (kDebugMode) {
            print('📞 Zego call notification detected in background');
            print('   Room ID: $roomID');
            print('   Caller ID: $callerID');
          }
          // Note: Background handlers run in isolate, so we can't directly access CallService
          // The message will be handled when the app is in foreground or when user taps the notification
        }
      }
    } catch (dataError) {
      if (kDebugMode) {
        print('⚠️ Error processing notification data: $dataError');
      }
    }
    
    // Handle other background notifications
    // Regular notifications (ride acceptance, etc.) will be shown by the system
    // The app will be woken up when user taps the notification
    
  } catch (e, stackTrace) {
    // Critical: Never let background handler crash - log and continue
    if (kDebugMode) {
      print('❌ Critical error in background message handler: $e');
      print('Stack trace: $stackTrace');
    }
    // In production, silently handle errors to prevent crashes
    // The notification will still be delivered by the system if possible
  }
}

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static String? _cachedDeviceId;
  static String? _cachedDeviceType;
  // Queue for notifications received when app is not ready
  static final List<RemoteMessage> _queuedNotifications = [];
  static bool _isAppReady = false;

  static Future<void> initialize() async {
    await CrashLogger.logInfo('PushNotificationService: Initializing');
    
    await _requestNotificationPermission();
    await _initializeLocalNotifications();

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle foreground messages - but only after app is ready
    // This prevents crashes when notifications arrive during app startup
    FirebaseMessaging.onMessage.listen((message) {
      // Queue all messages until app is ready
      if (!_isAppReady) {
        if (kDebugMode) {
          debugPrint('⏳ App not ready, queuing foreground message');
        }
        if (!_queuedNotifications.any((m) => m.messageId == message.messageId)) {
          _queuedNotifications.add(message);
        }
        return;
      }
      // App is ready, handle normally
      _handleForegroundMessage(message);
    });

    // CRITICAL FIX: Delay setting up notification tap handlers until app is ready
    // This prevents crashes when notifications arrive before the app is fully initialized
    // Use post-frame callback to ensure app widget tree is built
    // Use a longer delay to ensure everything is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 2000), () {
        _isAppReady = true;
        
        if (kDebugMode) {
          debugPrint('✅ App is now ready for notifications');
        }
        
        // Process any queued notifications now that app is ready
        _processQueuedNotifications();
        
        // Now set up notification tap handlers with additional safety
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
          // Add significant delay to ensure navigator and all services are ready
          Future.delayed(const Duration(milliseconds: 500), () {
            try {
              // CRITICAL: Check if this is a Zego call notification first
              if (_isZegoCallNotification(message.data)) {
                if (kDebugMode) {
                  debugPrint('📞 Zego call notification tapped (app opened from background)');
                }
                // Handle Zego call - forward to CallService which will show CallScreen via incomingCalls stream
                if (CallService.isInitialized) {
                  try {
                    CallService.handleIncomingCallFromFCM(message.data);
                    if (kDebugMode) {
                      debugPrint('✅ Zego call forwarded to CallService from notification tap');
                    }
                  } catch (e, stackTrace) {
                    if (kDebugMode) {
                      debugPrint('❌ Error handling Zego call tap: $e');
                      debugPrint('Stack trace: $stackTrace');
                    }
                  }
                } else if (ApiService.isAuthenticated) {
                  // Try to initialize CallService if user is authenticated
                  if (kDebugMode) {
                    debugPrint('⚠️ CallService not initialized - attempting initialization');
                  }
                  CallService.initialize().then((_) {
                    try {
                      CallService.handleIncomingCallFromFCM(message.data);
                      if (kDebugMode) {
                        debugPrint('✅ Zego call forwarded to CallService after initialization');
                      }
                    } catch (e) {
                      if (kDebugMode) {
                        debugPrint('❌ Error handling call after initialization: $e');
                      }
                    }
                  }).catchError((e) {
                    if (kDebugMode) {
                      debugPrint('❌ Failed to initialize CallService: $e');
                    }
                  });
                }
                return; // Don't process as regular notification
              }
              
              // Handle regular notification taps
              _handleNotificationTap(message);
            } catch (e, stackTrace) {
              if (kDebugMode) {
                debugPrint('❌ Critical error in onMessageOpenedApp: $e');
                debugPrint('Stack trace: $stackTrace');
              }
            }
          });
        });

        // Check if app was opened from a terminated state via notification
        // Add significant delay before checking
        Future.delayed(const Duration(milliseconds: 1000), () {
          _messaging.getInitialMessage().then((initialMessage) {
            if (initialMessage != null) {
              // Delay handling to ensure app is fully ready
              Future.delayed(const Duration(milliseconds: 500), () {
                try {
                  // CRITICAL: Check if this is a Zego call notification first
                  if (_isZegoCallNotification(initialMessage.data)) {
                    if (kDebugMode) {
                      debugPrint('📞 Zego call notification (app opened from terminated state)');
                    }
                    // Handle Zego call - forward to CallService which will show CallScreen
                    if (CallService.isInitialized) {
                      try {
                        CallService.handleIncomingCallFromFCM(initialMessage.data);
                        if (kDebugMode) {
                          debugPrint('✅ Zego call forwarded to CallService from initial message');
                        }
                      } catch (e, stackTrace) {
                        if (kDebugMode) {
                          debugPrint('❌ Error handling Zego call from initial message: $e');
                          debugPrint('Stack trace: $stackTrace');
                        }
                      }
                    } else if (ApiService.isAuthenticated) {
                      CallService.initialize().then((_) {
                        try {
                          CallService.handleIncomingCallFromFCM(initialMessage.data);
                          if (kDebugMode) {
                            debugPrint('✅ Zego call forwarded to CallService after initialization');
                          }
                        } catch (e) {
                          if (kDebugMode) {
                            debugPrint('❌ Error handling call after initialization: $e');
                          }
                        }
                      }).catchError((e) {
                        if (kDebugMode) {
                          debugPrint('❌ Failed to initialize CallService: $e');
                        }
                      });
                    }
                    return; // Don't process as regular notification
                  }
                  
                  // Handle regular notification taps
                  _handleNotificationTap(initialMessage);
                } catch (e, stackTrace) {
                  if (kDebugMode) {
                    debugPrint('❌ Critical error handling initial message: $e');
                    debugPrint('Stack trace: $stackTrace');
                  }
                }
              });
            }
          }).catchError((e) {
            if (kDebugMode) {
              debugPrint('❌ Error getting initial message: $e');
            }
          });
        });
        
        // Process any queued notifications with delay
        Future.delayed(const Duration(milliseconds: 500), () {
          _processQueuedNotifications();
        });
      });
    });

    final String? token = await _messaging.getToken();
    if (kDebugMode) {
      debugPrint('FCM Token: $token');
    }

    // Send token to backend on app start (if token exists)
    if (token != null && token.isNotEmpty) {
      await sendCurrentTokenToBackend();
    }

    _messaging.onTokenRefresh.listen((String newToken) async {
      if (kDebugMode) {
        debugPrint('FCM Token refreshed: $newToken');
      }
      // Send refreshed token to backend
      await sendCurrentTokenToBackend();
    });

    // Optional: iOS foreground notification presentation options
    if (Platform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (kDebugMode) {
          debugPrint('Notification tapped: ${response.payload}');
        }
        // Handle notification tap
      },
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'qglide_notifications', // id
        'QGlide Notifications', // name
        description: 'Notifications for QGlide ride updates',
        importance: Importance.high,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      // Log notification to file
      await CrashLogger.logNotification('Foreground message received', {
        'messageId': message.messageId,
        'title': message.notification?.title,
        'body': message.notification?.body,
        'data': message.data.toString(),
      });
      
      if (kDebugMode) {
        debugPrint('🔔 Foreground Message Received: ${message.messageId}');
        debugPrint('   Title: ${message.notification?.title}');
        debugPrint('   Body: ${message.notification?.body}');
        debugPrint('   Data: ${message.data}');
      }

      // Check if this is a Zego Cloud call notification
      if (_isZegoCallNotification(message.data)) {
        if (kDebugMode) {
          debugPrint('📞 Zego call notification detected in foreground');
        }
        
        // CRITICAL: Only handle if app is ready
        if (!_isAppReady) {
          if (kDebugMode) {
            debugPrint('⏳ App not ready, queuing Zego call notification');
          }
          // Queue for later - will be processed when app is ready
          if (!_queuedNotifications.any((m) => m.messageId == message.messageId)) {
            _queuedNotifications.add(message);
          }
          return;
        }
        
        // Handle Zego call - don't show regular notification, let CallService handle it
        // Check if CallService is initialized before calling
        if (CallService.isInitialized) {
          try {
            CallService.handleIncomingCallFromFCM(message.data);
          } catch (e, stackTrace) {
            if (kDebugMode) {
              debugPrint('❌ Error handling Zego call: $e');
              debugPrint('Stack trace: $stackTrace');
            }
          }
        } else {
          if (kDebugMode) {
            debugPrint('⚠️ CallService not initialized - attempting initialization');
          }
          // Try to initialize CallService if user is authenticated
          if (ApiService.isAuthenticated) {
            CallService.initialize().then((_) {
              // After initialization, try handling the call again
              try {
                CallService.handleIncomingCallFromFCM(message.data);
              } catch (e) {
                if (kDebugMode) {
                  debugPrint('❌ Error handling call after initialization: $e');
                }
              }
            }).catchError((e) {
              if (kDebugMode) {
                debugPrint('❌ Failed to initialize CallService: $e');
              }
            });
          } else {
            if (kDebugMode) {
              debugPrint('⚠️ User not authenticated, cannot initialize CallService');
            }
          }
        }
        return;
      }

      // Show local notification when app is in foreground
      // Handle regular notifications (ride acceptance, ride updates, etc.)
      if (message.notification != null) {
        final notification = message.notification!;
        
        // Safely extract notification data
        final title = notification.title;
        final body = notification.body;
        
        // Only show if we have valid content
        if ((title != null && title.isNotEmpty) || (body != null && body.isNotEmpty)) {
          const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
            'qglide_notifications',
            'QGlide Notifications',
            channelDescription: 'Notifications for QGlide ride updates',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            icon: '@mipmap/launcher_icon',
          );

          const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

          const NotificationDetails details = NotificationDetails(
            android: androidDetails,
            iOS: iosDetails,
          );

          try {
            await _localNotifications.show(
              message.hashCode,
              title ?? 'QGlide',
              body ?? '',
              details,
              payload: message.data.toString(),
            );
          } catch (e) {
            if (kDebugMode) {
              debugPrint('❌ Error showing notification: $e');
            }
          }
        }
      }
    } catch (e, stackTrace) {
      // Log error to file
      await CrashLogger.logError('Error handling foreground message', e, stackTrace);
      
      // Prevent crashes from notification handling
      if (kDebugMode) {
        debugPrint('❌ Error handling foreground message: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  // Process queued notifications now that app is ready
  static void _processQueuedNotifications() {
    if (_queuedNotifications.isEmpty) return;
    
    if (kDebugMode) {
      debugPrint('📬 Processing ${_queuedNotifications.length} queued notifications');
    }
    
    final queued = List<RemoteMessage>.from(_queuedNotifications);
    _queuedNotifications.clear();
    
    // Process with delays to avoid overwhelming the app
    for (int i = 0; i < queued.length; i++) {
      final message = queued[i];
      Future.delayed(Duration(milliseconds: i * 200), () {
        try {
          if (_isZegoCallNotification(message.data)) {
            // Handle Zego calls through CallService
            if (CallService.isInitialized) {
              CallService.handleIncomingCallFromFCM(message.data);
            } else if (ApiService.isAuthenticated) {
              CallService.initialize().then((_) {
                CallService.handleIncomingCallFromFCM(message.data);
              }).catchError((e) {
                if (kDebugMode) {
                  debugPrint('❌ Failed to initialize CallService for queued notification: $e');
                }
              });
            }
          } else {
            // Handle regular notifications
            _handleNotificationTap(message);
          }
        } catch (e, stackTrace) {
          if (kDebugMode) {
            debugPrint('❌ Error processing queued notification: $e');
            debugPrint('Stack trace: $stackTrace');
          }
        }
      });
    }
  }

  // Helper function to safely navigate - checks navigator readiness
  // This is for future use when implementing navigation from notifications
  // ignore: unused_element
  static void _safeNavigate(GlobalKey<NavigatorState> navigatorKey, Widget Function() builder, {String? debugMessage}) {
    try {
      // Use post-frame callback to ensure UI is ready
      SchedulerBinding.instance.addPostFrameCallback((_) {
        try {
          final navigatorState = navigatorKey.currentState;
          if (navigatorState != null) {
            navigatorState.push(
              MaterialPageRoute(builder: (_) => builder()),
            );
            if (kDebugMode && debugMessage != null) {
              debugPrint('✅ Navigation successful: $debugMessage');
            }
          } else {
            if (kDebugMode) {
              debugPrint('⚠️ Navigator not ready, cannot navigate: ${debugMessage ?? "unknown"}');
            }
            // Could queue navigation for later if needed
          }
        } catch (e, stackTrace) {
          if (kDebugMode) {
            debugPrint('❌ Error during navigation: $e');
            debugPrint('Stack trace: $stackTrace');
          }
        }
      });
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Error setting up navigation: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    try {
      // Log notification tap
      CrashLogger.logNotification('Notification tapped', {
        'messageId': message.messageId,
        'data': message.data.toString(),
      });
      
      // If app is not ready, queue the notification
      if (!_isAppReady) {
        CrashLogger.logWarning('App not ready, queuing notification: ${message.messageId}');
        if (kDebugMode) {
          debugPrint('⏳ App not ready, queuing notification: ${message.messageId}');
        }
        if (!_queuedNotifications.any((m) => m.messageId == message.messageId)) {
          _queuedNotifications.add(message);
        }
        return;
      }
      
      // Additional safety: Check if navigator exists before processing
      // This prevents crashes if notification arrives during app startup
      try {
        // Import appNavigatorKey from main.dart - we'll need to pass it or use a different approach
        // For now, just add extra delay and safety checks
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Navigator check failed, queuing notification: $e');
        }
        if (!_queuedNotifications.any((m) => m.messageId == message.messageId)) {
          _queuedNotifications.add(message);
        }
        return;
      }

      if (kDebugMode) {
        debugPrint('🔔 Notification Tap: ${message.messageId}');
        debugPrint('   Data: ${message.data}');
      }
      
      // Safely check notification data
      if (message.data.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ Notification has no data');
        }
        return;
      }
      
      // Check if this is a Twilio voice call notification
      if (_isZegoCallNotification(message.data)) {
        if (kDebugMode) {
          debugPrint('📞 Zego call notification tapped');
        }
        // Handle Zego call - forward to CallService
        // Check if CallService is initialized before calling
        if (CallService.isInitialized) {
          try {
            CallService.handleIncomingCallFromFCM(message.data);
          } catch (e, stackTrace) {
            if (kDebugMode) {
              debugPrint('❌ Error handling Zego call tap: $e');
              debugPrint('Stack trace: $stackTrace');
            }
          }
        } else {
          if (kDebugMode) {
            debugPrint('⚠️ CallService not initialized - attempting initialization');
          }
          // Try to initialize CallService if user is authenticated
          if (ApiService.isAuthenticated) {
            CallService.initialize().then((_) {
              // After initialization, try handling the call again
              try {
                CallService.handleIncomingCallFromFCM(message.data);
              } catch (e) {
                if (kDebugMode) {
                  debugPrint('❌ Error handling call after initialization: $e');
                }
              }
            }).catchError((e) {
              if (kDebugMode) {
                debugPrint('❌ Failed to initialize CallService: $e');
              }
            });
          } else {
            if (kDebugMode) {
              debugPrint('⚠️ User not authenticated, cannot initialize CallService');
            }
          }
        }
        return;
      }
      
      // Handle other notification taps (ride acceptance, ride updates, etc.)
      // Safely extract notification type/data
      try {
        final notificationType = message.data['type']?.toString() ?? message.data['notification_type']?.toString();
        final rideId = message.data['ride_id']?.toString() ?? message.data['rideId']?.toString();
        
        if (kDebugMode) {
          debugPrint('📬 Regular notification tapped: type=$notificationType, rideId=$rideId');
        }
        
        // TODO: Navigate to appropriate screen based on notification type
        // When implementing navigation, use _safeNavigate() helper function
        // Example:
        // if (rideId != null && rideId.isNotEmpty) {
        //   _safeNavigate(
        //     appNavigatorKey, // Import from main.dart
        //     () => RideDetailsScreen(rideId: rideId),
        //     debugMessage: 'Navigate to ride $rideId',
        //   );
        // }
      } catch (e, stackTrace) {
        if (kDebugMode) {
          debugPrint('⚠️ Error handling notification tap data: $e');
          debugPrint('Stack trace: $stackTrace');
        }
      }
    } catch (e, stackTrace) {
      // Log error to file
      CrashLogger.logError('Error handling notification tap', e, stackTrace);
      
      // Prevent crashes from notification tap handling
      if (kDebugMode) {
        debugPrint('❌ Error handling notification tap: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  // Check if FCM notification is from Zego Cloud
  static bool _isZegoCallNotification(Map<String, dynamic> data) {
    try {
      if (data.isEmpty) return false;
      
      final roomID = data['room_id']?.toString() ?? data['roomId']?.toString();
      final callerID = data['caller_id']?.toString() ?? data['callerId']?.toString() ?? data['from']?.toString();
      final type = data['type']?.toString() ?? '';
      
      // Zego Cloud calls have specific indicators
      return (roomID != null && roomID.isNotEmpty && callerID != null && callerID.isNotEmpty) ||
             (type.contains('call') || type.contains('zego'));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error checking Zego call notification: $e');
      }
      return false;
    }
  }

  static Future<void> _requestNotificationPermission() async {
    final NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    if (kDebugMode) {
      debugPrint('Notification permission status: ${settings.authorizationStatus}');
    }
  }

  static Future<Map<String, String>> getDeviceInfo() async {
    // Return cached values if available
    if (_cachedDeviceId != null && _cachedDeviceId!.isNotEmpty && 
        _cachedDeviceType != null && _cachedDeviceType!.isNotEmpty) {
      return {
        'device_type': _cachedDeviceType!,
        'device_id': _cachedDeviceId!,
      };
    }

    String deviceType = 'unknown';
    String deviceId = 'unknown-device';

    try {
      if (Platform.isAndroid) {
        deviceType = 'android';
        try {
          final androidInfo = await _deviceInfo.androidInfo;
          deviceId = androidInfo.id.isNotEmpty ? androidInfo.id : 'android-${DateTime.now().millisecondsSinceEpoch}';
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Error getting Android device info: $e');
          }
          deviceId = 'android-${DateTime.now().millisecondsSinceEpoch}';
        }
      } else if (Platform.isIOS) {
        deviceType = 'ios';
        try {
          final iosInfo = await _deviceInfo.iosInfo;
          deviceId = (iosInfo.identifierForVendor?.isNotEmpty == true) 
              ? iosInfo.identifierForVendor! 
              : 'ios-${DateTime.now().millisecondsSinceEpoch}';
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Error getting iOS device info: $e');
          }
          deviceId = 'ios-${DateTime.now().millisecondsSinceEpoch}';
        }
      } else {
        deviceType = 'unknown';
        deviceId = 'unknown-${DateTime.now().millisecondsSinceEpoch}';
      }

      // Validate device ID is not empty
      if (deviceId.isEmpty) {
        deviceId = '$deviceType-${DateTime.now().millisecondsSinceEpoch}';
      }

      // Cache the values only if valid
      if (deviceType.isNotEmpty && deviceId.isNotEmpty) {
        _cachedDeviceType = deviceType;
        _cachedDeviceId = deviceId;
      }

      return {
        'device_type': deviceType,
        'device_id': deviceId,
      };
    } catch (e, stackTrace) {
      // Critical: Never crash - always return valid fallback values
      if (kDebugMode) {
        debugPrint('❌ Critical error getting device info: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      // Fallback with timestamp to ensure uniqueness
      deviceType = Platform.isAndroid ? 'android' : Platform.isIOS ? 'ios' : 'unknown';
      deviceId = 'fallback-${deviceType}-${DateTime.now().millisecondsSinceEpoch}';
      
      // Cache fallback values
      _cachedDeviceType = deviceType;
      _cachedDeviceId = deviceId;
      
      return {
        'device_type': deviceType,
        'device_id': deviceId,
      };
    }
  }

  static Future<void> sendCurrentTokenToBackend() async {
    try {
      // Safely get FCM token
      String? token;
      try {
        token = await _messaging.getToken();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Error getting FCM token: $e');
        }
        return; // Can't proceed without token
      }

      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ No FCM token available to register');
        }
        return;
      }

      // Safely get device info with fallback
      Map<String, String> deviceInfo;
      try {
        deviceInfo = await getDeviceInfo();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Error getting device info for FCM registration: $e');
        }
        // Use fallback device info
        deviceInfo = {
          'device_type': Platform.isAndroid ? 'android' : Platform.isIOS ? 'ios' : 'unknown',
          'device_id': 'fallback-${DateTime.now().millisecondsSinceEpoch}',
        };
      }

      // Validate device info values
      final deviceType = deviceInfo['device_type']?.isNotEmpty == true 
          ? deviceInfo['device_type']! 
          : (Platform.isAndroid ? 'android' : Platform.isIOS ? 'ios' : 'unknown');
      final deviceId = deviceInfo['device_id']?.isNotEmpty == true 
          ? deviceInfo['device_id']! 
          : 'fallback-${DateTime.now().millisecondsSinceEpoch}';
      
      if (kDebugMode) {
        debugPrint('📱 Registering FCM Token:');
        debugPrint('   Token: ${token.length > 20 ? token.substring(0, 20) : token}...');
        debugPrint('   Device Type: $deviceType');
        debugPrint('   Device ID: $deviceId');
      }

      // Safely register token with backend
      try {
        final response = await ApiService.registerFcmToken(
          deviceToken: token,
          deviceType: deviceType,
          deviceId: deviceId,
        );

        if (response['success'] == true) {
          if (kDebugMode) {
            debugPrint('✅ FCM Token registered successfully');
          }
        } else {
          if (kDebugMode) {
            debugPrint('❌ FCM Token registration failed: ${response['error']}');
          }
        }
      } catch (apiError) {
        // API call failed but don't crash - just log
        if (kDebugMode) {
          debugPrint('❌ API error registering FCM token: $apiError');
        }
      }
    } catch (e, stackTrace) {
      // Critical: Never crash - log and continue
      if (kDebugMode) {
        debugPrint('❌ Critical error in sendCurrentTokenToBackend: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      // Silently fail in production to prevent crashes
    }
  }
}


