import 'dart:ui' show PlatformDispatcher;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'l10n/app_localizations.dart';
import 'cubits/theme_cubit.dart';
import 'cubits/locale_cubit.dart';
import 'cubits/driver_cubit.dart';
import 'cubits/document_cubit.dart';
import 'cubits/chat_cubit.dart';
import 'cubits/ride_cubit.dart';
import 'services/api_service.dart';
import 'views/splash/splash_screen.dart';
import 'services/push_notification_service.dart';
import 'services/call_service.dart';
import 'views/onboarding/onboarding_screen.dart';
import 'views/main_navigation/main_navigation_screen.dart';
import 'views/calls/call_screen.dart';
import 'package:flutter/scheduler.dart';
import 'utils/crash_logger.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
bool _appResumed = true;
final List<Map<String, dynamic>> _pendingIncoming = [];
final Set<String> _presentedCallKeys = {};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize crash logger FIRST - before anything else
  try {
    await CrashLogger.initialize();
    await CrashLogger.logInfo('=== App initialization started ===');
  } catch (e) {
    // Even if logger fails, try to continue
    if (kDebugMode) {
      print('⚠️ Failed to initialize crash logger: $e');
    }
  }
  
  // CRITICAL: Set up global error handlers to prevent crashes
  FlutterError.onError = (FlutterErrorDetails details) {
    // Log to file for release builds
    CrashLogger.logError(
      'Flutter Error: ${details.exception}',
      details.exception,
      details.stack,
    );
    
    if (kDebugMode) {
      FlutterError.presentError(details);
      print('❌ Flutter Error: ${details.exception}');
      print('Stack trace: ${details.stack}');
    }
    // In production, log to file instead of crashing
  };
  
  // Handle errors from async operations
  PlatformDispatcher.instance.onError = (error, stack) {
    // Log to file for release builds
    CrashLogger.logError('Platform Error', error, stack);
    
    if (kDebugMode) {
      print('❌ Platform Error: $error');
      print('Stack trace: $stack');
    }
    return true; // Prevent crash
  };
  
  // OPTIMIZATION: Initialize only critical services before showing splash screen
  // Non-critical services will initialize in background after app starts
  
  // Initialize Firebase (required for notifications) - but don't wait too long
  try {
    await CrashLogger.logInfo('Initializing Firebase...');
    await Firebase.initializeApp().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        CrashLogger.logWarning('Firebase initialization timed out, continuing anyway');
        throw TimeoutException('Firebase init timeout');
      },
    );
    await CrashLogger.logInfo('Firebase initialized successfully');
  } catch (e, stackTrace) {
    await CrashLogger.logError('Firebase initialization failed', e, stackTrace);
    // Continue anyway - some features may not work but app won't crash
  }

  // Initialize HydratedBloc storage (required for state) - but don't wait too long
  try {
    await CrashLogger.logInfo('Initializing HydratedBloc storage...');
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: await getApplicationDocumentsDirectory(),
    ).timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        CrashLogger.logWarning('HydratedBloc storage initialization timed out');
        throw TimeoutException('HydratedBloc init timeout');
      },
    );
    await CrashLogger.logInfo('HydratedBloc storage initialized successfully');
  } catch (e, stackTrace) {
    await CrashLogger.logError('HydratedBloc storage initialization failed', e, stackTrace);
    // Continue anyway - state won't persist but app will work
  }
  
  await CrashLogger.logInfo('=== Starting QGlideApp (splash screen will show now) ===');
  runApp(const QGlideApp());
  
  // Initialize non-critical services in background after app starts
  // This allows splash screen to show immediately
  _initializeBackgroundServices();
}

// Initialize non-critical services in background to speed up app startup
Future<void> _initializeBackgroundServices() async {
  // Run in background without blocking
  Future.microtask(() async {
    try {
      await CrashLogger.logInfo('Starting background service initialization...');
      
      // Initialize Supabase (auto-refreshes auth tokens) with error handling
      try {
        await CrashLogger.logInfo('Initializing Supabase (background)...');
        await Supabase.initialize(
          url: 'https://bvazoowmmiymbbhxoggo.supabase.co',
          anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ2YXpvb3dtbWl5bWJiaHhvZ2dvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk2OTQzMjQsImV4cCI6MjA3NTI3MDMyNH0.9vdJHTTnW38CctYwD9GZOvoX_SEu58FLu81mbjQFBdk',
        );
        await CrashLogger.logInfo('Supabase initialized successfully (background)');
      } catch (e, stackTrace) {
        await CrashLogger.logError('Supabase initialization failed (background)', e, stackTrace);
      }
      
      // Load stored access token on app start (before initializing CallService)
      try {
        await CrashLogger.logInfo('Loading stored access token (background)...');
        await ApiService.loadStoredToken();
        await CrashLogger.logInfo('Access token loaded successfully (background)');
      } catch (e, stackTrace) {
        await CrashLogger.logError('Failed to load stored access token (background)', e, stackTrace);
      }
      
      // Initialize Push Notification Service with error handling
      try {
        await CrashLogger.logInfo('Initializing PushNotificationService (background)...');
        await PushNotificationService.initialize();
        await CrashLogger.logInfo('PushNotificationService initialized successfully (background)');
      } catch (e, stackTrace) {
        await CrashLogger.logError('PushNotificationService initialization failed (background)', e, stackTrace);
      }
      
      // Initialize CallService only if user is already authenticated
      // Otherwise it will be initialized after login/OTP verification
      if (ApiService.isAuthenticated) {
        try {
          await CrashLogger.logInfo('Initializing CallService (background)...');
          // Add timeout to prevent app from hanging if Zego initialization gets stuck
          await CallService.initialize().timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              CrashLogger.logWarning('CallService initialization timed out after 10 seconds');
              // Reset CallService to clear any stuck state
              CallService.reset();
            },
          );
          await CrashLogger.logInfo('CallService initialized successfully (background)');
        } catch (e, stackTrace) {
          await CrashLogger.logError('CallService init failed on app start (background)', e, stackTrace);
          // Reset CallService to clear any stuck state on error
          CallService.reset();
          // Silently fail - will retry after login
        }
      }
      
      await CrashLogger.logInfo('Background service initialization completed');
    } catch (e, stackTrace) {
      await CrashLogger.logError('Error in background service initialization', e, stackTrace);
    }
  });
}

// Global flag to track if app is fully ready for navigation
bool _appFullyReady = false;

// Setup incoming call listener after app is running
bool _listenerSetup = false;
void _setupIncomingCallListener() {
  // Prevent multiple listeners
  if (_listenerSetup) {
    if (kDebugMode) {
      print('⚠️ Incoming call listener already set up');
    }
    return;
  }
  _listenerSetup = true;
  
  if (kDebugMode) {
    print('✅ Setting up incoming call listener');
  }
  
  // Mark app as fully ready after listener is set up
  Future.delayed(const Duration(milliseconds: 500), () {
    _appFullyReady = true;
    if (kDebugMode) {
      print('✅ App is fully ready for navigation');
    }
  });
  
  CallService.incomingCalls.listen((event) {
    try {
      // Log incoming call event
      CrashLogger.logCall('Incoming call received', event);
      
      final String counterpartName = (event['caller_name']?.toString() ?? event['from_name']?.toString() ?? 'Incoming Call');
      final String counterpartIdentity = (event['from']?.toString() ?? event['caller_identity']?.toString() ?? 'unknown');
      final String? roomID = event['room_id']?.toString() ?? event['roomId']?.toString() ?? event['callSid']?.toString();
      final String key = counterpartIdentity + ':' + DateTime.now().millisecondsSinceEpoch.toString();
      
      if (kDebugMode) {
        print('📞 Incoming call: name=$counterpartName, identity=$counterpartIdentity, roomID=$roomID');
      }
      
      // Prevent duplicate presentations
      if (_presentedCallKeys.contains(key)) {
        if (kDebugMode) {
          print('⚠️ Duplicate incoming call event ignored: $key');
        }
        return;
      }
      
      // Safe navigation function with retry mechanism
      void presentCallScreen({int retryCount = 0, int maxRetries = 10}) {
        try {
          // Check if navigator is ready
          final navigatorState = appNavigatorKey.currentState;
          if (navigatorState == null) {
            if (retryCount < maxRetries) {
              // Exponential backoff: 100ms, 200ms, 400ms, etc. (capped at 1 second)
              final delayMs = (100 * (1 << (retryCount.clamp(0, 3)))).clamp(100, 1000);
              if (kDebugMode) {
                print('⏳ Navigator not ready, retrying in ${delayMs}ms (attempt ${retryCount + 1}/$maxRetries)');
              }
              Future.delayed(Duration(milliseconds: delayMs), () {
                presentCallScreen(retryCount: retryCount + 1, maxRetries: maxRetries);
              });
            } else {
              // Max retries reached, queue for later
              if (kDebugMode) {
                print('⚠️ Max retries reached, queuing call for later: $counterpartName');
              }
              _pendingIncoming.add(event);
            }
            return;
          }
          
          // Navigator is ready, present the call screen
          _presentedCallKeys.add(key);
          navigatorState.push(
            MaterialPageRoute(
              builder: (_) => CallScreen(
                counterpartName: counterpartName,
                counterpartIdentity: counterpartIdentity,
                isIncoming: true,
                roomID: roomID,
              ),
            ),
          );
          
          if (kDebugMode) {
            print('✅ Call screen presented: $counterpartName (roomID: $roomID)');
          }
        } catch (e, stackTrace) {
          // Log error but don't crash
          if (kDebugMode) {
            print('❌ Error presenting call screen: $e');
            print('Stack trace: $stackTrace');
          }
          // Queue for later if app becomes ready
          if (!_pendingIncoming.contains(event)) {
            _pendingIncoming.add(event);
          }
        }
      }
      
      // CRITICAL: Only present if app is resumed AND fully ready
      if (_appResumed && _appFullyReady) {
        // Use post-frame callback to ensure UI is ready
        SchedulerBinding.instance.addPostFrameCallback((_) {
          presentCallScreen();
        });
      } else {
        if (kDebugMode) {
          print('📱 App not ready (resumed=$_appResumed, fullyReady=$_appFullyReady), queuing call: $counterpartName');
        }
        _pendingIncoming.add(event);
      }
    } catch (e, stackTrace) {
      // Critical: Never crash - log and queue for later
      CrashLogger.logError('Critical error in incoming call listener', e, stackTrace);
      
      if (kDebugMode) {
        print('❌ Critical error in incoming call listener: $e');
        print('Stack trace: $stackTrace');
      }
      // Queue the event for later processing
      if (!_pendingIncoming.contains(event)) {
        _pendingIncoming.add(event);
      }
    }
  });
}

class QGlideApp extends StatefulWidget {
  const QGlideApp({super.key});

  @override
  State<QGlideApp> createState() => _QGlideAppState();
}

class _QGlideAppState extends State<QGlideApp> {
  @override
  void initState() {
    super.initState();
    // Set up incoming call listener after first frame to ensure navigator is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        try {
          _setupIncomingCallListener();
          CrashLogger.logInfo('Incoming call listener setup completed');
        } catch (e, stackTrace) {
          CrashLogger.logError('Failed to setup incoming call listener', e, stackTrace);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ThemeCubit()),
        BlocProvider(create: (context) => LocaleCubit()),
        BlocProvider(create: (context) => DriverCubit()),
        BlocProvider(create: (context) => DocumentCubit()),
        BlocProvider(create: (context) => ChatCubit()),
        BlocProvider(create: (context) => RideCubit()),
      ],
      child: BlocBuilder<LocaleCubit, LocaleState>(
        builder: (context, localeState) {
          return BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
          final baseTheme = ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0D182E),
              brightness: themeState.isDarkTheme ? Brightness.dark : Brightness.light,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: themeState.backgroundColor,
            fontFamily: 'Poppins',
          );

          return _LifecycleHost(
            child: MaterialApp(
            title: 'QGlide',
            restorationScopeId: 'app',
            navigatorKey: appNavigatorKey,
            theme: baseTheme.copyWith(
              textTheme: baseTheme.textTheme.copyWith(
                bodyLarge: TextStyle(color: themeState.textPrimary, fontFamily: 'Poppins'),
                bodyMedium: TextStyle(color: themeState.textPrimary, fontFamily: 'Poppins'),
                bodySmall: TextStyle(color: themeState.textSecondary, fontFamily: 'Poppins'),
                headlineLarge: TextStyle(color: themeState.textPrimary, fontFamily: 'Poppins'),
                headlineMedium: TextStyle(color: themeState.textPrimary, fontFamily: 'Poppins'),
                headlineSmall: TextStyle(color: themeState.textPrimary, fontFamily: 'Poppins'),
                titleLarge: TextStyle(color: themeState.textPrimary, fontFamily: 'Poppins'),
                titleMedium: TextStyle(color: themeState.textPrimary, fontFamily: 'Poppins'),
                titleSmall: TextStyle(color: themeState.textPrimary, fontFamily: 'Poppins'),
              ),
            ),
            // Localization configuration
            locale: localeState.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SplashScreen(),
            routes: {
              '/onboarding': (context) => const OnboardingScreen(),
              '/main': (context) => const MainNavigationScreen(),
            },
            ),
          );
            },
          );
        },
      ),
    );
  }
}

class _LifecycleHost extends StatefulWidget {
  final Widget child;
  const _LifecycleHost({required this.child});

  @override
  State<_LifecycleHost> createState() => _LifecycleHostState();
}

class _LifecycleHostState extends State<_LifecycleHost> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appResumed = state == AppLifecycleState.resumed;
    if (_appResumed && _pendingIncoming.isNotEmpty) {
      // Present any queued incoming calls now that app is resumed
      final queued = List<Map<String, dynamic>>.from(_pendingIncoming);
      _pendingIncoming.clear();
      
      if (kDebugMode) {
        print('📱 App resumed, processing ${queued.length} queued calls');
      }
      
      for (final event in queued) {
        try {
          final String counterpartName = (event['caller_name']?.toString() ?? event['from_name']?.toString() ?? 'Incoming Call');
          final String counterpartIdentity = (event['from']?.toString() ?? event['caller_identity']?.toString() ?? 'unknown');
          final String? roomID = event['room_id']?.toString() ?? event['roomId']?.toString() ?? event['callSid']?.toString();
          final String key = counterpartIdentity + ':' + DateTime.now().millisecondsSinceEpoch.toString();
          
          // Check if already presented
          if (_presentedCallKeys.contains(key)) {
            continue;
          }
          
          // Use post-frame callback to ensure UI is ready
          SchedulerBinding.instance.addPostFrameCallback((_) {
            try {
              final navigatorState = appNavigatorKey.currentState;
              if (navigatorState != null) {
                _presentedCallKeys.add(key);
                navigatorState.push(
                  MaterialPageRoute(
                    builder: (_) => CallScreen(
                      counterpartName: counterpartName,
                      counterpartIdentity: counterpartIdentity,
                      isIncoming: true,
                      roomID: roomID,
                    ),
                  ),
                );
                if (kDebugMode) {
                  print('✅ Queued call screen presented: $counterpartName (roomID: $roomID)');
                }
              } else {
                // Navigator still not ready, re-queue
                if (kDebugMode) {
                  print('⚠️ Navigator still not ready, re-queuing call');
                }
                _pendingIncoming.add(event);
              }
            } catch (e, stackTrace) {
              if (kDebugMode) {
                print('❌ Error presenting queued call screen: $e');
                print('Stack trace: $stackTrace');
              }
              // Re-queue on error
              _pendingIncoming.add(event);
            }
          });
        } catch (e, stackTrace) {
          if (kDebugMode) {
            print('❌ Error processing queued call event: $e');
            print('Stack trace: $stackTrace');
          }
          // Re-queue on error
          _pendingIncoming.add(event);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

