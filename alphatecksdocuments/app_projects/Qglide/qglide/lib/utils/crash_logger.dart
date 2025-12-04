import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class CrashLogger {
  static File? _logFile;
  static const int _maxLogSize = 100 * 1024; // 100KB max log file size
  static const int _maxLogLines = 1000; // Keep last 1000 lines

  /// Initialize the crash logger
  static Future<void> initialize() async {
    try {
      Directory directory;
      
      // Try to use external storage (more accessible) first, fallback to app directory
      if (Platform.isAndroid) {
        try {
          // Try external storage directory (usually /storage/emulated/0/Android/data/com.alphatecks.qglide/files)
          // This is accessible via ADB without root
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            // Create a logs subdirectory
            final logsDir = Directory('${externalDir.path}/QGlideLogs');
            if (!await logsDir.exists()) {
              await logsDir.create(recursive: true);
            }
            directory = logsDir;
          } else {
            // Fallback to app documents directory (requires run-as to access)
            directory = await getApplicationDocumentsDirectory();
          }
        } catch (e) {
          // Fallback to app documents directory
          directory = await getApplicationDocumentsDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      
      _logFile = File('${directory.path}/qglide_crash_logs.txt');
      
      // Rotate log if it gets too large
      if (await _logFile!.exists()) {
        final size = await _logFile!.length();
        if (size > _maxLogSize) {
          await _rotateLog();
        }
      }
      
      await _writeLog('=== App Started at ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())} ===');
    } catch (e) {
      // Silently fail - logging shouldn't crash the app
      if (kDebugMode) {
        print('⚠️ Failed to initialize crash logger: $e');
      }
    }
  }

  /// Rotate log file to keep it manageable
  static Future<void> _rotateLog() async {
    try {
      if (_logFile == null || !await _logFile!.exists()) return;
      
      final content = await _logFile!.readAsString();
      final lines = content.split('\n');
      
      // Keep only the last N lines
      if (lines.length > _maxLogLines) {
        final recentLines = lines.sublist(lines.length - _maxLogLines);
        await _logFile!.writeAsString(recentLines.join('\n'));
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Write a log entry
  static Future<void> _writeLog(String message) async {
    try {
      if (_logFile == null) {
        await initialize();
      }
      
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());
      final logEntry = '[$timestamp] $message\n';
      
      await _logFile!.writeAsString(
        logEntry,
        mode: FileMode.append,
        flush: true,
      );
      
      // Also print to console in debug mode
      if (kDebugMode) {
        print(logEntry.trim());
      }
    } catch (e) {
      // Silently fail - don't crash the app
    }
  }

  /// Log an error with stack trace
  static Future<void> logError(String message, [Object? error, StackTrace? stackTrace]) async {
    try {
      final errorMsg = error != null ? error.toString() : '';
      final stackMsg = stackTrace != null ? stackTrace.toString() : '';
      
      await _writeLog('ERROR: $message');
      if (errorMsg.isNotEmpty) {
        await _writeLog('  Error: $errorMsg');
      }
      if (stackMsg.isNotEmpty) {
        // Split stack trace into multiple lines for readability
        final stackLines = stackMsg.split('\n');
        for (final line in stackLines) {
          if (line.trim().isNotEmpty) {
            await _writeLog('  $line');
          }
        }
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Log a warning
  static Future<void> logWarning(String message) async {
    await _writeLog('WARNING: $message');
  }

  /// Log an info message
  static Future<void> logInfo(String message) async {
    await _writeLog('INFO: $message');
  }

  /// Log notification events
  static Future<void> logNotification(String event, Map<String, dynamic>? data) async {
    try {
      await _writeLog('NOTIFICATION: $event');
      if (data != null && data.isNotEmpty) {
        await _writeLog('  Data: ${data.toString()}');
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Log call events
  static Future<void> logCall(String event, Map<String, dynamic>? data) async {
    try {
      await _writeLog('CALL: $event');
      if (data != null && data.isNotEmpty) {
        await _writeLog('  Data: ${data.toString()}');
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Get the log file path (for sharing/debugging)
  static Future<String?> getLogFilePath() async {
    try {
      if (_logFile == null) {
        await initialize();
      }
      return _logFile?.path;
    } catch (e) {
      return null;
    }
  }

  /// Get log file content as string
  static Future<String> getLogContent() async {
    try {
      if (_logFile == null) {
        await initialize();
      }
      if (await _logFile!.exists()) {
        return await _logFile!.readAsString();
      }
      return 'No logs available';
    } catch (e) {
      return 'Error reading logs: $e';
    }
  }

  /// Clear logs
  static Future<void> clearLogs() async {
    try {
      if (_logFile != null && await _logFile!.exists()) {
        await _logFile!.delete();
      }
      await initialize();
    } catch (e) {
      // Silently fail
    }
  }
}

