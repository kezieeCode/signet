# How to View Crash Logs for Release APK

When your release APK crashes, you can view the errors using the methods below.

## Method 1: View Logs via ADB (Recommended)

### Step 1: Connect your device
```bash
# Check if device is connected
adb devices
```

### Step 2: Capture logs during testing (RECOMMENDED)

**Start capturing logs BEFORE running your app:**

```bash
# Clear old logs first
adb logcat -c

# Start capturing logs to file (runs continuously)
adb logcat > crash_logs_$(date +%Y%m%d_%H%M%S).txt

# Or filter for your app only (less verbose)
adb logcat | grep -i "qglide\|flutter\|error\|exception" > crash_logs_$(date +%Y%m%d_%H%M%S).txt

# Or capture only errors and warnings (most useful) - QUOTE THE FILTERS FOR ZSH
adb logcat '*:E' '*:W' > crash_logs_errors_$(date +%Y%m%d_%H%M%S).txt
```

**Run this in a separate terminal window** - it will keep capturing logs until you press `Ctrl+C`. Then run your app and test. When done, press `Ctrl+C` to stop capturing.

### Step 3: View real-time logs (alternative)
```bash
# View all logs from your app
adb logcat -s flutter

# View all logs (more verbose)
adb logcat | grep -i qglide

# View only errors and warnings (quote filters for zsh)
adb logcat '*:E' '*:W' | grep -i qglide
```

### Step 3: View crash log file from app
The app stores crash logs in a file. To access it:

```bash
# For Android 10+ (API 29+)
adb shell run-as com.alphatecks.qglide cat /data/data/com.alphatecks.qglide/files/QGlideLogs/qglide_crash_logs.txt

# For external storage (if available)
adb shell cat /storage/emulated/0/Android/data/com.alphatecks.qglide/files/QGlideLogs/qglide_crash_logs.txt

# Pull the log file to your computer
adb pull /storage/emulated/0/Android/data/com.alphatecks.qglide/files/QGlideLogs/qglide_crash_logs.txt ./crash_logs.txt
```

## Method 2: View Logs via Android Studio

1. Open Android Studio
2. Connect your device
3. Go to **View > Tool Windows > Logcat**
4. Filter by package name: `com.alphatecks.qglide`
5. Look for errors marked in red

## Method 3: View Logs via Device File Manager

1. Install a file manager app on your device (e.g., "Files by Google")
2. Navigate to: `Android/data/com.alphatecks.qglide/files/QGlideLogs/`
3. Open `qglide_crash_logs.txt`

## Method 4: Check Logcat During Crash

When the app crashes, immediately run:

```bash
# Get the last 500 lines of logcat
adb logcat -d -t 500 > crash_logs.txt

# Or filter for your app only
adb logcat -d | grep -i "com.alphatecks.qglide" > crash_logs.txt
```

## Common Issues and Solutions

### Issue: "run-as: package not debuggable"
**Solution**: The release APK is not debuggable. Use external storage method instead:
```bash
adb shell cat /storage/emulated/0/Android/data/com.alphatecks.qglide/files/QGlideLogs/qglide_crash_logs.txt
```

### Issue: "Permission denied"
**Solution**: Make sure you have USB debugging enabled and the device is authorized.

### Issue: Logs are empty
**Solution**: 
1. Check if the app has storage permissions
2. Try running the app in debug mode first to verify logging works
3. Check if the log file exists: `adb shell ls -la /storage/emulated/0/Android/data/com.alphatecks.qglide/files/QGlideLogs/`

## What to Look For in Logs

1. **Flutter Errors**: Look for lines starting with `ERROR:` or `Flutter Error:`
2. **Stack Traces**: Look for lines with file paths and line numbers
3. **Initialization Errors**: Look for errors during app startup
4. **Missing Assets**: Look for errors about missing images or fonts
5. **Permission Errors**: Look for permission-related errors
6. **API Errors**: Look for network or API-related errors

## Quick Debug Commands

### For Continuous Logging During Testing:

```bash
# 1. Clear old logs
adb logcat -c

# 2. Start capturing logs (run in separate terminal, press Ctrl+C when done)
adb logcat > test_logs_$(date +%Y%m%d_%H%M%S).txt

# 3. Now run your app and test
# 4. When done testing, press Ctrl+C to stop capturing
```

### Other Useful Commands:

```bash
# Clear logcat buffer
adb logcat -c

# Capture logs with timestamps
adb logcat -v time > test_logs_$(date +%Y%m%d_%H%M%S).txt

# Filter for errors only (quote filters for zsh)
adb logcat '*:E' > errors_only.txt

# Monitor in real-time (see logs as they happen)
adb logcat -v time | grep -i "qglide\|flutter\|error"

# Capture with specific tags (most useful) - QUOTE FILTERS FOR ZSH
adb logcat -v time '*:E' '*:W' 'flutter:*' > test_logs_$(date +%Y%m%d_%H%M%S).txt
```

### Recommended Testing Workflow:

```bash
# Terminal 1: Start log capture (quote filters for zsh)
adb logcat -c
adb logcat -v time '*:E' '*:W' 'flutter:*' > test_session_$(date +%Y%m%d_%H%M%S).txt

# Terminal 2: Run your app
flutter run --release
# or install and run the APK

# When done testing, go back to Terminal 1 and press Ctrl+C
```

## Getting Help

When reporting crashes, include:
1. The crash log file content
2. The device model and Android version
3. Steps to reproduce the crash
4. Screenshots if available

