import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:permission_handler/permission_handler.dart';

import 'api_service.dart';
import '../utils/crash_logger.dart';

class CallService {
  static ZegoExpressEngine? _engine;
  static String? _currentToken;
  static String? _currentUserID;
  static String? _currentRoomID;
  static Timer? _tokenRefreshTimer;
  static final StreamController<Map<String, dynamic>> _incomingController = StreamController.broadcast();
  static Stream<Map<String, dynamic>> get incomingCalls => _incomingController.stream;

  // Call events stream for UI debugging (works in release builds)
  static final StreamController<String> _callEventsController = StreamController.broadcast();
  static Stream<String> get callEvents => _callEventsController.stream;
  
  static void _emitEvent(String event) {
    if (!_callEventsController.isClosed) {
      _callEventsController.add(event);
    }
  }

  static bool _isInitializing = false;
  static bool _isInitialized = false;
  static Future<void>? _ongoingRegister;

  // Public method to check if CallService is initialized and ready
  static bool get isInitialized => _isInitialized && ApiService.isAuthenticated;
  
  // Expose current room ID for debugging
  static String? get currentRoomID => _currentRoomID;

  static Future<void> initialize() async {
    // Only initialize if user is authenticated
    if (!ApiService.isAuthenticated) {
      if (kDebugMode) {
        print('⚠️ CallService: Skipping initialization - user not authenticated');
      }
      _isInitialized = false;
      _isInitializing = false;
      return;
    }

    // If already initializing, wait for it to complete (with timeout)
    if (_isInitializing) {
      if (_ongoingRegister != null) {
        try {
          await _ongoingRegister!.timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              if (kDebugMode) {
                print('⚠️ Initialization timeout - clearing state');
              }
              _isInitializing = false;
              _ongoingRegister = null;
            },
          );
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Waiting for initialization failed: $e');
          }
          _isInitializing = false;
          _ongoingRegister = null;
        }
      }
      // Check if initialization completed successfully
      if (_isInitialized && _engine != null && _currentToken != null && _currentUserID != null) {
        return;
      }
    }
    
    _isInitializing = true;
    try {
      CrashLogger.logInfo('CallService: Starting Zego Cloud initialization');
      
      // CRITICAL: Request microphone permission FIRST
      await _ensureMicPermission();
      
      // Get Zego token from backend
      await _ensureRegistered();
      
      // Final validation - mark as initialized only if all components are ready
      _isInitialized = (_engine != null && 
                       _currentToken != null && 
                       _currentToken!.isNotEmpty &&
                       _currentUserID != null && 
                       _currentUserID!.isNotEmpty);
      
      CrashLogger.logInfo('CallService: Zego Cloud initialization complete - initialized: $_isInitialized');
      
      if (kDebugMode) {
        print('✅ CallService initialized: $_isInitialized');
        if (!_isInitialized) {
          print('   Engine: ${_engine != null}');
          print('   Token: ${_currentToken != null && _currentToken!.isNotEmpty}');
          print('   UserID: ${_currentUserID != null && _currentUserID!.isNotEmpty}');
        }
      }
    } catch (e, st) {
      _isInitialized = false;
      _isInitializing = false;
      _ongoingRegister = null;
      CrashLogger.logError('CallService.initialize error', e, st);
      if (kDebugMode) {
        print('❌ CallService.initialize error: $e');
        print(st);
      }
      // Re-throw so caller knows initialization failed
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  static void _setupEventHandlers() {
    _emitEvent('Setting up Zego event handlers');
    
    // Room state update handler - must be set on class, not instance
    ZegoExpressEngine.onRoomStateUpdate = (String roomID, ZegoRoomState state, int errorCode, Map<String, dynamic> extendedData) {
      _emitEvent('Room state: $state (error: $errorCode)');
      if (kDebugMode) {
        print('📞 Zego Room State Update: roomID=$roomID, state=$state, errorCode=$errorCode');
      }
      // Room state updated - can be used for call state management if needed
    };

    // Room user update handler - must be set on class, not instance
    ZegoExpressEngine.onRoomUserUpdate = (String roomID, ZegoUpdateType updateType, List<ZegoUser> userList) {
      final action = updateType == ZegoUpdateType.Add ? 'joined' : 'left';
      _emitEvent('User $action room: ${userList.length} user(s)');
      
      if (kDebugMode) {
        print('📞 Zego Room User Update: roomID=$roomID, updateType=$updateType, users=${userList.length}');
      }
      
      // When a user joins, treat it as an incoming call if we're in a room
      if (updateType == ZegoUpdateType.Add && _currentRoomID == roomID) {
        for (var user in userList) {
          if (user.userID != _currentUserID) {
            _emitEvent('Remote user: ${user.userID}');
            _incomingController.add({
              'from': user.userID,
              'caller_identity': user.userID,
              'caller_name': user.userName.isNotEmpty ? user.userName : user.userID,
              'room_id': roomID,
            });
          }
        }
      }
    };
    
    // Publisher state callback - to know if our stream is being published
    ZegoExpressEngine.onPublisherStateUpdate = (String streamID, ZegoPublisherState state, int errorCode, Map<String, dynamic> extendedData) {
      final stateStr = state == ZegoPublisherState.Publishing ? 'PUBLISHING' : 
                       state == ZegoPublisherState.PublishRequesting ? 'REQUESTING' : 'NO_PUBLISH';
      _emitEvent('Publish state: $stateStr (error: $errorCode)');
      if (kDebugMode) {
        print('📞 Publisher State: streamID=$streamID, state=$state, errorCode=$errorCode');
      }
    };
    
    // Player state callback - to know if remote stream is being received
    ZegoExpressEngine.onPlayerStateUpdate = (String streamID, ZegoPlayerState state, int errorCode, Map<String, dynamic> extendedData) {
      final stateStr = state == ZegoPlayerState.Playing ? 'PLAYING' : 
                       state == ZegoPlayerState.PlayRequesting ? 'REQUESTING' : 'NO_PLAY';
      _emitEvent('Player state: $stateStr (error: $errorCode)');
      if (kDebugMode) {
        print('📞 Player State: streamID=$streamID, state=$state, errorCode=$errorCode');
      }
    };

    // Stream event handler - must be set on class, not instance, and needs 4 parameters
    ZegoExpressEngine.onRoomStreamUpdate = (String roomID, ZegoUpdateType updateType, List<ZegoStream> streamList, Map<String, dynamic> extendedData) {
      if (kDebugMode) {
        print('📞 Zego Stream Update: roomID=$roomID, updateType=$updateType, streams=${streamList.length}');
      }
      
      // When a new stream is added, start playing it
      if (updateType == ZegoUpdateType.Add && _engine != null) {
        _emitEvent('Remote stream detected: ${streamList.length} stream(s)');
        
        for (var stream in streamList) {
          if (stream.streamID.isNotEmpty) {
            _emitEvent('Playing remote stream...');
            
            if (kDebugMode) {
              print('📞 Attempting to play stream: ${stream.streamID}');
            }
            
            _engine!.startPlayingStream(stream.streamID).then((_) async {
              _emitEvent('Remote stream playing!');
              
              if (kDebugMode) {
                print('✅ Started playing stream: ${stream.streamID}');
              }
              
              // Ensure audio output is working
              try {
                // CRITICAL: Unmute the playing stream audio
                await _engine!.mutePlayStreamAudio(stream.streamID, false);
                _emitEvent('Stream audio unmuted');
                
                // Enable speaker output (not muted)
                await _engine!.muteSpeaker(false);
                _emitEvent('Speaker enabled');
                
                // Set default audio route to earpiece for calls
                await _engine!.setAudioRouteToSpeaker(false);
                _emitEvent('Audio route: earpiece');
                
                if (kDebugMode) {
                  print('✅ Audio configured for incoming stream: ${stream.streamID}');
                }
              } catch (e) {
                _emitEvent('Audio config error: $e');
                if (kDebugMode) {
                  print('⚠️ Error configuring audio for stream: $e');
                }
              }
            }).catchError((e) {
              _emitEvent('Stream play error: $e');
              if (kDebugMode) {
                print('❌ Error starting to play stream ${stream.streamID}: $e');
              }
            });
          }
        }
      }
      
      // When streams are removed, log it
      if (updateType == ZegoUpdateType.Delete && _engine != null) {
        for (var stream in streamList) {
          if (kDebugMode) {
            print('📞 Stream removed: ${stream.streamID}');
          }
          // Stop playing the removed stream
          try {
            _engine!.stopPlayingStream(stream.streamID);
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Error stopping stream ${stream.streamID}: $e');
            }
          }
        }
      }
    };
  }

  // Public method to handle incoming call from FCM notification
  static void handleIncomingCallFromFCM(Map<String, dynamic> fcmData) {
    try {
      CrashLogger.logCall('handleIncomingCallFromFCM called', fcmData);
      
      if (fcmData.isEmpty) {
        CrashLogger.logWarning('CallService: Empty FCM data received');
        if (kDebugMode) {
          print('⚠️ CallService: Empty FCM data received');
        }
        return;
      }

      if (!isInitialized) {
        if (kDebugMode) {
          print('⚠️ CallService not initialized - cannot handle incoming call');
        }
        if (ApiService.isAuthenticated) {
          initialize().then((_) {
            if (kDebugMode) {
              print('✅ CallService initialized, retrying call handling');
            }
            handleIncomingCallFromFCM(fcmData);
          }).catchError((e) {
            if (kDebugMode) {
              print('❌ Failed to initialize CallService for incoming call: $e');
            }
          });
        }
        return;
      }

      if (_incomingController.isClosed) {
        if (kDebugMode) {
          print('⚠️ CallService: Incoming calls stream is closed');
        }
        return;
      }

      if (kDebugMode) {
        print('📞 Handling incoming call from FCM: $fcmData');
      }
      
      // Extract Zego call data from FCM notification
      String? roomID;
      String? callerID;
      String? callerName;
      String? callToken;
      String? appId;
      String? userId;
      
      try {
        roomID = fcmData['room_id']?.toString() ?? fcmData['roomId']?.toString();
        callerID = fcmData['caller_id']?.toString() ?? fcmData['callerId']?.toString() ?? fcmData['from']?.toString();
        callerName = fcmData['caller_name']?.toString() ?? fcmData['callerName']?.toString();
        // Backend now sends token directly in FCM notification
        callToken = fcmData['token']?.toString();
        appId = fcmData['app_id']?.toString();
        userId = fcmData['user_id']?.toString();
        
        if (kDebugMode) {
          print('📞 FCM Data extracted:');
          print('   roomID: $roomID');
          print('   callerID: $callerID');
          print('   hasToken: ${callToken != null && callToken.isNotEmpty}');
          print('   appId: $appId');
          print('   userId: $userId');
        }
        
        // If FCM includes a token for this call, store it for use when answering
        if (callToken != null && callToken.isNotEmpty) {
          _currentToken = callToken;
          _emitEvent('Received call token from FCM');
          if (kDebugMode) {
            print('✅ Stored call token from FCM notification');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Error extracting FCM data: $e');
        }
        return;
      }
      
      // Check if this is a Zego call notification
      if (roomID != null && roomID.isNotEmpty && callerID != null && callerID.isNotEmpty) {
        try {
          _incomingController.add({
            'from': callerID,
            'caller_identity': callerID,
            'callSid': roomID,
            'caller_name': callerName,
            'callerName': callerName,
            'from_name': callerName,
            'room_id': roomID,
            'token': callToken,
            'app_id': appId,
            'user_id': userId,
          });
          
          if (kDebugMode) {
            print('✅ Incoming call forwarded to stream: from=$callerID, roomID=$roomID');
          }
        } catch (e, stackTrace) {
          if (kDebugMode) {
            print('❌ Error adding to incoming calls stream: $e');
            print('Stack trace: $stackTrace');
          }
        }
      } else {
        if (kDebugMode) {
          print('⚠️ FCM data is not a Zego call: roomID=$roomID, callerID=$callerID');
        }
      }
    } catch (e, stackTrace) {
      CrashLogger.logError('Error in handleIncomingCallFromFCM', e, stackTrace);
      
      if (kDebugMode) {
        print('❌ Error in handleIncomingCallFromFCM: $e');
        print('Stack trace: $stackTrace');
      }
    }
  }

  static Future<void> _ensureRegistered() async {
    // Check if already fully registered with all required components
    if (_isInitialized && 
        _engine != null && 
        _currentToken != null && 
        _currentToken!.isNotEmpty &&
        _currentUserID != null && 
        _currentUserID!.isNotEmpty) {
      if (kDebugMode) {
        print('✅ CallService already registered - skipping');
      }
      return; // already registered
    }

    // If there's an ongoing registration, wait for it (but with timeout)
    if (_ongoingRegister != null) {
      try {
        await _ongoingRegister!.timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            if (kDebugMode) {
              print('⚠️ Registration timeout - clearing and retrying');
            }
            _ongoingRegister = null;
            _isInitializing = false;
            throw Exception('Registration timeout - please try again');
          },
        );
        // After waiting, verify we're actually registered
        if (_isInitialized && _engine != null && _currentToken != null && _currentUserID != null) {
          return;
        }
      } catch (e) {
        // If the ongoing registration failed, clear it and retry
        _ongoingRegister = null;
        _isInitializing = false;
        if (kDebugMode) {
          print('⚠️ Ongoing registration failed: $e - retrying');
        }
      }
    }

    // Start new registration
    _ongoingRegister = _registerWithBackoff();
    try {
      await _ongoingRegister;
    } finally {
      _ongoingRegister = null;
    }
    
    // Final validation that registration succeeded
    if (!_isInitialized || _engine == null || _currentToken == null || _currentUserID == null) {
      throw Exception('Registration completed but state is invalid. Please try again.');
    }
  }

  static Future<void> _registerWithBackoff() async {
    if (!ApiService.isAuthenticated) {
      if (kDebugMode) {
        print('⚠️ Cannot register Zego: user not authenticated');
      }
      throw Exception('User not authenticated. Please log in first.');
    }

    const List<int> delays = [0, 1000, 2000];
    dynamic lastError;
    bool isAuthError = false;
    
    for (final delay in delays) {
      if (delay > 0) await Future.delayed(Duration(milliseconds: delay));
      try {
        final result = await ApiService.generateZegoToken();
        if (result['success'] != true) {
          final error = result['error'];
          if (error is Map) {
            final errorMsg = error['message']?.toString().toLowerCase() ?? '';
            if (errorMsg.contains('unauthorised') || 
                errorMsg.contains('unauthorized') || 
                errorMsg.contains('401') ||
                errorMsg.contains('token')) {
              isAuthError = true;
              throw Exception('Authentication failed. Please log in again.');
            }
          }
          throw Exception('Fetch token failed: ${result['error']}');
        }

        final data = result['data'];
        
        // CRITICAL: Log the full response structure for debugging
        // Log to file so it's available in release builds too
        await CrashLogger.logInfo('📞 Zego Token API Response Structure:');
        await CrashLogger.logInfo('   result keys: ${result.keys}');
        await CrashLogger.logInfo('   data type: ${data.runtimeType}');
        if (data != null) {
          await CrashLogger.logInfo('   data keys: ${data is Map ? data.keys : 'not a map'}');
          if (data is Map && data.containsKey('data')) {
            await CrashLogger.logInfo('   data.data keys: ${data['data'] is Map ? data['data'].keys : 'not a map'}');
          }
          await CrashLogger.logInfo('   Full data: $data');
        }
        
        if (kDebugMode) {
          print('📞 Zego Token API Response Structure:');
          print('   result keys: ${result.keys}');
          print('   data type: ${data.runtimeType}');
          if (data != null) {
            print('   data keys: ${data is Map ? data.keys : 'not a map'}');
            if (data is Map && data.containsKey('data')) {
              print('   data.data keys: ${data['data'] is Map ? data['data'].keys : 'not a map'}');
            }
            print('   Full data: $data');
          }
        }
        
        // Handle nested data structure (data.data vs data)
        // Try multiple possible structures
        Map<String, dynamic>? tokenData;
        
        if (data is Map) {
          // Try data.data first (nested structure)
          if (data.containsKey('data') && data['data'] is Map) {
            tokenData = Map<String, dynamic>.from(data['data'] as Map);
            if (kDebugMode) {
              print('📞 Using nested data.data structure');
            }
          } else {
            // Use data directly
            tokenData = Map<String, dynamic>.from(data);
            if (kDebugMode) {
              print('📞 Using direct data structure');
            }
          }
        } else {
          // If data is not a Map, log it and throw
          if (kDebugMode) {
            print('❌ Invalid data structure: $data (type: ${data.runtimeType})');
          }
          throw Exception('Invalid response structure from Zego token API');
        }
        
        // Extract fields with multiple fallback options
        final token = tokenData['token']?.toString().trim();
        final userID = tokenData['user_id']?.toString().trim() ?? 
                       tokenData['userID']?.toString().trim() ??
                       tokenData['userId']?.toString().trim() ??
                       tokenData['userid']?.toString().trim();
        final appID = tokenData['app_id']?.toString().trim() ?? 
                     tokenData['appID']?.toString().trim() ??
                     tokenData['appId']?.toString().trim() ??
                     tokenData['appid']?.toString().trim();
        // Get AppSign for non-token authentication (fallback)
        final appSign = tokenData['app_sign']?.toString().trim() ?? 
                       tokenData['appSign']?.toString().trim() ??
                       tokenData['appsign']?.toString().trim();
        final expiresIn = (tokenData['expires_in'] ?? tokenData['expiresIn'] ?? 3600) as int;

        // Log extracted values for debugging (to file for release builds)
        await CrashLogger.logInfo('📞 Extracted Zego Token Data:');
        await CrashLogger.logInfo('   token: ${token != null && token.isNotEmpty ? '${token.substring(0, token.length > 20 ? 20 : token.length)}...' : 'null/empty'}');
        await CrashLogger.logInfo('   userID: $userID');
        await CrashLogger.logInfo('   appID: $appID');
        await CrashLogger.logInfo('   appSign: ${appSign != null && appSign.isNotEmpty ? 'present' : 'null/empty'}');
        await CrashLogger.logInfo('   expiresIn: $expiresIn');
        
        if (kDebugMode) {
          print('📞 Extracted Zego Token Data:');
          print('   token: ${token != null && token.isNotEmpty ? '${token.substring(0, token.length > 20 ? 20 : token.length)}...' : 'null/empty'}');
          print('   userID: $userID');
          print('   appID: $appID');
          print('   appSign: ${appSign != null && appSign.isNotEmpty ? 'present' : 'null/empty'}');
          print('   expiresIn: $expiresIn');
        }

        // Validate required fields with detailed error messages
        // Include actual response data in error message so it's visible even without debug logs
        if (token == null || token.isEmpty) {
          final availableKeys = tokenData.keys.join(", ");
          final responsePreview = tokenData.toString().length > 200 
            ? '${tokenData.toString().substring(0, 200)}...' 
            : tokenData.toString();
          
          await CrashLogger.logError(
            'Token validation failed',
            Exception('Empty or missing Zego token'),
            StackTrace.current,
          );
          await CrashLogger.logInfo('   tokenData keys: $availableKeys');
          await CrashLogger.logInfo('   tokenData content: $tokenData');
          
          if (kDebugMode) {
            print('❌ Token validation failed - tokenData keys: $availableKeys');
            print('   tokenData content: $tokenData');
          }
          
          throw Exception(
            'Empty or missing Zego token in response.\n'
            'Available keys: $availableKeys\n'
            'Response data: $responsePreview'
          );
        }
        
        if (userID == null || userID.isEmpty) {
          final availableKeys = tokenData.keys.join(", ");
          
          await CrashLogger.logError(
            'UserID validation failed',
            Exception('Empty or missing Zego userID'),
            StackTrace.current,
          );
          await CrashLogger.logInfo('   tokenData keys: $availableKeys');
          
          if (kDebugMode) {
            print('❌ UserID validation failed - tokenData keys: $availableKeys');
          }
          
          throw Exception(
            'Empty or missing Zego userID in response.\n'
            'Available keys: $availableKeys\n'
            'Response: ${tokenData.toString().length > 200 ? tokenData.toString().substring(0, 200) + "..." : tokenData.toString()}'
          );
        }

        if (appID == null || appID.isEmpty) {
          final availableKeys = tokenData.keys.join(", ");
          
          await CrashLogger.logError(
            'AppID validation failed',
            Exception('Empty or missing Zego AppID'),
            StackTrace.current,
          );
          await CrashLogger.logInfo('   tokenData keys: $availableKeys');
          
          if (kDebugMode) {
            print('❌ AppID validation failed - tokenData keys: $availableKeys');
          }
          
          throw Exception(
            'Empty or missing Zego AppID in response.\n'
            'Available keys: $availableKeys\n'
            'Response: ${tokenData.toString().length > 200 ? tokenData.toString().substring(0, 200) + "..." : tokenData.toString()}'
          );
        }

        _currentToken = token;
        _currentUserID = userID;

        if (kDebugMode) {
          print('📞 Initializing Zego Engine:');
          print('   AppID: $appID');
          print('   UserID: $_currentUserID');
          print('   Has Token: ${_currentToken != null && _currentToken!.isNotEmpty}');
          print('   Has AppSign: ${appSign != null && appSign.toString().isNotEmpty}');
        }

        try {
          // Create Zego Express Engine
          if (_engine == null) {
            final profile = ZegoEngineProfile(
              int.parse(appID.toString()),
              ZegoScenario.Communication,
              appSign: appSign?.toString(), // Include AppSign if available for non-token auth
            );
            
            _emitEvent('Creating Zego engine...');
            _emitEvent('AppID: $appID');
            _emitEvent('Has AppSign: ${appSign != null}');
            
            // createEngineWithProfile is async and returns Future<void>
            await ZegoExpressEngine.createEngineWithProfile(profile);
            // After creation, the engine is accessible via static instance
            _engine = ZegoExpressEngine.instance;
            
            // CRITICAL: Validate engine was created successfully
            if (_engine == null) {
              throw Exception('Zego engine creation failed - instance is null');
            }
            
            // Set up event handlers (must be set after engine creation)
            _setupEventHandlers();
            
            _emitEvent('Zego engine created');
            
            if (kDebugMode) {
              print('✅ Zego Engine created successfully');
              print('   Engine instance: ${_engine != null}');
            }
          } else {
            // Engine already exists - validate it's still valid
            if (_engine == null) {
              if (kDebugMode) {
                print('⚠️ Engine was null despite check - recreating...');
              }
              // Recreate engine
              final profile = ZegoEngineProfile(
                int.parse(appID.toString()),
                ZegoScenario.Communication,
                appSign: appSign?.toString(),
              );
              await ZegoExpressEngine.createEngineWithProfile(profile);
              _engine = ZegoExpressEngine.instance;
              if (_engine == null) {
                throw Exception('Failed to recreate Zego engine');
              }
              _setupEventHandlers();
            }
          }

          // Only mark as initialized if we have all required components
          if (_engine != null && _currentToken != null && _currentUserID != null) {
            _isInitialized = true;
          } else {
            throw Exception('Registration incomplete: Engine: ${_engine != null}, Token: ${_currentToken != null}, UserID: ${_currentUserID != null}');
          }
          
          _tokenRefreshTimer?.cancel();
          final refreshIn = Duration(seconds: ((expiresIn - 300).clamp(60, 3540) as num).toInt());
          _tokenRefreshTimer = Timer(refreshIn, () async {
            try {
              if (kDebugMode) {
                print('🔄 Token refresh timer triggered - refreshing Zego token');
              }
              _isInitialized = false;
              _isInitializing = false; // CRITICAL: Reset this to prevent deadlock
              _ongoingRegister = null; // Clear any stuck registration
              await _ensureRegistered();
            } catch (e) {
              if (kDebugMode) {
                print('⚠️ Token refresh failed: $e');
              }
              // Don't crash - just log the error
            }
          });
          
          if (kDebugMode) {
            print('✅ Zego registered successfully for userID=$_currentUserID');
          }
          return;
        } on PlatformException catch (pe) {
          CrashLogger.logError(
            'Zego SDK registration PlatformException',
            'code=${pe.code}, message=${pe.message}',
            null,
          );
          if (kDebugMode) {
            print('❌ Zego SDK registration PlatformException: code=${pe.code}, message=${pe.message}');
          }
          throw Exception('Zego SDK registration failed: ${pe.message ?? pe.code}');
        } catch (zegoError, stackTrace) {
          CrashLogger.logError('Zego SDK registration error', zegoError, stackTrace);
          if (kDebugMode) {
            print('❌ Zego SDK registration error: $zegoError');
            print('Stack trace: $stackTrace');
          }
          throw Exception('Zego SDK registration failed: $zegoError');
        }
      } catch (e) {
        lastError = e;
        CrashLogger.logError('Zego register attempt failed', e, null);
        if (kDebugMode) {
          print('⚠️ Zego register attempt failed: $e');
        }
        if (isAuthError) {
          break;
        }
      }
    }
    CrashLogger.logError('Zego registration failed after all retries', lastError, null);
    throw Exception('Zego registration failed: $lastError');
  }

  static Future<void> startCall({required String rideId}) async {
    if (!ApiService.isAuthenticated) {
      throw Exception('Please log in to make calls');
    }

    if (rideId.isEmpty) {
      throw Exception('Invalid ride ID');
    }

    // Ensure CallService is fully initialized before starting call
    if (!_isInitialized || _engine == null || _currentToken == null || _currentUserID == null) {
      try {
        CrashLogger.logInfo('CallService: Ensuring registration before startCall');
        await _ensureRegistered();
        
        // Double-check after registration
        if (!_isInitialized || _engine == null || _currentToken == null || _currentUserID == null) {
          throw Exception('CallService registration incomplete. Engine: ${_engine != null}, Token: ${_currentToken != null}, UserID: ${_currentUserID != null}');
        }
      } catch (e) {
        CrashLogger.logError('CallService registration failed before startCall', e, null);
        if (kDebugMode) {
          print('❌ CallService registration failed before startCall: $e');
        }
        throw Exception('Cannot make call: Zego registration failed. Please ensure you are logged in.');
      }
    }

    final initRes = await ApiService.initiateCall(rideId: rideId);
    if (initRes['success'] != true) {
      final error = initRes['error'];
      String errorMsg = 'Failed to initiate call';
      
      if (error != null) {
        if (error is Map) {
          errorMsg = error['message']?.toString() ?? 
                     error['error']?.toString() ?? 
                     error['status']?.toString() ?? 
                     error['msg']?.toString() ??
                     error['detail']?.toString() ??
                     'Failed to initiate call';
        } else if (error is String) {
          errorMsg = error;
        } else {
          errorMsg = error.toString();
        }
      } else {
        final message = initRes['message'];
        if (message != null) {
          errorMsg = message.toString();
        }
      }
      
      if (errorMsg.trim().isEmpty || errorMsg.toLowerCase() == 'null') {
        errorMsg = 'Failed to initiate call. Please try again.';
      }
      
      if (kDebugMode) {
        print('❌ Initiate call failed: $errorMsg');
      }
      
      throw Exception(errorMsg);
    }
    
    final payload = initRes['data'];
    if (payload == null) {
      throw Exception('Invalid response: missing data');
    }
    
    final data = payload['data'] ?? payload;
    if (data == null || data is! Map) {
      throw Exception('Invalid response: missing call data');
    }
    
    final String? roomID = data['room_id']?.toString() ?? data['roomId']?.toString();
    
    // Check if backend returned a room-specific token (can be in 'zego' object or directly)
    final zegoData = data['zego'];
    String? callToken;
    if (zegoData != null && zegoData is Map) {
      callToken = zegoData['token']?.toString();
      _emitEvent('Found token in zego object');
    } else {
      callToken = data['token']?.toString() ?? data['zego_token']?.toString();
    }
    
    if (callToken != null && callToken.isNotEmpty) {
      _currentToken = callToken;
      _emitEvent('Using call-specific token');
      if (kDebugMode) {
        print('📞 Using call-specific token from initiateCall');
      }
    } else {
      _emitEvent('No call token found, using existing');
    }
    
    if (roomID == null || roomID.isEmpty || roomID.trim().isEmpty) {
      CrashLogger.logError('CallService: Invalid room ID', 'Empty or null roomID: $roomID', null);
      throw Exception('Invalid response: missing or empty room ID');
    }

    // If we got a call-specific token, use it; otherwise ensure we have a valid token
    if (callToken != null && callToken.isNotEmpty) {
      // We already set _currentToken above, so we're good
      if (kDebugMode) {
        print('📞 Using call-specific token for room: $roomID');
      }
    } else {
      // No call-specific token - ensure we have a valid general token
      if (_currentToken == null || _currentToken!.isEmpty) {
        CrashLogger.logWarning('CallService: No call token and no general token, re-registering...');
        try {
          await _ensureRegistered();
        } catch (e) {
          CrashLogger.logError('CallService: Failed to get token before makeCall', e, null);
          throw Exception('Cannot make call: Zego registration failed. Please ensure you are logged in.');
        }
      }
    }

    // Request microphone permission
    await _ensureMicPermission();
    
    // Final validation before joining room
    if (!_isInitialized || _engine == null || _currentUserID == null || _currentUserID!.isEmpty) {
      CrashLogger.logError('CallService: Invalid state before joining room', 
        'Initialized: $_isInitialized, Engine: ${_engine != null}, UserID: $_currentUserID', null);
      throw Exception('Call service not ready. Please try again.');
    }
    
    if (_currentToken == null || _currentToken!.isEmpty) {
      CrashLogger.logError('CallService: No token available before joining room', null, null);
      throw Exception('Call service authentication failed. Please log out and log in again.');
    }
    
    CrashLogger.logInfo('CallService: Joining room $roomID');
    
    try {
      _emitEvent('Joining room: $roomID');
      _emitEvent('UserID: $_currentUserID');
      _emitEvent('Has token: ${_currentToken != null && _currentToken!.isNotEmpty}');
      
      // Join the room with token authentication
      final roomConfig = ZegoRoomConfig.defaultConfig();
      roomConfig.isUserStatusNotify = true;
      
      // Set token if available
      if (_currentToken != null && _currentToken!.isNotEmpty) {
        roomConfig.token = _currentToken!;
        _emitEvent('Using token for login');
      } else {
        _emitEvent('WARNING: No token available');
      }
      
      final loginResult = await _engine!.loginRoom(
        roomID,
        ZegoUser(_currentUserID!, _currentUserID!),
        config: roomConfig,
      );
      
      // Check if login actually succeeded
      if (loginResult.errorCode != 0) {
        _emitEvent('Room login FAILED: ${loginResult.errorCode}');
        throw Exception('Room login failed with error: ${loginResult.errorCode}');
      }
      
      _currentRoomID = roomID;
      _emitEvent('Room joined OK!');
      
      // Create a stream ID for publishing (usually roomID or userID-based)
      final streamID = '${_currentUserID}_$roomID';
      
      // CRITICAL: Enable audio capture device
      await _engine!.enableAudioCaptureDevice(true);
      _emitEvent('Audio capture enabled');
      
      // Ensure microphone is unmuted before publishing
      await _engine!.muteMicrophone(false);
      _emitEvent('Microphone unmuted');
      
      // Start publishing audio stream
      await _engine!.startPublishingStream(streamID);
      _emitEvent('Publishing audio stream');
      
      // Enable speaker (ensure we can hear remote audio)
      await _engine!.muteSpeaker(false);
      _emitEvent('Speaker enabled');
      
      // Set audio route to earpiece by default (user can switch to speaker)
      await _engine!.setAudioRouteToSpeaker(false);
      _emitEvent('Audio route: earpiece');
      
      _emitEvent('Call connected - waiting for remote');
      
      if (kDebugMode) {
        print('✅ Started publishing stream: $streamID');
        print('📞 Audio capture enabled, microphone unmuted, speaker enabled');
      }
      
      CrashLogger.logInfo('CallService: Successfully joined room and started call');
    } on PlatformException catch (pe) {
      _emitEvent('ERROR: ${pe.message ?? pe.code}');
      CrashLogger.logError(
        'Zego makeCall PlatformException',
        'code=${pe.code}, message=${pe.message}, roomID=$roomID',
        null,
      );
      if (kDebugMode) {
        print('❌ Zego makeCall PlatformException: code=${pe.code}, message=${pe.message}');
      }
      throw Exception('Call failed: ${pe.message ?? pe.code}');
    } catch (e, stackTrace) {
      _emitEvent('ERROR: $e');
      CrashLogger.logError('Zego makeCall error', e, stackTrace);
      if (kDebugMode) {
        print('❌ Zego makeCall error: $e');
        print('Stack trace: $stackTrace');
      }
      throw Exception('Call failed: ${e.toString()}');
    }
  }

  /// Answer an incoming call by joining the room and starting audio
  static Future<void> answerCall({required String roomID}) async {
    if (!ApiService.isAuthenticated) {
      throw Exception('Please log in to answer calls');
    }

    if (roomID.isEmpty) {
      throw Exception('Invalid room ID');
    }

    if (kDebugMode) {
      print('📞 Answering call in room: $roomID');
    }

    // Ensure CallService is fully initialized before answering call
    if (!_isInitialized || _engine == null || _currentUserID == null) {
      try {
        CrashLogger.logInfo('CallService: Ensuring registration before answerCall');
        await _ensureRegistered();
        
        // Double-check after registration
        if (!_isInitialized || _engine == null || _currentUserID == null || _currentUserID!.isEmpty) {
          throw Exception('CallService registration incomplete. Engine: ${_engine != null}, UserID: ${_currentUserID != null}');
        }
      } catch (e) {
        CrashLogger.logError('CallService registration failed before answerCall', e, null);
        if (kDebugMode) {
          print('❌ CallService registration failed before answerCall: $e');
        }
        throw Exception('Call service not ready. Please try again.');
      }
    }

    // Check if we have a token (should be set from FCM notification)
    if (_currentToken != null && _currentToken!.isNotEmpty) {
      _emitEvent('Using token from FCM notification');
      if (kDebugMode) {
        print('📞 Using existing token for answering call');
      }
    } else {
      // Fallback: try to get a token for this room
      _emitEvent('No FCM token, requesting new token...');
      if (kDebugMode) {
        print('📞 No token available, requesting token for room: $roomID');
      }
      try {
        final tokenResult = await ApiService.generateZegoToken(roomId: roomID);
        if (tokenResult['success'] == true) {
          final data = tokenResult['data'];
          final tokenData = data['data'] ?? data;
          final newToken = tokenData['token']?.toString();
          if (newToken != null && newToken.isNotEmpty) {
            _currentToken = newToken;
            _emitEvent('Got new token for room');
            if (kDebugMode) {
              print('✅ Got new token for room: $roomID');
            }
          } else {
            if (kDebugMode) {
              print('⚠️ Token response received but token is empty');
            }
          }
        } else {
          final error = tokenResult['error'];
          final errorMsg = error is Map ? error['message']?.toString() : error?.toString();
          if (kDebugMode) {
            print('❌ Failed to get token: $errorMsg');
          }
          throw Exception('Failed to get call token: $errorMsg');
        }
      } catch (e) {
        _emitEvent('Token request failed: $e');
        CrashLogger.logError('CallService: Failed to get token for answerCall', e, null);
        throw Exception('Failed to get call token. Please try again.');
      }
    }

    // Request microphone permission
    await _ensureMicPermission();

    // Final validation before joining room
    if (!_isInitialized || _engine == null || _currentUserID == null || _currentUserID!.isEmpty) {
      CrashLogger.logError('CallService: Invalid state before answering call', 
        'Initialized: $_isInitialized, Engine: ${_engine != null}, UserID: $_currentUserID', null);
      throw Exception('Call service not ready. Please try again.');
    }
    
    if (_currentToken == null || _currentToken!.isEmpty) {
      CrashLogger.logError('CallService: No token available before answering call', null, null);
      throw Exception('Call service authentication failed. Please log out and log in again.');
    }

    CrashLogger.logInfo('CallService: Answering call - joining room $roomID');

    try {
      _emitEvent('Joining room: $roomID');
      _emitEvent('UserID: $_currentUserID');
      _emitEvent('Has token: ${_currentToken != null && _currentToken!.isNotEmpty}');
      
      // Join the room with token authentication
      final roomConfig = ZegoRoomConfig.defaultConfig();
      roomConfig.isUserStatusNotify = true;
      
      // Set token if available (should be from FCM notification)
      if (_currentToken != null && _currentToken!.isNotEmpty) {
        roomConfig.token = _currentToken!;
        _emitEvent('Using token for login');
      } else {
        _emitEvent('WARNING: No token available');
      }
      
      final loginResult = await _engine!.loginRoom(
        roomID,
        ZegoUser(_currentUserID!, _currentUserID!),
        config: roomConfig,
      );

      // Check if login actually succeeded
      if (loginResult.errorCode != 0) {
        _emitEvent('Room login FAILED: ${loginResult.errorCode}');
        throw Exception('Room login failed with error: ${loginResult.errorCode}');
      }

      _currentRoomID = roomID;
      _emitEvent('Room joined OK!');

      // Create a stream ID for publishing
      final streamID = '${_currentUserID}_$roomID';

      // CRITICAL: Enable audio capture device
      await _engine!.enableAudioCaptureDevice(true);
      _emitEvent('Audio capture enabled');

      // Ensure microphone is unmuted before publishing
      await _engine!.muteMicrophone(false);
      _emitEvent('Microphone unmuted');

      // Start publishing audio stream
      await _engine!.startPublishingStream(streamID);
      _emitEvent('Publishing audio stream');

      // Enable speaker (ensure we can hear remote audio)
      await _engine!.muteSpeaker(false);
      _emitEvent('Speaker enabled');

      // Set audio route to earpiece by default (user can switch to speaker)
      await _engine!.setAudioRouteToSpeaker(false);
      _emitEvent('Audio route: earpiece');
      
      _emitEvent('Call answered - waiting for remote');

      if (kDebugMode) {
        print('✅ Call answered successfully - publishing stream: $streamID');
        print('📞 Audio capture enabled, microphone unmuted, speaker enabled');
      }

      CrashLogger.logInfo('CallService: Successfully answered call in room $roomID');
    } on PlatformException catch (pe) {
      _emitEvent('ERROR: ${pe.message ?? pe.code}');
      CrashLogger.logError(
        'Zego answerCall PlatformException',
        'code=${pe.code}, message=${pe.message}, roomID=$roomID',
        null,
      );
      if (kDebugMode) {
        print('❌ Zego answerCall PlatformException: code=${pe.code}, message=${pe.message}');
      }
      throw Exception('Answer call failed: ${pe.message ?? pe.code}');
    } catch (e, stackTrace) {
      _emitEvent('ERROR: $e');
      CrashLogger.logError('Zego answerCall error', e, stackTrace);
      if (kDebugMode) {
        print('❌ Zego answerCall error: $e');
        print('Stack trace: $stackTrace');
      }
      throw Exception('Answer call failed: ${e.toString()}');
    }
  }

  static Future<void> endCall() async {
    try {
      if (_engine != null) {
        // Stop publishing stream
        try {
          await _engine!.stopPublishingStream();
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error stopping publishing: $e');
          }
        }
        
        // Stop all playing streams
        try {
          // Get all streams in the room and stop them
          // Note: Zego doesn't have a direct way to stop all streams, 
          // so we'll just leave the room which stops everything
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error stopping playing: $e');
          }
        }
        
        // Leave the room (this stops all streams)
        if (_currentRoomID != null) {
          await _engine!.logoutRoom(_currentRoomID!);
          _currentRoomID = null;
        }
        
        if (kDebugMode) {
          print('✅ Call ended successfully');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error ending call: $e');
        print('Stack trace: $stackTrace');
      }
    }
  }

  static Future<void> setMuted(bool muted) async {
    try {
      if (_engine == null) {
        throw Exception('Engine not initialized');
      }
      
      // muteMicrophone(true) = mute, muteMicrophone(false) = unmute
      await _engine!.muteMicrophone(muted);
      
      if (kDebugMode) {
        print('✅ Microphone ${muted ? "muted" : "unmuted"}');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error setting mute: $e');
        print('Stack trace: $stackTrace');
      }
      throw Exception('Failed to set mute: ${e.toString()}');
    }
  }

  static Future<void> setSpeaker(bool speakerOn) async {
    try {
      if (_engine == null) {
        throw Exception('Engine not initialized');
      }
      
      await _engine!.setAudioRouteToSpeaker(speakerOn);
      
      if (kDebugMode) {
        print('✅ Speaker ${speakerOn ? "on" : "off"}');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error setting speaker: $e');
        print('Stack trace: $stackTrace');
      }
      throw Exception('Failed to set speaker: ${e.toString()}');
    }
  }

  static Future<void> _ensureMicPermission() async {
    try {
      final status = await Permission.microphone.status;
      if (status.isGranted) {
        await Future.delayed(const Duration(milliseconds: 300));
        return;
      }

      CrashLogger.logWarning('CallService: Microphone permission not granted, requesting...');
      final result = await Permission.microphone.request();
      if (!result.isGranted) {
        CrashLogger.logError('CallService: Microphone permission denied', 'User denied microphone permission', null);
        throw PlatformException(
          code: 'MIC_PERMISSION_DENIED',
          message: 'Microphone permission is required to make or receive calls.',
        );
      }
      
      CrashLogger.logInfo('CallService: Microphone permission granted');
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e, stackTrace) {
      CrashLogger.logError('CallService: Error ensuring mic permission', e, stackTrace);
      rethrow;
    }
  }

  // Reset registration state (call on logout)
  static void reset() {
    if (kDebugMode) {
      print('🔄 CallService reset - starting...');
    }
    
    // CRITICAL: Reset initialization flags first to prevent deadlocks
    _isInitialized = false;
    _isInitializing = false;
    _ongoingRegister = null;
    
    // Clear tokens and user state
    _currentToken = null;
    _currentUserID = null;
    
    // Cancel token refresh timer
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
    
    // Save roomID before clearing (for logout)
    final roomIDToLogout = _currentRoomID;
    _currentRoomID = null;
    
    // Clean up Zego engine with proper error handling for each step
    if (_engine != null) {
      // Step 1: Try to logout from room
      if (roomIDToLogout != null && roomIDToLogout.isNotEmpty) {
        try {
          _engine!.logoutRoom(roomIDToLogout);
          if (kDebugMode) {
            print('✅ Logged out of room: $roomIDToLogout');
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error logging out of room: $e');
          }
          // Continue cleanup even if logout fails
        }
      }
      
      // Step 2: Destroy the engine
      try {
        ZegoExpressEngine.destroyEngine();
        if (kDebugMode) {
          print('✅ Zego engine destroyed');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Error destroying Zego engine: $e');
        }
        // Continue cleanup even if destroy fails
      }
      
      _engine = null;
    }
    
    if (kDebugMode) {
      print('🔄 CallService reset - completed');
    }
  }
}
