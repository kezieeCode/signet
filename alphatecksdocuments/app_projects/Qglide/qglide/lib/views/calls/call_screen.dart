import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/theme_cubit.dart';
import '../../utils/responsive_helper.dart';
import '../../services/call_service.dart';
import '../../services/api_service.dart';
import '../../utils/crash_logger.dart';

class CallScreen extends StatefulWidget {
  final String counterpartName;
  final String counterpartIdentity;
  final bool isIncoming;
  final String? roomID; // Required for incoming calls to join the room

  const CallScreen({
    super.key,
    required this.counterpartName,
    required this.counterpartIdentity,
    this.isIncoming = false,
    this.roomID,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _muted = false;
  bool _speakerOn = false;
  bool _isConnecting = true;
  bool _isConnected = false;
  String? _connectionError;
  
  // Status log for debugging in release builds
  final List<String> _statusLog = [];
  bool _remoteAudioDetected = false;
  StreamSubscription? _callEventSubscription;

  void _addStatus(String status) {
    if (mounted) {
      setState(() {
        _statusLog.add('${DateTime.now().toString().substring(11, 19)}: $status');
        // Keep only last 10 entries
        if (_statusLog.length > 10) {
          _statusLog.removeAt(0);
        }
      });
    }
  }

  void _showSnackBar(String message, {Color? color}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color ?? Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    CrashLogger.logInfo('CallScreen: Initialized - isIncoming: ${widget.isIncoming}, counterpart: ${widget.counterpartName}, roomID: ${widget.roomID}');
    
    _addStatus('Call screen opened');
    _addStatus('Type: ${widget.isIncoming ? "Incoming" : "Outgoing"}');
    if (widget.roomID != null) {
      _addStatus('Room: ${widget.roomID}');
    }
    
    // Listen to call events from CallService
    _callEventSubscription = CallService.callEvents.listen((event) {
      _addStatus(event);
      if (event.contains('Playing remote') || event.contains('Remote stream') || event.contains('Player state: PLAYING')) {
        setState(() => _remoteAudioDetected = true);
        _showSnackBar('Remote audio connected!', color: Colors.green);
      }
      if (event.contains('User joined')) {
        _showSnackBar('Other party joined!', color: Colors.blue);
      }
    });
    
    // If this is an incoming call, automatically answer it
    if (widget.isIncoming && widget.roomID != null && widget.roomID!.isNotEmpty) {
      _answerIncomingCall();
    } else if (!widget.isIncoming) {
      // Outgoing call - already connected via startCall
      final currentRoom = CallService.currentRoomID;
      _addStatus('Outgoing call - waiting for remote');
      _addStatus('RoomID: ${currentRoom ?? "unknown"}');
      setState(() {
        _isConnecting = false;
        _isConnected = true;
      });
    } else {
      // Safety: Ensure CallService is ready before allowing interactions
      _addStatus('Initializing call service...');
      if (!CallService.isInitialized) {
        CrashLogger.logWarning('CallScreen: CallService not initialized');
        // Try to initialize if authenticated
        if (ApiService.isAuthenticated) {
          CallService.initialize().then((_) {
            _addStatus('Call service initialized');
            if (mounted) {
              setState(() {
                _isConnecting = false;
              });
            }
          }).catchError((e) {
            _addStatus('Init failed: $e');
            CrashLogger.logError('CallScreen: Failed to initialize CallService', e);
            if (mounted) {
              setState(() {
                _isConnecting = false;
                _connectionError = 'Failed to initialize call service';
              });
            }
          });
        }
      } else {
        _addStatus('Call service ready');
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _callEventSubscription?.cancel();
    super.dispose();
  }

  Future<void> _answerIncomingCall() async {
    _addStatus('Answering incoming call...');
    _addStatus('RoomID: ${widget.roomID ?? "NULL!"}');
    _showSnackBar('Joining call...', color: Colors.orange);

    if (widget.roomID == null || widget.roomID!.isEmpty) {
      _addStatus('ERROR: No room ID provided!');
      _showSnackBar('Error: No room ID!', color: Colors.red);
      setState(() {
        _isConnecting = false;
        _connectionError = 'No room ID provided in call notification';
      });
      return;
    }

    try {
      await CallService.answerCall(roomID: widget.roomID!);
      
      _addStatus('Call answered successfully');
      _showSnackBar('Connected! Waiting for audio...', color: Colors.green);
      
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _isConnected = true;
        });
      }
    } catch (e, stackTrace) {
      _addStatus('Answer failed: $e');
      _showSnackBar('Failed: ${e.toString().replaceAll('Exception: ', '')}', color: Colors.red);
      
      CrashLogger.logError('CallScreen: Failed to answer incoming call', e, stackTrace);
      
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _connectionError = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return Scaffold(
          backgroundColor: themeState.backgroundColor,
          appBar: AppBar(
            backgroundColor: themeState.backgroundColor,
            elevation: 0,
            title: Text(
              widget.isIncoming ? 'Incoming Call' : 'Calling',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: themeState.textPrimary,
              ),
            ),
            centerTitle: true,
          ),
          body: Padding(
            padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: ResponsiveHelper.getResponsiveSpacing(context, 40),
                  backgroundColor: Colors.grey.shade800,
                  child: Icon(
                    Icons.person,
                    size: ResponsiveHelper.getResponsiveIconSize(context, 40),
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                Text(
                  widget.counterpartName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: themeState.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                Text(
                  widget.counterpartIdentity,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: themeState.textSecondary,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                // Show connection status
                if (_isConnecting)
                  Column(
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                      Text(
                        'Connecting...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: themeState.textSecondary,
                        ),
                      ),
                    ],
                  )
                else if (_connectionError != null)
                  Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: ResponsiveHelper.getResponsiveIconSize(context, 32),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                      Text(
                        _connectionError!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                else if (_isConnected)
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Connected',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Remote audio indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _remoteAudioDetected ? Icons.hearing : Icons.hearing_disabled,
                            color: _remoteAudioDetected ? Colors.green : Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _remoteAudioDetected ? 'Remote audio active' : 'Waiting for remote audio...',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _remoteAudioDetected ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
                // Status log (scrollable)
                Container(
                  height: 100,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    reverse: true,
                    itemCount: _statusLog.length,
                    itemBuilder: (context, index) {
                      final reversedIndex = _statusLog.length - 1 - index;
                      return Text(
                        _statusLog[reversedIndex],
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade400,
                          fontFamily: 'monospace',
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _controlButton(
                      icon: _muted ? Icons.mic_off : Icons.mic,
                      label: _muted ? 'Unmute' : 'Mute',
                      enabled: _isConnected,
                      onTap: () async {
                        if (!_isConnected) return;
                        try {
                          setState(() => _muted = !_muted);
                          await CallService.setMuted(_muted);
                        } catch (e) {
                          if (kDebugMode) {
                            print('❌ Error setting mute: $e');
                          }
                          // Revert state on error
                          if (mounted) {
                            setState(() => _muted = !_muted);
                          }
                        }
                      },
                    ),
                    _controlButton(
                      icon: _speakerOn ? Icons.volume_up : Icons.hearing,
                      label: _speakerOn ? 'Speaker' : 'Earpiece',
                      enabled: _isConnected,
                      onTap: () async {
                        if (!_isConnected) return;
                        try {
                          setState(() => _speakerOn = !_speakerOn);
                          await CallService.setSpeaker(_speakerOn);
                        } catch (e) {
                          if (kDebugMode) {
                            print('❌ Error setting speaker: $e');
                          }
                          // Revert state on error
                          if (mounted) {
                            setState(() => _speakerOn = !_speakerOn);
                          }
                        }
                      },
                    ),
                    _controlButton(
                      icon: Icons.call_end,
                      label: 'Hang Up',
                      color: Colors.red,
                      onTap: () async {
                        try {
                          await CallService.endCall();
                          if (mounted) {
                            Navigator.of(context).pop();
                          }
                        } catch (e) {
                          if (kDebugMode) {
                            print('❌ Error ending call: $e');
                          }
                          // Still try to pop the screen
                          if (mounted) {
                            Navigator.of(context).pop();
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        },
      );
    } catch (e, stackTrace) {
      // Critical: Never crash - return a safe fallback UI
      CrashLogger.logError('Critical error building CallScreen', e, stackTrace);
      
      if (kDebugMode) {
        print('❌ Critical error building CallScreen: $e');
        print('Stack trace: $stackTrace');
      }
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Call'),
        ),
        body: const Center(
          child: Text('Call screen error. Please try again.'),
        ),
      );
    }
  }

  Widget _controlButton({required IconData icon, required String label, Color? color, bool enabled = true, required VoidCallback onTap}) {
    final effectiveColor = enabled ? (color ?? Colors.grey.shade900) : Colors.grey.shade600;
    
    return Column(
      children: [
        InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(40),
          child: CircleAvatar(
            radius: ResponsiveHelper.getResponsiveSpacing(context, 28),
            backgroundColor: effectiveColor,
            child: Icon(
              icon,
              color: enabled ? Colors.white : Colors.grey.shade400,
            ),
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: enabled ? null : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}


