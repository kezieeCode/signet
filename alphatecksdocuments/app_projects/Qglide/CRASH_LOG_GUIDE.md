# How to Get Crash Logs from Release Builds

This guide explains how to retrieve crash logs when testing release APK builds.

## Method 1: Using ADB Logcat (Recommended - Works with Release Builds)

**This is the BEST method for release builds** - it works even when the app is not debuggable.

Even in release builds, Android logcat captures system-level logs. You can filter for your app's logs:

### Step 1: Connect Your Device
```bash
# Connect your Android device via USB and enable USB debugging
adb devices
```

### Step 2: Clear and Start Fresh Logging
```bash
# Clear the logcat buffer first
adb logcat -c

# Start logging everything (best for catching crashes)
adb logcat > crash_logs.txt
```

### Step 3: Reproduce the Crash
1. With `adb logcat > crash_logs.txt` running in your terminal
2. Reproduce the crash on your device
3. Stop logging (Ctrl+C in terminal)
4. Check `crash_logs.txt` for error messages

### Step 4: Filter the Logs
```bash
# View only errors and warnings
cat crash_logs.txt | grep -E "(ERROR|FATAL|AndroidRuntime|Exception|Error)" > errors_only.txt

# Or view last 200 lines (most recent)
tail -200 crash_logs.txt

# Search for specific terms
grep -i "qglide\|twilio\|call\|notification" crash_logs.txt
```

## Method 2: Using the App's Internal Log File

The app now automatically logs all errors, warnings, and important events to a file on the device.

### Step 1: Get the Log File

**Note:** `run-as` only works with debuggable builds. For release builds, use **Method 1 (ADB Logcat)** above, or rebuild with the updated code that writes to external storage.

#### Option A: If App is Debuggable (Debug Builds)
```bash
# Using run-as (works on debuggable apps)
adb shell run-as com.alphatecks.qglide cat files/qglide_crash_logs.txt > crash_logs.txt
```

#### Option B: External Storage (After Rebuild)
After rebuilding with the updated code, logs will be in external storage:
```bash
# Check if logs exist in external storage
adb shell ls -la /storage/emulated/0/Android/data/com.alphatecks.qglide/files/QGlideLogs/

# Pull the log file (no permission issues)
adb pull /storage/emulated/0/Android/data/com.alphatecks.qglide/files/QGlideLogs/qglide_crash_logs.txt ./crash_logs.txt
```

#### Option C: Copy to Accessible Location (If App is Debuggable)
```bash
# Copy the file to Downloads folder
adb shell run-as com.alphatecks.qglide cp files/qglide_crash_logs.txt /sdcard/Download/qglide_crash_logs.txt
adb pull /sdcard/Download/qglide_crash_logs.txt ./crash_logs.txt
```

### Step 3: View the Logs
```bash
# View the log file
cat crash_logs.txt

# Or open in your text editor
open crash_logs.txt  # macOS
notepad crash_logs.txt  # Windows
```

## Method 3: Using Android Studio Logcat

1. Open Android Studio
2. Connect your device
3. Go to **View > Tool Windows > Logcat**
4. Select your device from the dropdown
5. Filter by package name: `com.alphatecks.qglide`
6. Reproduce the crash
7. Copy the relevant error logs

## Method 4: Check Android System Logs

Android also stores crash logs in system directories:

```bash
# Check for ANR (Application Not Responding) logs
adb shell cat /data/anr/traces.txt

# Check for crash logs (requires root on some devices)
adb shell cat /data/tombstones/tombstone_*
```

## What the Logs Contain

The app's internal log file (`qglide_crash_logs.txt`) contains:

- **Timestamps**: Every log entry has a timestamp
- **Error Logs**: All exceptions with full stack traces
- **Warning Logs**: Important warnings that might indicate issues
- **Info Logs**: App lifecycle events (startup, initialization)
- **Notification Logs**: All FCM notification events
- **Call Logs**: All Twilio call-related events

### Log Format Example:
```
[2024-01-15 14:30:25.123] INFO: App initialization started
[2024-01-15 14:30:25.456] INFO: Firebase initialized
[2024-01-15 14:30:26.789] NOTIFICATION: Foreground message received
  Data: {messageId: abc123, title: Incoming Call, data: {...}}
[2024-01-15 14:30:27.012] ERROR: Flutter Error: Exception: Navigator not ready
  Error: Exception: Navigator not ready
  Stack trace:
    #0      main.<anonymous closure>.<anonymous closure> (package:qglide/main.dart:175:12)
    ...
```

## Tips for Debugging

1. **Clear logs before testing**: The log file auto-rotates when it gets too large, but you can clear it manually if needed
2. **Reproduce immediately**: After a crash, pull the logs right away before the app restarts
3. **Check both sources**: Compare ADB logcat with the internal log file for complete picture
4. **Look for patterns**: Multiple crashes with the same error indicate a systematic issue

## Quick Commands Reference

### For Release Builds (Not Debuggable):
```bash
# Clear logcat and start fresh logging (BEST METHOD)
adb logcat -c && adb logcat > crash_logs.txt

# After crash, filter for errors
cat crash_logs.txt | grep -E "(ERROR|FATAL|AndroidRuntime|Exception)" > errors.txt

# View last 200 lines (most recent)
tail -200 crash_logs.txt
```

### For Debug Builds (Debuggable):
```bash
# Get internal log file using run-as
adb shell run-as com.alphatecks.qglide cat files/qglide_crash_logs.txt > crash_logs.txt

# Or pull from external storage (after rebuild)
adb pull /storage/emulated/0/Android/data/com.alphatecks.qglide/files/QGlideLogs/qglide_crash_logs.txt ./crash_logs.txt
```

### Filter Logcat for Specific Terms:
```bash
# View last 100 lines filtered for your app
adb logcat -t 100 | grep -i "qglide"

# Filter for errors only
adb logcat *:E | grep -i "qglide"
```

## Troubleshooting

**Problem**: `adb pull` says "permission denied"
**Solution**: Use `adb shell run-as` method or ensure USB debugging is enabled

**Problem**: Log file is empty
**Solution**: The crash might have happened before logging initialized. Check ADB logcat instead.

**Problem**: Can't find the log file
**Solution**: The file is created on first app launch. Make sure the app has run at least once.

